import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/sika_tokens.dart';

/// Logo YouPlay : disque sombre + triangle « lecture » jaune (couleur primaire) aux coins arrondis.
/// `background` : fond carré arrondi (icône d'app) ; null = disque seul.
class YouPlayLogo extends StatelessWidget {
  const YouPlayLogo({super.key, this.size = 24, this.background, this.round = false, this.disc = SikaColors.onYellow, this.play = SikaColors.yellow});
  final double size;
  final Color? background;
  /// Fond rond plutôt que carré arrondi (forme du splash Android 12+).
  final bool round;
  final Color disc;
  final Color play;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _LogoPainter(background, round, disc, play)),
      );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.background, this.round, this.disc, this.play);
  final Color? background;
  final bool round;
  final Color disc;
  final Color play;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);
    if (background != null && round) {
      canvas.drawCircle(c, s / 2, Paint()..color = background!);
    } else if (background != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.22)),
        Paint()..color = background!,
      );
    }
    // Disque : 66 % avec fond, plein cadre sans fond.
    final rd = background != null ? s * 0.33 : s * 0.5;
    canvas.drawCircle(c, rd, Paint()..color = disc);
    final h = rd * 1.0, w = h * 0.88, ox = rd * 0.07;
    final pts = [
      Offset(c.dx - w / 2 + ox, c.dy - h / 2),
      Offset(c.dx - w / 2 + ox, c.dy + h / 2),
      Offset(c.dx + w / 2 + ox, c.dy),
    ];
    canvas.drawPath(_rounded(pts, rd * 0.13), Paint()..color = play);
  }

  /// Polygone aux coins arrondis (arcs tangents), identique au générateur d'icônes.
  Path _rounded(List<Offset> pts, double r) {
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i], a = pts[(i - 1 + pts.length) % pts.length], b = pts[(i + 1) % pts.length];
      final u = (a - p) / (a - p).distance, v = (b - p) / (b - p).distance;
      final theta = math.acos((u.dx * v.dx + u.dy * v.dy).clamp(-1.0, 1.0));
      final t = r / math.tan(theta / 2);
      final p1 = p + u * t, p2 = p + v * t;
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.arcToPoint(p2, radius: Radius.circular(r), clockwise: _clockwise(u, v));
    }
    return path..close();
  }

  bool _clockwise(Offset u, Offset v) => (u.dx * v.dy - u.dy * v.dx) < 0;

  @override
  bool shouldRepaint(_LogoPainter old) => old.background != background || old.round != round || old.disc != disc || old.play != play;
}
