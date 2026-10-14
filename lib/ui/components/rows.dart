import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/sika_tokens.dart';
import 'cover_art.dart';
import 'sika_icon.dart';

/// Égaliseur animé : 4 barres yellow (titre en cours).
class Equalizer extends StatefulWidget {
  const Equalizer({super.key, this.animating = true, this.color = SikaColors.yellow, this.bars = 4, this.height = 14});
  final bool animating;
  final Color color;
  final int bars;
  final double height;

  @override
  State<Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer> {
  static const _base = [8.0, 14.0, 5.0, 11.0];
  final _rnd = Random();
  late List<double> _h = List.generate(widget.bars, (i) => _base[i % 4] * widget.height / 14);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Equalizer old) {
    super.didUpdateWidget(old);
    if (old.animating != widget.animating) _sync();
  }

  void _sync() {
    _t?.cancel();
    if (widget.animating) {
      _t = Timer.periodic(const Duration(milliseconds: 380), (_) {
        if (mounted) setState(() => _h = List.generate(widget.bars, (_) => 3 + _rnd.nextDouble() * (widget.height - 3)));
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < widget.bars; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeInOut,
              width: 3,
              height: _h[i],
              decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(1)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ligne de titre (playlist).
class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.index,
    required this.title,
    required this.meta,
    required this.duration,
    required this.seed,
    this.imageUrl,
    this.current = false,
    this.playing = false,
    this.downloaded = false,
    this.onTap,
    this.onMore,
  });

  final int index;
  final String title;
  final String meta;
  final String duration;
  final String seed;
  final String? imageUrl;
  final bool current;
  final bool playing;
  final bool downloaded;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onMore,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Center(
                child: current
                    ? Equalizer(animating: playing)
                    : Text('$index', style: SikaText.ui(13, w: FontWeight.w600, color: SikaColors.textMuted)),
              ),
            ),
            const SizedBox(width: 12),
            CoverArt.seeded(seed, size: 46, imageUrl: imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SikaText.rowTitle.copyWith(color: current ? SikaColors.yellow : SikaColors.text),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (downloaded) ...[const SikaIcon('download-circle-filled', size: 12, color: SikaColors.yellow), const SizedBox(width: 5)],
                      Flexible(child: Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.meta)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(duration, style: SikaText.ui(12, w: FontWeight.w600, color: SikaColors.textMuted)),
            if (onMore != null)
              IconButtonSika(icon: 'more', label: 'Options du titre', iconSize: 18, color: SikaColors.textMuted, onTap: onMore)
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// Ligne de bibliothèque (liste) — pochette 60.
class LibraryRow extends StatelessWidget {
  const LibraryRow({
    super.key,
    required this.title,
    required this.meta,
    required this.seed,
    this.imageUrl,
    this.circle = false,
    this.pinned = false,
    this.downloaded = false,
    this.variant,
    this.onTap,
    this.onLongPress,
    this.size = 60,
    this.trailing,
    this.radius = SikaRadius.sm,
  });

  final String title;
  final String meta;
  final String seed;
  final String? imageUrl;
  final bool circle;
  final bool pinned;
  final bool downloaded;
  final int? variant;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double size;
  final Widget? trailing;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            CoverArt(variant: variant ?? CoverArt.variantFor(seed), size: size, radius: radius, imageUrl: imageUrl, circle: circle, outlined: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.rowTitle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (pinned) ...[const SikaIcon('pin', size: 12, color: SikaColors.yellow), const SizedBox(width: 5)],
                      if (downloaded) ...[const SikaIcon('download-circle-filled', size: 12, color: SikaColors.yellow), const SizedBox(width: 5)],
                      Flexible(child: Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.meta)),
                    ],
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Élément de bibliothèque en grille (3 colonnes).
class LibraryGridItem extends StatelessWidget {
  const LibraryGridItem({super.key, required this.title, required this.type, required this.seed, this.imageUrl, this.circle = false, this.variant, this.onTap});
  final String title;
  final String type;
  final String seed;
  final String? imageUrl;
  final bool circle;
  final int? variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: circle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          CoverArt(variant: variant ?? CoverArt.variantFor(seed), radius: SikaRadius.sm, imageUrl: imageUrl, circle: circle, outlined: true),
          const SizedBox(height: 8),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(12, w: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(type, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(11, color: SikaColors.textMuted)),
        ],
      ),
    );
  }
}

enum DownloadRowStatus { done, downloading, queued, failed }

/// Ligne de l'écran Téléchargés.
class DownloadRow extends StatelessWidget {
  const DownloadRow({
    super.key,
    required this.title,
    required this.meta,
    required this.seed,
    required this.status,
    this.progress = 0,
    this.imageUrl,
    this.podcast = false,
    this.variant,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String meta;
  final String seed;
  final DownloadRowStatus status;
  final double progress;
  final String? imageUrl;
  final bool podcast;
  final int? variant;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final trailing = switch (status) {
      DownloadRowStatus.done => const SikaIcon('download-circle-filled', size: 24, color: SikaColors.yellow),
      DownloadRowStatus.downloading =>
        Text('${(progress * 100).round()} %', style: SikaText.ui(12, w: FontWeight.w800, color: SikaColors.yellow)),
      DownloadRowStatus.queued => Text('En attente', style: SikaText.ui(11, w: FontWeight.w700, color: SikaColors.textMuted)),
      DownloadRowStatus.failed => Text('Échec · réessayer', style: SikaText.ui(11, w: FontWeight.w700, color: SikaColors.orange)),
    };
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            CoverArt(
              variant: variant ?? CoverArt.variantFor(seed),
              size: 56,
              radius: podcast ? SikaRadius.md : SikaRadius.sm,
              imageUrl: imageUrl,
              outlined: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.rowTitle),
                  const SizedBox(height: 4),
                  Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.meta),
                  if (status == DownloadRowStatus.downloading) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: SikaColors.surface2,
                        color: SikaColors.yellow,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            trailing,
          ],
        ),
      ),
    );
  }
}
