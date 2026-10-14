import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/youtube_source.dart';
import '../../state/library_store.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/rows.dart';
import '../components/sika_chip.dart';
import '../components/sika_icon.dart';

class _Genre {
  const _Genre(this.name, this.bg, this.fg, this.square, this.ref);
  final String name;
  final Color bg;
  final Color fg;
  final Color square;
  final CollectionRef ref;
}

CollectionRef _q(String query, String title) => CollectionRef(CollectionKind.ytquery, query, title: title, subtitle: 'Mix');

final _genres = [
  _Genre('Afrobeat', SikaColors.yellow, SikaColors.onYellow, SikaColors.onYellow, _q('afrobeat', 'Afrobeat')),
  _Genre('Amapiano', SikaColors.orange, SikaColors.onYellow, SikaColors.yellow, _q('amapiano', 'Amapiano')),
  _Genre('Highlife', SikaColors.forest, SikaColors.text, SikaColors.yellow, _q('highlife', 'Highlife')),
  _Genre('Gospel', SikaColors.plum, SikaColors.text, SikaColors.orange, _q('gospel', 'Gospel')),
  _Genre('Podcasts', SikaColors.cream, SikaColors.onYellow, SikaColors.forest, _q('podcast musique', 'Podcasts')),
  _Genre('Concentration', SikaColors.surface3, SikaColors.yellow, SikaColors.cream, _q('lofi focus', 'Concentration')),
  _Genre('Rap FR', SikaColors.wine, SikaColors.text, SikaColors.onYellow, _q('rap français', 'Rap FR')),
  _Genre('Traditionnel', SikaColors.yellowSoft, SikaColors.onYellow, SikaColors.wine, _q('musique traditionnelle africaine', 'Traditionnel')),
  _Genre('Électro', SikaColors.onYellow, SikaColors.yellow, SikaColors.orange, _q('électro', 'Électro')),
  _Genre('Hip-Hop', SikaColors.orange, SikaColors.onYellow, SikaColors.plum, _q('hip hop', 'Hip-Hop')),
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => setState(() => _query = v.trim()));
    setState(() {});
  }

  void _searchFor(String q) {
    _ctrl.text = q;
    _ctrl.selection = TextSelection.collapsed(offset: q.length);
    setState(() => _query = q);
    ref.read(libraryProvider.notifier).addSearch(q);
  }

  void _clear() {
    _ctrl.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;
    final focused = _focus.hasFocus;
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 14, bottom: 190),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Recherche', style: SikaText.display(32, ls: -1)),
            ),
            // Champ (clair)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                height: 52,
                padding: const EdgeInsets.only(left: 16, right: 8),
                decoration: BoxDecoration(color: SikaColors.text, borderRadius: BorderRadius.circular(SikaRadius.md)),
                child: Row(
                  children: [
                    const SikaIcon('search', size: 22, color: SikaColors.onYellow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        onChanged: _onChanged,
                        onSubmitted: (v) => ref.read(libraryProvider.notifier).addSearch(v),
                        textInputAction: TextInputAction.search,
                        cursorColor: SikaColors.onYellow,
                        style: SikaText.ui(15, w: FontWeight.w600, color: SikaColors.onYellow),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: 'Artistes, titres, playlists…',
                          hintStyle: SikaText.ui(15, w: FontWeight.w600, color: SikaColors.placeholder),
                        ),
                      ),
                    ),
                    if (_ctrl.text.isNotEmpty)
                      IconButtonSika(icon: 'close', label: 'Effacer', size: 36, iconSize: 18, color: SikaColors.onYellow, onTap: _clear)
                    else
                      IconButtonSika(
                        icon: 'mic',
                        label: 'Recherche vocale',
                        size: 36,
                        iconSize: 18,
                        color: SikaColors.onYellow,
                        background: SikaColors.yellow,
                        onTap: () {
                          _focus.requestFocus();
                          showSnack(context, 'Utilise le micro de ton clavier pour dicter');
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (searching)
              _Results(query: _query, onCommit: () => ref.read(libraryProvider.notifier).addSearch(_query))
            else ...[
              _RecentSearches(onTap: _searchFor),
              if (!focused) ...[
                const _TrendingCard(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  child: Text('Parcourir tout', style: SikaText.h2Small),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: ((MediaQuery.sizeOf(context).width - 50) / 2) / 104,
                    children: [for (final g in _genres) _GenreTile(g)],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.onTap});
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(libraryProvider.select((s) => s.recentSearches));
    if (recent.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text('Recherches récentes', style: SikaText.h2Small),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onLongPress: () => ref.read(libraryProvider.notifier).removeSearch(recent[i]),
              child: SikaChip(label: recent[i], icon: 'clock', background: SikaColors.surface, padding: 14, onTap: () => onTap(recent[i])),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
          child: Text('Tendances de la semaine', style: SikaText.h2Small),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: SikaColors.surface,
            borderRadius: BorderRadius.circular(SikaRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => openCollection(context, const CollectionRef(CollectionKind.trending, 'top', title: 'Top 50', subtitle: 'Mix')),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: SikaColors.yellow, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('50', style: SikaText.display(26, color: SikaColors.onYellow)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Top 50 — France', style: SikaText.rowTitle),
                          const SizedBox(height: 4),
                          Text('Mis à jour en continu', style: SikaText.meta),
                        ],
                      ),
                    ),
                    const SikaIcon('chevron-right', size: 22, color: SikaColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenreTile extends StatelessWidget {
  const _GenreTile(this.g);
  final _Genre g;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: g.bg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openCollection(context, g.ref),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -10,
              child: Transform.rotate(
                angle: 22 * 3.14159 / 180,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: g.square,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(g.name, style: SikaText.tile.copyWith(color: g.fg)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.query, required this.onCommit});
  final String query;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) => YoutubeSource.supported
      ? _YtResults(query: query, onCommit: onCommit)
      : const EmptyState('La recherche YouTube fonctionne dans l\'app Android.');
}

/// Résultats YouTube Music : titres, artistes, albums.
class _YtResults extends ConsumerWidget {
  const _YtResults({required this.query, required this.onCommit});
  final String query;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(ytSongsProvider(query));
    final albums = ref.watch(ytAlbumsProvider(query));
    final current = ref.watch(playerProvider.select((s) => s.current?.id));
    final playing = ref.watch(playerProvider.select((s) => s.playing));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AsyncView<List<Track>>(
          value: songs,
          onRetry: () => ref.invalidate(ytSongsProvider(query)),
          data: (t) {
            if (t.isEmpty) return EmptyState('Aucun titre YouTube pour « $query ».');
            final seen = <String>{};
            final artists = [for (final x in t) if (seen.add(x.artist.id)) x.artist].take(4).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Titres'),
                for (final (i, x) in t.take(12).indexed)
                  TrackRow(
                    index: i + 1,
                    title: x.title,
                    meta: x.artist.name,
                    duration: formatDuration(x.duration),
                    seed: x.id,
                    imageUrl: x.artworkUrl,
                    current: current == x.id,
                    playing: playing,
                    onTap: () {
                      onCommit();
                      playTracks(context, ref, t, start: i, source: CollectionRef(CollectionKind.ytquery, query, title: ''));
                    },
                    onMore: () => showTrackOptions(context, ref, x),
                  ),
                const SectionLabel('Artistes'),
                for (final a in artists)
                  LibraryRow(
                    title: a.name,
                    meta: 'Artiste',
                    seed: a.id,
                    imageUrl: t.firstWhere((x) => x.artist.id == a.id).artworkUrl,
                    circle: true,
                    size: 52,
                    onTap: () {
                      onCommit();
                      openArtist(context, a);
                    },
                  ),
              ],
            );
          },
        ),
        AsyncView<List<Playlist>>(
          value: albums,
          loading: const SizedBox.shrink(),
          data: (p) => p.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Albums'),
                    for (final x in p.take(6))
                      LibraryRow(
                        title: x.name,
                        meta: 'Album · ${x.owner.name}',
                        seed: x.id,
                        imageUrl: x.artworkUrl,
                        size: 52,
                        onTap: () {
                          onCommit();
                          openCollection(context, playlistRef(x));
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Text(text, style: SikaText.h2Small),
      );
}
