import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Flat oval contact shadow painted beneath a turntable subject (a kart, a
/// racer) standing on a lit stage — shared by every screen that shows one of
/// these stages so the shadow reads identically everywhere instead of each
/// screen carrying its own copy of the same painter.
class DashGroundShadow extends StatelessWidget {
  const DashGroundShadow({
    super.key,
    this.widthFraction = 0.62,
    this.centerYFraction = 0.765,
    this.maxWidth = 310.0,
  });

  /// How wide the shadow is, as a fraction of the stage's own width.
  final double widthFraction;

  /// Vertical centre of the shadow, as a fraction of the stage's height.
  final double centerYFraction;

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GroundShadowPainter(
        widthFraction: widthFraction,
        centerYFraction: centerYFraction,
        maxWidth: maxWidth,
      ),
    );
  }
}

class _GroundShadowPainter extends CustomPainter {
  const _GroundShadowPainter({
    required this.widthFraction,
    required this.centerYFraction,
    required this.maxWidth,
  });

  final double widthFraction;
  final double centerYFraction;
  final double maxWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * centerYFraction);
    final shadowW = math.min(size.width * widthFraction, maxWidth);
    final shadowH = shadowW * 0.12;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: shadowW, height: shadowH),
      Paint()
        ..color = const Color.fromARGB(68, 0, 30, 61)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );
  }

  @override
  bool shouldRepaint(_GroundShadowPainter old) =>
      old.widthFraction != widthFraction ||
      old.centerYFraction != centerYFraction ||
      old.maxWidth != maxWidth;
}
