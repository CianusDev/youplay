import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import 'download_manager.dart';
import 'providers.dart';
import '../l10n/l10n.dart';

class MyPlaylist {
  const MyPlaylist({required this.id, required this.name, required this.tracks});
  final String id;
  final String name;
  final List<Track> tracks;

  MyPlaylist copyWith({String? name, List<Track>? tracks}) => MyPlaylist(id: id, name: name ?? this.name, tracks: tracks ?? this.tracks);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'tracks': tracks.map((t) => t.toJson()).toList()};
  factory MyPlaylist.fromJson(Map<String, dynamic> j) => MyPlaylist(
        id: j['id'] as String,
        name: j['name'] as String,
        tracks: (j['tracks'] as List).cast<Map<String, dynamic>>().map(Track.fromJson).toList(),
      );
}

class HistoryEntry {
  const HistoryEntry({required this.track, required this.playedAt, this.seconds = 0});
  final Track track;
  final DateTime playedAt;
  final int seconds;

  HistoryEntry withSeconds(int s) => HistoryEntry(track: track, playedAt: playedAt, seconds: s);

  Map<String, dynamic> toJson() => {'track': track.toJson(), 'at': playedAt.millisecondsSinceEpoch, 's': seconds};
  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        track: Track.fromJson(j['track'] as Map<String, dynamic>),
        playedAt: DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
        seconds: j['s'] as int? ?? 0,
      );
}

class LibraryState {
  const LibraryState({
    this.userName = 'Utilisateur',
    this.likedTracks = const [],
    this.savedPlaylists = const [],
    this.followedArtists = const [],
    this.myPlaylists = const [],
    this.recentSearches = const [],
    this.history = const [],
    this.pinned = const {'likes:me'},
    this.addedAt = const {},
  });

  final String userName;
  final List<Track> likedTracks;
  final List<Playlist> savedPlaylists;
  final List<Artist> followedArtists;
  final List<MyPlaylist> myPlaylists;
  final List<String> recentSearches;
  final List<HistoryEntry> history;
  final Set<String> pinned;
  final Map<String, int> addedAt; // clé de collection → timestamp d'ajout

  bool isLiked(String trackId) => likedTracks.any((t) => t.id == trackId);
  bool isSaved(String playlistId) => savedPlaylists.any((p) => p.id == playlistId);
  bool isFollowing(String artistId) => followedArtists.any((a) => a.id == artistId);

  /// Artistes écoutés récemment (uniques, plus récent d'abord).
  List<Artist> get recentArtists {
    final seen = <String>{};
    final out = <Artist>[];
    for (final h in history) {
      if (seen.add(h.track.artist.id)) out.add(h.track.artist);
      if (out.length >= 12) break;
    }
    return out;
  }

  /// Artistes les plus écoutés sur les 30 derniers jours (nombre d'écoutes + minutes).
  List<Artist> topArtists({int days = 30}) {
    final since = DateTime.now().subtract(Duration(days: days));
    final score = <String, (Artist, int)>{};
    for (final h in history.where((h) => h.playedAt.isAfter(since))) {
      final cur = score[h.track.artist.id];
      score[h.track.artist.id] = (h.track.artist, (cur?.$2 ?? 0) + 1 + h.seconds ~/ 60);
    }
    final list = score.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
    return list.map((e) => e.$1).toList();
  }

  /// Dernière pochette connue d'un artiste (les artistes YouTube n'ont pas d'image propre).
  String? artworkFor(String artistId) {
    for (final h in history) {
      if (h.track.artist.id == artistId && h.track.artworkUrl != null) return h.track.artworkUrl;
    }
    for (final t in likedTracks) {
      if (t.artist.id == artistId && t.artworkUrl != null) return t.artworkUrl;
    }
    return null;
  }

  /// Genres les plus écoutés sur les 30 derniers jours.
  List<String> topGenres({int days = 30}) {
    final since = DateTime.now().subtract(Duration(days: days));
    final count = <String, int>{};
    for (final h in history.where((h) => h.playedAt.isAfter(since) && h.track.genre.isNotEmpty)) {
      count[h.track.genre] = (count[h.track.genre] ?? 0) + 1 + h.seconds ~/ 60;
    }
    final list = count.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return list.map((e) => e.key).toList();
  }

  LibraryState copyWith({
    String? userName,
    List<Track>? likedTracks,
    List<Playlist>? savedPlaylists,
    List<Artist>? followedArtists,
    List<MyPlaylist>? myPlaylists,
    List<String>? recentSearches,
    List<HistoryEntry>? history,
    Set<String>? pinned,
    Map<String, int>? addedAt,
  }) =>
      LibraryState(
        userName: userName ?? this.userName,
        likedTracks: likedTracks ?? this.likedTracks,
        savedPlaylists: savedPlaylists ?? this.savedPlaylists,
        followedArtists: followedArtists ?? this.followedArtists,
        myPlaylists: myPlaylists ?? this.myPlaylists,
        recentSearches: recentSearches ?? this.recentSearches,
        history: history ?? this.history,
        pinned: pinned ?? this.pinned,
        addedAt: addedAt ?? this.addedAt,
      );

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'liked': likedTracks.map((t) => t.toJson()).toList(),
        'saved': savedPlaylists.map((p) => p.toJson()).toList(),
        'followed': followedArtists.map((a) => a.toJson()).toList(),
        'mine': myPlaylists.map((p) => p.toJson()).toList(),
        'searches': recentSearches,
        'history': history.map((h) => h.toJson()).toList(),
        'pinned': pinned.toList(),
        'addedAt': addedAt,
      };

  factory LibraryState.fromJson(Map<String, dynamic> j) => LibraryState(
        userName: j['userName'] as String? ?? 'Utilisateur',
        likedTracks: _list(j['liked'], Track.fromJson),
        savedPlaylists: _list(j['saved'], Playlist.fromJson),
        followedArtists: _list(j['followed'], Artist.fromJson),
        myPlaylists: _list(j['mine'], MyPlaylist.fromJson),
        recentSearches: (j['searches'] as List?)?.cast<String>() ?? const [],
        history: _list(j['history'], HistoryEntry.fromJson),
        pinned: ((j['pinned'] as List?)?.cast<String>() ?? const ['likes:me']).toSet(),
        addedAt: (j['addedAt'] as Map?)?.cast<String, int>() ?? const {},
      );

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) f) =>
      (raw as List?)?.cast<Map<String, dynamic>>().map(f).toList() ?? <T>[];
}

/// Bibliothèque locale : likes, playlists, artistes suivis, historique.
/// Tout reste sur l'appareil (shared_preferences), aucun compte requis.
class LibraryStore extends Notifier<LibraryState> {
  static const _key = 'sika.library.v1';

  @override
  LibraryState build() {
    final raw = ref.read(prefsProvider).getString(_key);
    if (raw == null) return const LibraryState();
    try {
      return LibraryState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const LibraryState();
    }
  }

  void _set(LibraryState s) {
    state = s;
    ref.read(prefsProvider).setString(_key, jsonEncode(s.toJson()));
  }

  Map<String, int> _stamp(String key) => {...state.addedAt, key: DateTime.now().millisecondsSinceEpoch};

  void setUserName(String name) => _set(state.copyWith(userName: name.trim().isEmpty ? state.userName : name.trim()));

  /// Retourne true si le titre est maintenant liké.
  bool toggleLike(Track t) {
    final liked = state.isLiked(t.id);
    _set(state.copyWith(
      likedTracks: liked ? state.likedTracks.where((x) => x.id != t.id).toList() : [t, ...state.likedTracks],
      addedAt: _stamp('likes:me'),
    ));
    // Téléchargement intelligent : les titres likés sont gardés hors ligne.
    if (!liked && ref.read(downloadsProvider).smartDownload) ref.read(downloadsProvider.notifier).enqueue([t]);
    return !liked;
  }

  void toggleSavePlaylist(Playlist p) {
    final saved = state.isSaved(p.id);
    _set(state.copyWith(
      savedPlaylists: saved ? state.savedPlaylists.where((x) => x.id != p.id).toList() : [p, ...state.savedPlaylists],
      addedAt: _stamp('playlist:${p.id}'),
    ));
  }

  void toggleFollow(Artist a) {
    final f = state.isFollowing(a.id);
    _set(state.copyWith(
      followedArtists: f ? state.followedArtists.where((x) => x.id != a.id).toList() : [a, ...state.followedArtists],
      addedAt: _stamp('artist:${a.id}'),
    ));
  }

  void togglePin(String key) {
    final p = {...state.pinned};
    if (!p.remove(key)) p.add(key);
    _set(state.copyWith(pinned: p));
  }

  MyPlaylist createPlaylist(String name) {
    final id = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999)}';
    // Nom unique (insensible à la casse) : chaque playlist a son propre dossier sur le téléphone.
    var base = name.trim().isEmpty ? L10n.current.myPlaylistN(state.myPlaylists.length + 1) : name.trim();
    final taken = state.myPlaylists.map((p) => p.name.toLowerCase()).toSet();
    var unique = base;
    for (var i = 2; taken.contains(unique.toLowerCase()); i++) {
      unique = '$base ($i)';
    }
    final p = MyPlaylist(id: id, name: unique, tracks: const []);
    _set(state.copyWith(myPlaylists: [p, ...state.myPlaylists], addedAt: _stamp('mine:$id')));
    return p;
  }

  /// Nom libre pour une playlist (unique, insensible à la casse). Retourne le nom retenu.
  String uniquePlaylistName(String wanted, {String? exceptId}) {
    final base = wanted.trim().isEmpty ? L10n.current.myPlaylist : wanted.trim();
    final taken = state.myPlaylists.where((p) => p.id != exceptId).map((p) => p.name.toLowerCase()).toSet();
    var unique = base;
    for (var i = 2; taken.contains(unique.toLowerCase()); i++) {
      unique = '$base ($i)';
    }
    return unique;
  }

  void renamePlaylist(String id, String name) => _set(state.copyWith(myPlaylists: [
        for (final p in state.myPlaylists) if (p.id == id) p.copyWith(name: name) else p,
      ]));

  void deletePlaylist(String id) => _set(state.copyWith(myPlaylists: state.myPlaylists.where((p) => p.id != id).toList()));

  void addToPlaylist(String playlistId, Track t) {
    _set(state.copyWith(
      myPlaylists: [
        for (final p in state.myPlaylists)
          if (p.id == playlistId && !p.tracks.contains(t)) p.copyWith(tracks: [...p.tracks, t]) else p,
      ],
      addedAt: _stamp('mine:$playlistId'),
    ));
  }

  /// Nouvelle playlist déjà remplie (import) : une seule écriture au lieu d'une par titre.
  MyPlaylist createPlaylistWith(String name, List<Track> tracks) {
    final p = createPlaylist(name).copyWith(tracks: tracks);
    _set(state.copyWith(myPlaylists: [for (final x in state.myPlaylists) if (x.id == p.id) p else x]));
    return p;
  }

  void removeFromPlaylist(String playlistId, String trackId) {
    _set(state.copyWith(myPlaylists: [
      for (final p in state.myPlaylists)
        if (p.id == playlistId) p.copyWith(tracks: p.tracks.where((t) => t.id != trackId).toList()) else p,
    ]));
  }

  void addSearch(String q) {
    q = q.trim();
    if (q.isEmpty) return;
    _set(state.copyWith(recentSearches: [q, ...state.recentSearches.where((s) => s.toLowerCase() != q.toLowerCase())].take(10).toList()));
  }

  void removeSearch(String q) => _set(state.copyWith(recentSearches: state.recentSearches.where((s) => s != q).toList()));

  void recordPlay(Track t) {
    _set(state.copyWith(history: [HistoryEntry(track: t, playedAt: DateTime.now()), ...state.history].take(300).toList()));
  }

  /// Ajoute des secondes d'écoute à l'entrée la plus récente de ce titre.
  void addListenTime(String trackId, int seconds) {
    if (seconds <= 0 || state.history.isEmpty) return;
    final h = [...state.history];
    final i = h.indexWhere((e) => e.track.id == trackId);
    if (i < 0) return;
    h[i] = h[i].withSeconds(h[i].seconds + seconds);
    _set(state.copyWith(history: h));
  }
}

final libraryProvider = NotifierProvider<LibraryStore, LibraryState>(LibraryStore.new);
