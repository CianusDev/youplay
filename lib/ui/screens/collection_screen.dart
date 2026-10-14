import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models.dart';
import '../../data/youtube_source.dart';
import '../../state/download_manager.dart';
import '../../state/library_store.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/cover_art.dart';
import '../components/play_button.dart';
import '../components/rows.dart';
import '../components/sika_icon.dart';

class CollectionData {
  const CollectionData({
    required this.title,
    required this.eyebrow,
    required this.meta,
    required this.tracks,
    this.description = '',
    this.artworkUrl,
    this.circle = false,
    this.playlist,
    this.artist,
    this.shareUrl,
  });

  final String title;
  final String eyebrow;
  final String meta;
  final List<Track> tracks;
  final String description;
  final String? artworkUrl;
  final bool circle;
  final Playlist? playlist;
  final Artist? artist;
  final String? shareUrl;
}

String _countMeta(String owner, List<Track> t) {
  final total = t.fold(Duration.zero, (s, x) => s + x.duration);
  return '$owner · ${t.length} titre${t.length > 1 ? 's' : ''} · ${formatTotal(total)}';
}

final collectionProvider = FutureProvider.family<CollectionData, CollectionRef>((ref, c) async {
  switch (c.kind) {
    case CollectionKind.trending:
      final t = await ref.watch(ytSongsProvider('top 50 france ${DateTime.now().year}').future);
      return CollectionData(
        title: 'Top 50',
        eyebrow: 'TENDANCES',
        meta: _countMeta('YouTube', t),
        tracks: t,
        description: 'Les titres qui tournent le plus en ce moment.',
      );
    // Anciennes collections Audius enregistrées : recherche YouTube sur leur titre.
    case CollectionKind.playlist || CollectionKind.artist || CollectionKind.genre || CollectionKind.query:
      final q = c.title.isNotEmpty ? c.title : c.id;
      final t = await ref.watch(ytSongsProvider(q).future);
      return CollectionData(title: q, eyebrow: 'MIX', meta: _countMeta('YouTube', t), tracks: t, artworkUrl: c.artworkUrl);
    case CollectionKind.likes:
      final lib = ref.watch(libraryProvider);
      return CollectionData(title: 'Titres likés', eyebrow: 'PLAYLIST', meta: _countMeta(lib.userName, lib.likedTracks), tracks: lib.likedTracks);
    case CollectionKind.mine:
      final lib = ref.watch(libraryProvider);
      final p = lib.myPlaylists.where((p) => p.id == c.id).firstOrNull;
      if (p == null) throw StateError('Playlist supprimée');
      return CollectionData(
        title: p.name,
        eyebrow: 'PLAYLIST',
        meta: _countMeta(lib.userName, p.tracks),
        tracks: p.tracks,
        description: p.tracks.isEmpty ? 'Ajoute des titres avec « … › Ajouter à une playlist ».' : '',
      );
    case CollectionKind.ytquery:
      final t = await ref.watch(ytSongsProvider(c.id).future);
      final isArtist = c.subtitle == 'Artiste';
      return CollectionData(
        title: c.title.isEmpty ? c.id : c.title,
        eyebrow: isArtist ? 'ARTISTE' : 'MIX',
        meta: _countMeta('YouTube', t),
        tracks: t,
        artworkUrl: c.artworkUrl ?? t.firstOrNull?.artworkUrl,
        circle: isArtist,
        artist: isArtist ? Artist(id: '$ytArtistPrefix${c.title.toLowerCase()}', name: c.title, imageUrl: c.artworkUrl) : null,
      );
    case CollectionKind.ytalbum:
      final (p, t) = await ref.watch(ytPlaylistProvider(c.id).future);
      return CollectionData(
        title: p.name,
        eyebrow: 'ALBUM',
        meta: _countMeta(p.owner.name, t),
        tracks: t,
        artworkUrl: p.artworkUrl ?? c.artworkUrl,
        playlist: p,
        shareUrl: c.id,
      );
    case CollectionKind.downloads:
      final dl = ref.watch(downloadsProvider);
      final t = dl.done.map((i) => i.track).toList();
      return CollectionData(title: 'Titres téléchargés', eyebrow: 'HORS LIGNE', meta: _countMeta('YouPlay', t), tracks: t);
  }
});

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key, required this.collection});
  final CollectionRef collection;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _scroll = ScrollController();
  bool _compact = false;
  bool _filtering = false;
  String _filter = '';

  CollectionRef get c => widget.collection;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final v = _scroll.offset > 260;
      if (v != _compact) setState(() => _compact = v);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(collectionProvider(c));
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          AsyncView<CollectionData>(
            value: data,
            onRetry: () => ref.invalidate(collectionProvider(c)),
            loading: ListView(padding: EdgeInsets.zero, children: [_header(null, top), const _Loader()]),
            data: (d) {
              final q = _filter.toLowerCase();
              final tracks = q.isEmpty
                  ? d.tracks
                  : d.tracks.where((t) => t.title.toLowerCase().contains(q) || t.artist.name.toLowerCase().contains(q)).toList();
              return CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(child: _header(d, top)),
                  SliverToBoxAdapter(child: _actions(d)),
                  if (_filtering)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: TextField(
                          autofocus: true,
                          cursorColor: SikaColors.yellow,
                          style: SikaText.ui(14, w: FontWeight.w600),
                          onChanged: (v) => setState(() => _filter = v),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: SikaColors.surface,
                            hintText: 'Rechercher dans ${d.title}',
                            hintStyle: SikaText.ui(14, color: SikaColors.placeholder),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(SikaRadius.sm), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ),
                  if (tracks.isEmpty)
                    SliverToBoxAdapter(child: EmptyState(d.tracks.isEmpty ? 'Aucun titre pour l\'instant.' : 'Aucun résultat.'))
                  else
                    SliverList.builder(
                      itemCount: tracks.length,
                      itemBuilder: (_, i) => _TrackItem(
                        track: tracks[i],
                        index: i,
                        onTap: () => playTracks(context, ref, tracks, start: i, source: _sourceRef(d)),
                        removeFromPlaylistId: c.kind == CollectionKind.mine ? c.id : null,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 180)),
                ],
              );
            },
          ),
          // Barre compacte au scroll
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_compact,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _compact ? 1 : 0,
                child: Container(
                  color: SikaColors.yellow,
                  padding: EdgeInsets.fromLTRB(10, top + 4, 10, 6),
                  child: Row(
                    children: [
                      IconButtonSika(icon: 'chevron-left', label: 'Retour', color: SikaColors.onYellow, iconSize: 24, onTap: () => context.pop()),
                      Expanded(
                        child: Text(
                          data.value?.title ?? c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SikaText.display(17, color: SikaColors.onYellow),
                        ),
                      ),
                      if (data.value != null)
                        _HeaderPlay(data: data.value!, source: _sourceRef(data.value!), size: 40, iconSize: 16, dark: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CollectionRef _sourceRef(CollectionData d) =>
      CollectionRef(c.kind, c.id, title: d.title, subtitle: d.eyebrow, artworkUrl: d.artworkUrl ?? c.artworkUrl);

  Widget _header(CollectionData? d, double top) {
    const ink = SikaColors.onYellow;
    final title = d?.title ?? c.title;
    final art = d?.artworkUrl ?? c.artworkUrl;
    final variant = c.kind == CollectionKind.likes ? 1 : CoverArt.variantFor(c.key);
    return Container(
      decoration: const BoxDecoration(
        color: SikaColors.yellow,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(SikaRadius.sheetBottom)),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-10, 0),
            child: Row(
              children: [
                IconButtonSika(icon: 'chevron-left', label: 'Retour', color: ink, iconSize: 24, onTap: () => context.pop()),
                const Spacer(),
                Transform.translate(
                  offset: const Offset(20, 0),
                  child: IconButtonSika(
                    icon: 'search',
                    label: 'Rechercher dans la playlist',
                    color: ink,
                    onTap: () => setState(() {
                      _filtering = !_filtering;
                      if (!_filtering) _filter = '';
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(d?.circle == true ? 999 : SikaRadius.lg),
                  boxShadow: SikaShadows.playlistCover,
                ),
                child: CoverArt(variant: variant, size: 148, radius: SikaRadius.lg, imageUrl: art, circle: d?.circle ?? c.kind == CollectionKind.artist),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d?.eyebrow ?? '', style: SikaText.eyebrow.copyWith(color: ink)),
                    const SizedBox(height: 6),
                    Text(title, maxLines: 4, overflow: TextOverflow.ellipsis, style: SikaText.h1Playlist.copyWith(color: ink, fontSize: title.length > 18 ? 26 : 32)),
                    const SizedBox(height: 10),
                    Text(d?.meta ?? ' ', maxLines: 2, style: SikaText.ui(12, w: FontWeight.w600, color: ink)),
                  ],
                ),
              ),
            ],
          ),
          if (d != null && d.description.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(d.description.trim(), maxLines: 3, overflow: TextOverflow.ellipsis, style: SikaText.ui(13, color: ink, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _actions(CollectionData d) {
    final lib = ref.watch(libraryProvider);
    final dl = ref.watch(downloadsProvider);
    final shuffle = ref.watch(playerProvider.select((s) => s.shuffle));
    final saved = d.playlist != null ? lib.isSaved(d.playlist!.id) : (d.artist != null ? lib.isFollowing(d.artist!.id) : null);
    final colKey = c.key;
    final downloaded = dl.hasCollection(colKey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 18, 12, 8),
      child: Row(
        children: [
          if (saved != null)
            IconButtonSika(
              icon: 'add-circle',
              label: saved ? 'Retirer de la bibliothèque' : 'Ajouter à la bibliothèque',
              color: saved ? SikaColors.yellow : SikaColors.text,
              iconSize: 26,
              onTap: () {
                if (d.playlist != null) {
                  ref.read(libraryProvider.notifier).toggleSavePlaylist(d.playlist!);
                } else {
                  ref.read(libraryProvider.notifier).toggleFollow(d.artist!);
                }
                showSnack(context, saved ? 'Retiré de ta bibliothèque' : 'Ajouté à ta bibliothèque');
              },
            ),
          if (DownloadManager.supported)
            IconButtonSika(
              icon: downloaded ? 'download-circle-filled' : 'download-circle',
              label: downloaded ? 'Supprimer le téléchargement' : 'Télécharger',
              color: downloaded ? SikaColors.yellow : SikaColors.text,
              iconSize: 24,
              onTap: () {
                if (downloaded) {
                  ref.read(downloadsProvider.notifier).removeCollection(colKey);
                  showSnack(context, 'Téléchargement supprimé');
                } else if (d.tracks.isNotEmpty) {
                  ref.read(downloadsProvider.notifier).downloadCollection(
                        CollectionRef(c.kind, c.id, title: d.title, subtitle: _typeLabel(d), artworkUrl: d.artworkUrl),
                        d.tracks,
                      );
                  showSnack(context, 'Téléchargement de ${d.tracks.length} titres lancé');
                }
              },
            ),
          if (d.shareUrl != null)
            IconButtonSika(
              icon: 'share',
              label: 'Partager',
              onTap: () => SharePlus.instance.share(ShareParams(text: '${d.title}\n${d.shareUrl}')),
            ),
          if (c.kind == CollectionKind.mine)
            IconButtonSika(
              icon: 'more',
              label: 'Options de la playlist',
              onTap: () => showSikaSheet(context, (ctx) => SafeArea(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SheetAction(
                        icon: 'close',
                        label: 'Supprimer la playlist',
                        color: SikaColors.orange,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          ref.read(libraryProvider.notifier).deletePlaylist(c.id);
                          context.pop();
                        },
                      ),
                      const SizedBox(height: 8),
                    ]),
                  )),
            ),
          const Spacer(),
          IconButtonSika(
            icon: 'shuffle',
            label: shuffle ? 'Désactiver l\'aléatoire' : 'Activer l\'aléatoire',
            color: shuffle ? SikaColors.yellow : SikaColors.text,
            iconSize: 24,
            onTap: () => ref.read(playerProvider.notifier).toggleShuffle(),
          ),
          const SizedBox(width: 8),
          _HeaderPlay(data: d, source: _sourceRef(d)),
        ],
      ),
    );
  }

  String _typeLabel(CollectionData d) => switch (c.kind) {
        CollectionKind.ytalbum => 'Album',
        CollectionKind.ytquery => c.subtitle == 'Artiste' ? 'Artiste' : 'Mix',
        CollectionKind.playlist || CollectionKind.artist || CollectionKind.genre || CollectionKind.query || CollectionKind.trending => 'Mix',
        _ => 'Playlist',
      };
}

class _HeaderPlay extends ConsumerWidget {
  const _HeaderPlay({required this.data, required this.source, this.size = 60, this.iconSize = 24, this.dark = false});
  final CollectionData data;
  final CollectionRef source;
  final double size;
  final double iconSize;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(playerProvider);
    final isThis = ui.source?.key == source.key && ui.current != null;
    return PlayButton(
      playing: isThis && ui.playing,
      size: size,
      iconSize: iconSize,
      background: dark ? SikaColors.onYellow : SikaColors.yellow,
      foreground: dark ? SikaColors.yellow : SikaColors.onYellow,
      onTap: data.tracks.isEmpty
          ? null
          : () {
              if (isThis) {
                ref.read(playerProvider.notifier).toggle();
              } else {
                playTracks(context, ref, data.tracks, source: source);
              }
            },
    );
  }
}

class _TrackItem extends ConsumerWidget {
  const _TrackItem({required this.track, required this.index, required this.onTap, this.removeFromPlaylistId});
  final Track track;
  final int index;
  final VoidCallback onTap;
  final String? removeFromPlaylistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(playerProvider.select((s) => s.current?.id == track.id));
    final playing = current && ref.watch(playerProvider.select((s) => s.playing));
    final downloaded = ref.watch(downloadsProvider.select((s) => s.isDownloaded(track.id)));
    final meta = [track.artist.name, if (track.genre.isNotEmpty) track.genre].join(' · ');
    return TrackRow(
      index: index + 1,
      title: track.title,
      meta: meta,
      duration: formatDuration(track.duration),
      seed: track.id,
      imageUrl: track.artworkUrl,
      current: current,
      playing: playing,
      downloaded: downloaded,
      onTap: onTap,
      onMore: () => showTrackOptions(context, ref, track, removeFromPlaylistId: removeFromPlaylistId),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: SikaColors.yellow))),
      );
}

