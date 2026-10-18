import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
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
import 'lyrics_share_sheet.dart';

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
    final key = LyricsKey(track.id, track.artist.name, track.title, track.duration);
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
          child: _LyricsView(
            key: ValueKey('${track.id}-${l.id}'),
            lyrics: l,
            trackId: track.id,
            compact: true,
            // Appui long : paroles plein écran, directement en sélection avec cette ligne.
            onLongPressLine: (i) => showFullLyrics(context, track, l, select: true, initialLine: i),
          ),
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
              Text('Paroles', style: SikaText.display(17, color: ink)),
              const SizedBox(width: 10),
              // Clip plus long que la version minutée et pas encore réglé : on le signale.
              if (l != null && l.approximate && ref.watch(lyricsOffsetProvider(track.id)) == Duration.zero)
                GestureDetector(
                  onTap: () => showFullLyrics(context, track, l),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0x1F141208), borderRadius: BorderRadius.circular(8)),
                    child: Text('Synchro approx. · régler', style: SikaText.ui(10, w: FontWeight.w800, color: ink)),
                  ),
                ),
              const Spacer(),
              if (l != null) ...[
                IconButtonSika(
                  icon: 'share',
                  label: 'Partager des paroles',
                  size: 36,
                  iconSize: 17,
                  color: ink,
                  background: const Color(0x1F141208),
                  onTap: () => showFullLyrics(context, track, l, select: true),
                ),
                const SizedBox(width: 8),
              ],
              if (l != null)
                IconButtonSika(
                  icon: 'expand',
                  label: 'Agrandir les paroles',
                  size: 36,
                  iconSize: 18,
                  color: ink,
                  background: const Color(0x1F141208),
                  onTap: () => showFullLyrics(context, track, l),
                ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

}

/// Ouvre les paroles en plein écran. `select` : directement en mode sélection (partage),
/// `initialLine` : ligne présélectionnée (appui long).
void showFullLyrics(BuildContext context, Track track, Lyrics l, {bool select = false, int? initialLine}) {
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
      builder: (ctx, scroll) => _FullLyricsSheet(track: track, lyrics: l, scroll: scroll, select: select, initialLine: initialLine),
    ),
  );
}

const _maxShareLines = 6;
bool _shareable(String line) => line.trim().isNotEmpty && line.trim() != '♪';

/// Paroles plein écran avec un mode sélection intégré (comme Spotify) :
/// on choisit les lignes sur place, puis « Suivant » ouvre la personnalisation de la carte.
class _FullLyricsSheet extends StatefulWidget {
  const _FullLyricsSheet({required this.track, required this.lyrics, required this.scroll, this.select = false, this.initialLine});
  final Track track;
  final Lyrics lyrics;
  final ScrollController scroll;
  final bool select;
  final int? initialLine;

  @override
  State<_FullLyricsSheet> createState() => _FullLyricsSheetState();
}

class _FullLyricsSheetState extends State<_FullLyricsSheet> {
  late bool _selecting = widget.select || widget.initialLine != null;
  late final Set<int> _selected = {
    if (widget.initialLine != null && _shareable(widget.lyrics.lines[widget.initialLine!].text)) widget.initialLine!,
  };

  void _enter([int? line]) => setState(() {
        _selecting = true;
        _selected.clear();
        if (line != null && _shareable(widget.lyrics.lines[line].text)) _selected.add(line);
      });

  void _exit() => setState(() {
        _selecting = false;
        _selected.clear();
      });

  void _toggle(int i) {
    if (!_shareable(widget.lyrics.lines[i].text)) return;
    setState(() {
      if (!_selected.remove(i)) {
        if (_selected.length >= _maxShareLines) {
          showSnack(context, '$_maxShareLines lignes maximum');
          return;
        }
        _selected.add(i);
      }
    });
  }

  void _next() {
    final lines = (_selected.toList()..sort()).map((i) => widget.lyrics.lines[i].text).toList();
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => LyricsCardEditor(track: widget.track, lines: lines),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const ink = SikaColors.onYellow;
    final n = _selected.length;
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _selecting
              ? Padding(
                  key: const ValueKey('sel'),
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
                  child: Column(
                    children: [
                      Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0x33141208), borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Choisis des paroles', style: SikaText.display(20, color: ink)),
                                Text(n == 0 ? 'Touche jusqu\'à $_maxShareLines lignes' : '$n / $_maxShareLines ligne${n > 1 ? 's' : ''}',
                                    style: SikaText.ui(12, w: FontWeight.w600, color: ink.withValues(alpha: 0.65))),
                              ],
                            ),
                          ),
                          _Pill(label: 'Annuler', onTap: _exit),
                        ],
                      ),
                    ],
                  ),
                )
              : _LyricsControls(key: const ValueKey('read'), track: widget.track, lyrics: widget.lyrics, onShare: () => _enter()),
        ),
        Expanded(
          child: _LyricsView(
            lyrics: widget.lyrics,
            trackId: widget.track.id,
            controller: widget.scroll,
            selected: _selecting ? _selected : null,
            onToggle: _toggle,
            onLongPressLine: _selecting ? null : (i) => _enter(i),
            scrollTo: widget.initialLine,
          ),
        ),
        // Barre « Suivant » (mode sélection)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: !_selecting
              ? const SizedBox(width: double.infinity)
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: n == 0 ? null : _next,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          backgroundColor: SikaColors.onYellow,
                          foregroundColor: SikaColors.yellow,
                          disabledBackgroundColor: const Color(0x26141208),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          n == 0 ? 'Touche des lignes pour les choisir' : 'Suivant · $n ligne${n > 1 ? 's' : ''}',
                          style: SikaText.ui(15, w: FontWeight.w800, color: n == 0 ? ink.withValues(alpha: 0.5) : SikaColors.yellow),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Bouton pilule sur fond jaune (lisible quel que soit le thème Material).
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.icon, this.strong = false, this.semantics});
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool strong; // action mise en avant : fond noir, texte jaune
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final fg = strong ? SikaColors.yellow : SikaColors.onYellow;
    return Semantics(
      button: true,
      label: semantics ?? label,
      child: Material(
        color: strong ? SikaColors.onYellow : const Color(0x1F141208),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 10 : 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) Icon(icon, size: 18, color: fg),
                  if (icon != null && label.isNotEmpty) const SizedBox(width: 6),
                  if (label.isNotEmpty) Text(label, style: SikaText.ui(13, w: FontWeight.w800, color: fg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// En-tête de la feuille plein écran : poignée, titre, actions (partager, signaler, fermer)
/// et réglage du décalage sur une seule ligne compacte.
class _LyricsControls extends ConsumerWidget {
  const _LyricsControls({super.key, required this.track, required this.lyrics, required this.onShare});
  final Track track;
  final Lyrics lyrics;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const ink = SikaColors.onYellow;
    final offset = ref.watch(lyricsOffsetProvider(track.id));
    final prefs = ref.read(lyricsPrefsProvider.notifier);
    final gap = lyrics.durationGap;
    String fmt(Duration d) {
      final v = d.inMilliseconds / 1000;
      return '${v > 0 ? '+' : ''}${v.toStringAsFixed(1).replaceAll('.', ',')} s';
    }

    void report() {
      showSikaSheet(context, (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mauvaises paroles ?', style: SikaText.h2Small),
                  const SizedBox(height: 6),
                  Text('On écarte ce texte pour ce titre et on cherche une autre version.', style: SikaText.meta),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: SikaColors.yellow,
                        foregroundColor: SikaColors.onYellow,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        prefs.reject(track.id, lyrics.id!);
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                        showSnack(context, 'Recherche d\'autres paroles…');
                      },
                      child: Text('Chercher d\'autres paroles', style: SikaText.ui(15, w: FontWeight.w800, color: SikaColors.onYellow)),
                    ),
                  ),
                ],
              ),
            ),
          ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: const Color(0x33141208), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 10),
          // Titre + actions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paroles', style: SikaText.display(20, color: ink)),
                    Text('${track.title} · ${track.artist.name}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(12, w: FontWeight.w600, color: ink.withValues(alpha: 0.65))),
                  ],
                ),
              ),
              _Pill(
                label: '',
                icon: Icons.ios_share_rounded,
                semantics: 'Partager des paroles',
                onTap: onShare,
              ),
              if (lyrics.id != null) ...[
                const SizedBox(width: 8),
                _Pill(label: '', icon: Icons.flag_outlined, semantics: 'Signaler de mauvaises paroles', onTap: report),
              ],
              const SizedBox(width: 8),
              _Pill(label: '', icon: Icons.close_rounded, semantics: 'Fermer', onTap: () => Navigator.of(context).pop()),
            ],
          ),
          // Décalage (paroles synchronisées uniquement)
          if (lyrics.synced) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Synchro', style: SikaText.ui(13, w: FontWeight.w700, color: ink)),
                const SizedBox(width: 10),
                _Pill(label: '−0,5', onTap: () => prefs.setOffset(track.id, offset - const Duration(milliseconds: 500)), semantics: 'Paroles plus tôt'),
                GestureDetector(
                  onTap: () => prefs.setOffset(track.id, Duration.zero),
                  child: SizedBox(
                    width: 64,
                    child: Text(offset == Duration.zero ? '0 s' : fmt(offset),
                        textAlign: TextAlign.center, style: SikaText.ui(14, w: FontWeight.w800, color: ink)),
                  ),
                ),
                _Pill(label: '+0,5', onTap: () => prefs.setOffset(track.id, offset + const Duration(milliseconds: 500)), semantics: 'Paroles plus tard'),
                const Spacer(),
                // Clip plus long : l'écart vient le plus souvent d'une intro avant le premier couplet.
                if (lyrics.approximate && gap > Duration.zero && offset != gap)
                  _Pill(label: 'Clip ${fmt(gap)}', strong: true, semantics: 'Aligner sur le clip', onTap: () => prefs.setOffset(track.id, gap)),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            lyrics.synced ? 'Touche une ligne pour y sauter · appui long pour partager' : 'Appui long sur une ligne pour partager',
            style: SikaText.ui(11, color: ink.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

/// Paroles défilantes : ligne en cours animée et suivie automatiquement.
/// `compact` = carte du lecteur (pas de défilement manuel) ; sinon feuille plein écran.
class _LyricsView extends ConsumerStatefulWidget {
  const _LyricsView({
    super.key,
    required this.lyrics,
    required this.trackId,
    this.controller,
    this.compact = false,
    this.selected,
    this.onToggle,
    this.onLongPressLine,
    this.scrollTo,
  });
  final Lyrics lyrics;
  final String trackId;
  /// Non nul = mode sélection : toucher une ligne la (dé)sélectionne, le suivi auto est suspendu.
  final Set<int>? selected;
  final ValueChanged<int>? onToggle;
  final ValueChanged<int>? onLongPressLine;
  /// Ligne à amener à l'écran à l'ouverture (appui long depuis la carte).
  final int? scrollTo;
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
  void initState() {
    super.initState();
    final target = widget.scrollTo;
    if (target != null) {
      _current = -2; // le suivi auto ne doit pas écraser ce défilement initial
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);
        _follow(target, animate: false);
        _userScrolledAt = DateTime.now(); // laisse la ligne choisie à l'écran quelques secondes
      });
    }
  }

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  void _follow(int index, {bool animate = true}) {
    // Pause du suivi pendant 4 s après un défilement manuel (plein écran).
    if (DateTime.now().difference(_userScrolledAt) < const Duration(seconds: 4)) return;
    final ctx = _keys[index].currentContext;
    if (ctx == null || !mounted || !_ctrl.hasClients) return;
    // On ne fait défiler QUE la vue des paroles : Scrollable.ensureVisible ferait aussi
    // défiler la page du lecteur (parent) et ramènerait l'écran sur la carte.
    final box = ctx.findRenderObject();
    if (box == null) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final target = viewport
        .getOffsetToReveal(box, widget.compact ? 0.4 : 0.3)
        .offset
        .clamp(_ctrl.position.minScrollExtent, _ctrl.position.maxScrollExtent);
    if (animate) {
      _ctrl.animateTo(target, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    } else {
      _ctrl.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lyrics;
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    // Décalage choisi par l'utilisateur + 250 ms d'anticipation (la ligne s'allume juste avant d'être chantée).
    final offset = ref.watch(lyricsOffsetProvider(widget.trackId));
    final cur = l.synced ? l.indexAt(pos - offset + const Duration(milliseconds: 250)) : -1;
    final selecting = widget.selected != null;
    if (cur != _current && !selecting) {
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
                onLongPress: widget.onLongPressLine == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        widget.onLongPressLine!(i);
                      },
                onTap: selecting
                    ? () {
                        HapticFeedback.selectionClick();
                        widget.onToggle?.call(i);
                      }
                    : l.lines[i].time == null
                    ? null
                    : () {
                        _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);
                        final at = l.lines[i].time! + ref.read(lyricsOffsetProvider(widget.trackId));
                        ref.read(playerProvider.notifier).seek(at < Duration.zero ? Duration.zero : at);
                      },
                child: selecting
                    ? _SelectableLine(text: l.lines[i].text, selected: widget.selected!.contains(i), style: other)
                    : Padding(
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

/// Ligne en mode sélection : surlignée en noir quand elle est choisie (comme Spotify).
class _SelectableLine extends StatelessWidget {
  const _SelectableLine({required this.text, required this.selected, required this.style});
  final String text;
  final bool selected;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final usable = _shareable(text);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? SikaColors.onYellow : Colors.transparent,
        borderRadius: BorderRadius.circular(SikaRadius.sm),
      ),
      child: Text(
        text,
        style: style.copyWith(
          color: selected ? SikaColors.yellow : SikaColors.onYellow.withValues(alpha: usable ? 0.55 : 0.25),
        ),
      ),
    );
  }
}
