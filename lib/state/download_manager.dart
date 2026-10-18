import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/media_storage.dart';
import '../data/models.dart';
import '../data/youtube_source.dart';
import 'providers.dart';

enum DownloadStatus { queued, downloading, done, failed }

class DownloadItem {
  const DownloadItem({required this.track, required this.status, this.progress = 0, this.path, this.bytes = 0, this.addedAt = 0});
  final Track track;
  final DownloadStatus status;
  final double progress; // 0..1
  final String? path;
  final int bytes;
  final int addedAt;

  DownloadItem copyWith({DownloadStatus? status, double? progress, String? path, int? bytes}) => DownloadItem(
        track: track,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        path: path ?? this.path,
        bytes: bytes ?? this.bytes,
        addedAt: addedAt,
      );

  Map<String, dynamic> toJson() => {
        'track': track.toJson(),
        // Un téléchargement interrompu par la fermeture de l'app repart en file.
        'status': (status == DownloadStatus.downloading ? DownloadStatus.queued : status).name,
        'path': path,
        'bytes': bytes,
        'addedAt': addedAt,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> j) => DownloadItem(
        track: Track.fromJson(j['track'] as Map<String, dynamic>),
        status: DownloadStatus.values.byName(j['status'] as String),
        path: j['path'] as String?,
        bytes: j['bytes'] as int? ?? 0,
        addedAt: j['addedAt'] as int? ?? 0,
        progress: j['status'] == 'done' ? 1 : 0,
      );
}

/// Collection téléchargée (playlist, album, artiste, titres likés…).
class DownloadedCollection {
  const DownloadedCollection({required this.ref, required this.trackIds, required this.addedAt});
  final CollectionRef ref;
  final List<String> trackIds;
  final int addedAt;

  Map<String, dynamic> toJson() => {'ref': ref.toJson(), 'tracks': trackIds, 'addedAt': addedAt};
  factory DownloadedCollection.fromJson(Map<String, dynamic> j) => DownloadedCollection(
        ref: CollectionRef.fromJson(j['ref'] as Map<String, dynamic>),
        trackIds: (j['tracks'] as List).cast<String>(),
        addedAt: j['addedAt'] as int? ?? 0,
      );
}

class DownloadsState {
  const DownloadsState({
    this.items = const {},
    this.collections = const [],
    this.offlineMode = false,
    this.smartDownload = true,
    this.paused = false,
  });

  final Map<String, DownloadItem> items;
  final List<DownloadedCollection> collections;
  final bool offlineMode;
  final bool smartDownload;
  final bool paused;

  bool isDownloaded(String trackId) => items[trackId]?.status == DownloadStatus.done;
  /// Fichier local du titre, s'il existe encore (il peut avoir été supprimé depuis l'explorateur).
  String? pathOf(String trackId) {
    final p = isDownloaded(trackId) ? items[trackId]!.path : null;
    if (p == null || kIsWeb) return p;
    return File(p).existsSync() ? p : null;
  }
  bool hasCollection(String key) => collections.any((c) => c.ref.key == key);

  List<DownloadItem> get active =>
      items.values.where((i) => i.status == DownloadStatus.downloading || i.status == DownloadStatus.queued).toList()
        ..sort((a, b) => a.addedAt.compareTo(b.addedAt));
  List<DownloadItem> get done => items.values.where((i) => i.status == DownloadStatus.done).toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  int get totalBytes => items.values.fold(0, (s, i) => s + i.bytes);
  int get podcastBytes => items.values.where((i) => i.track.isPodcast).fold(0, (s, i) => s + i.bytes);

  /// Progression agrégée d'une collection (0..1) et état global.
  ({double progress, DownloadStatus status}) collectionStatus(DownloadedCollection c) {
    if (c.trackIds.isEmpty) return (progress: 1, status: DownloadStatus.done);
    var sum = 0.0;
    var anyActive = false, anyDownloading = false, anyFailed = false;
    for (final id in c.trackIds) {
      final it = items[id];
      if (it == null) continue;
      sum += it.status == DownloadStatus.done ? 1 : it.progress;
      if (it.status == DownloadStatus.downloading) anyDownloading = true;
      if (it.status == DownloadStatus.queued) anyActive = true;
      if (it.status == DownloadStatus.failed) anyFailed = true;
    }
    final p = sum / c.trackIds.length;
    if (anyDownloading) return (progress: p, status: DownloadStatus.downloading);
    if (anyActive) return (progress: p, status: p > 0 ? DownloadStatus.downloading : DownloadStatus.queued);
    if (anyFailed) return (progress: p, status: DownloadStatus.failed);
    return (progress: 1, status: DownloadStatus.done);
  }

  DownloadsState copyWith({
    Map<String, DownloadItem>? items,
    List<DownloadedCollection>? collections,
    bool? offlineMode,
    bool? smartDownload,
    bool? paused,
  }) =>
      DownloadsState(
        items: items ?? this.items,
        collections: collections ?? this.collections,
        offlineMode: offlineMode ?? this.offlineMode,
        smartDownload: smartDownload ?? this.smartDownload,
        paused: paused ?? this.paused,
      );
}

/// Téléchargements hors ligne : fichiers audio stockés dans le dossier privé de l'app.
class DownloadManager extends Notifier<DownloadsState> {
  static const _key = 'sika.downloads.v1';

  bool _working = false;
  StreamSubscription<List<int>>? _current;
  Completer<void>? _abort;

  void _abortCurrent() {
    if (_abort?.isCompleted == false) _abort!.complete();
  }

  static bool get supported => !kIsWeb;

  @override
  DownloadsState build() {
    final prefs = ref.read(prefsProvider);
    final raw = prefs.getString(_key);
    var s = const DownloadsState();
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        s = DownloadsState(
          items: {
            for (final e in (j['items'] as List).cast<Map<String, dynamic>>().map(DownloadItem.fromJson)) e.track.id: e,
          },
          collections: (j['collections'] as List).cast<Map<String, dynamic>>().map(DownloadedCollection.fromJson).toList(),
          offlineMode: j['offline'] as bool? ?? false,
          smartDownload: j['smart'] as bool? ?? true,
        );
      } catch (_) {}
    }
    if (s.active.isNotEmpty) Future.microtask(_pump);
    if (supported && s.done.isNotEmpty) Future.microtask(_migrateToMusic);
    return s;
  }

  void _set(DownloadsState s, {bool persist = true}) {
    state = s;
    if (persist) {
      ref.read(prefsProvider).setString(
            _key,
            jsonEncode({
              'items': s.items.values.map((i) => i.toJson()).toList(),
              'collections': s.collections.map((c) => c.toJson()).toList(),
              'offline': s.offlineMode,
              'smart': s.smartDownload,
            }),
          );
    }
  }

  /// Le fichier d'un titre a été déplacé (dossier de playlist ↔ Music/YouPlay) : on met à jour son chemin.
  void relocate(String trackId, String newPath) {
    final it = state.items[trackId];
    if (it == null || it.path == newPath) return;
    _set(state.copyWith(items: {...state.items, trackId: it.copyWith(path: newPath)}));
  }

  void setOffline(bool v) => _set(state.copyWith(offlineMode: v));
  void setSmart(bool v, {Iterable<Track> liked = const []}) {
    _set(state.copyWith(smartDownload: v));
    if (v) enqueue(liked);
  }

  bool _askedPermission = false;

  void enqueue(Iterable<Track> tracks) {
    if (!supported) return;
    if (!_askedPermission) {
      _askedPermission = true;
      MediaStorage.ensurePermission();
    }
    final items = {...state.items};
    final now = DateTime.now().millisecondsSinceEpoch;
    var i = 0;
    for (final t in tracks) {
      final cur = items[t.id];
      if (cur == null || cur.status == DownloadStatus.failed) {
        items[t.id] = DownloadItem(track: t, status: DownloadStatus.queued, addedAt: now + i++);
      }
    }
    _set(state.copyWith(items: items));
    _pump();
  }

  void downloadCollection(CollectionRef ref, List<Track> tracks) {
    if (!supported) return;
    final cols = state.collections.where((c) => c.ref.key != ref.key).toList();
    cols.insert(0, DownloadedCollection(ref: ref, trackIds: tracks.map((t) => t.id).toList(), addedAt: DateTime.now().millisecondsSinceEpoch));
    _set(state.copyWith(collections: cols));
    enqueue(tracks);
  }

  /// Supprime une collection (et les fichiers qui ne servent plus ailleurs).
  Future<void> removeCollection(String key) async {
    final col = state.collections.where((c) => c.ref.key == key).firstOrNull;
    if (col == null) return;
    final rest = state.collections.where((c) => c.ref.key != key).toList();
    final stillUsed = rest.expand((c) => c.trackIds).toSet();
    _set(state.copyWith(collections: rest));
    for (final id in col.trackIds.where((id) => !stillUsed.contains(id))) {
      await removeTrack(id);
    }
  }

  Future<void> removeTrack(String id) async {
    final it = state.items[id];
    if (it == null) return;
    if (it.status == DownloadStatus.downloading) _abortCurrent();
    final items = {...state.items}..remove(id);
    _set(state.copyWith(items: items));
    if (it.path != null) {
      try {
        await File(it.path!).delete();
        await MediaStorage.scan(it.path!);
      } catch (_) {}
    }
  }

  void togglePause() {
    final paused = !state.paused;
    _set(state.copyWith(paused: paused));
    if (paused) {
      _abortCurrent();
    } else {
      _pump();
    }
  }

  void retryFailed() {
    final items = {
      for (final e in state.items.entries)
        e.key: e.value.status == DownloadStatus.failed ? e.value.copyWith(status: DownloadStatus.queued, progress: 0) : e.value,
    };
    _set(state.copyWith(items: items));
    _pump();
  }

  /// Déplace les anciens téléchargements (dossier privé) vers Music/YouPlay.
  Future<void> _migrateToMusic() async {
    final dir = await MediaStorage.downloadsDir();
    if (!dir.path.contains('/Music/')) return; // stockage public indisponible
    for (final it in state.done) {
      final old = it.path;
      if (old == null || old.startsWith(dir.path)) continue;
      try {
        final src = File(old);
        if (!await src.exists()) continue;
        final dst = await MediaStorage.fileFor(it.track);
        await src.copy(dst.path);
        await src.delete();
        _update(it.track.id, (i) => i.copyWith(path: dst.path), persist: true);
        await MediaStorage.scan(dst.path);
      } catch (_) {
        // On garde l'ancien emplacement : le titre reste lisible.
      }
    }
  }

  Future<void> _pump() async {
    if (_working || !supported) return;
    _working = true;
    try {
      while (!state.paused) {
        final next = state.items.values.where((i) => i.status == DownloadStatus.queued).toList()
          ..sort((a, b) => a.addedAt.compareTo(b.addedAt));
        if (next.isEmpty) break;
        await _download(next.first);
      }
    } finally {
      _working = false;
    }
  }

  void _update(String id, DownloadItem Function(DownloadItem) f, {bool persist = false}) {
    final cur = state.items[id];
    if (cur == null) return;
    _set(state.copyWith(items: {...state.items, id: f(cur)}), persist: persist);
  }

  Future<void> _download(DownloadItem item) async {
    final id = item.track.id;
    _update(id, (i) => i.copyWith(status: DownloadStatus.downloading, progress: 0));
    final file = await MediaStorage.fileFor(item.track);
    final tmp = File('${file.path}.part');
    final client = http.Client();
    _abort = Completer<void>();
    IOSink? sink;
    try {
      if (!isYoutubeTrack(id)) throw const HttpException('Source Audius retirée');
      final res = await ref.read(youtubeProvider).open(id, client: client);
      if (res.statusCode != 200 && res.statusCode != 206) throw HttpException('HTTP ${res.statusCode}');
      final total = res.contentLength ?? 0;
      var received = 0;
      var lastTick = 0.0;
      sink = tmp.openWrite();
      final done = Completer<bool>();
      _current = res.stream.listen(
        (chunk) {
          sink!.add(chunk);
          received += chunk.length;
          if (total > 0) {
            final p = received / total;
            if (p - lastTick > 0.01) {
              lastTick = p;
              _update(id, (i) => i.copyWith(progress: p));
            }
          }
        },
        onDone: () => done.complete(true),
        onError: (Object e) => done.completeError(e),
        cancelOnError: true,
      );
      // Pause ou suppression : _abort est complété, on coupe le flux.
      final ok = await Future.any([done.future, _abort!.future.then((_) => false)]);
      await _current?.cancel();
      await sink.close();
      sink = null;
      if (!ok) {
        try {
          await tmp.delete();
        } catch (_) {}
        if (state.items[id] != null) _update(id, (i) => i.copyWith(status: DownloadStatus.queued, progress: 0), persist: true);
        return;
      }
      await tmp.rename(file.path);
      _update(id, (i) => i.copyWith(status: DownloadStatus.done, progress: 1, path: file.path, bytes: received), persist: true);
      await MediaStorage.scan(file.path);
    } catch (e) {
      await sink?.close();
      if (state.items[id] != null) _update(id, (i) => i.copyWith(status: DownloadStatus.failed, progress: 0), persist: true);
    } finally {
      _current = null;
      client.close();
    }
  }
}

final downloadsProvider = NotifierProvider<DownloadManager, DownloadsState>(DownloadManager.new);
