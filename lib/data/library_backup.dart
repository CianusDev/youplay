import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sauvegarde de la bibliothèque (likes, playlists, historique, téléchargements, réglages) dans un
/// fichier JSON : sert aussi à passer de l'ancienne app `com.example.sika_app` à
/// `io.github.cianusdev.youplay` (clés différentes, voir `LibraryTransfer.kt`).
class LibraryBackup {
  static const _ch = MethodChannel('youplay/backup');

  /// Tout ce qui fait « ta » YouPlay. Les clés absentes d'une sauvegarde sont effacées à la restauration.
  static const keys = [
    'sika.library.v1', // likes, playlists, artistes suivis, historique, prénom
    'sika.downloads.v1', // sons téléchargés (chemins dans Music/YouPlay) et réglages hors ligne
    'youplay.lyrics.v1', // décalages de paroles
    'youplay.session.v1', // file d'attente en cours
    'youplay.locale', // langue choisie
  ];
  static const _format = 1;

  /// Contenu du fichier de sauvegarde.
  static String export(SharedPreferences prefs) => const JsonEncoder.withIndent(' ').convert({
        'app': 'YouPlay',
        'format': _format,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'data': {
          for (final k in keys)
            if (prefs.getString(k) != null) k: prefs.getString(k),
        },
      });

  /// Lit une sauvegarde ; null si ce n'est pas un fichier YouPlay.
  static Map<String, String>? parse(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['app'] != 'YouPlay' || (j['format'] as num? ?? 0) > _format) return null;
      final data = (j['data'] as Map).cast<String, dynamic>();
      return {
        for (final e in data.entries)
          if (keys.contains(e.key) && e.value is String) e.key: e.value as String,
      };
    } catch (_) {
      return null;
    }
  }

  /// Remplace la bibliothèque. Les sons dont le fichier n'est plus sur le téléphone (sauvegarde
  /// venue d'un autre appareil) sont retirés : ceux des playlists se retéléchargent tout seuls.
  /// Demander « Musique et audio » avant : sans elle, les sons d'une autre app paraissent absents.
  static Future<void> restore(SharedPreferences prefs, Map<String, String> data, {bool checkFiles = true}) async {
    for (final k in keys) {
      var v = data[k];
      if (checkFiles && k == 'sika.downloads.v1' && v != null) v = _keepExistingFiles(v);
      if (v == null) {
        await prefs.remove(k);
      } else {
        await prefs.setString(k, v);
      }
    }
  }

  static String _keepExistingFiles(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final items = (j['items'] as List).cast<Map<String, dynamic>>();
      j['items'] = [
        for (final it in items)
          if (it['status'] != 'done' || (it['path'] is String && File(it['path'] as String).existsSync())) it,
      ];
      return jsonEncode(j);
    } catch (_) {
      return raw;
    }
  }

  /// Chemins des sons téléchargés enregistrés dans les préférences.
  static List<String> downloadedPaths(SharedPreferences prefs) {
    try {
      final j = jsonDecode(prefs.getString('sika.downloads.v1') ?? '') as Map<String, dynamic>;
      return [
        for (final it in (j['items'] as List).cast<Map<String, dynamic>>())
          if (it['status'] == 'done' && it['path'] is String) it['path'] as String,
      ];
    } catch (_) {
      return const [];
    }
  }

  // --- Fichier (sélecteurs Android) ---

  /// Enregistre la sauvegarde là où l'utilisateur choisit. true = enregistré, null = annulé.
  static Future<bool?> saveToFile(SharedPreferences prefs) {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return _ch.invokeMethod<bool>('save', {
      'name': 'youplay-${d.year}-${two(d.month)}-${two(d.day)}.json',
      'content': export(prefs),
    });
  }

  /// Contenu du fichier choisi ; null = annulé.
  static Future<String?> pickFile() => _ch.invokeMethod<String>('open');

  /// Relance l'app pour recharger la bibliothèque restaurée.
  static Future<void> restart() => _ch.invokeMethod<void>('restart');

  // --- Passage de l'ancienne app (com.example.sika_app) à la nouvelle ---

  static Future<MigrationInfo> info() async {
    final m = (await _ch.invokeMethod<Map<Object?, Object?>>('info') ?? const {}).cast<String, Object?>();
    return MigrationInfo(
      packageName: m['packageName'] as String? ?? '',
      legacyInstalled: m['legacyInstalled'] == true,
      sdk: (m['sdk'] as num?)?.toInt() ?? 0,
    );
  }

  /// Ouvre l'ancienne YouPlay (pour y exporter la bibliothèque).
  static Future<bool> openLegacy() async => await _ch.invokeMethod<bool>('openLegacy') ?? false;

  /// Ouvre la désinstallation de l'ancienne app (Android demande confirmation).
  static Future<bool> uninstallLegacy() async => await _ch.invokeMethod<bool>('uninstallLegacy') ?? false;

  /// Nombre de sons téléchargés qui appartiennent à une autre app (lecture seule pour nous).
  static Future<int> foreignCount(List<String> paths) async => await _ch.invokeMethod<int>('foreign', {'paths': paths}) ?? 0;

  /// Reprend les sons téléchargés par une autre app (ancienne YouPlay, ou YouPlay réinstallée) :
  /// copie + confirmation Android. Retourne le nombre de sons repris, -1 si l'utilisateur a refusé.
  static Future<int> adopt(List<String> paths) async => await _ch.invokeMethod<int>('adopt', {'paths': paths}) ?? 0;
}

class MigrationInfo {
  const MigrationInfo({required this.packageName, required this.legacyInstalled, required this.sdk});
  final String packageName;

  /// L'ancienne YouPlay (`com.example.sika_app`, notre certificat) est encore installée.
  final bool legacyInstalled;
  final int sdk;
}
