import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/media_storage.dart';
import '../data/models.dart';
import 'download_manager.dart';
import 'library_store.dart';

/// Chaque playlist perso = un dossier `Music/YouPlay/<nom>` sur le téléphone :
/// - les titres de la playlist y sont téléchargés (copie du fichier) ;
/// - un `<nom>.m3u8` permet aux autres lecteurs de voir la playlist ;
/// - un manifeste caché `.youplay.json` liste les fichiers gérés par l'app :
///   seuls ceux-là sont supprimés quand un titre est retiré (tes propres fichiers ne sont jamais touchés).
class PlaylistFolders {
  PlaylistFolders(this.ref);
  final Ref ref;

  Timer? _debounce;
  bool _running = false;
  bool _again = false;

  static String folderName(String playlistName) {
    var n = playlistName.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (n.startsWith('.')) n = n.substring(1).trim();
    if (n.length > 80) n = n.substring(0, 80).trim();
    return n.isEmpty ? 'Playlist' : n;
  }

  static String fileName(Track t) {
    var base = '${t.artist.name} - ${t.title}'.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (base.length > 120) base = base.substring(0, 120).trim();
    return '${base.isEmpty ? t.id : base}.m4a';
  }

  /// Chemin lisible affiché dans l'app (ex. « Music/YouPlay/Ma playlist »).
  static String displayPath(String playlistName) => 'Music/YouPlay/${folderName(playlistName)}';

  Future<Directory?> dirFor(String playlistName) async {
    if (!DownloadManager.supported) return null;
    final root = await MediaStorage.downloadsDir();
    return Directory('${root.path}/${folderName(playlistName)}');
  }

  /// Planifie une synchronisation (regroupe les changements rapprochés).
  void schedule() {
    if (!DownloadManager.supported) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _sync);
  }

  Future<void> _sync() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      final lib = ref.read(libraryProvider);
      final dl = ref.read(downloadsProvider);
      final missing = <Track>[];
      for (final p in lib.myPlaylists) {
        final dir = await dirFor(p.name);
        if (dir == null) continue;
        await dir.create(recursive: true);
        final manifestFile = File('${dir.path}/.youplay.json');
        final managed = <String>{};
        try {
          managed.addAll((jsonDecode(await manifestFile.readAsString()) as List).cast<String>());
        } catch (_) {}

        final wanted = <String, Track>{for (final t in p.tracks) fileName(t): t};
        // 1. Copier les titres déjà téléchargés ; télécharger les autres.
        for (final e in wanted.entries) {
          final dst = File('${dir.path}/${e.key}');
          if (await dst.exists()) {
            managed.add(e.key);
            continue;
          }
          final src = dl.pathOf(e.value.id);
          if (src == null) {
            missing.add(e.value);
            continue;
          }
          try {
            await File(src).copy(dst.path);
            managed.add(e.key);
            await MediaStorage.scan(dst.path);
          } catch (_) {}
        }
        // 2. Supprimer les fichiers gérés par l'app qui ne sont plus dans la playlist.
        for (final name in managed.difference(wanted.keys.toSet()).toList()) {
          final f = File('${dir.path}/$name');
          try {
            if (await f.exists()) await f.delete();
            await MediaStorage.scan(f.path);
          } catch (_) {}
          managed.remove(name);
        }
        // 3. Playlist .m3u8 (ordre de la playlist) + manifeste.
        final present = [for (final e in wanted.entries) if (managed.contains(e.key)) e];
        final m3u = StringBuffer('#EXTM3U\n#PLAYLIST:${p.name}\n');
        for (final e in present) {
          m3u
            ..writeln('#EXTINF:${e.value.duration.inSeconds},${e.value.artist.name} - ${e.value.title}')
            ..writeln(e.key);
        }
        final m3uFile = File('${dir.path}/${folderName(p.name)}.m3u8');
        await m3uFile.writeAsString(m3u.toString());
        await manifestFile.writeAsString(jsonEncode(managed.toList()));
        await MediaStorage.scan(m3uFile.path);
      }
      if (missing.isNotEmpty) ref.read(downloadsProvider.notifier).enqueue(missing);
    } catch (_) {
      // Stockage indisponible : on réessaiera au prochain changement.
    } finally {
      _running = false;
      if (_again) {
        _again = false;
        schedule();
      }
    }
  }

  /// Renomme le dossier d'une playlist (et son .m3u8). Si un dossier du nouveau nom existe déjà,
  /// on y déplace les fichiers gérés par l'app et on supprime l'ancien s'il est vide.
  Future<void> renameFolder(String oldName, String newName) async {
    final from = await dirFor(oldName), to = await dirFor(newName);
    if (from == null || to == null || from.path == to.path || !await from.exists()) return;
    try {
      final oldM3u = File('${from.path}/${folderName(oldName)}.m3u8');
      if (await oldM3u.exists()) await oldM3u.delete();
      if (!await to.exists()) {
        await from.rename(to.path);
      } else {
        final manifest = File('${from.path}/.youplay.json');
        final managed = <String>{};
        try {
          managed.addAll((jsonDecode(await manifest.readAsString()) as List).cast<String>());
        } catch (_) {}
        for (final name in managed) {
          final f = File('${from.path}/$name');
          if (await f.exists() && !await File('${to.path}/$name').exists()) await f.rename('${to.path}/$name');
        }
        if (await manifest.exists()) await manifest.delete();
        if (await from.list().isEmpty) await from.delete();
      }
      await for (final e in to.list()) {
        if (e is File) await MediaStorage.scan(e.path);
      }
    } catch (_) {
      // Échec du déplacement : la synchro recopiera les titres dans le nouveau dossier.
    }
  }

  /// Renomme une playlist (nom unique) en déplaçant son dossier. Retourne le nom retenu.
  Future<String> renamePlaylist(String playlistId, String wanted) async {
    final lib = ref.read(libraryProvider.notifier);
    final p = ref.read(libraryProvider).myPlaylists.where((x) => x.id == playlistId).firstOrNull;
    if (p == null) return wanted;
    final name = lib.uniquePlaylistName(wanted, exceptId: playlistId);
    if (name == p.name) return name;
    _debounce?.cancel(); // pas de synchro pendant le déplacement (elle recréerait l'ancien dossier)
    await renameFolder(p.name, name);
    lib.renamePlaylist(playlistId, name);
    return name;
  }

  /// Supprime le dossier d'une playlist : uniquement les fichiers gérés par l'app,
  /// puis le dossier s'il est vide (les fichiers ajoutés à la main restent).
  Future<int> deleteFolder(String playlistName) async {
    final dir = await dirFor(playlistName);
    if (dir == null || !await dir.exists()) return 0;
    var kept = 0;
    final manifest = File('${dir.path}/.youplay.json');
    final managed = <String>{};
    try {
      managed.addAll((jsonDecode(await manifest.readAsString()) as List).cast<String>());
    } catch (_) {}
    managed
      ..add('${folderName(playlistName)}.m3u8')
      ..add('.youplay.json');
    await for (final e in dir.list()) {
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (e is File && managed.contains(name)) {
        await e.delete();
        await MediaStorage.scan(e.path);
      } else {
        kept++;
      }
    }
    if (kept == 0) await dir.delete();
    return kept;
  }
}

/// Instancié au démarrage : resynchronise les dossiers quand les playlists ou les téléchargements changent.
final playlistFoldersProvider = Provider<PlaylistFolders>((ref) {
  final f = PlaylistFolders(ref);
  ref.listen(libraryProvider.select((s) => s.myPlaylists), (_, _) => f.schedule());
  ref.listen(downloadsProvider.select((s) => s.done.length), (_, _) => f.schedule());
  f.schedule();
  return f;
});
