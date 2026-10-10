import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Streaks that rush outward from the edges of the screen as the kart gains
/// speed, and surge hard while boosting — the "world is bending past you"
/// cue a kart racer lives on. Drawn over the 3D view, under the HUD.
///
/// Costs one cheap [CustomPaint] of a few dozen lines per frame, and nothing
/// at all below [_minIntensity].
class SpeedLines extends StatelessWidget {
  const SpeedLines({
    super.key,
    required this.speed,
    required this.boosting,
    required this.seconds,
  });

  /// Current speed as a fraction of top speed, 0..1+.
  final double speed;
  final bool boosting;

  /// Race clock, drives the streaks' motion.
  final double seconds;

  static const _minIntensity = 0.45;

  @override
  Widget build(BuildContext context) {
    final intensity = boosting ? 1.0 : ((speed - _minIntensity) / 0.55);
    if (intensity <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _SpeedLinesPainter(
          intensity: intensity.clamp(0.0, 1.0),
          boosting: boosting,
          seconds: seconds,
        ),
      ),
    );
  }
}

class _SpeedLinesPainter extends CustomPainter {
  const _SpeedLinesPainter({
    required this.intensity,
    required this.boosting,
    required this.seconds,
  });

  final double intensity;
  final bool boosting;
  final double seconds;

  static const _count = 36;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height * 0.46);
    final reach = size.longestSide * 0.62;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = (boosting ? const Color(0xFFFFC46B) : const Color(0xFFFFFFFF))
          .withValues(alpha: 0.10 + 0.32 * intensity);

    for (var i = 0; i < _count; i++) {
      // Deterministic per-line values, so lines are stable between frames.
      final angle = (i / _count) * math.pi * 2 + math.sin(i * 12.9898) * 0.07;
      final offset = (math.sin(i * 78.233) * 43758.5453).abs() % 1.0;
      final speedMul = 0.7 + offset * 0.9;
      final phase =
          (seconds * (boosting ? 2.6 : 1.5) * speedMul + offset) % 1.0;

      // Born near the middle, accelerating outward, stretching as they go.
      final start = reach * (0.5 + 0.5 * phase * phase);
      final length = reach * (0.04 + 0.16 * intensity) * (0.4 + phase);
      final dir = Offset(math.cos(angle), math.sin(angle));
      paint.strokeWidth = 1.5 + 2.5 * phase * intensity;
      canvas.drawLine(
        centre + dir * start,
        centre + dir * (start + length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeedLinesPainter old) =>
      old.intensity != intensity ||
      old.boosting != boosting ||
      old.seconds != seconds;
}
