import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/sika_tokens.dart';

/// Icône SVG de `assets/icons/` (viewBox 24, currentColor).
class SikaIcon extends StatelessWidget {
  const SikaIcon(this.name, {super.key, this.size = 24, this.color = SikaColors.text});
  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icons/$name.svg',
        width: size,
        height: size,
        theme: SvgTheme(currentColor: color),
      );
}

/// Bouton-icône rond 44 (48 dans le lecteur), fond transparent, press rgba(255,255,255,.06).
class IconButtonSika extends StatelessWidget {
  const IconButtonSika({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.size = 44,
    this.iconSize = 22,
    this.color = SikaColors.text,
    this.background,
    this.badge = false,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color color;
  final Color? background;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: background ?? Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            highlightColor: const Color(0x0FFFFFFF),
            hoverColor: const Color(0x0FFFFFFF),
            splashColor: const Color(0x14FFFFFF),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SikaIcon(icon, size: iconSize, color: color),
                if (badge)
                  Positioned(
                    top: 11,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: SikaColors.yellow, shape: BoxShape.circle),
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
