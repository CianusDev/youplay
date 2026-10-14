import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
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

final _feeds = [
  _Feed('Tout', const ['Damso', 'Gims', 'Beendo Z', 'Ninho', 'Tiakola', 'Aya Nakamura'], [
    ('Nouveautés Rap FR', 'Les sorties rap du moment', 'nouveauté rap français $_year'),
    ('Hits Afro', 'Afrobeats, Afro-pop', 'afrobeats hits $_year'),
    ('Drill FR', 'Drill, Trap', 'drill français $_year'),
    ('Amapiano', 'Amapiano, Log drum', 'amapiano $_year'),
  ]),
  _Feed('Rap FR', const ['Ninho', 'Damso', 'SDM', 'Jul', 'Tiakola', 'PLK'], [
    ('Nouveautés Rap FR', 'Les sorties de la semaine', 'nouveauté rap français $_year'),
    ('Rap Belge', 'Damso, Hamza, Shay…', 'rap belge $_year'),
    ('Classiques Rap FR', 'Les incontournables', 'classiques rap français'),
  ]),
  _Feed('Afro', const ['Burna Boy', 'Wizkid', 'Rema', 'Fally Ipupa', 'Tayc', 'Asake'], [
    ('Hits Afro', 'Afrobeats, Afro-pop', 'afrobeats hits $_year'),
    ('Amapiano', 'Amapiano, Log drum', 'amapiano $_year'),
    ('Coupé-décalé', 'Côte d\'Ivoire', 'coupé décalé $_year'),
  ]),
  _Feed('Drill', const ['Gazo', 'Kerchak', 'Freeze Corleone', 'Central Cee', 'Ziak', 'Leto'], [
    ('Drill FR', 'Drill, Trap', 'drill français $_year'),
    ('UK Drill', 'Londres', 'uk drill $_year'),
    ('Trap FR', 'Trap, Plugg', 'trap français $_year'),
  ]),
  _Feed('Chill', const ['Tayc', 'Dadju', 'Joé Dwèt Filé', 'Tems', 'Aya Nakamura', 'Burna Boy'], [
    ('R&B Chill', 'Love songs, R&B', 'rnb français $_year'),
    ('Afro Love', 'Afro-pop douce', 'afro love songs'),
    ('Lo-fi Focus', 'Pour bosser', 'lofi focus'),
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

String _greeting() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return 'Bonjour';
  if (h >= 12 && h < 18) return 'Bon après-midi';
  return 'Bonsoir';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chip = ref.watch(homeChipProvider);
    final lib = ref.watch(libraryProvider);
    final feed = _feeds[chip];

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
          'Daily Mix ${i ~/ 2 + 1}',
          '${mixArtists[i]}, ${mixArtists[i + 1]} et plus',
          _mixRef('${mixArtists[i]} ${mixArtists[i + 1]}', 'Daily Mix ${i ~/ 2 + 1}'),
        ),
    ];
    const mixVariants = [5, 2, 3];

    Future<void> refresh() async {
      ref.invalidate(ytSongsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    if (!YoutubeSource.supported) {
      return const Scaffold(body: Center(child: EmptyState('YouPlay lit YouTube : utilise l\'app Android.')));
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
                      child: Text(lib.userName.characters.first.toUpperCase(), style: SikaText.display(16, color: SikaColors.onYellow)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(), style: SikaText.ui(12, color: SikaColors.textMuted)),
                        Text(lib.userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.userName),
                      ],
                    ),
                  ),
                  IconButtonSika(icon: 'bell', label: 'Notifications', onTap: () => showSnack(context, 'Aucune nouvelle notification')),
                  const SizedBox(width: 4),
                  IconButtonSika(icon: 'settings', label: 'Réglages', onTap: () => showSettingsSheet(context)),
                ],
              ),
            ),
            // 2. Filtres
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 4),
              child: ChipRow(labels: [for (final f in _feeds) f.label], selected: chip, onSelect: ref.read(homeChipProvider.notifier).set),
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
                    title: 'Titres likés',
                    seed: 'likes',
                    variant: 1,
                    onTap: () => openCollection(
                      context,
                      CollectionRef(CollectionKind.likes, 'me', title: 'Titres likés', subtitle: '${lib.likedTracks.length} titres'),
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
            SectionHeader('Tes mix du jour', action: 'Tout voir', onAction: () => context.go('/library')),
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
            const SectionHeader('Nouveautés'),
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
      if (mounted) showSnack(context, 'Radio indisponible. Vérifie ta connexion.');
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
                      Text('NOUVEAU POUR TOI', style: SikaText.eyebrow.copyWith(color: SikaColors.onYellow)),
                      const SizedBox(height: 6),
                      Text('Ta Radio YouPlay', style: SikaText.heroCard.copyWith(color: SikaColors.onYellow)),
                      const SizedBox(height: 6),
                      Text(
                        'Un flux infini, calé sur tes 30 derniers jours.',
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
        const SectionHeader('Écoutés récemment'),
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
