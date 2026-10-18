import 'package:flutter/material.dart';

import '../../theme/sika_tokens.dart';
import 'youplay_logo.dart';

/// Prolonge visuellement le splash natif : même fond, même logo, qui grossit et s'efface
/// pendant que l'accueil apparaît dessous (aucune attente ajoutée).
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});
  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Laisse le temps à l'accueil de dessiner sa première image, puis on dévoile.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      await _ctrl.forward();
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (!_done)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) {
                final t = Curves.easeInCubic.transform(_ctrl.value);
                return Opacity(
                  opacity: 1 - t,
                  child: ColoredBox(
                    color: SikaColors.bg,
                    child: Center(
                      child: Transform.scale(
                        scale: 1 + 0.18 * Curves.easeOutBack.transform(_ctrl.value),
                        // Taille et forme du splash Android 12+ (cercle 160 dp, logo au centre).
                        child: const YouPlayLogo(size: 160, background: SikaColors.yellowSoft, round: true),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
