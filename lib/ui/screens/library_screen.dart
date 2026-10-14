import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../state/download_manager.dart';
import '../../state/library_store.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/cover_art.dart';
import '../components/rows.dart';
import '../components/sika_chip.dart';
import '../components/sika_icon.dart';

enum _Type { playlist, artist, album, podcast }

class _Item {
  const _Item({
    required this.ref,
    required this.title,
    required this.meta,
    required this.typeLabel,
    required this.type,
    this.imageUrl,
    this.variant,
    this.circle = false,
  });
  final CollectionRef ref;
  final String title;
  final String meta;
  final String typeLabel;
  final _Type type;
  final String? imageUrl;
  final int? variant;
  final bool circle;
}

const _chips = ['Tout', 'Playlists', 'Artistes', 'Albums', 'Podcasts', 'Téléchargés'];

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _chip = 0;
  bool _grid = false;
  bool _alpha = false;
  bool _filtering = false;
  String _filter = '';

  List<_Item> _items(LibraryState lib, DownloadsState dl) {
    final items = <_Item>[
      _Item(
        ref: const CollectionRef(CollectionKind.likes, 'me', title: 'Titres likés'),
        title: 'Titres likés',
        meta: 'Playlist · ${lib.likedTracks.length} titres',
        typeLabel: 'Playlist',
        type: _Type.playlist,
        variant: 1,
      ),
      for (final p in lib.myPlaylists)
        _Item(
          ref: CollectionRef(CollectionKind.mine, p.id, title: p.name),
          title: p.name,
          meta: 'Playlist · ${lib.userName} · ${p.tracks.length} titres',
          typeLabel: 'Playlist',
          type: _Type.playlist,
          imageUrl: p.tracks.firstOrNull?.artworkUrl,
        ),
      for (final p in lib.savedPlaylists)
        _Item(
          ref: playlistRef(p),
          title: p.name,
          meta: '${p.isAlbum ? 'Album' : 'Playlist'} · ${p.owner.name}',
          typeLabel: p.isAlbum ? 'Album' : 'Playlist',
          type: p.isAlbum ? _Type.album : _Type.playlist,
          imageUrl: p.artworkUrl,
        ),
      for (final a in lib.followedArtists)
        _Item(
          ref: artistRef(a),
          title: a.name,
          meta: 'Artiste',
          typeLabel: 'Artiste',
          type: _Type.artist,
          imageUrl: a.imageUrl,
          circle: true,
        ),
    ];
    // Collections téléchargées absentes de la liste (mix, tendances…)
    for (final c in dl.collections) {
      if (items.any((i) => i.ref.key == c.ref.key)) continue;
      items.add(_Item(
        ref: c.ref,
        title: c.ref.title,
        meta: '${c.ref.subtitle.isEmpty ? 'Mix' : c.ref.subtitle} · ${c.trackIds.length} titres',
        typeLabel: c.ref.subtitle.isEmpty ? 'Mix' : c.ref.subtitle,
        type: c.ref.subtitle == 'Podcast' ? _Type.podcast : _Type.playlist,
        imageUrl: c.ref.artworkUrl,
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final lib = ref.watch(libraryProvider);
    final dl = ref.watch(downloadsProvider);
    var items = _items(lib, dl);
    items = switch (_chip) {
      1 => items.where((i) => i.type == _Type.playlist).toList(),
      2 => items.where((i) => i.type == _Type.artist).toList(),
      3 => items.where((i) => i.type == _Type.album).toList(),
      4 => items.where((i) => i.type == _Type.podcast).toList(),
      5 => items.where((i) => dl.hasCollection(i.ref.key)).toList(),
      _ => items,
    };
    if (_filter.isNotEmpty) items = items.where((i) => i.title.toLowerCase().contains(_filter.toLowerCase())).toList();
    items.sort((a, b) {
      final pa = lib.pinned.contains(a.ref.key), pb = lib.pinned.contains(b.ref.key);
      if (pa != pb) return pa ? -1 : 1;
      if (_alpha) return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return (lib.addedAt[b.ref.key] ?? 0).compareTo(lib.addedAt[a.ref.key] ?? 0);
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 14, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: SikaColors.yellow, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(lib.userName.characters.first.toUpperCase(), style: SikaText.display(14, color: SikaColors.onYellow)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Bibliothèque', style: SikaText.display(26, ls: -0.8))),
                  IconButtonSika(
                    icon: 'search',
                    label: 'Rechercher dans la bibliothèque',
                    color: _filtering ? SikaColors.yellow : SikaColors.text,
                    onTap: () => setState(() {
                      _filtering = !_filtering;
                      if (!_filtering) _filter = '';
                    }),
                  ),
                  IconButtonSika(icon: 'plus', label: 'Créer une playlist', onTap: _create),
                ],
              ),
            ),
          ),
          if (_filtering)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  autofocus: true,
                  cursorColor: SikaColors.yellow,
                  style: SikaText.ui(14, w: FontWeight.w600),
                  onChanged: (v) => setState(() => _filter = v),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: SikaColors.surface,
                    hintText: 'Rechercher dans ta bibliothèque',
                    hintStyle: SikaText.ui(14, color: SikaColors.placeholder),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(SikaRadius.sm), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ChipRow(labels: _chips, selected: _chip, onSelect: (i) => setState(() => _chip = i)),
            ),
          ),
          SliverToBoxAdapter(child: _MonthCard(onTap: () => _showStats(context, lib))),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 4),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _alpha = !_alpha),
                    icon: const SikaIcon('sort', size: 16),
                    label: Text(_alpha ? 'Alphabétique' : 'Récents', style: SikaText.ui(13, w: FontWeight.w700)),
                  ),
                  const Spacer(),
                  IconButtonSika(
                    icon: _grid ? 'list' : 'grid',
                    label: _grid ? 'Afficher en liste' : 'Afficher en grille',
                    onTap: () => setState(() => _grid = !_grid),
                  ),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(switch (_chip) {
                2 => 'Suis des artistes pour les retrouver ici.',
                3 => 'Aucun album enregistré.',
                4 => 'Aucun podcast enregistré.',
                5 => 'Rien de téléchargé pour l\'instant.',
                _ => 'Rien ici pour l\'instant.',
              }),
            )
          else if (_grid)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                // Hauteur = pochette carrée + 2 lignes de texte, à la taille de police du téléphone.
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: (MediaQuery.sizeOf(context).width - 40 - 28) / 3 +
                      10 +
                      MediaQuery.textScalerOf(context).scale(12) * 1.45 +
                      MediaQuery.textScalerOf(context).scale(11) * 1.45 +
                      6,
                ),
                delegate: SliverChildListDelegate([
                  for (final i in items)
                    LibraryGridItem(
                      title: i.title,
                      type: i.typeLabel,
                      seed: i.ref.key,
                      imageUrl: i.imageUrl,
                      variant: i.variant,
                      circle: i.circle,
                      onTap: () => openCollection(context, i.ref),
                    ),
                ]),
              ),
            )
          else
            SliverList.builder(
              itemCount: items.length,
              itemBuilder: (_, k) {
                final i = items[k];
                return LibraryRow(
                  title: i.title,
                  meta: i.meta,
                  seed: i.ref.key,
                  imageUrl: i.imageUrl,
                  variant: i.variant,
                  circle: i.circle,
                  pinned: lib.pinned.contains(i.ref.key),
                  downloaded: dl.hasCollection(i.ref.key),
                  onTap: () => openCollection(context, i.ref),
                  onLongPress: () => _options(context, i),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 190)),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final name = await askText(context, 'Nouvelle playlist', 'Nom de la playlist');
    if (name == null || !mounted) return;
    final p = ref.read(libraryProvider.notifier).createPlaylist(name);
    openCollection(context, CollectionRef(CollectionKind.mine, p.id, title: p.name));
  }

  void _options(BuildContext context, _Item i) {
    final lib = ref.read(libraryProvider);
    final pinned = lib.pinned.contains(i.ref.key);
    showSikaSheet(context, (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SheetAction(
              icon: 'pin',
              label: pinned ? 'Désépingler' : 'Épingler',
              onTap: () {
                ref.read(libraryProvider.notifier).togglePin(i.ref.key);
                Navigator.of(ctx).pop();
              },
            ),
            if (i.type == _Type.playlist || i.type == _Type.album)
              if (lib.savedPlaylists.any((p) => playlistRef(p).key == i.ref.key))
              SheetAction(
                icon: 'close',
                label: 'Retirer de la bibliothèque',
                onTap: () {
                  ref.read(libraryProvider.notifier).toggleSavePlaylist(lib.savedPlaylists.firstWhere((p) => playlistRef(p).key == i.ref.key));
                  Navigator.of(ctx).pop();
                },
              ),
            if (i.type == _Type.artist)
              SheetAction(
                icon: 'close',
                label: 'Ne plus suivre',
                onTap: () {
                  ref.read(libraryProvider.notifier).toggleFollow(lib.followedArtists.firstWhere((a) => artistRef(a).key == i.ref.key));
                  Navigator.of(ctx).pop();
                },
              ),
            if (i.ref.kind == CollectionKind.mine)
              SheetAction(
                icon: 'close',
                label: 'Supprimer la playlist',
                color: SikaColors.orange,
                onTap: () {
                  ref.read(libraryProvider.notifier).deletePlaylist(i.ref.id);
                  Navigator.of(ctx).pop();
                },
              ),
            const SizedBox(height: 8),
          ]),
        ));
  }

  void _showStats(BuildContext context, LibraryState lib) {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final month = lib.history.where((h) => h.playedAt.isAfter(since)).toList();
    final minutes = month.fold(0, (s, h) => s + h.seconds) ~/ 60;
    final byArtist = <String, (Artist, int)>{};
    for (final h in month) {
      final cur = byArtist[h.track.artist.id];
      byArtist[h.track.artist.id] = (h.track.artist, (cur?.$2 ?? 0) + 1);
    }
    final topArtists = byArtist.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
    final genres = lib.topGenres().take(5).toList();

    showSikaSheet(context, (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ton mois en musique', style: SikaText.display(24, ls: -0.6)),
                const SizedBox(height: 16),
                Row(children: [
                  _Stat(value: '$minutes', label: 'minutes'),
                  const SizedBox(width: 10),
                  _Stat(value: '${month.length}', label: 'écoutes'),
                  const SizedBox(width: 10),
                  _Stat(value: '${byArtist.length}', label: 'artistes'),
                ]),
                if (month.isEmpty) const EmptyState('Écoute de la musique pour voir tes stats ici.'),
                if (topArtists.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Artistes les plus écoutés', style: SikaText.h2Small),
                  const SizedBox(height: 8),
                  for (final (i, a) in topArtists.take(5).indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        SizedBox(width: 22, child: Text('${i + 1}', style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow))),
                        CoverArt.seeded(a.$1.id, size: 40, circle: true, imageUrl: a.$1.imageUrl),
                        const SizedBox(width: 12),
                        Expanded(child: Text(a.$1.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.cardTitle)),
                        Text('${a.$2} écoutes', style: SikaText.meta),
                      ]),
                    ),
                ],
                if (genres.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Genres', style: SikaText.h2Small),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final g in genres) SikaChip(label: g)]),
                ],
              ],
            ),
          ),
        ));
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: SikaColors.surface2, borderRadius: BorderRadius.circular(SikaRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: SikaText.display(24, color: SikaColors.yellow)),
            Text(label, style: SikaText.meta),
          ]),
        ),
      );
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Material(
        color: SikaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SikaRadius.lg),
          side: const BorderSide(color: SikaColors.yellow, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: SikaColors.yellow, borderRadius: BorderRadius.circular(SikaRadius.md)),
                  alignment: Alignment.center,
                  child: const SikaIcon('chart', size: 24, color: SikaColors.onYellow),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ton mois en musique', style: SikaText.rowTitle),
                      const SizedBox(height: 2),
                      Text('Artistes, genres et minutes d\'écoute', style: SikaText.meta),
                    ],
                  ),
                ),
                const SikaIcon('chevron-right', size: 22, color: SikaColors.yellow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
