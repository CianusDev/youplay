import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sika_app/data/lyrics_api.dart';

Map<String, dynamic> rec(int id, String artist, String title, num duration) => {
      'id': id,
      'artistName': artist,
      'trackName': title,
      'duration': duration,
      'syncedLyrics': '[00:01.00] ligne de $artist\n[00:05.00] suite',
      'plainLyrics': 'ligne de $artist',
    };

LyricsApi api(List<Map<String, dynamic>> search) => LyricsApi(
      client: MockClient((req) async {
        if (req.url.path == '/api/get') return http.Response('{}', 404);
        return http.Response(jsonEncode(search), 200, headers: {'content-type': 'application/json'});
      }),
    );

void main() {
  test('refuse les paroles d\'un autre artiste pour un titre court identique', () async {
    final l = await api([rec(1, 'Orelsan', 'Intro', 200)]).fetch(artist: 'Damso', title: 'Intro', duration: const Duration(seconds: 120));
    expect(l, isNull);
  });

  test('accepte le bon artiste et prend la version la plus proche en durée', () async {
    final l = await api([
      rec(1, 'Damso', 'Θ. Macarena', 230),
      rec(2, 'Damso', 'Θ. Macarena', 190),
    ]).fetch(artist: 'DAMSO', title: 'Θ. Macarena (Clip Officiel)', duration: const Duration(seconds: 195));
    expect(l?.id, 2);
    expect(l!.approximate, isTrue); // 195 s lu vs 190 s minuté
  });

  test('refuse une autre version trop éloignée (live, mix)', () async {
    final l = await api([rec(1, 'Tiakola', 'Meuda', 420)]).fetch(artist: 'Tiakola', title: 'Meuda', duration: const Duration(seconds: 153));
    expect(l, isNull);
  });

  test('ignore les paroles signalées comme mauvaises', () async {
    final l = await api([
      rec(1, 'Damso', 'Feu de bois', 200),
      rec(2, 'Damso', 'Feu de bois', 201),
    ]).fetch(artist: 'Damso', title: 'Feu de bois', duration: const Duration(seconds: 200), exclude: {1});
    expect(l?.id, 2);
  });

  test('indexAt applique bien un décalage', () {
    const l = Lyrics([LyricLine(Duration(seconds: 10), 'a'), LyricLine(Duration(seconds: 20), 'b')], synced: true);
    // clip avec 10 s d'intro : à 25 s de lecture, on est à 15 s des paroles -> ligne 0
    expect(l.indexAt(const Duration(seconds: 25) - const Duration(seconds: 10)), 0);
  });
}
