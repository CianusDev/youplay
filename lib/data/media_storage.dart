import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models.dart';

/// Emplacement des téléchargements : `Music/YouPlay` (visible dans le gestionnaire de fichiers
/// et les autres lecteurs), avec repli sur le dossier privé de l'app si l'écriture échoue.
class MediaStorage {
  static const _ch = MethodChannel('youplay/media');
  static Directory? _dir;

  /// Tests uniquement : oublie le dossier résolu.
  @visibleForTesting
  static void resetForTest() => _dir = null;

  /// Demande « Musique et audio » (Android 13+) ou le stockage (≤ 12).
  /// Écrire ses propres fichiers dans Music n'en a pas besoin ; relire après réinstallation, si.
  static Future<void> ensurePermission() async {
    try {
      final audio = await Permission.audio.status;
      if (!audio.isGranted) {
        final r = await Permission.audio.request();
        if (r.isGranted) return;
      } else {
        return;
      }
      if (!(await Permission.storage.status).isGranted) await Permission.storage.request();
    } catch (_) {}
  }

  static Future<Directory> downloadsDir() async {
    if (_dir != null) return _dir!;
    try {
      final music = await _ch.invokeMethod<String>('musicDir');
      final d = Directory('$music/YouPlay');
      await d.create(recursive: true);
      // Test d'écriture réel (stockage partagé indisponible ou refusé).
      final probe = File('${d.path}/.youplay');
      await probe.writeAsString('ok');
      return _dir = d;
    } catch (_) {
      final d = Directory('${(await getApplicationSupportDirectory()).path}/downloads');
      await d.create(recursive: true);
      return _dir = d;
    }
  }

  /// Nom lisible et unique : « Artiste - Titre.m4a » (puis « (2) », « (3) »…).
  static Future<File> fileFor(Track t) async {
    final dir = await downloadsDir();
    var base = '${t.artist.name} - ${t.title}'.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (base.length > 120) base = base.substring(0, 120).trim();
    if (base.isEmpty) base = t.id;
    var f = File('${dir.path}/$base.m4a');
    for (var i = 2; await f.exists(); i++) {
      f = File('${dir.path}/$base ($i).m4a');
    }
    return f;
  }

  /// Enregistre une image dans `Pictures/YouPlay` (visible dans la galerie). Retourne le chemin.
  static Future<String?> savePicture(List<int> bytes, String name) async {
    try {
      final pics = await _ch.invokeMethod<String>('picturesDir');
      final dir = Directory('$pics/YouPlay');
      await dir.create(recursive: true);
      final f = File('${dir.path}/$name');
      await f.writeAsBytes(bytes);
      await scan(f.path);
      return f.path;
    } catch (_) {
      return null;
    }
  }

  /// Signale le fichier à la médiathèque Android (apps musique, explorateur).
  static Future<void> scan(String path) async {
    try {
      await _ch.invokeMethod<void>('scan', {'path': path});
    } catch (_) {}
  }
}
