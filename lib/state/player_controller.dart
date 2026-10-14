import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/models.dart';
import '../data/youtube_source.dart';
import 'download_manager.dart';
import 'library_store.dart';
import 'providers.dart';

enum SikaRepeat { off, all, one }

class PlayerUi {
  const PlayerUi({
    this.queue = const [],
    this.index = 0,
    this.playing = false,
    this.buffering = false,
    this.shuffle = false,
    this.repeat = SikaRepeat.off,
    this.source,
    this.isRadio = false,
    this.error,
  });

  final List<Track> queue;
  final int index;
  final bool playing;
  final bool buffering;
  final bool shuffle;
  final SikaRepeat repeat;
  final CollectionRef? source;
  final bool isRadio;
  final String? error;

  Track? get current => queue.isEmpty || index >= queue.length ? null : queue[index];

  PlayerUi copyWith({
    List<Track>? queue,
    int? index,
    bool? playing,
    bool? buffering,
    bool? shuffle,
    SikaRepeat? repeat,
    CollectionRef? source,
    bool? isRadio,
    String? error,
    bool clearError = false,
  }) =>
      PlayerUi(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        playing: playing ?? this.playing,
        buffering: buffering ?? this.buffering,
        shuffle: shuffle ?? this.shuffle,
        repeat: repeat ?? this.repeat,
        source: source ?? this.source,
        isRadio: isRadio ?? this.isRadio,
        error: clearError ? null : (error ?? this.error),
      );
}

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final p = AudioPlayer();
  ref.onDispose(p.dispose);
  return p;
});

final positionProvider = StreamProvider<Duration>((ref) => ref.watch(audioPlayerProvider).positionStream);
final durationProvider = StreamProvider<Duration?>((ref) => ref.watch(audioPlayerProvider).durationStream);

/// Lecteur : file d'attente, lecture intégrale, aléatoire, répétition, radio infinie.
/// Aucune limite de sauts, aucune pub, lecture à la demande partout.
class PlayerController extends Notifier<PlayerUi> {
  late AudioPlayer _p;
  final _subs = <StreamSubscription<dynamic>>[];
  final _listen = Stopwatch();
  bool _loadingRadio = false;
  Timer? _saveTimer;
  Duration? _restoredPosition; // position restaurée, tant que la lecture n'a pas repris
  AppLifecycleListener? _lifecycle;

  static const _sessionKey = 'youplay.session.v1';

  @override
  PlayerUi build() {
    _p = ref.watch(audioPlayerProvider);
    // Reprise : dernière session restaurée au démarrage (en pause, à la bonne position).
    Future.microtask(_restore);
    _lifecycle = AppLifecycleListener(onPause: _save, onHide: _save, onDetach: _save);
    _subs
      ..add(_p.playerStateStream.listen((s) {
        final buffering = s.processingState == ProcessingState.loading || s.processingState == ProcessingState.buffering;
        if (s.playing && !_listen.isRunning) _listen.start();
        if (!s.playing && _listen.isRunning) _flushListen();
        // Position sauvegardée toutes les 5 s pendant la lecture, et à chaque pause.
        if (s.playing && s.processingState == ProcessingState.ready) _restoredPosition = null;
        if (s.playing) {
          _saveTimer ??= Timer.periodic(const Duration(seconds: 5), (_) => _save());
        } else {
          _saveTimer?.cancel();
          _saveTimer = null;
          _save();
        }
        if (state.playing != s.playing || state.buffering != buffering) {
          state = state.copyWith(playing: s.playing, buffering: buffering);
        }
        if (s.processingState == ProcessingState.completed) _p.pause();
      }))
      ..add(_p.currentIndexStream.listen((i) {
        if (i == null || i == state.index || i >= state.queue.length) return;
        _flushListen();
        state = state.copyWith(index: i);
        ref.read(libraryProvider.notifier).recordPlay(state.queue[i]);
        _save();
        _maybeExtendRadio();
      }))
      ..add(_p.errorStream.listen((e) {
        state = state.copyWith(error: 'Lecture impossible : ${e.message ?? 'erreur réseau'}');
      }));
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _saveTimer?.cancel();
      _lifecycle?.dispose();
    });
    return const PlayerUi();
  }

  // ---------------------------------------------------------------------------
  // Session (reprise de la lecture)
  // ---------------------------------------------------------------------------

  void _save() {
    final q = state.queue;
    if (q.isEmpty) return;
    // Fenêtre de 200 titres max autour du titre en cours (radio infinie).
    final from = (state.index - 50).clamp(0, q.length);
    final to = (from + 200).clamp(0, q.length);
    final data = {
      'queue': q.sublist(from, to).map((t) => t.toJson()).toList(),
      'index': state.index - from,
      'position': (_restoredPosition ?? _p.position).inMilliseconds,
      'source': state.source?.toJson(),
      'shuffle': state.shuffle,
      'repeat': state.repeat.name,
      'radio': state.isRadio,
    };
    ref.read(prefsProvider).setString(_sessionKey, jsonEncode(data));
  }

  Future<void> _restore() async {
    if (state.queue.isNotEmpty) return;
    final raw = ref.read(prefsProvider).getString(_sessionKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final saved = (j['queue'] as List).cast<Map<String, dynamic>>().map(Track.fromJson).toList();
      if (saved.isEmpty) return;
      final current = saved[(j['index'] as int).clamp(0, saved.length - 1)];
      final dl = ref.read(downloadsProvider);
      final queue = saved.where((t) => isYoutubeTrack(t.id) || dl.isDownloaded(t.id)).toList();
      if (queue.isEmpty) return;
      final index = queue.contains(current) ? queue.indexOf(current) : 0;
      final position = queue[index] == current ? Duration(milliseconds: j['position'] as int? ?? 0) : Duration.zero;
      final repeat = SikaRepeat.values.byName(j['repeat'] as String? ?? 'off');
      final shuffle = j['shuffle'] as bool? ?? false;
      _restoredPosition = position;
      state = state.copyWith(
        queue: queue,
        index: index,
        source: j['source'] == null ? null : CollectionRef.fromJson((j['source'] as Map).cast<String, dynamic>()),
        shuffle: shuffle,
        repeat: repeat,
        isRadio: j['radio'] as bool? ?? false,
        playing: false,
      );
      await _p.setLoopMode(switch (repeat) {
        SikaRepeat.off => LoopMode.off,
        SikaRepeat.all => LoopMode.all,
        SikaRepeat.one => LoopMode.one,
      });
      await _p.setShuffleModeEnabled(shuffle);
      // preload: false → aucun appel réseau tant que l'utilisateur n'appuie pas sur lecture.
      await _p.setAudioSources(queue.map(_source).toList(), initialIndex: index, initialPosition: position, preload: false);
    } catch (_) {
      // Session illisible : on repart de zéro.
    }
  }

  void _flushListen() {
    final cur = state.current;
    final secs = _listen.elapsed.inSeconds;
    _listen
      ..stop()
      ..reset();
    if (cur != null && secs > 0) ref.read(libraryProvider.notifier).addListenTime(cur.id, secs);
    if (_p.playing) _listen.start();
  }

  AudioSource _source(Track t) {
    final local = ref.read(downloadsProvider).pathOf(t.id);
    final tag = MediaItem(
      id: t.id,
      title: t.title,
      artist: t.artist.name,
      album: state.source?.title,
      duration: t.duration,
      artUri: t.artworkUrl == null ? null : Uri.parse(t.artworkUrl!),
    );
    if (local != null && !kIsWeb) return AudioSource.file(local, tag: tag);
    return YoutubeAudioSource(t.id, ref.read(youtubeProvider), tag: tag);
  }

  /// Lance une liste de titres. Retourne un message d'erreur si rien n'est jouable.
  Future<String?> playQueue(List<Track> tracks, {int start = 0, CollectionRef? source, bool? shuffle, bool radio = false}) async {
    if (tracks.isEmpty) return 'Aucun titre à lire';
    final dl = ref.read(downloadsProvider);
    // Anciens titres Audius : lisibles seulement s'ils sont téléchargés.
    final startTrack = tracks[start.clamp(0, tracks.length - 1)];
    tracks = tracks.where((t) => isYoutubeTrack(t.id) || dl.isDownloaded(t.id)).toList();
    if (tracks.isEmpty) return 'Ce titre venait d\'Audius (source retirée) : cherche-le sur YouTube';
    var list = tracks;
    var startIdx = tracks.contains(startTrack) ? tracks.indexOf(startTrack) : 0;
    if (dl.offlineMode) {
      final target = tracks[startIdx];
      list = tracks.where((t) => dl.isDownloaded(t.id)).toList();
      if (list.isEmpty) return 'Mode hors ligne : aucun de ces titres n\'est téléchargé';
      startIdx = list.indexOf(target).clamp(0, list.length - 1);
    }
    _flushListen();
    _restoredPosition = null;
    final sh = shuffle ?? state.shuffle;
    state = state.copyWith(
      queue: list,
      index: startIdx,
      source: source ?? const CollectionRef(CollectionKind.query, ''),
      isRadio: radio,
      shuffle: sh,
      clearError: true,
    );
    ref.read(libraryProvider.notifier).recordPlay(list[startIdx]);
    try {
      await _p.setShuffleModeEnabled(sh);
      await _p.setAudioSources(list.map(_source).toList(), initialIndex: startIdx, initialPosition: Duration.zero);
      if (sh) await _p.shuffle();
      _p.play();
      _save();
    } catch (e) {
      state = state.copyWith(error: 'Lecture impossible : $e');
      return 'Lecture impossible';
    }
    return null;
  }

  /// Radio : titres liés au dernier titre écouté, ou aux artistes les plus écoutés.
  Future<String?> playRadio() async {
    final yt = ref.read(youtubeProvider);
    final lib = ref.read(libraryProvider);
    const src = CollectionRef(CollectionKind.trending, 'radio', title: 'Ta Radio YouPlay');
    final last = lib.history.where((h) => isYoutubeTrack(h.track.id)).firstOrNull?.track;
    if (last != null) {
      final rel = await yt.related(last.id);
      if (rel.isNotEmpty) return playQueue([last, ...rel.where((t) => t.id != last.id)], source: src, radio: true);
    }
    final artists = lib.topArtists().where((a) => isYoutubeArtist(a.id)).take(3).map((a) => a.name).toList();
    final query = artists.isEmpty ? 'hits rap français ${DateTime.now().year}' : artists.join(' ');
    final tracks = (await yt.searchSongs(query))..shuffle();
    return playQueue(tracks, source: src, radio: true);
  }

  Future<void> _maybeExtendRadio() async {
    if (!state.isRadio || _loadingRadio || state.index < state.queue.length - 3) return;
    _loadingRadio = true;
    try {
      final more = (await ref.read(youtubeProvider).related(state.queue.last.id)).where((t) => !state.queue.contains(t)).toList();
      if (more.isEmpty) return;
      await _p.addAudioSources(more.map(_source).toList());
      state = state.copyWith(queue: [...state.queue, ...more]);
    } catch (_) {
    } finally {
      _loadingRadio = false;
    }
  }

  void toggle() => _p.playing ? _p.pause() : _p.play();
  void play() => _p.play();
  void pause() => _p.pause();

  Future<void> next() async {
    if (_p.hasNext) {
      await _p.seekToNext();
    } else if (state.queue.isNotEmpty) {
      await _p.seek(Duration.zero, index: 0);
    }
  }

  Future<void> previous() async {
    if (_p.position > const Duration(seconds: 3) || !_p.hasPrevious) {
      await _p.seek(Duration.zero);
    } else {
      await _p.seekToPrevious();
    }
  }

  Future<void> seek(Duration d) => _p.seek(d);

  Future<void> jumpTo(int index) async {
    await _p.seek(Duration.zero, index: index);
    _p.play();
  }

  Future<void> toggleShuffle() async {
    final v = !state.shuffle;
    state = state.copyWith(shuffle: v);
    if (v) await _p.shuffle();
    await _p.setShuffleModeEnabled(v);
    _save();
  }

  Future<void> cycleRepeat() async {
    final next = SikaRepeat.values[(state.repeat.index + 1) % SikaRepeat.values.length];
    state = state.copyWith(repeat: next);
    await _p.setLoopMode(switch (next) {
      SikaRepeat.off => LoopMode.off,
      SikaRepeat.all => LoopMode.all,
      SikaRepeat.one => LoopMode.one,
    });
    _save();
  }

  /// Ajoute un titre juste après celui en cours.
  Future<void> playNext(Track t) async {
    if (state.queue.isEmpty) {
      await playQueue([t]);
      return;
    }
    final at = state.index + 1;
    await _p.insertAudioSource(at, _source(t));
    final q = [...state.queue]..insert(at, t);
    state = state.copyWith(queue: q);
  }

  Future<void> addToQueue(Track t) async {
    if (state.queue.isEmpty) {
      await playQueue([t]);
      return;
    }
    await _p.addAudioSource(_source(t));
    state = state.copyWith(queue: [...state.queue, t]);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final playerProvider = NotifierProvider<PlayerController, PlayerUi>(PlayerController.new);
