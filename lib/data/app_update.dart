import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Une version publiée sur les releases GitHub (tag `build-<versionCode>`).
class AppRelease {
  const AppRelease({required this.versionCode, required this.versionName, required this.notes, required this.apkUrl, required this.apkSize});
  final int versionCode;
  final String versionName;
  final String notes;
  final String apkUrl;
  final int apkSize;
}

/// Mises à jour hors Play Store : chaque push sur `main` publie une release GitHub (voir
/// `.github/workflows/release.yml`) ; l'app compare son versionCode et installe l'APK de son ABI.
class AppUpdater {
  static const repo = 'CianusDev/youplay';
  static const _ch = MethodChannel('youplay/update');

  static Map<String, dynamic>? _info;

  static Future<Map<String, dynamic>> _deviceInfo() async =>
      _info ??= Map<String, dynamic>.from(await _ch.invokeMethod<Map<Object?, Object?>>('info') ?? const {});

  static Future<int> currentVersionCode() async => ((await _deviceInfo())['versionCode'] as num?)?.toInt() ?? 0;

  static Future<String> currentVersionName() async => (await _deviceInfo())['versionName'] as String? ?? '';

  /// Dernière release si elle est plus récente que l'app installée, sinon null.
  static Future<AppRelease?> checkNewer() async {
    if (!Platform.isAndroid) return null;
    final res = await http.get(
      Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
      headers: const {'Accept': 'application/vnd.github+json', 'User-Agent': 'YouPlay-app'},
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final code = int.tryParse((j['tag_name'] as String? ?? '').replaceFirst('build-', ''));
    if (code == null || code <= await currentVersionCode()) return null;

    // APK de l'architecture du téléphone (arm64-v8a sur presque tous les téléphones récents).
    final assets = (j['assets'] as List? ?? const []).cast<Map<String, dynamic>>();
    final abis = ((await _deviceInfo())['abis'] as List? ?? const []).cast<String>();
    Map<String, dynamic>? apk;
    for (final abi in [...abis, 'universal']) {
      apk = assets.where((a) => (a['name'] as String).contains('-$abi-')).firstOrNull;
      if (apk != null) break;
    }
    apk ??= assets.where((a) => (a['name'] as String).endsWith('.apk')).firstOrNull;
    if (apk == null) return null;

    final name = (j['name'] as String? ?? '').replaceFirst('YouPlay ', '');
    return AppRelease(
      versionCode: code,
      versionName: name.isEmpty ? 'build $code' : name,
      notes: (j['body'] as String? ?? '').trim(),
      apkUrl: apk['browser_download_url'] as String,
      apkSize: (apk['size'] as num?)?.toInt() ?? 0,
    );
  }

  /// Télécharge l'APK dans le cache (dossier partagé avec l'installateur via FileProvider).
  static Future<File> download(AppRelease r, void Function(double progress) onProgress) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/updates');
    if (await dir.exists()) await dir.delete(recursive: true); // anciens APK
    await dir.create(recursive: true);
    final file = File('${dir.path}/youplay-${r.versionCode}.apk');
    final client = http.Client();
    try {
      final res = await client.send(http.Request('GET', Uri.parse(r.apkUrl)));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final total = res.contentLength ?? r.apkSize;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in res.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress(received / total);
        }
      } finally {
        await sink.close();
      }
      return file;
    } finally {
      client.close();
    }
  }

  /// Ouvre l'installateur Android (l'utilisateur confirme ; la 1re fois, il autorise YouPlay).
  static Future<void> install(File apk) => _ch.invokeMethod<void>('install', {'path': apk.path});
}
