import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/download_manager.dart';
import '../../state/library_store.dart';
import '../../state/player_controller.dart';
import '../../theme/sika_tokens.dart';
import 'cover_art.dart';
import 'play_button.dart';
import 'sika_icon.dart';
import '../../l10n/l10n.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(playerProvider);
    final t = ui.current;
    if (t == null) return const SizedBox.shrink();
    final liked = ref.watch(libraryProvider.select((s) => s.isLiked(t.id)));
    final offline = ref.watch(downloadsProvider.select((s) => s.offlineMode || s.isDownloaded(t.id)));
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final dur = ref.watch(durationProvider).value ?? t.duration;
    final ratio = dur.inMilliseconds <= 0 ? 0.0 : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(color: SikaColors.surface3, borderRadius: BorderRadius.circular(SikaRadius.md), boxShadow: SikaShadows.miniPlayer),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: context.l10n.openPlayer,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push('/player'),
                      onVerticalDragEnd: (d) {
                        if ((d.primaryVelocity ?? 0) < -200) context.push('/player');
                      },
                      child: Row(
                        children: [
                          Hero(tag: 'now-cover', child: CoverArt.seeded(t.id, size: 44, imageUrl: t.artworkUrl)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(13, w: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (offline)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: const BoxDecoration(color: SikaColors.yellow, shape: BoxShape.circle),
                                      )
                                    else ...[
                                      const SikaIcon('speaker', size: 12, color: SikaColors.yellow),
                                      const SizedBox(width: 5),
                                    ],
                                    Flexible(
                                      child: Text(
                                        '${t.artist.name} · ${offline ? context.l10n.offlineBadge : context.l10n.thisDevice}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: SikaText.ui(12, color: SikaColors.textSoft),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButtonSika(
                  icon: liked ? 'heart-filled' : 'heart',
                  label: liked ? context.l10n.removeFromLiked : context.l10n.addToLiked,
                  color: liked ? SikaColors.yellow : SikaColors.text,
                  onTap: () => ref.read(libraryProvider.notifier).toggleLike(t),
                ),
                const SizedBox(width: 4),
                PlayButton(
                  playing: ui.playing,
                  loading: ui.buffering && !ui.playing,
                  onTap: ref.read(playerProvider.notifier).toggle,
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            child: LayoutBuilder(
              builder: (_, c) => Stack(
                children: [
                  Container(height: 3, color: const Color(0x1FFFFFFF)),
                  Container(height: 3, width: c.maxWidth * ratio, color: SikaColors.yellow),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
