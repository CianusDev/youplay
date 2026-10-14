import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/lyrics_api.dart';
import '../../data/models.dart';
import '../../state/download_manager.dart';
import '../../state/library_store.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/cover_art.dart';
import '../components/play_button.dart';
import '../components/sika_icon.dart';
import '../components/waveform_seek_bar.dart';

String _sourceLabel(CollectionRef? s) {
  if (s == null) return 'LECTURE EN COURS';
  return switch (s.kind) {
    CollectionKind.playlist => s.subtitle == 'ALBUM' ? 'LECTURE DEPUIS L\'ALBUM' : 'LECTURE DEPUIS LA PLAYLIST',
    CollectionKind.mine || CollectionKind.likes => 'LECTURE DEPUIS LA PLAYLIST',
    CollectionKind.artist => 'LECTURE DEPUIS L\'ARTISTE',
    CollectionKind.trending => s.id == 'radio' ? 'LECTURE DEPUIS LA RADIO' : 'LECTURE DEPUIS LES TENDANCES',
    CollectionKind.genre => 'LECTURE DEPUIS LE MIX',
    CollectionKind.query => s.title.isEmpty ? 'LECTURE DEPUIS LA RECHERCHE' : 'LECTURE DEPUIS LE MIX',
    CollectionKind.downloads => 'LECTURE HORS LIGNE',
    CollectionKind.ytalbum => 'LECTURE DEPUIS L\'ALBUM',
    CollectionKind.ytquery => s.subtitle == 'Artiste' ? 'LECTURE DEPUIS L\'ARTISTE' : 'LECTURE DEPUIS LA RECHERCHE',
  };
}

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});
  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  double _dragY = 0;

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(playerProvider);
    final t = ui.current;
    ref.listen(playerProvider.select((s) => s.error), (_, e) {
      if (e != null) {
        showSnack(context, e);
        ref.read(playerProvider.notifier).clearError();
      }
    });
    if (t == null) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const EmptyState('Rien en lecture.'),
            TextButton(onPressed: () => context.pop(), child: Text('Fermer', style: SikaText.ui(14, w: FontWeight.w700, color: SikaColors.yellow))),
          ]),
        ),
      );
    }
    final ctrl = ref.read(playerProvider.notifier);
    final liked = ref.watch(libraryProvider.select((s) => s.isLiked(t.id)));
    final offlineFile = ref.watch(downloadsProvider.select((s) => s.isDownloaded(t.id)));
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final dur = ref.watch(durationProvider).value ?? t.duration;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Transform.translate(
        offset: Offset(0, _dragY),
        child: Stack(
          children: [
            // Fond d'ambiance : couleur dominante de la pochette (transition douce entre titres)
            Positioned.fill(child: _AmbientBackground(artworkUrl: t.artworkUrl)),
            ListView(
              padding: EdgeInsets.fromLTRB(24, top + 10, 24, 40),
              children: [
                // 1. Header (drag vers le bas = fermer)
                GestureDetector(
                  onVerticalDragUpdate: (d) => setState(() => _dragY = (_dragY + d.delta.dy).clamp(0, 400)),
                  onVerticalDragEnd: (d) {
                    if (_dragY > 120 || (d.primaryVelocity ?? 0) > 600) {
                      context.pop();
                    } else {
                      setState(() => _dragY = 0);
                    }
                  },
                  child: Transform.translate(
                    offset: const Offset(-12, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          IconButtonSika(icon: 'chevron-down', label: 'Fermer le lecteur', size: 48, iconSize: 24, onTap: () => context.pop()),
                          Expanded(
                            child: Column(
                              children: [
                                Text(_sourceLabel(ui.source), maxLines: 1, style: SikaText.ui(11, w: FontWeight.w600, ls: 1.2, color: SikaColors.textSoft)),
                                const SizedBox(height: 2),
                                Text(ui.source?.title.isNotEmpty == true ? ui.source!.title : t.artist.name,
                                    maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(14, w: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(24, 0),
                            child: IconButtonSika(icon: 'more', label: 'Options', size: 48, onTap: () => showTrackOptions(context, ref, t)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 2. Pochette (swipe = suivant / précédent)
                const SizedBox(height: 28),
                GestureDetector(
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v < -300) ctrl.next();
                    if (v > 300) ctrl.previous();
                  },
                  onVerticalDragUpdate: (d) => setState(() => _dragY = (_dragY + d.delta.dy).clamp(0, 400)),
                  onVerticalDragEnd: (d) {
                    if (_dragY > 120 || (d.primaryVelocity ?? 0) > 600) {
                      context.pop();
                    } else {
                      setState(() => _dragY = 0);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(SikaRadius.xl), boxShadow: SikaShadows.playerCover),
                    child: Hero(
                      tag: 'now-cover',
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: CoverArt.seeded(t.id, key: ValueKey(t.id), radius: SikaRadius.xl, imageUrl: t.artworkUrl),
                      ),
                    ),
                  ),
                ),
                // 3. Titre + like
                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: SikaText.h1Player),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => openArtist(context, t.artist),
                            child: Text(t.artist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(15, color: SikaColors.textSoft)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButtonSika(
                      icon: liked ? 'heart-filled' : 'heart',
                      label: liked ? 'Retirer des titres likés' : 'Ajouter aux titres likés',
                      size: 48,
                      iconSize: 28,
                      color: liked ? SikaColors.yellow : SikaColors.text,
                      onTap: () => ref.read(libraryProvider.notifier).toggleLike(t),
                    ),
                  ],
                ),
                // 4. Waveform
                const SizedBox(height: 20),
                WaveformSeekBar(
                  position: pos,
                  duration: dur,
                  seed: t.id.hashCode % 97,
                  badge: offlineFile ? 'Hors ligne' : 'Haute qualité',
                  onSeek: ctrl.seek,
                ),
                // 5. Contrôles
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButtonSika(
                      icon: 'shuffle',
                      label: ui.shuffle ? 'Désactiver l\'aléatoire' : 'Activer l\'aléatoire',
                      size: 48,
                      color: ui.shuffle ? SikaColors.yellow : SikaColors.text,
                      onTap: ctrl.toggleShuffle,
                    ),
                    IconButtonSika(icon: 'skip-prev', label: 'Précédent', size: 56, iconSize: 30, onTap: ctrl.previous),
                    PlayButton(
                      playing: ui.playing,
                      loading: ui.buffering && !ui.playing,
                      size: 76,
                      iconSize: 30,
                      shadow: SikaShadows.playButton,
                      onTap: ctrl.toggle,
                    ),
                    IconButtonSika(icon: 'skip-next', label: 'Suivant', size: 56, iconSize: 30, onTap: ctrl.next),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButtonSika(
                          icon: 'repeat',
                          label: switch (ui.repeat) {
                            SikaRepeat.off => 'Répéter : désactivé',
                            SikaRepeat.all => 'Répéter : tout',
                            SikaRepeat.one => 'Répéter : ce titre',
                          },
                          size: 48,
                          color: ui.repeat == SikaRepeat.off ? SikaColors.text : SikaColors.yellow,
                          onTap: ctrl.cycleRepeat,
                        ),
                        if (ui.repeat == SikaRepeat.one)
                          IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text('1', style: SikaText.ui(8, w: FontWeight.w800, color: SikaColors.yellow)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // 6. Barre secondaire
                const SizedBox(height: 10),
                Transform.translate(
                  offset: const Offset(-12, 0),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const SikaIcon('speaker', size: 20, color: SikaColors.yellow),
                      const SizedBox(width: 8),
                      Text('Cet appareil', style: SikaText.ui(12, w: FontWeight.w700, color: SikaColors.yellow)),
                      const Spacer(),
                      IconButtonSika(
                        icon: 'share',
                        label: 'Partager',
                        onTap: () => SharePlus.instance.share(ShareParams(text: '${t.title} — ${t.artist.name}\n${t.shareUrl}')),
                      ),
                      Transform.translate(
                        offset: const Offset(24, 0),
                        child: IconButtonSika(icon: 'queue', label: 'File d\'attente', onTap: () => _showQueue(context)),
                      ),
                    ],
                  ),
                ),
                // 7. Paroles
                const SizedBox(height: 24),
                _LyricsCard(track: t),
                // 8. Artiste
                const SizedBox(height: 14),
                _ArtistCard(artist: t.artist, artwork: t.artworkUrl),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showSikaSheet(context, (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (ctx, scroll) => Consumer(builder: (ctx, ref, _) {
            final ui = ref.watch(playerProvider);
            return ListView.builder(
              controller: scroll,
              itemCount: ui.queue.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text('File d\'attente', style: SikaText.h2Small),
                  );
                }
                final q = ui.queue[i - 1];
                final cur = i - 1 == ui.index;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: CoverArt.seeded(q.id, size: 44, imageUrl: q.artworkUrl),
                  title: Text(q.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: SikaText.ui(14, w: FontWeight.w700, color: cur ? SikaColors.yellow : SikaColors.text)),
                  subtitle: Text(q.artist.name, maxLines: 1, style: SikaText.meta),
                  trailing: Text(formatDuration(q.duration), style: SikaText.meta),
                  onTap: () {
                    ref.read(playerProvider.notifier).jumpTo(i - 1);
                    Navigator.of(ctx).pop();
                  },
                );
              },
            );
          }),
        ));
  }
}

class _LyricsCard extends ConsumerWidget {
  const _LyricsCard({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = LyricsKey(track.artist.name, track.title, track.duration);
    final lyrics = ref.watch(lyricsProvider(key));
    const ink = SikaColors.onYellow;
    final other = SikaText.lyricsOther.copyWith(color: ink.withValues(alpha: 0.4));

    Widget body;
    Lyrics? l = lyrics.value;
    if (lyrics.isLoading && l == null) {
      body = Text('Recherche des paroles…', style: other);
    } else if (l == null) {
      body = Text('Paroles indisponibles pour ce titre.', style: other.copyWith(fontSize: 17));
    } else {
      // Fenêtre de hauteur fixe : les paroles défilent dedans, la carte ne saute plus.
      body = SizedBox(
        height: 210,
        child: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
            stops: [0, 0.14, 0.82, 1],
          ).createShader(r),
          blendMode: BlendMode.dstIn,
          child: _LyricsView(key: ValueKey(track.id), lyrics: l, compact: true),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(color: SikaColors.yellow, borderRadius: BorderRadius.circular(SikaRadius.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Paroles', style: SikaText.display(17, color: ink))),
              if (l != null)
                IconButtonSika(
                  icon: 'expand',
                  label: 'Agrandir les paroles',
                  size: 36,
                  iconSize: 18,
                  color: ink,
                  background: const Color(0x1F141208),
                  onTap: () => _showFullLyrics(context, l),
                ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  void _showFullLyrics(BuildContext context, Lyrics l) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: SikaColors.yellow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(SikaRadius.xl))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => _LyricsView(lyrics: l, controller: scroll),
      ),
    );
  }
}

/// Paroles défilantes : ligne en cours animée et suivie automatiquement.
/// `compact` = carte du lecteur (pas de défilement manuel) ; sinon feuille plein écran.
class _LyricsView extends ConsumerStatefulWidget {
  const _LyricsView({super.key, required this.lyrics, this.controller, this.compact = false});
  final Lyrics lyrics;
  final ScrollController? controller;
  final bool compact;

  @override
  ConsumerState<_LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<_LyricsView> {
  late final _keys = List.generate(widget.lyrics.lines.length, (_) => GlobalKey());
  late final ScrollController _own = ScrollController();
  ScrollController get _ctrl => widget.controller ?? _own;
  int _current = -1;
  DateTime _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  void _follow(int index, {bool animate = true}) {
    // Pause du suivi pendant 4 s après un défilement manuel (plein écran).
    if (DateTime.now().difference(_userScrolledAt) < const Duration(seconds: 4)) return;
    final ctx = _keys[index].currentContext;
    if (ctx == null || !mounted) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: widget.compact ? 0.4 : 0.3,
      duration: animate ? const Duration(milliseconds: 500) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lyrics;
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final cur = l.synced ? l.indexAt(pos) : -1;
    if (cur != _current) {
      final first = _current == -1;
      _current = cur;
      if (cur >= 0) WidgetsBinding.instance.addPostFrameCallback((_) => _follow(cur, animate: !first));
    }
    final compact = widget.compact;
    final current = compact ? SikaText.display(21, height: 1.3) : SikaText.lyricsCurrent;
    final other = compact ? SikaText.display(19, w: FontWeight.w700, height: 1.35) : SikaText.lyricsOther;

    return NotificationListener<UserScrollNotification>(
      onNotification: (_) {
        _userScrolledAt = DateTime.now();
        return false;
      },
      child: SingleChildScrollView(
        controller: _ctrl,
        physics: compact ? const NeverScrollableScrollPhysics() : null,
        padding: compact ? const EdgeInsets.symmetric(vertical: 80) : const EdgeInsets.fromLTRB(24, 24, 24, 320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < l.lines.length; i++)
              GestureDetector(
                key: _keys[i],
                onTap: l.lines[i].time == null
                    ? null
                    : () {
                        _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);
                        ref.read(playerProvider.notifier).seek(l.lines[i].time!);
                      },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 3 : 5),
                  child: AnimatedScale(
                    scale: !l.synced || i == cur ? 1.0 : 0.96,
                    alignment: Alignment.centerLeft,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      style: (i == cur ? current : other).copyWith(
                        color: SikaColors.onYellow.withValues(alpha: !l.synced || i == cur ? 1 : (i < cur ? 0.3 : 0.45)),
                      ),
                      child: Text(l.lines[i].text),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArtistCard extends ConsumerWidget {
  const _ArtistCard({required this.artist, this.artwork});
  final Artist artist;
  final String? artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final added = ref.watch(libraryProvider.select((s) => s.isFollowing(artist.id)));
    final image = artist.imageUrl ?? artwork;
    return GestureDetector(
      onTap: () => openArtist(context, Artist(id: artist.id, name: artist.name, imageUrl: image)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(color: SikaColors.surface, borderRadius: BorderRadius.circular(SikaRadius.xl)),
        child: Row(
          children: [
            CoverArt.seeded(artist.id, size: 56, circle: true, imageUrl: image),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.rowTitle),
                  const SizedBox(height: 2),
                  Text('Voir ses titres', style: SikaText.meta),
                ],
              ),
            ),
            // Ajout local à la Bibliothèque (filtre « Artistes ») : aucun compte requis.
            OutlinedButton.icon(
              onPressed: () {
                ref.read(libraryProvider.notifier).toggleFollow(Artist(id: artist.id, name: artist.name, imageUrl: image));
                showSnack(context, added ? 'Retiré de ta bibliothèque' : 'Ajouté à ta bibliothèque');
              },
              icon: added ? const SizedBox.shrink() : const SikaIcon('plus', size: 16),
              label: Text(
                added ? 'Dans ta biblio' : 'Ajouter',
                style: SikaText.ui(13, w: FontWeight.w700, color: added ? SikaColors.onYellow : SikaColors.text),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: EdgeInsets.only(left: added ? 16 : 12, right: 16),
                foregroundColor: added ? SikaColors.onYellow : SikaColors.text,
                backgroundColor: added ? SikaColors.yellow : Colors.transparent,
                side: BorderSide(color: added ? SikaColors.yellow : SikaColors.text, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientBackground extends ConsumerWidget {
  const _AmbientBackground({required this.artworkUrl});
  final String? artworkUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = (artworkUrl == null ? null : ref.watch(artworkColorProvider(artworkUrl!)).value) ?? SikaColors.orange;
    return IgnorePointer(
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: accent),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        builder: (_, c, _) {
          final color = c ?? accent;
          return Stack(
            children: [
              // Dégradé vertical : teinte en haut, fond Sika en bas (lisibilité des contrôles).
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.45, 0.85],
                      colors: [
                        Color.lerp(SikaColors.bg, color, 0.55)!,
                        Color.lerp(SikaColors.bg, color, 0.22)!,
                        SikaColors.bg,
                      ],
                    ),
                  ),
                ),
              ),
              // Halo flou en haut à gauche (maquette), dans la même teinte.
              Positioned(
                left: -120,
                top: -160,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(
                    width: 630,
                    height: 520,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.22),
                      borderRadius: const BorderRadius.all(Radius.elliptical(315, 260)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
