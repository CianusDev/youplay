import 'package:flutter/material.dart';

import '../../theme/sika_tokens.dart';
import 'sika_icon.dart';
import '../../l10n/l10n.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.playing,
    required this.onTap,
    this.size = 44,
    this.iconSize = 18,
    this.background = SikaColors.yellow,
    this.foreground = SikaColors.onYellow,
    this.shadow,
    this.loading = false,
  });

  final bool playing;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color background;
  final Color foreground;
  final List<BoxShadow>? shadow;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? context.l10n.pause : context.l10n.play,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: shadow),
        child: Material(
          color: background,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                child: loading
                    ? SizedBox(
                        key: const ValueKey('l'),
                        width: iconSize,
                        height: iconSize,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
                      )
                    : SikaIcon(playing ? 'pause' : 'play', key: ValueKey(playing), size: iconSize, color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
