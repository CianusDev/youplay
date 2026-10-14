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
final ytAlbumsProvider = FutureProvider.family<List<Playlist>, String>((ref, q) => ref.watch(youtubeProvider).searchAlbums(q));
final ytPlaylistProvider = FutureProvider.family<(Playlist, List<Track>), String>(
  (ref, url) => ref.watch(youtubeProvider).playlist(url),
);

class LyricsKey {
  const LyricsKey(this.artist, this.title, this.duration);
  final String artist;
  final String title;
  final Duration duration;
  @override
  bool operator ==(Object other) => other is LyricsKey && other.artist == artist && other.title == title;
  @override
  int get hashCode => Object.hash(artist, title);
}

final lyricsProvider = FutureProvider.family((ref, LyricsKey k) {
  return ref.watch(lyricsApiProvider).fetch(artist: k.artist, title: k.title, duration: k.duration);
});

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
