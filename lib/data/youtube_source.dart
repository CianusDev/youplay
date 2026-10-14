// StreamAudioSource est marqué expérimental dans just_audio, mais stable en pratique.
// ignore_for_file: experimental_member_use
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import 'models.dart';

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

/// Catalogue YouTube / YouTube Music via NewPipeExtractor (canal natif Android).
/// Usage personnel uniquement : contourne les conditions d'utilisation de YouTube.
class YoutubeSource {
  static const _ch = MethodChannel('sika/newpipe');
  static bool get supported => !kIsWeb && Platform.isAndroid;

  final _cache = <String, ResolvedStream>{};

  Future<List<Track>> searchSongs(String query) => _tracks('searchSongs', {'query': query});
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
      name: m['name'] as String? ?? 'Album',
      owner: _artist(m['uploader'] as String?),
      artworkUrl: m['thumbnail'] as String?,
      trackCount: items.length,
      isAlbum: true,
    );
    return (p, items);
  }

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
        title: m['title'] as String? ?? 'Sans titre',
        artist: _artist(m['artist'] as String?),
        duration: Duration(seconds: (m['duration'] as num?)?.toInt() ?? 0),
        artworkUrl: m['thumbnail'] as String?,
        permalink: m['url'] as String? ?? '',
      );

  static Playlist _playlist(Map<String, dynamic> m) => Playlist(
        id: m['url'] as String,
        name: m['title'] as String? ?? 'Album',
        owner: _artist(m['artist'] as String?),
        artworkUrl: m['thumbnail'] as String?,
        trackCount: (m['count'] as num?)?.toInt() ?? 0,
        isAlbum: true,
      );

  /// Ouvre un flux HTTP (avec Range) vers l'audio d'un titre, en renouvelant l'URL si elle a expiré.
  Future<http.StreamedResponse> open(String trackId, {int? start, int? end, http.Client? client}) async {
    final c = client ?? http.Client();
    for (var attempt = 0; attempt < 2; attempt++) {
      final s = await resolve(trackId, force: attempt > 0);
      final req = http.Request('GET', Uri.parse(s.url));
      if (s.userAgent.isNotEmpty) req.headers['User-Agent'] = s.userAgent;
      req.headers['Range'] = 'bytes=${start ?? 0}-${end != null ? end - 1 : ''}';
      final res = await c.send(req);
      if (res.statusCode == 200 || res.statusCode == 206) return res;
      await res.stream.drain<void>();
      if (res.statusCode != 403 && res.statusCode != 410) throw http.ClientException('HTTP ${res.statusCode}');
    }
    throw http.ClientException('Flux YouTube refusé (403)');
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
    final res = await yt.open(trackId, start: start, end: end, client: _client);
    int? total;
    final range = res.headers['content-range']; // "bytes 0-999/12345"
    if (range != null && range.contains('/')) total = int.tryParse(range.split('/').last);
    total ??= res.contentLength != null ? (start ?? 0) + res.contentLength! : null;
    return StreamAudioResponse(
      sourceLength: total,
      contentLength: res.contentLength,
      offset: start ?? 0,
      stream: res.stream,
      contentType: res.headers['content-type'] ?? (await yt.resolve(trackId)).mime,
    );
  }
}
