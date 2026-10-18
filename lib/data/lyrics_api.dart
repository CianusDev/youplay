import 'dart:convert';

import 'package:http/http.dart' as http;

class LyricLine {
  const LyricLine(this.time, this.text);
  final Duration? time; // null = paroles non synchronisées
  final String text;
}

class Lyrics {
  const Lyrics(this.lines, {required this.synced, this.id, this.sourceDuration, this.trackDuration});
  final List<LyricLine> lines;
  final bool synced;
  final int? id; // identifiant LRCLIB (pour « mauvaises paroles »)
  final Duration? sourceDuration; // durée de la version minutée
  final Duration? trackDuration; // durée du titre lu

  /// Écart de durée entre le titre lu (souvent un clip) et la version minutée.
  Duration get durationGap => (trackDuration == null || sourceDuration == null) ? Duration.zero : trackDuration! - sourceDuration!;

  /// Vrai si le titre lu est sensiblement plus long/court : intro/outro de clip, synchro incertaine.
  bool get approximate => synced && durationGap.inMilliseconds.abs() > 4000;

  /// Index de la ligne en cours pour une position donnée.
  int indexAt(Duration position) {
    if (!synced) return 0;
    var idx = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time! <= position) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }

  Lyrics withTrackDuration(Duration d) =>
      Lyrics(lines, synced: synced, id: id, sourceDuration: sourceDuration, trackDuration: d);
}

/// Paroles via LRCLIB (https://lrclib.net) : base libre et gratuite, sans clé.
class LyricsApi {
  LyricsApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _headers = {'User-Agent': 'YouPlay (usage personnel)'};

  /// 1. correspondance exacte (artiste + titre + durée ±2 s) ; 2. recherche floue stricte.
  /// `exclude` = enregistrements LRCLIB signalés comme mauvais par l'utilisateur pour ce titre.
  Future<Lyrics?> fetch({
    required String artist,
    required String title,
    required Duration duration,
    Set<int> exclude = const {},
  }) async {
    final t = cleanTitle(title);
    Lyrics? done(Map<String, dynamic> rec) => _fromRecord(rec)?.withTrackDuration(duration);
    try {
      final exact = await _getJson(Uri.https('lrclib.net', '/api/get', {
        'artist_name': artist,
        'track_name': t,
        if (duration.inSeconds > 0) 'duration': '${duration.inSeconds}',
      }));
      if (exact is Map<String, dynamic> && !exclude.contains(exact['id'])) {
        final l = done(exact);
        if (l != null) return l;
      }
      final seen = <int>{};
      final pool = <Map<String, dynamic>>[];
      for (final q in ['$artist $t', t]) {
        final res = await _getJson(Uri.https('lrclib.net', '/api/search', {'q': q}));
        if (res is! List) continue;
        for (final r in res.cast<Map<String, dynamic>>()) {
          final id = r['id'] as int?;
          if (id != null && seen.add(id) && !exclude.contains(id)) pool.add(r);
        }
        final best = _best(pool, artist: artist, title: t, duration: duration);
        if (best != null) return done(best);
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

  /// Choisit le meilleur résultat. Règles (mieux vaut « indisponible » que les paroles d'un autre son) :
  /// - le titre doit correspondre (identique, ou l'un contient l'autre s'il fait au moins 5 caractères) ;
  /// - l'artiste doit correspondre, SAUF titre identique ET durée à ±3 s ;
  /// - au-delà de ±45 s d'écart de durée, c'est une autre version (live, remix, mix) : refusé.
  static Map<String, dynamic>? _best(List<Map<String, dynamic>> items,
      {required String artist, required String title, required Duration duration}) {
    final nt = _norm(title), na = _norm(artist);
    final artistWords = na.split(' ').where((w) => w.length >= 3).toList();
    Map<String, dynamic>? best;
    var bestScore = -1.0;
    for (final it in items) {
      final ct = _norm(cleanTitle(it['trackName'] as String? ?? ''));
      final ca = _norm(it['artistName'] as String? ?? '');
      if (ct.isEmpty || nt.isEmpty) continue;
      final titleExact = ct == nt;
      final titleOk = titleExact || (nt.length >= 5 && ct.length >= 5 && (ct.contains(nt) || nt.contains(ct)));
      if (!titleOk) continue;
      // L'artiste YouTube vaut parfois « Damso, Hamza » ou une chaîne : on accepte un mot commun significatif.
      final artistOk = ca.isNotEmpty &&
          na.isNotEmpty &&
          (ca.contains(na) || na.contains(ca) || artistWords.any((w) => ca.split(' ').contains(w)));
      final synced = (it['syncedLyrics'] as String?)?.trim().isNotEmpty == true;
      final plain = (it['plainLyrics'] as String?)?.trim().isNotEmpty == true;
      if (!synced && !plain) continue;
      final recDur = (it['duration'] as num?)?.toDouble() ?? 0;
      final diff = duration.inSeconds > 0 && recDur > 0 ? (recDur - duration.inSeconds).abs() : 999.0;
      if (!artistOk && !(titleExact && diff <= 3)) continue;
      if (diff > 45 && diff != 999.0) continue;
      var score = (titleExact ? 30.0 : 10.0) + (artistOk ? 40.0 : 0.0) + (synced ? 15.0 : 0.0);
      score -= diff == 999.0 ? 10.0 : diff.clamp(0, 45) * 0.8; // la version la plus proche en durée gagne
      if (score > bestScore) {
        bestScore = score;
        best = it;
      }
    }
    return best;
  }

  Lyrics? _fromRecord(Map<String, dynamic> j) {
    final id = j['id'] as int?;
    final dur = (j['duration'] as num?) == null ? null : Duration(milliseconds: ((j['duration'] as num) * 1000).round());
    final synced = j['syncedLyrics'] as String?;
    if (synced != null && synced.trim().isNotEmpty) {
      final l = _parseLrc(synced);
      return l == null ? null : Lyrics(l.lines, synced: true, id: id, sourceDuration: dur);
    }
    final plain = j['plainLyrics'] as String?;
    if (plain != null && plain.trim().isNotEmpty) {
      return Lyrics(
        plain.split('\n').where((l) => l.trim().isNotEmpty).map((l) => LyricLine(null, l.trim())).toList(),
        synced: false,
        id: id,
        sourceDuration: dur,
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
