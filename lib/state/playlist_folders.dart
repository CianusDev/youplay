import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/media_storage.dart';
import '../data/models.dart';
import 'download_manager.dart';
import 'library_store.dart';

/// Chaque playlist perso = un dossier `Music/YouPlay/<nom>` sur le téléphone, SANS duplication :
/// - chaque son téléchargé n'a qu'UN fichier ;
/// - s'il appartient à une ou plusieurs playlists, il vit dans le dossier de la plus ancienne ;
///   sinon (titre liké / téléchargé seul) il vit dans `Music/YouPlay/` ;
/// - chaque dossier contient un `<nom>.m3u8` qui référence ses titres, y compris ceux rangés
///   dans un autre dossier (chemin relatif `../Autre playlist/son.m4a`) ;
/// - un manifeste caché `.youplay.json` liste les fichiers gérés par l'app : tes propres
///   fichiers ajoutés à la main ne sont jamais touchés.
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

  /// Synchronise tout de suite (utilisé avant de supprimer un dossier de playlist).
  Future<void> syncNow() async {
    _debounce?.cancel();
    while (_running) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await _sync();
  }

  Future<void> _sync() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      final lib = ref.read(libraryProvider);
      final dlNotifier = ref.read(downloadsProvider.notifier);
      final root = await MediaStorage.downloadsDir();
      // Playlists de la plus ancienne à la plus récente : le dossier « maison » d'un son reste stable.
      final playlists = lib.myPlaylists.reversed.toList();
      final dirs = <String, Directory>{for (final p in playlists) p.id: Directory('${root.path}/${folderName(p.name)}')};
      final home = <String, Directory>{}; // trackId → dossier où vit son fichier
      for (final p in playlists) {
        for (final t in p.tracks) {
          home.putIfAbsent(t.id, () => dirs[p.id]!);
        }
      }

      // 1. Un seul fichier par son, rangé dans son dossier « maison ».
      final missing = <Track>[];
      final managedPaths = <String>{};
      // Chemin → titre propriétaire : deux titres différents ne partagent jamais un fichier.
      final owner = <String, String>{
        for (final it in ref.read(downloadsProvider).done)
          if (it.path != null) it.path!: it.track.id,
      };
      for (final it in ref.read(downloadsProvider).done) {
        final t = it.track;
        final dir = home[t.id] ?? root;
        await dir.create(recursive: true);
        var target = File('${dir.path}/${fileName(t)}');
        final taken = owner[target.path];
        if (taken != null && taken != t.id) {
          // Homonyme (ex. clip et audio du même son) : nom distinct, jamais d'écrasement.
          final n = fileName(t);
          target = File('${dir.path}/${n.substring(0, n.length - 4)} [${t.id.replaceFirst('yt_', '')}].m4a');
        }
        final current = it.path == null ? null : File(it.path!);
        try {
          if (current != null && await current.exists()) {
            if (current.path != target.path) {
              if (await target.exists()) {
                await current.delete(); // ancien doublon (copie déjà présente au bon endroit)
              } else {
                await current.rename(target.path); // déplacement, pas de copie
              }
              await MediaStorage.scan(current.path);
              await MediaStorage.scan(target.path);
              dlNotifier.relocate(t.id, target.path);
              owner
                ..remove(current.path)
                ..[target.path] = t.id;
            }
          } else if (await target.exists()) {
            dlNotifier.relocate(t.id, target.path); // fichier déplacé (ex. dossier renommé) : on le retrouve
          } else {
            continue; // fichier disparu : le titre sera retéléchargé s'il est dans une playlist
          }
          managedPaths.add(target.path);
        } catch (_) {}
      }

      // 2. Titres de playlist pas encore téléchargés → téléchargement (rangés au prochain passage).
      final downloaded = ref.read(downloadsProvider).done.map((i) => i.track.id).toSet();
      for (final p in playlists) {
        for (final t in p.tracks) {
          if (!downloaded.contains(t.id) && !missing.contains(t)) missing.add(t);
        }
      }

      // 3. Par dossier : nettoyage des anciens fichiers gérés + playlist .m3u8 + manifeste.
      for (final p in playlists) {
        final dir = dirs[p.id]!;
        await dir.create(recursive: true);
        final manifestFile = File('${dir.path}/.youplay.json');
        final previous = <String>{};
        try {
          previous.addAll((jsonDecode(await manifestFile.readAsString()) as List).cast<String>());
        } catch (_) {}
        final own = <String>{
          for (final path in managedPaths)
            if (File(path).parent.path == dir.path) File(path).uri.pathSegments.last,
        };
        // Fichiers créés par l'app qui n'ont plus rien à faire ici (anciennes copies, titres retirés).
        for (final name in previous.difference(own)) {
          final f = File('${dir.path}/$name');
          if (managedPaths.contains(f.path)) continue;
          try {
            if (await f.exists()) {
              await f.delete();
              await MediaStorage.scan(f.path);
            }
          } catch (_) {}
        }
        final m3u = StringBuffer('#EXTM3U\n#PLAYLIST:${p.name}\n');
        final items = ref.read(downloadsProvider).items;
        for (final t in p.tracks) {
          final path = items[t.id]?.path;
          if (path == null || !managedPaths.contains(path)) continue;
          final f = File(path);
          final name = f.uri.pathSegments.last;
          final rel = f.parent.path == dir.path
              ? name
              : (f.parent.path == root.path ? '../$name' : '../${f.parent.uri.pathSegments.where((x) => x.isNotEmpty).last}/$name');
          m3u
            ..writeln('#EXTINF:${t.duration.inSeconds},${t.artist.name} - ${t.title}')
            ..writeln(rel);
        }
        final m3uFile = File('${dir.path}/${folderName(p.name)}.m3u8');
        await m3uFile.writeAsString(m3u.toString());
        await manifestFile.writeAsString(jsonEncode(own.toList()));
        await MediaStorage.scan(m3uFile.path);
      }
      if (missing.isNotEmpty) dlNotifier.enqueue(missing);
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

  /// Après suppression d'une playlist : ses sons sont d'abord rangés ailleurs (Music/YouPlay ou
  /// une autre playlist) par la synchro, puis on retire .m3u8, manifeste et dossier s'il est vide.
  /// Retourne le nombre de fichiers perso laissés dans le dossier.
  Future<int> deleteFolder(String playlistName) async {
    await syncNow();
    final dir = await dirFor(playlistName);
    if (dir == null || !await dir.exists()) return 0;
    var kept = 0;
    for (final name in ['${folderName(playlistName)}.m3u8', '.youplay.json']) {
      final f = File('${dir.path}/$name');
      if (await f.exists()) {
        await f.delete();
        await MediaStorage.scan(f.path);
      }
    }
    await for (final _ in dir.list()) {
      kept++;
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
