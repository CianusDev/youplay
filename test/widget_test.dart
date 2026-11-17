import 'package:flutter_test/flutter_test.dart';
import 'package:sika_app/data/lyrics_api.dart';
import 'dart:ui' show Locale;

import 'package:sika_app/data/models.dart';
import 'package:sika_app/l10n/l10n.dart';
import 'package:sika_app/ui/components/cover_art.dart';

void main() {
  test('formatDuration', () {
    expect(formatDuration(const Duration(seconds: 221)), '3:41');
    L10n.update(const Locale('fr'));
    expect(formatTotal(const Duration(minutes: 156)), '2 h 36');
    expect(formatTotal(const Duration(minutes: 45)), '45 min');
    L10n.update(const Locale('en'));
    expect(formatTotal(const Duration(minutes: 156)), '2 hr 36 min');
  });

  test('langue : choix, sinon téléphone en français, sinon anglais', () {
    expect(resolveAppLocale(const Locale('en'), const [Locale('fr', 'FR')]).languageCode, 'en');
    expect(resolveAppLocale(null, const [Locale('fr', 'CI')]).languageCode, 'fr');
    expect(resolveAppLocale(null, const [Locale('pt', 'BR'), Locale('fr')]).languageCode, 'fr');
    expect(resolveAppLocale(null, const [Locale('de')]).languageCode, 'en');
  });

  test('les deux langues ont exactement les mêmes textes', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(en.songCount(1), '1 song');
    expect(fr.songCount(3), '3 titres');
    expect(fr.likedSongs, 'Titres likés');
    expect(en.likedSongs, 'Liked songs');
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
