import 'dart:convert';

import 'package:http/http.dart' as http;

class LyricLine {
  const LyricLine(this.time, this.text);
  final Duration? time; // null = paroles non synchronisées
  final String text;
}

class Lyrics {
  const Lyrics(this.lines, {required this.synced});
  final List<LyricLine> lines;
  final bool synced;

  /// Index de la ligne en cours pour une position donnée.
  int indexAt(Duration position) {
    if (!synced) return 0;
    var idx = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time! <= position) idx = i;
    }
    return idx;
  }
}

/// Paroles via LRCLIB (https://lrclib.net) : base libre et gratuite, sans clé.
class LyricsApi {
  LyricsApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _headers = {'User-Agent': 'YouPlay (usage personnel)'};

  /// 1. correspondance exacte (rapide) ; 2. recherche floue, car les durées des clips YouTube
  /// diffèrent souvent de la version audio et `/api/get` exige ±2 s.
  Future<Lyrics?> fetch({required String artist, required String title, required Duration duration}) async {
    final t = cleanTitle(title);
    try {
      final exact = await _getJson(Uri.https('lrclib.net', '/api/get', {
        'artist_name': artist,
        'track_name': t,
        if (duration.inSeconds > 0) 'duration': '${duration.inSeconds}',
      }));
      if (exact is Map<String, dynamic>) {
        final l = _fromRecord(exact);
        if (l != null) return l;
      }
      for (final q in ['$artist $t', t]) {
        final res = await _getJson(Uri.https('lrclib.net', '/api/search', {'q': q}));
        if (res is! List || res.isEmpty) continue;
        final best = _best(res.cast<Map<String, dynamic>>(), artist: artist, title: t, duration: duration);
        if (best != null) return _fromRecord(best);
      }
    } catch (_) {
      // Réseau indisponible ou réponse invalide : pas de paroles.
    }
    return null;
  }

  Future<dynamic> _getJson(Uri uri) async {
    final res = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }

  /// Retire « (Clip officiel) », « [Audio] », « feat. X », « Artiste - » etc.
  static String cleanTitle(String title) {
    var t = title.replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]'), '');
    t = t.replaceAll(RegExp(r'\s+(feat\.?|ft\.?|featuring)\s+.*$', caseSensitive: false), '');
    final dash = RegExp(r'^.+?\s+[-–—]\s+').firstMatch(t);
    if (dash != null && t.length - dash.end > 1) t = t.substring(dash.end);
    return t.trim().isEmpty ? title.trim() : t.trim();
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  /// Choisit le meilleur résultat ; refuse s'il n'y a pas de vraie correspondance de titre
  /// (mieux vaut « indisponible » que les paroles d'une autre chanson).
  static Map<String, dynamic>? _best(List<Map<String, dynamic>> items,
      {required String artist, required String title, required Duration duration}) {
    final nt = _norm(title), na = _norm(artist);
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final it in items) {
      final ct = _norm(cleanTitle(it['trackName'] as String? ?? ''));
      final ca = _norm(it['artistName'] as String? ?? '');
      if (ct.isEmpty || nt.isEmpty) continue;
      final titleOk = ct == nt || ct.contains(nt) || nt.contains(ct);
      if (!titleOk) continue;
      final artistOk = ca.isNotEmpty && na.isNotEmpty && (ca.contains(na) || na.contains(ca));
      final synced = (it['syncedLyrics'] as String?)?.trim().isNotEmpty == true;
      final plain = (it['plainLyrics'] as String?)?.trim().isNotEmpty == true;
      if (!synced && !plain) continue;
      final diff = ((it['duration'] as num?)?.toDouble() ?? 0) - duration.inSeconds;
      var score = (ct == nt ? 3 : 1) + (artistOk ? 4 : 0) + (synced ? 3 : 0);
      if (diff.abs() <= 5) {
        score += 2;
      } else if (diff.abs() <= 20) {
        score += 1;
      }
      // Sans l'artiste, on n'accepte qu'un titre identique (titres courts trop ambigus).
      if (!artistOk && ct != nt) continue;
      if (score > bestScore) {
        bestScore = score;
        best = it;
      }
    }
    return best;
  }

  Lyrics? _fromRecord(Map<String, dynamic> j) {
    final synced = j['syncedLyrics'] as String?;
    if (synced != null && synced.trim().isNotEmpty) return _parseLrc(synced);
    final plain = j['plainLyrics'] as String?;
    if (plain != null && plain.trim().isNotEmpty) {
      return Lyrics(
        plain.split('\n').where((l) => l.trim().isNotEmpty).map((l) => LyricLine(null, l.trim())).toList(),
        synced: false,
      );
    }
    return null;
  }

  static final _lrc = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');

  Lyrics? _parseLrc(String raw) {
    final lines = <LyricLine>[];
    for (final l in raw.split('\n')) {
      final m = _lrc.firstMatch(l);
      if (m == null) continue;
      final ms = (int.parse(m.group(1)!) * 60000 + double.parse(m.group(2)!) * 1000).round();
      final text = m.group(3)!.trim();
      lines.add(LyricLine(Duration(milliseconds: ms), text.isEmpty ? '♪' : text));
    }
    if (lines.isEmpty) return null;
    return Lyrics(lines, synced: true);
  }
}
