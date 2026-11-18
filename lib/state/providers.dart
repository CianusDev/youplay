import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/lyrics_api.dart';
import '../data/models.dart';
import '../data/youtube_source.dart';

/// Initialisé dans main() puis injecté via override.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('prefsProvider non initialisé'));

final lyricsApiProvider = Provider<LyricsApi>((ref) => LyricsApi());
final youtubeProvider = Provider<YoutubeSource>((ref) => YoutubeSource());

// ---------------------------------------------------------------------------
// YouTube / YouTube Music (Android, via NewPipeExtractor)
// ---------------------------------------------------------------------------

final ytSongsProvider = FutureProvider.family<List<Track>, String>((ref, q) => ref.watch(youtubeProvider).searchSongs(q));
final ytSearchProvider = FutureProvider.family<YtSearch, String>((ref, q) => ref.watch(youtubeProvider).searchTop(q));
final ytArtistTracksProvider = FutureProvider.family<List<Track>, (String, String?)>(
  (ref, a) => ref.watch(youtubeProvider).artistTracks(a.$1, url: a.$2),
);
final ytArtistsProvider = FutureProvider.family<List<Artist>, String>((ref, q) => ref.watch(youtubeProvider).searchArtists(q));
final ytSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, q) => ref.watch(youtubeProvider).suggestions(q));
final ytAlbumsProvider = FutureProvider.family<List<Playlist>, String>((ref, q) => ref.watch(youtubeProvider).searchAlbums(q));
final ytPlaylistProvider = FutureProvider.family<(Playlist, List<Track>), String>(
  (ref, url) => ref.watch(youtubeProvider).playlist(url),
);

class LyricsKey {
  const LyricsKey(this.trackId, this.artist, this.title, this.duration);
  final String trackId;
  final String artist;
  final String title;
  final Duration duration;
  @override
  bool operator ==(Object other) => other is LyricsKey && other.trackId == trackId;
  @override
  int get hashCode => trackId.hashCode;
}

/// Réglages de paroles par titre : décalage choisi (ms) et paroles signalées comme mauvaises.
class LyricsPrefsState {
  const LyricsPrefsState({this.offsets = const {}, this.rejected = const {}});
  final Map<String, int> offsets;
  final Map<String, List<int>> rejected;
}

class LyricsPrefs extends Notifier<LyricsPrefsState> {
  static const _key = 'youplay.lyrics.v1';

  @override
  LyricsPrefsState build() {
    final raw = ref.read(prefsProvider).getString(_key);
    if (raw == null) return const LyricsPrefsState();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return LyricsPrefsState(
        offsets: (j['offsets'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt())),
        rejected: (j['rejected'] as Map).map((k, v) => MapEntry(k as String, (v as List).cast<int>())),
      );
    } catch (_) {
      return const LyricsPrefsState();
    }
  }

  void _set(LyricsPrefsState s) {
    state = s;
    ref.read(prefsProvider).setString(_key, jsonEncode({'offsets': s.offsets, 'rejected': s.rejected}));
  }

  Duration offsetOf(String trackId) => Duration(milliseconds: state.offsets[trackId] ?? 0);

  void setOffset(String trackId, Duration d) {
    final o = {...state.offsets};
    if (d == Duration.zero) {
      o.remove(trackId);
    } else {
      o[trackId] = d.inMilliseconds.clamp(-60000, 60000);
    }
    _set(LyricsPrefsState(offsets: o, rejected: state.rejected));
  }

  /// « Ce ne sont pas les bonnes paroles » : on écarte cet enregistrement et on cherche le suivant.
  void reject(String trackId, int lyricsId) {
    final r = {...state.rejected, trackId: [...?state.rejected[trackId], lyricsId]};
    final o = {...state.offsets}..remove(trackId);
    _set(LyricsPrefsState(offsets: o, rejected: r));
  }

  void clearRejected(String trackId) {
    final r = {...state.rejected}..remove(trackId);
    _set(LyricsPrefsState(offsets: state.offsets, rejected: r));
  }
}

final lyricsPrefsProvider = NotifierProvider<LyricsPrefs, LyricsPrefsState>(LyricsPrefs.new);

final lyricsProvider = FutureProvider.family((ref, LyricsKey k) {
  final rejected = ref.watch(lyricsPrefsProvider.select((s) => s.rejected[k.trackId] ?? const <int>[]));
  return ref.watch(lyricsApiProvider).fetch(artist: k.artist, title: k.title, duration: k.duration, exclude: rejected.toSet());
});

/// Décalage des paroles d'un titre (positif = paroles retardées).
final lyricsOffsetProvider = Provider.family<Duration, String>(
  (ref, trackId) => Duration(milliseconds: ref.watch(lyricsPrefsProvider.select((s) => s.offsets[trackId] ?? 0))),
);

/// Couleur d'ambiance d'une pochette (fond du lecteur) : teinte dominante, version sombre.
final artworkColorProvider = FutureProvider.family<Color?, String>((ref, url) async {
  try {
    final scheme = await ColorScheme.fromImageProvider(
      provider: CachedNetworkImageProvider(url),
      brightness: Brightness.dark,
    );
    return scheme.primary;
  } catch (_) {
    return null;
  }
});
