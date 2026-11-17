import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../data/youtube_source.dart';
import '../../state/library_store.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/rows.dart';
import '../components/tiles.dart';
import '../components/cover_art.dart';
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

// Libellés traduits ; les requêtes YouTube restent en français (le catalogue visé).
List<_Genre> _genres(AppLocalizations l) => [
  _Genre('Afrobeat', SikaColors.yellow, SikaColors.onYellow, SikaColors.onYellow, _q('afrobeat', 'Afrobeat')),
  _Genre('Amapiano', SikaColors.orange, SikaColors.onYellow, SikaColors.yellow, _q('amapiano', 'Amapiano')),
  _Genre('Highlife', SikaColors.forest, SikaColors.text, SikaColors.yellow, _q('highlife', 'Highlife')),
  _Genre('Gospel', SikaColors.plum, SikaColors.text, SikaColors.orange, _q('gospel', 'Gospel')),
  _Genre(l.genrePodcasts, SikaColors.cream, SikaColors.onYellow, SikaColors.forest, _q('podcast musique', l.genrePodcasts)),
  _Genre(l.genreFocus, SikaColors.surface3, SikaColors.yellow, SikaColors.cream, _q('lofi focus', l.genreFocus)),
  _Genre(l.chipFrenchRap, SikaColors.wine, SikaColors.text, SikaColors.onYellow, _q('rap français', l.chipFrenchRap)),
  _Genre(l.genreTraditional, SikaColors.yellowSoft, SikaColors.onYellow, SikaColors.wine, _q('musique traditionnelle africaine', l.genreTraditional)),
  _Genre(l.genreElectro, SikaColors.onYellow, SikaColors.yellow, SikaColors.orange, _q('électro', l.genreElectro)),
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
  Timer? _suggestDebounce;
  String _query = ''; // requête des résultats (après une pause ou validation)
  String _typed = ''; // texte en cours de frappe (suggestions)

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _suggestDebounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    // Suggestions quasi instantanées, résultats complets après une vraie pause de frappe.
    _suggestDebounce?.cancel();
    _suggestDebounce = Timer(const Duration(milliseconds: 150), () => setState(() => _typed = v.trim()));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () => setState(() => _query = v.trim()));
    setState(() {});
  }

  /// Lance la recherche tout de suite (validation clavier, suggestion, recherche récente).
  void _searchFor(String q) {
    q = q.trim();
    if (q.isEmpty) return;
    _debounce?.cancel();
    _suggestDebounce?.cancel();
    _ctrl.text = q;
    _ctrl.selection = TextSelection.collapsed(offset: q.length);
    _focus.unfocus();
    setState(() {
      _query = q;
      _typed = q;
    });
    ref.read(libraryProvider.notifier).addSearch(q);
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _query = '';
      _typed = '';
    });
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
              child: Text(context.l10n.searchTitle, style: SikaText.display(32, ls: -1)),
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
                        onSubmitted: _searchFor,
                        textInputAction: TextInputAction.search,
                        cursorColor: SikaColors.onYellow,
                        style: SikaText.ui(15, w: FontWeight.w600, color: SikaColors.onYellow),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: context.l10n.searchHint,
                          hintStyle: SikaText.ui(15, w: FontWeight.w600, color: SikaColors.placeholder),
                        ),
                      ),
                    ),
                    if (_ctrl.text.isNotEmpty)
                      IconButtonSika(icon: 'close', label: context.l10n.clear, size: 36, iconSize: 18, color: SikaColors.onYellow, onTap: _clear)
                    else
                      IconButtonSika(
                        icon: 'mic',
                        label: context.l10n.voiceSearch,
                        size: 36,
                        iconSize: 18,
                        color: SikaColors.onYellow,
                        background: SikaColors.yellow,
                        onTap: () {
                          _focus.requestFocus();
                          showSnack(context, context.l10n.voiceSearchHint);
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (focused && _typed.isNotEmpty && YoutubeSource.supported)
              _Suggestions(query: _typed, onPick: _searchFor),
            if (searching)
              _Results(query: _query, onCommit: () => ref.read(libraryProvider.notifier).addSearch(_query), onSearch: _searchFor)
            else ...[
              _RecentSearches(onTap: _searchFor),
              if (!focused) ...[
                const _TrendingCard(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  child: Text(context.l10n.browseAll, style: SikaText.h2Small),
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
                    children: [for (final g in _genres(context.l10n)) _GenreTile(g)],
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
          child: Text(context.l10n.recentSearches, style: SikaText.h2Small),
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
          child: Text(context.l10n.trendingThisWeek, style: SikaText.h2Small),
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
                          Text(context.l10n.top50France, style: SikaText.rowTitle),
                          const SizedBox(height: 4),
                          Text(context.l10n.updatedContinuously, style: SikaText.meta),
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
  const _Results({required this.query, required this.onCommit, required this.onSearch});
  final String query;
  final VoidCallback onCommit;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) => YoutubeSource.supported
      ? _YtResults(query: query, onCommit: onCommit, onSearch: onSearch)
      : EmptyState(context.l10n.searchAndroidOnly);
}

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[àâäá]'), 'a')
    .replaceAll(RegExp(r'[éèêë]'), 'e')
    .replaceAll(RegExp(r'[îïí]'), 'i')
    .replaceAll(RegExp(r'[ôöó]'), 'o')
    .replaceAll(RegExp(r'[ùûüú]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

/// Suggestions de saisie (autocomplétion YouTube), affichées pendant la frappe.
class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.query, required this.onPick});
  final String query;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(ytSuggestionsProvider(query)).value ?? const <String>[];
    if (list.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (final sug in list.take(6))
            InkWell(
              onTap: () => onPick(sug),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const SikaIcon('search', size: 18, color: SikaColors.textMuted),
                    const SizedBox(width: 14),
                    Expanded(child: Text(sug, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(15, w: FontWeight.w600))),
                    const SikaIcon('chevron-right', size: 18, color: SikaColors.textMuted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Résultats YouTube : meilleur résultat, titres, artistes, albums.
class _YtResults extends ConsumerWidget {
  const _YtResults({required this.query, required this.onCommit, required this.onSearch});
  final String query;
  final VoidCallback onCommit;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(ytSearchProvider(query));
    final artists = ref.watch(ytArtistsProvider(query)).value ?? const <Artist>[];
    final albums = ref.watch(ytAlbumsProvider(query));
    final current = ref.watch(playerProvider.select((s) => s.current?.id));
    final playing = ref.watch(playerProvider.select((s) => s.playing));
    final nq = _norm(query);
    // L'artiste est le meilleur résultat si son nom correspond à la recherche.
    final topArtist = artists.where((a) => _norm(a.name) == nq || (nq.length >= 4 && _norm(a.name).startsWith(nq))).firstOrNull;

    void openA(Artist a) {
      onCommit();
      openArtist(context, a);
    }

    return AsyncView<YtSearch>(
      value: search,
      onRetry: () => ref.invalidate(ytSearchProvider(query)),
      data: (res) {
        final t = res.songs;
        if (t.isEmpty && artists.isEmpty) return EmptyState(context.l10n.noResultsFor(query));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (res.suggestion != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: res.corrected ? null : () => onSearch(res.suggestion!),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: res.corrected ? context.l10n.resultsFor : context.l10n.didYouMean, style: SikaText.meta),
                    TextSpan(text: res.suggestion, style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow)),
                    if (!res.corrected) TextSpan(text: ' ?', style: SikaText.meta),
                  ])),
                ),
              ),
            // Meilleur résultat
            SectionLabel(context.l10n.topResult),
            if (topArtist != null)
              _BestCard(
                title: topArtist.name,
                subtitle: topArtist.followers > 0 ? context.l10n.artistFollowers(formatCount(topArtist.followers)) : context.l10n.kindArtist,
                imageUrl: topArtist.imageUrl,
                seed: topArtist.id,
                circle: true,
                onTap: () => openA(topArtist),
              )
            else if (t.isNotEmpty)
              _BestCard(
                title: t.first.title,
                subtitle: context.l10n.songBy(t.first.artist.name),
                imageUrl: t.first.artworkUrl,
                seed: t.first.id,
                onTap: () {
                  onCommit();
                  playTracks(context, ref, t, source: CollectionRef(CollectionKind.ytquery, query, title: ''));
                },
              ),
            if (t.isNotEmpty) ...[
              SectionLabel(context.l10n.songs),
              for (final (i, x) in t.take(10).indexed)
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
            ],
            if (artists.isNotEmpty) ...[
              SectionLabel(context.l10n.artists),
              SizedBox(
                height: 124,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: artists.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (_, i) => ArtistBubble(
                    name: artists[i].name,
                    seed: artists[i].id,
                    imageUrl: artists[i].imageUrl,
                    onTap: () => openA(artists[i]),
                  ),
                ),
              ),
            ],
            AsyncView<List<Playlist>>(
              value: albums,
              loading: const SizedBox.shrink(),
              data: (p) => p.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabel(context.l10n.albumsAndPlaylists),
                        for (final x in p.take(6))
                          LibraryRow(
                            title: x.name,
                            meta: '${x.isAlbum ? context.l10n.kindAlbum : context.l10n.kindPlaylist} · ${x.owner.name}',
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
      },
    );
  }
}

/// Grande carte « Meilleur résultat ».
class _BestCard extends StatelessWidget {
  const _BestCard({required this.title, required this.subtitle, required this.seed, required this.onTap, this.imageUrl, this.circle = false});
  final String title;
  final String subtitle;
  final String seed;
  final String? imageUrl;
  final bool circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: SikaColors.surface,
        borderRadius: BorderRadius.circular(SikaRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CoverArt.seeded(seed, size: 84, radius: SikaRadius.md, circle: circle, imageUrl: imageUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: SikaText.display(20, ls: -0.4)),
                      const SizedBox(height: 6),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.meta),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
