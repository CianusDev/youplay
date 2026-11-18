// StreamAudioSource est marqué expérimental dans just_audio, mais stable en pratique.
// ignore_for_file: experimental_member_use
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import 'models.dart';
import '../l10n/l10n.dart';

/// Préfixes d'identifiants des contenus YouTube.
const ytTrackPrefix = 'yt_';
const ytArtistPrefix = 'ytc_';

bool isYoutubeTrack(String id) => id.startsWith(ytTrackPrefix);
bool isYoutubeArtist(String id) => id.startsWith(ytArtistPrefix);
String videoIdOf(String trackId) => trackId.substring(ytTrackPrefix.length);

class ResolvedStream {
  ResolvedStream(this.url, this.mime, this.userAgent) : at = DateTime.now();
  final String url;
  final String mime;
  final String userAgent;
  final DateTime at;
  // Les URL googlevideo expirent après ~6 h : on les renouvelle bien avant.
  bool get fresh => DateTime.now().difference(at) < const Duration(hours: 3);
}

/// Résultat d'une recherche de titres : liste triée + correction éventuelle de la requête.
class YtSearch {
  const YtSearch(this.songs, {this.suggestion, this.corrected = false});
  final List<Track> songs;
  final String? suggestion; // « Vouliez-vous dire … »
  final bool corrected; // YouTube a déjà cherché la version corrigée
}

/// Catalogue YouTube / YouTube Music via NewPipeExtractor (canal natif Android).
/// Usage personnel uniquement : contourne les conditions d'utilisation de YouTube.
class YoutubeSource {
  static const _ch = MethodChannel('sika/newpipe');
  static bool get supported => !kIsWeb && Platform.isAndroid;

  final _cache = <String, ResolvedStream>{};

  Future<List<Track>> searchSongs(String query) => _tracks('searchSongs', {'query': query});
  /// Titres triés par pertinence (sans doublons) + « Vouliez-vous dire ».
  Future<YtSearch> searchTop(String query) async {
    final m = (await _ch.invokeMapMethod<String, dynamic>('searchTop', {'query': query}))!;
    final songs = (m['songs'] as List).cast<Map>().map((e) => e.cast<String, dynamic>()).where((e) => e['type'] == 'stream').map(_track).toList();
    return YtSearch(songs, suggestion: m['suggestion'] as String?, corrected: m['corrected'] as bool? ?? false);
  }

  /// Chaînes d'artistes (avec photo), triées par pertinence.
  Future<List<Artist>> searchArtists(String query) async {
    final raw = await _ch.invokeListMethod<Map>('searchArtists', {'query': query}) ?? const [];
    return raw.map((m) => m.cast<String, dynamic>()).map((m) {
      final name = m['name'] as String? ?? L10n.current.kindArtist;
      return Artist(
        id: '$ytArtistPrefix${name.toLowerCase()}',
        name: name,
        handle: m['verified'] == true ? 'verified' : '',
        imageUrl: m['thumbnail'] as String?,
        followers: (m['subscribers'] as num?)?.toInt() ?? 0,
        url: m['url'] as String?,
      );
    }).toList();
  }

  /// Suggestions de saisie (autocomplétion YouTube).
  Future<List<String>> suggestions(String query) async =>
      (await _ch.invokeListMethod<String>('suggestions', {'query': query})) ?? const [];

  /// Titres d'un artiste (sa chaîne YouTube), pas une simple recherche sur son nom.
  /// [url] : sa chaîne si on la connaît ; sinon la chaîne qui porte exactement ce nom.
  Future<List<Track>> artistTracks(String name, {String? url}) => _tracks('artistTracks', {'name': name, 'url': url});

  Future<List<Track>> searchVideos(String query) => _tracks('searchVideos', {'query': query});
  Future<List<Track>> related(String trackId) => _tracks('related', {'id': videoIdOf(trackId)});

  Future<List<Playlist>> searchAlbums(String query) async {
    final raw = await _ch.invokeListMethod<Map>('searchAlbums', {'query': query}) ?? const [];
    return raw.where((m) => m['type'] == 'playlist').map((m) => _playlist(m.cast<String, dynamic>())).toList();
  }

  Future<(Playlist, List<Track>)> playlist(String url) async {
    final m = (await _ch.invokeMapMethod<String, dynamic>('playlist', {'url': url}))!;
    final items = (m['items'] as List).cast<Map>().map((e) => e.cast<String, dynamic>()).where((e) => e['type'] == 'stream').map(_track).toList();
    final p = Playlist(
      id: url,
      name: m['name'] as String? ?? L10n.current.kindAlbum,
      owner: _artist(m['uploader'] as String?),
      artworkUrl: m['thumbnail'] as String?,
      trackCount: items.length,
      isAlbum: true,
    );
    return (p, items);
  }

  /// Playlist YouTube complète, pour l'importer dans la bibliothèque (doublons retirés).
  Future<ImportedPlaylist> importPlaylist(String url, {int max = importMax}) async {
    final m = (await _ch.invokeMapMethod<String, dynamic>('playlistAll', {'url': url, 'max': max}))!;
    final seen = <String>{};
    final tracks = [
      for (final t in (m['items'] as List).cast<Map>().map((e) => e.cast<String, dynamic>()).where((e) => e['type'] == 'stream').map(_track))
        if (seen.add(t.id)) t,
    ];
    return ImportedPlaylist(name: (m['name'] as String? ?? '').trim(), tracks: tracks, truncated: m['truncated'] == true);
  }

  static const importMax = 1000;

  Future<ResolvedStream> resolve(String trackId, {bool force = false}) async {
    final c = _cache[trackId];
    if (!force && c != null && c.fresh) return c;
    final m = (await _ch.invokeMapMethod<String, dynamic>('audioStream', {'id': videoIdOf(trackId)}))!;
    final r = ResolvedStream(m['url'] as String, m['mime'] as String? ?? 'audio/mp4', m['userAgent'] as String? ?? '');
    _cache[trackId] = r;
    return r;
  }

  Future<List<Track>> _tracks(String method, Map<String, dynamic> args) async {
    final raw = await _ch.invokeListMethod<Map>(method, args) ?? const [];
    return raw.map((m) => m.cast<String, dynamic>()).where((m) => m['type'] == 'stream' && m['id'] != null).map(_track).toList();
  }

  static Artist _artist(String? name) {
    final n = (name == null || name.isEmpty) ? 'YouTube' : name;
    return Artist(id: '$ytArtistPrefix${n.toLowerCase()}', name: n);
  }

  static Track _track(Map<String, dynamic> m) => Track(
        id: '$ytTrackPrefix${m['id']}',
        title: m['title'] as String? ?? L10n.current.untitled,
        artist: _artist(m['artist'] as String?),
        duration: Duration(seconds: (m['duration'] as num?)?.toInt() ?? 0),
        artworkUrl: m['thumbnail'] as String?,
        permalink: m['url'] as String? ?? '',
      );

  static Playlist _playlist(Map<String, dynamic> m) => Playlist(
        id: m['url'] as String,
        name: m['title'] as String? ?? L10n.current.kindAlbum,
        owner: _artist(m['artist'] as String?),
        artworkUrl: m['thumbnail'] as String?,
        trackCount: (m['count'] as num?)?.toInt() ?? 0,
        isAlbum: true,
      );

  /// Oublie l'URL en cache d'un titre (expirée / refusée) : la prochaine lecture en résout une neuve.
  void invalidate(String trackId) => _cache.remove(trackId);

  /// Résout à l'avance l'URL d'un titre (le suivant de la file) : transition sans attente ni échec.
  Future<void> prefetch(String trackId) async {
    if (!isYoutubeTrack(trackId)) return;
    try {
      await resolve(trackId);
    } catch (_) {}
  }

  /// Ouvre un flux HTTP (avec Range) vers l'audio d'un titre. Réessaie sur coupure réseau,
  /// et renouvelle l'URL si YouTube la refuse (403/410 : URL expirée).
  Future<http.StreamedResponse> open(String trackId, {int? start, int? end, http.Client? client, bool force = false}) async {
    final c = client ?? http.Client();
    Object? lastError;
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        final s = await resolve(trackId, force: force || attempt >= 2);
        final req = http.Request('GET', Uri.parse(s.url));
        if (s.userAgent.isNotEmpty) req.headers['User-Agent'] = s.userAgent;
        req.headers['Range'] = 'bytes=${start ?? 0}-${end != null ? end - 1 : ''}';
        final res = await c.send(req).timeout(const Duration(seconds: 20));
        if (res.statusCode == 200 || res.statusCode == 206) return res;
        await res.stream.drain<void>();
        lastError = http.ClientException('HTTP ${res.statusCode}');
        if (res.statusCode == 403 || res.statusCode == 410) {
          invalidate(trackId);
          force = true;
        } else if (res.statusCode < 500 && res.statusCode != 429) {
          break; // erreur définitive
        }
      } catch (e) {
        lastError = e; // réseau coupé, délai dépassé, extraction impossible…
      }
      await Future<void>.delayed(Duration(milliseconds: 600 * (attempt + 1)));
    }
    throw lastError ?? http.ClientException('Flux YouTube indisponible');
  }
}

/// Source just_audio paresseuse : l'URL n'est résolue qu'au moment où le titre est lu.
class YoutubeAudioSource extends StreamAudioSource {
  YoutubeAudioSource(this.trackId, this.yt, {super.tag});
  final String trackId;
  final YoutubeSource yt;
  static final _client = http.Client();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final res = await yt.open(trackId, start: from, end: end, client: _client);
    int? total;
    final range = res.headers['content-range']; // "bytes 0-999/12345"
    if (range != null && range.contains('/')) total = int.tryParse(range.split('/').last);
    total ??= res.contentLength != null ? from + res.contentLength! : null;
    return StreamAudioResponse(
      sourceLength: total,
      contentLength: res.contentLength,
      offset: from,
      stream: _resilient(res, from, end ?? total),
      contentType: res.headers['content-type'] ?? (await yt.resolve(trackId)).mime,
    );
  }

  /// Si la connexion casse ou se bloque en cours de route, on se reconnecte à l'octet près
  /// (Range) au lieu de remonter une erreur qui arrêterait la lecture.
  Stream<List<int>> _resilient(http.StreamedResponse first, int start, int? end) async* {
    var pos = start;
    var res = first;
    var retries = 0;
    while (true) {
      try {
        await for (final chunk in res.stream.timeout(const Duration(seconds: 20))) {
          pos += chunk.length;
          retries = 0;
          yield chunk;
        }
        return;
      } catch (_) {
        if (end != null && pos >= end) return;
        if (++retries > 5) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 700 * retries));
        res = await yt.open(trackId, start: pos, end: end, client: _client, force: retries > 2);
      }
    }
  }
}

class ImportedPlaylist {
  const ImportedPlaylist({required this.name, required this.tracks, required this.truncated});
  final String name;
  final List<Track> tracks;

  /// Plus de [YoutubeSource.importMax] titres : seuls les premiers sont importés.
  final bool truncated;
}

/// Lien de playlist YouTube canonique, ou null si le texte n'en contient pas.
/// Accepte youtube.com/playlist?list=…, music.youtube.com, youtu.be/…?list=…, watch?v=…&list=…,
/// et un lien au milieu d'un texte partagé.
String? youtubePlaylistUrl(String input) {
  final match = RegExp(r'https?://\S+').firstMatch(input.trim());
  final uri = Uri.tryParse(match?.group(0) ?? input.trim());
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  final youtube = host == 'youtu.be' || host == 'youtube.com' || host.endsWith('.youtube.com');
  final id = uri.queryParameters['list'];
  if (!youtube || id == null || !RegExp(r'^[A-Za-z0-9_-]{10,}$').hasMatch(id)) return null;
  return 'https://www.youtube.com/playlist?list=$id';
}
