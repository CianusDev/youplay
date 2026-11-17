import 'package:flutter/material.dart';

import '../../theme/sika_tokens.dart';
import 'artwork_image.dart';

/// Pochette : image réelle si disponible, sinon une des 6 pochettes géométriques (c1..c6).
class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    this.variant = 1,
    this.size,
    this.radius = SikaRadius.xs,
    this.imageUrl,
    this.circle = false,
    this.outlined = false,
    this.borderRadius,
  });

  /// Choisit une variante stable à partir d'un identifiant.
  factory CoverArt.seeded(
    String seed, {
    Key? key,
    double? size,
    double radius = SikaRadius.xs,
    String? imageUrl,
    bool circle = false,
    BorderRadius? borderRadius,
  }) =>
      CoverArt(
        key: key,
        variant: variantFor(seed),
        size: size,
        radius: radius,
        imageUrl: imageUrl,
        circle: circle,
        borderRadius: borderRadius,
      );

  static int variantFor(String seed) => seed.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff) % 6 + 1;

  final int variant;
  final double? size;
  final double radius;
  final String? imageUrl;
  final bool circle;
  final bool outlined;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final placeholder = CustomPaint(painter: _CoverPainter(variant), child: const SizedBox.expand());
    Widget child = imageUrl == null
        ? placeholder
        // Taille libre (pochette du lecteur, en-têtes) ou ≥ 120 : version haute définition.
        : ArtworkImage(url: imageUrl!, large: size == null || size! >= 120, placeholder: placeholder);
    final br = circle ? BorderRadius.circular(SikaRadius.pill) : (borderRadius ?? BorderRadius.circular(radius));
    child = ClipRRect(borderRadius: br, child: child);
    if (outlined && variant == 6 && imageUrl == null) {
      child = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(borderRadius: br, border: Border.all(color: SikaColors.surface3)),
        child: child,
      );
    }
    return size == null ? AspectRatio(aspectRatio: 1, child: child) : SizedBox(width: size, height: size, child: child);
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(this.variant);
  final int variant;

  static const _ink = Color(0xFF141208);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final p = Paint()..isAntiAlias = true;
    switch (variant) {
      case 1:
        canvas.drawRect(rect, p..color = SikaColors.yellow);
        canvas.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.31, p..color = _ink);
      case 2:
        canvas.drawRect(rect, p..color = SikaColors.orange);
        // Ø 90 %, left −25 %, bottom −45 % → centre (20 %, 100 %)
        canvas.drawCircle(Offset(s * 0.20, s * 1.0), s * 0.45, p..color = SikaColors.yellow);
      case 3:
        canvas.drawRect(rect, p..color = SikaColors.forest);
        p.color = SikaColors.yellow;
        // repeating-linear-gradient(135deg, yellow 0 8%, transparent 8% 20%)
        for (var k = 0; k < 6; k++) {
          final c1 = k * 0.4 * s, c2 = c1 + 0.16 * s;
          canvas.drawPath(
            Path()
              ..moveTo(c1 + s, -s)
              ..lineTo(c2 + s, -s)
              ..lineTo(c2 - 2 * s, 2 * s)
              ..lineTo(c1 - 2 * s, 2 * s)
              ..close(),
            p,
          );
        }
      case 4:
        canvas.drawRect(rect, p..color = SikaColors.cream);
        canvas.drawRect(Rect.fromLTWH(s * 0.42, s * 0.12, s * 0.46, s * 0.46), p..color = _ink);
      case 5:
        canvas.drawRect(rect, p..color = SikaColors.plum);
        final w = s >= 148 ? 6.0 : (s >= 60 ? 5.0 : 4.0);
        canvas.drawCircle(
          Offset(s * 0.5, s * 0.5),
          s * 0.28 - w / 2,
          p
            ..color = SikaColors.yellow
            ..style = PaintingStyle.stroke
            ..strokeWidth = w,
        );
      default:
        canvas.drawRect(rect, p..color = _ink);
        final left = s * 0.18, base = s * 0.43, h = s * 0.35, bottom = s * (1 - 0.14);
        canvas.drawPath(
          Path()
            ..moveTo(left, bottom)
            ..lineTo(left + base, bottom)
            ..lineTo(left + base / 2, bottom - h)
            ..close(),
          p..color = SikaColors.yellow,
        );
    }
  }

  @override
  bool shouldRepaint(_CoverPainter old) => old.variant != variant;
}
