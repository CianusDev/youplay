import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../theme/sika_tokens.dart';
import 'sika_icon.dart';
import '../../l10n/l10n.dart';

/// Barre de progression en forme d'onde : tap / drag horizontal = seek.
class WaveformSeekBar extends StatefulWidget {
  const WaveformSeekBar({super.key, required this.position, required this.duration, required this.onSeek, this.seed = 0, this.badge});

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final int seed;
  final String? badge;

  @override
  State<WaveformSeekBar> createState() => _WaveformSeekBarState();
}

class _WaveformSeekBarState extends State<WaveformSeekBar> {
  static const _bars = 56;
  double? _drag; // 0..1 pendant le geste

  double get _ratio {
    if (_drag != null) return _drag!;
    final d = widget.duration.inMilliseconds;
    return d <= 0 ? 0 : (widget.position.inMilliseconds / d).clamp(0.0, 1.0);
  }

  double _height(int i) {
    final k = widget.seed * 0.13;
    final v = 0.35 + 0.35 * sin(i * 0.9 + k).abs() + 0.3 * sin(i * 0.37 + 1 + k * 2).abs();
    return 10 + v * 40;
  }

  void _update(Offset local, double width) => setState(() => _drag = (local.dx / width).clamp(0.0, 1.0));

  void _commit() {
    if (_drag == null) return;
    widget.onSeek(widget.duration * _drag!);
    setState(() => _drag = null);
  }

  void _step(int seconds) {
    final p = widget.position + Duration(seconds: seconds);
    widget.onSeek(p < Duration.zero ? Duration.zero : (p > widget.duration ? widget.duration : p));
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ratio;
    final shown = widget.duration * ratio;
    final remaining = widget.duration - shown;
    return Column(
      children: [
        Semantics(
          slider: true,
          label: context.l10n.playbackPosition,
          value: context.l10n.positionOf(formatDuration(shown), formatDuration(widget.duration)),
          increasedValue: formatDuration(shown + const Duration(seconds: 10)),
          decreasedValue: formatDuration(shown - const Duration(seconds: 10)),
          onIncrease: () => _step(10),
          onDecrease: () => _step(-10),
          child: Focus(
            onKeyEvent: (_, e) {
              if (e is! KeyDownEvent) return KeyEventResult.ignored;
              if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
                _step(5);
                return KeyEventResult.handled;
              }
              if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _step(-5);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _update(d.localPosition, w),
                  onTapUp: (_) => _commit(),
                  onHorizontalDragStart: (d) => _update(d.localPosition, w),
                  onHorizontalDragUpdate: (d) => _update(d.localPosition, w),
                  onHorizontalDragEnd: (_) => _commit(),
                  onHorizontalDragCancel: () => setState(() => _drag = null),
                  child: SizedBox(
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          children: [
                            for (var i = 0; i < _bars; i++) ...[
                              if (i > 0) const SizedBox(width: 2),
                              Expanded(
                                child: Center(
                                  child: Container(
                                    height: _height(i),
                                    decoration: BoxDecoration(
                                      color: (i + 0.5) / _bars <= ratio ? SikaColors.yellow : SikaColors.track,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Positioned(
                          left: (ratio * w - 1.5).clamp(0.0, w - 3),
                          top: 2,
                          bottom: 2,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: SikaColors.text,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: const [BoxShadow(color: Color(0x990F0E0B), spreadRadius: 3)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(formatDuration(shown), style: SikaText.time.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            // Badge facultatif (son hors ligne) ; sans badge, les deux durées restent aux extrémités.
            if (widget.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: SikaColors.navBorder, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SikaIcon('download-circle-filled', size: 12, color: SikaColors.yellow),
                    const SizedBox(width: 6),
                    Text(
                      widget.badge!,
                      style: SikaText.ui(11, w: FontWeight.w700, color: SikaColors.textSoft),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Text(
                '-${formatDuration(remaining)}',
                textAlign: TextAlign.right,
                style: SikaText.ui(13, w: FontWeight.w600, color: SikaColors.textSoft).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
