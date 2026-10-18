import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sika_app/data/media_storage.dart';
import 'package:sika_app/data/models.dart';
import 'package:sika_app/state/download_manager.dart';
import 'package:sika_app/state/library_store.dart';
import 'package:sika_app/state/playlist_folders.dart';
import 'package:sika_app/state/providers.dart';

Track tr(String id, String artist, String title) =>
    Track(id: 'yt_$id', title: title, artist: Artist(id: 'ytc_${artist.toLowerCase()}', name: artist), duration: const Duration(seconds: 180));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late Directory root; // simule Music/YouPlay

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('youplay_test');
    root = Directory('${tmp.path}/Music/YouPlay')..createSync(recursive: true);
    MediaStorage.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('youplay/media'),
      (call) async => call.method == 'musicDir' ? '${tmp.path}/Music' : null,
    );
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Future<ProviderContainer> boot({required List<MyPlaylist> playlists, required Map<Track, String> files}) async {
    final items = <Map<String, dynamic>>[];
    for (final e in files.entries) {
      File(e.value)
        ..createSync(recursive: true)
        ..writeAsStringSync('audio ${e.key.id}');
      items.add(DownloadItem(track: e.key, status: DownloadStatus.done, path: e.value, bytes: 10, addedAt: 1).toJson());
    }
    SharedPreferences.setMockInitialValues({
      'sika.library.v1': jsonEncode(LibraryState(myPlaylists: playlists).toJson()),
      'sika.downloads.v1': jsonEncode({'items': items, 'collections': [], 'offline': false, 'smart': false}),
    });
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
  }

  List<String> listAll() => root
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.substring(root.path.length + 1))
      .where((p) => !p.endsWith('.json') && p != '.youplay')
      .toList()
    ..sort();

  test('un son de playlist est DÉPLACÉ dans le dossier (aucune copie à la racine)', () async {
    final a = tr('a', 'Damso', 'Macarena');
    final c = await boot(
      playlists: [MyPlaylist(id: '1', name: 'Chill', tracks: [a])],
      files: {a: '${root.path}/Damso - Macarena.m4a'},
    );
    await c.read(playlistFoldersProvider).syncNow();
    expect(listAll(), ['Chill/Chill.m3u8', 'Chill/Damso - Macarena.m4a']);
    expect(c.read(downloadsProvider).items[a.id]!.path, '${root.path}/Chill/Damso - Macarena.m4a');
    c.dispose();
  });

  test('ancien doublon (racine + copie de playlist) : il ne reste qu\'un fichier', () async {
    final a = tr('a', 'Damso', 'Macarena');
    File('${root.path}/Chill/Damso - Macarena.m4a')
      ..createSync(recursive: true)
      ..writeAsStringSync('copie');
    File('${root.path}/Chill/.youplay.json').writeAsStringSync(jsonEncode(['Damso - Macarena.m4a']));
    final c = await boot(
      playlists: [MyPlaylist(id: '1', name: 'Chill', tracks: [a])],
      files: {a: '${root.path}/Damso - Macarena.m4a'},
    );
    await c.read(playlistFoldersProvider).syncNow();
    expect(listAll(), ['Chill/Chill.m3u8', 'Chill/Damso - Macarena.m4a']);
    c.dispose();
  });

  test('son dans deux playlists : un seul fichier, référencé par chemin relatif', () async {
    final a = tr('a', 'Tiakola', 'Meuda');
    final c = await boot(
      // la liste est stockée de la plus récente à la plus ancienne : « Vieille » est la maison du son
      playlists: [MyPlaylist(id: '2', name: 'Récente', tracks: [a]), MyPlaylist(id: '1', name: 'Vieille', tracks: [a])],
      files: {a: '${root.path}/Tiakola - Meuda.m4a'},
    );
    await c.read(playlistFoldersProvider).syncNow();
    expect(listAll(), ['Récente/Récente.m3u8', 'Vieille/Tiakola - Meuda.m4a', 'Vieille/Vieille.m3u8']);
    expect(File('${root.path}/Récente/Récente.m3u8').readAsStringSync(), contains('../Vieille/Tiakola - Meuda.m4a'));
    c.dispose();
  });

  test('retirer le son de la playlist le renvoie à la racine', () async {
    final a = tr('a', 'Damso', 'Macarena');
    final c = await boot(
      playlists: [MyPlaylist(id: '1', name: 'Chill', tracks: const [])],
      files: {a: '${root.path}/Chill/Damso - Macarena.m4a'},
    );
    await c.read(playlistFoldersProvider).syncNow();
    expect(listAll(), ['Chill/Chill.m3u8', 'Damso - Macarena.m4a']);
    c.dispose();
  });

  test('deux versions homonymes ne s\'écrasent jamais', () async {
    final clip = tr('clip', 'Damso', 'Macarena');
    final audio = tr('audio', 'Damso', 'Macarena');
    final c = await boot(
      playlists: [MyPlaylist(id: '1', name: 'Chill', tracks: [clip, audio])],
      files: {clip: '${root.path}/Damso - Macarena.m4a', audio: '${root.path}/Damso - Macarena (2).m4a'},
    );
    await c.read(playlistFoldersProvider).syncNow();
    final files = listAll().where((f) => f.endsWith('.m4a')).toList();
    expect(files.length, 2);
    expect(File(c.read(downloadsProvider).items[clip.id]!.path!).readAsStringSync(), 'audio yt_clip');
    expect(File(c.read(downloadsProvider).items[audio.id]!.path!).readAsStringSync(), 'audio yt_audio');
    c.dispose();
  });
}
