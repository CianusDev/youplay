import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Une version publiée sur les releases GitHub (tag `build-<versionCode>`).
class AppRelease {
  const AppRelease({
    required this.versionCode,
    required this.versionName,
    required this.notes,
    required this.apkUrl,
    required this.apkSize,
    this.newApp = false,
  });
  final int versionCode;
  final String versionName;
  final String notes;
  final String apkUrl;
  final int apkSize;

  /// Identifiant d'app différent : l'APK s'installe à côté de l'app actuelle (déménagement
  /// `com.example.sika_app` → `io.github.cianusdev.youplay`), puis la bibliothèque est transférée.
  final bool newApp;
}

/// Mises à jour hors Play Store : chaque push sur `main` publie une release GitHub (voir
/// `.github/workflows/release.yml`) ; l'app compare son versionCode et installe l'APK de son ABI.
class AppUpdater {
  static const repo = 'CianusDev/youplay';
  static const _ch = MethodChannel('youplay/update');

  static Map<String, dynamic>? _info;

  static Future<Map<String, dynamic>> _deviceInfo() async =>
      _info ??= Map<String, dynamic>.from(await _ch.invokeMethod<Map<Object?, Object?>>('info') ?? const {});

  /// Numéro de build installé. Un APK `--split-per-abi` ajoute l'ABI au versionCode
  /// (armeabi-v7a 1000+n, arm64-v8a 2000+n, x86_64 4000+n) : on ne garde que n, le numéro
  /// des tags `build-<n>`. Sans ça, la version 20 valait 2020 et aucune release ne semblait plus récente.
  static Future<int> currentBuild() async => (((await _deviceInfo())['versionCode'] as num?)?.toInt() ?? 0) % 1000;

  static Future<String> currentVersionName() async => (await _deviceInfo())['versionName'] as String? ?? '';

  /// Infos techniques jointes aux avis : version de l'app, d'Android, modèle du téléphone.
  static Future<String> diagnostics() async {
    try {
      final i = await _deviceInfo();
      return 'YouPlay ${i['versionName']} (${await currentBuild()})\n'
          'Android ${i['android']} (SDK ${i['sdk']})\n'
          '${i['device']}';
    } catch (_) {
      return 'YouPlay';
    }
  }

  /// Dernière release si elle est plus récente que l'app installée, sinon null.
  /// Lit `version.json` publié avec chaque release, via une simple redirection GitHub :
  /// l'API REST est évitée car limitée à 60 requêtes/heure par adresse IP, vite atteinte
  /// derrière le NAT d'un opérateur mobile (la vérification échouait alors sans raison visible).
  static Future<AppRelease?> checkNewer() async {
    if (!Platform.isAndroid) return null;
    final res = await http.get(
      Uri.parse('https://github.com/$repo/releases/latest/download/version.json'),
      headers: const {'User-Agent': 'YouPlay-app'},
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 404) return null; // aucune release avec version.json
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final code = (j['versionCode'] as num?)?.toInt();
    final tag = j['tag'] as String?;
    if (code == null || tag == null || code <= await currentBuild()) return null;

    // APK de l'architecture du téléphone (arm64-v8a sur presque tous les téléphones récents).
    final apks = (j['apks'] as Map? ?? const {}).cast<String, dynamic>();
    final abis = ((await _deviceInfo())['abis'] as List? ?? const []).cast<String>();
    Map<String, dynamic>? apk;
    for (final abi in abis) {
      apk = (apks[abi] as Map?)?.cast<String, dynamic>();
      if (apk != null) break;
    }
    if (apk == null) return null; // aucune version pour ce processeur

    return AppRelease(
      versionCode: code,
      versionName: j['versionName'] as String? ?? 'build $code',
      notes: (j['notes'] as String? ?? '').trim(),
      apkUrl: 'https://github.com/$repo/releases/download/$tag/${apk['name']}',
      apkSize: (apk['size'] as num?)?.toInt() ?? 0,
      newApp: j['applicationId'] is String && j['applicationId'] != (await _deviceInfo())['packageName'],
    );
  }

  /// Dossier des APK : dans les fichiers privés de l'app (pas le cache, qu'Android peut vider),
  /// partagé avec l'installateur via FileProvider (`update_paths.xml`).
  static Future<Directory> _dir() async {
    final d = Directory('${(await getApplicationSupportDirectory()).path}/updates');
    await d.create(recursive: true);
    return d;
  }

  static Future<File> _apkFile(AppRelease r) async => File('${(await _dir()).path}/youplay-${r.versionCode}.apk');

  /// APK de cette version déjà téléchargé en entier (téléphone éteint, installation reportée…).
  static Future<File?> downloaded(AppRelease r) async {
    final f = await _apkFile(r);
    if (!await f.exists()) return null;
    if (r.apkSize > 0 && await f.length() != r.apkSize) return null;
    return f;
  }

  /// Télécharge l'APK, ou réutilise celui déjà téléchargé. Un téléchargement interrompu
  /// (coupure réseau, téléphone éteint) reprend là où il s'était arrêté.
  static Future<File> download(AppRelease r, void Function(double progress) onProgress) async {
    final dir = await _dir();
    final file = await _apkFile(r);
    final part = File('${file.path}.part');
    // Anciennes versions : plus utiles.
    await for (final e in dir.list()) {
      if (e is File && e.path != file.path && e.path != part.path) await e.delete();
    }
    if (await downloaded(r) != null) {
      onProgress(1);
      return file;
    }
    var have = await part.exists() ? await part.length() : 0;
    if (r.apkSize > 0 && have > r.apkSize) {
      await part.delete();
      have = 0;
    }
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(r.apkUrl));
      if (have > 0) req.headers['Range'] = 'bytes=$have-';
      final res = await client.send(req);
      if (res.statusCode == 200) {
        have = 0; // le serveur renvoie tout : on repart de zéro
      } else if (res.statusCode != 206) {
        if (res.statusCode == 416) await part.delete(); // morceau invalide : recommencer au prochain essai
        throw HttpException('HTTP ${res.statusCode}');
      }
      final total = r.apkSize > 0 ? r.apkSize : have + (res.contentLength ?? 0);
      var received = have;
      if (total > 0) onProgress(received / total);
      final sink = part.openWrite(mode: have > 0 ? FileMode.append : FileMode.write);
      try {
        await for (final chunk in res.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress(received / total);
        }
      } finally {
        await sink.close();
      }
      if (r.apkSize > 0 && await part.length() != r.apkSize) throw const HttpException('APK incomplet');
      return await part.rename(file.path);
    } finally {
      client.close();
    }
  }

  /// Au démarrage : supprime les APK déjà installés (version égale ou plus ancienne que l'app).
  static Future<void> cleanup() async {
    try {
      final current = await currentBuild();
      final dir = await _dir();
      await for (final e in dir.list()) {
        final code = int.tryParse(RegExp(r'youplay-(\d+)\.apk').firstMatch(e.path)?.group(1) ?? '');
        if (code != null && code <= current) await e.delete();
      }
      // Ancien emplacement (cache) des versions précédentes de l'app.
      final old = Directory('${(await getTemporaryDirectory()).path}/updates');
      if (await old.exists()) await old.delete(recursive: true);
    } catch (_) {}
  }

  /// Ouvre l'installateur Android (l'utilisateur confirme ; la 1re fois, il autorise YouPlay).
  static Future<void> install(File apk) => _ch.invokeMethod<void>('install', {'path': apk.path});
}
