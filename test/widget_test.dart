import 'package:flutter_test/flutter_test.dart';
import 'package:sika_app/data/lyrics_api.dart';
import 'package:sika_app/data/models.dart';
import 'package:sika_app/ui/components/cover_art.dart';

void main() {
  test('formatDuration', () {
    expect(formatDuration(const Duration(seconds: 221)), '3:41');
    expect(formatTotal(const Duration(minutes: 156)), '2 h 36');
  });

  test('CoverArt.variantFor est stable et dans 1..6', () {
    for (final s in ['a', 'abc', 'GEG9ZWx', '']) {
      final v = CoverArt.variantFor(s);
      expect(v, inInclusiveRange(1, 6));
      expect(CoverArt.variantFor(s), v);
    }
  });

  test('Lyrics.indexAt', () {
    const l = Lyrics([
      LyricLine(Duration(seconds: 0), 'a'),
      LyricLine(Duration(seconds: 10), 'b'),
      LyricLine(Duration(seconds: 20), 'c'),
    ], synced: true);
    expect(l.indexAt(const Duration(seconds: 5)), 0);
    expect(l.indexAt(const Duration(seconds: 15)), 1);
    expect(l.indexAt(const Duration(seconds: 99)), 2);
  });

  test('Track JSON aller-retour', () {
    const t = Track(id: 'x', title: 'T', artist: Artist(id: 'a', name: 'A'), duration: Duration(seconds: 90), genre: 'Podcasts');
    final back = Track.fromJson(t.toJson());
    expect(back.id, 'x');
    expect(back.artist.name, 'A');
    expect(back.isPodcast, isTrue);
  });

  test('LyricsApi.cleanTitle nettoie les titres YouTube', () {
    expect(LyricsApi.cleanTitle('Impardonnable (Clip Officiel)'), 'Impardonnable');
    expect(LyricsApi.cleanTitle('Tiakola - Meuda (Clip officiel)'), 'Meuda');
    expect(LyricsApi.cleanTitle('Bolide allemand feat. Damso [Audio]'), 'Bolide allemand');
    expect(LyricsApi.cleanTitle('La rue est morte.'), 'La rue est morte.');
  });
}
