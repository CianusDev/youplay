import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../data/youtube_source.dart';
import '../../state/library_store.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/play_button.dart';
import '../components/sika_chip.dart';
import '../components/sika_icon.dart';
import '../components/tiles.dart';
import 'settings_sheet.dart';

/// Un filtre de l'accueil : artistes de départ + recherches « nouveautés ».
class _Feed {
  const _Feed(this.label, this.artists, this.news);
  final String label;
  final List<String> artists;
  final List<(String title, String subtitle, String query)> news;
}

final _year = DateTime.now().year;

// Titres et sous-titres traduits ; les requêtes YouTube restent en français (le catalogue visé).
List<_Feed> _feeds(AppLocalizations l) => [
  _Feed(l.chipAll, const ['Damso', 'Gims', 'Beendo Z', 'Ninho', 'Tiakola', 'Aya Nakamura'], [
    (l.mixNewFrenchRap, l.mixNewFrenchRapSub, 'nouveauté rap français $_year'),
    (l.mixAfroHits, 'Afrobeats, Afro-pop', 'afrobeats hits $_year'),
    (l.mixFrenchDrill, 'Drill, Trap', 'drill français $_year'),
    ('Amapiano', 'Amapiano, Log drum', 'amapiano $_year'),
  ]),
  _Feed(l.chipFrenchRap, const ['Ninho', 'Damso', 'SDM', 'Jul', 'Tiakola', 'PLK'], [
    (l.mixNewFrenchRap, l.mixWeeklyReleases, 'nouveauté rap français $_year'),
    (l.mixBelgianRap, 'Damso, Hamza, Shay…', 'rap belge $_year'),
    (l.mixFrenchRapClassics, l.mixEssentials, 'classiques rap français'),
  ]),
  _Feed('Afro', const ['Burna Boy', 'Wizkid', 'Rema', 'Fally Ipupa', 'Tayc', 'Asake'], [
    (l.mixAfroHits, 'Afrobeats, Afro-pop', 'afrobeats hits $_year'),
    ('Amapiano', 'Amapiano, Log drum', 'amapiano $_year'),
    ('Coupé-décalé', l.mixIvoryCoast, 'coupé décalé $_year'),
  ]),
  _Feed('Drill', const ['Gazo', 'Kerchak', 'Freeze Corleone', 'Central Cee', 'Ziak', 'Leto'], [
    (l.mixFrenchDrill, 'Drill, Trap', 'drill français $_year'),
    ('UK Drill', l.mixLondon, 'uk drill $_year'),
    (l.mixFrenchTrap, 'Trap, Plugg', 'trap français $_year'),
  ]),
  _Feed('Chill', const ['Tayc', 'Dadju', 'Joé Dwèt Filé', 'Tems', 'Aya Nakamura', 'Burna Boy'], [
    ('R&B Chill', 'Love songs, R&B', 'rnb français $_year'),
    ('Afro Love', l.mixSoftAfroPop, 'afro love songs'),
    ('Lo-fi Focus', l.mixForWork, 'lofi focus'),
  ]),
];

final homeChipProvider = NotifierProvider<_ChipIndex, int>(_ChipIndex.new);

class _ChipIndex extends Notifier<int> {
  @override
  int build() => 0;
  void set(int i) => state = i;
}

CollectionRef _artistRef(String name, {String? art}) =>
    CollectionRef(CollectionKind.ytquery, name, title: name, subtitle: 'Artiste', artworkUrl: art);

CollectionRef _mixRef(String query, String title) => CollectionRef(CollectionKind.ytquery, query, title: title, subtitle: 'Mix');

/// Pochette d'une recherche : première miniature des résultats (chargée à la demande).
String? _artFor(WidgetRef ref, String query) => ref.watch(ytSongsProvider(query)).value?.firstOrNull?.artworkUrl;

String _greeting(AppLocalizations l) {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return l.goodMorning;
  if (h >= 12 && h < 18) return l.goodAfternoon;
  return l.goodEvening;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chip = ref.watch(homeChipProvider);
    final lib = ref.watch(libraryProvider);
    final l = context.l10n;
    final feeds = _feeds(l);
    final feed = feeds[chip];

    // Artistes : sur « Tout », tes plus écoutés d'abord, complétés par la sélection.
    final mine = chip == 0 ? lib.topArtists().where((a) => isYoutubeArtist(a.id)).map((a) => a.name).toList() : <String>[];
    final artists = <String>[];
    for (final n in [...mine, ...feed.artists]) {
      if (!artists.any((a) => a.toLowerCase() == n.toLowerCase())) artists.add(n);
    }
    final picks = artists.take(5).toList();
    final mixArtists = artists.take(6).toList();
    final mixes = [
      for (var i = 0; i + 1 < mixArtists.length && i < 6; i += 2)
        (
          l.dailyMix(i ~/ 2 + 1),
          l.artistsAndMore(mixArtists[i], mixArtists[i + 1]),
          _mixRef('${mixArtists[i]} ${mixArtists[i + 1]}', l.dailyMix(i ~/ 2 + 1)),
        ),
    ];
    const mixVariants = [5, 2, 3];

    Future<void> refresh() async {
      ref.invalidate(ytSongsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    if (!YoutubeSource.supported) {
      return Scaffold(body: Center(child: EmptyState(l.androidOnly)));
    }

    return Scaffold(
      body: RefreshIndicator(
        color: SikaColors.onYellow,
        backgroundColor: SikaColors.yellow,
        onRefresh: refresh,
        child: ListView(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 14, bottom: 190),
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => showSettingsSheet(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: SikaColors.yellow, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(displayUserName(l, lib.userName).characters.first.toUpperCase(), style: SikaText.display(16, color: SikaColors.onYellow)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(l), style: SikaText.ui(12, color: SikaColors.textMuted)),
                        Text(displayUserName(l, lib.userName), maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.userName),
                      ],
                    ),
                  ),
                  IconButtonSika(icon: 'bell', label: l.notifications, onTap: () => showSnack(context, l.noNotifications)),
                  const SizedBox(width: 4),
                  IconButtonSika(icon: 'settings', label: l.settingsTitle, onTap: () => showSettingsSheet(context)),
                ],
              ),
            ),
            // 2. Filtres
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 4),
              child: ChipRow(labels: [for (final f in feeds) f.label], selected: chip, onSelect: ref.read(homeChipProvider.notifier).set),
            ),
            // 3. Accès rapides : titres likés + artistes
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: ((MediaQuery.sizeOf(context).width - 48) / 2) / 56,
                children: [
                  QuickPickTile(
                    title: l.likedSongs,
                    seed: 'likes',
                    variant: 1,
                    onTap: () => openCollection(
                      context,
                      CollectionRef(CollectionKind.likes, 'me', title: l.likedSongs, subtitle: l.songCount(lib.likedTracks.length)),
                    ),
                  ),
                  for (final name in picks)
                    Builder(builder: (context) {
                      final art = lib.artworkFor('$ytArtistPrefix${name.toLowerCase()}') ?? _artFor(ref, name);
                      return QuickPickTile(
                        title: name,
                        seed: name,
                        imageUrl: art,
                        onTap: () => openCollection(context, _artistRef(name, art: art)),
                      );
                    }),
                ],
              ),
            ),
            // 4. Radio
            const _RadioCard(),
            // 5. Mix du jour (à partir de tes artistes)
            SectionHeader(l.yourDailyMixes, action: l.seeAll, onAction: () => context.go('/library')),
            SizedBox(
              height: 222,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: mixes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (_, i) => MixCard(
                  title: mixes[i].$1,
                  subtitle: mixes[i].$2,
                  seed: mixes[i].$3.key,
                  variant: mixVariants[i % 3],
                  imageUrl: _artFor(ref, mixes[i].$3.id),
                  onTap: () => openCollection(context, mixes[i].$3),
                ),
              ),
            ),
            // 6. Nouveautés
            SectionHeader(l.newReleases),
            SizedBox(
              height: 222,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: feed.news.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (_, i) {
                  final (title, subtitle, query) = feed.news[i];
                  return MixCard(
                    title: title,
                    subtitle: subtitle,
                    seed: query,
                    imageUrl: _artFor(ref, query),
                    onTap: () => openCollection(context, _mixRef(query, title)),
                  );
                },
              ),
            ),
            // 7. Écoutés récemment
            const _RecentArtists(),
          ],
        ),
      ),
    );
  }
}

class _RadioCard extends ConsumerStatefulWidget {
  const _RadioCard();
  @override
  ConsumerState<_RadioCard> createState() => _RadioCardState();
}

class _RadioCardState extends ConsumerState<_RadioCard> {
  bool _loading = false;

  Future<void> _start() async {
    final ui = ref.read(playerProvider);
    if (ui.isRadio && ui.current != null) {
      context.push('/player');
      return;
    }
    setState(() => _loading = true);
    try {
      final err = await ref.read(playerProvider.notifier).playRadio();
      if (!mounted) return;
      if (err != null) {
        showSnack(context, err);
      } else {
        context.push('/player');
      }
    } catch (_) {
      if (mounted) showSnack(context, context.l10n.radioUnavailable);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radioPlaying = ref.watch(playerProvider.select((s) => s.isRadio && s.playing));
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      decoration: BoxDecoration(color: SikaColors.yellow, borderRadius: BorderRadius.circular(SikaRadius.xxl)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SikaColors.onYellow, width: 22)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.newForYou, style: SikaText.eyebrow.copyWith(color: SikaColors.onYellow)),
                      const SizedBox(height: 6),
                      Text(context.l10n.yourRadio, style: SikaText.heroCard.copyWith(color: SikaColors.onYellow)),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.yourRadioSub,
                        style: SikaText.ui(13, color: SikaColors.onYellow),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                PlayButton(
                  playing: radioPlaying,
                  loading: _loading,
                  size: 56,
                  iconSize: 22,
                  background: SikaColors.onYellow,
                  foreground: SikaColors.yellow,
                  onTap: _loading ? null : _start,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentArtists extends ConsumerWidget {
  const _RecentArtists();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryProvider);
    final artists = lib.recentArtists.where((a) => isYoutubeArtist(a.id)).take(10).toList();
    if (artists.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(context.l10n.recentlyPlayed),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: artists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final a = artists[i];
              final art = a.imageUrl ?? lib.artworkFor(a.id);
              return ArtistBubble(
                name: a.name,
                seed: a.id,
                imageUrl: art,
                onTap: () => openCollection(context, _artistRef(a.name, art: art)),
              );
            },
          ),
        ),
      ],
    );
  }
}
