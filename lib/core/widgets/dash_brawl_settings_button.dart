import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_pressable.dart';

/// The home screen's top-right settings button.
///
/// Features:
/// * Parallelogram silhouette slanted at `-0.09` skew
/// * Dark slate gradient face (`#353E54` -> `#263347`) with top specular sheen
/// * Right-edge subtle specular sheen line
/// * Hard dark bottom bevel that collapses on press
/// * Heavy solid black border all around
/// * A chunky hand-painted gear, inked and glossed like the rail icons
class DashBrawlSettingsButton extends StatelessWidget {
  const DashBrawlSettingsButton({
    super.key,
    required this.onPressed,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool compact;

  static const _skewX = -0.09;
  static const _bevelDepth = 3.5;
  static const _bevelPressed = 1.0;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 52.0 : 62.0;
    final height = compact ? 32.0 : 38.0;
    final gear = compact ? 25.0 : 30.0;

    return DashPressable(
      onPressed: onPressed,
      semanticLabel: 'Settings',
      builder: (context, rawPress, _) {
        final press = rawPress.clamp(0.0, 1.0);
        final currentDepth =
            _bevelDepth - (_bevelDepth - _bevelPressed) * press;
        final currentSink = _bevelDepth - currentDepth;

        return Padding(
          padding: EdgeInsets.only(top: currentSink, bottom: currentDepth),
          child: Transform(
            transform: Matrix4.skewX(_skewX),
            alignment: Alignment.center,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(compact ? 3.0 : 4.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x8A000000),
                    offset: Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(compact ? 3.0 : 4.0),
                child: Stack(
                  children: [
                    // Bottom Bevel background
                    Positioned.fill(
                      child: Container(color: const Color(0xFF141722)),
                    ),

                    // Main Slate Face
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: currentDepth,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF353C4E),
                              Color(0xFF282E3E),
                              Color(0xFF1E2330),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Top highlight sheen line
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 2.0,
                              child: Container(color: const Color(0xFF56546E)),
                            ),

                            // Top-right corner specular facet
                            Positioned(
                              top: 0,
                              right: 0,
                              width: 8.0,
                              height: 8.0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      Color(0xFF6F6C8C),
                                      Color(0x006F6C8C),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Right edge subtle specular highlight
                            Positioned(
                              top: 0,
                              right: 0,
                              bottom: 0,
                              width: 1.6,
                              child: Container(
                                color: DashColors.textPrimary.withValues(
                                  alpha: 0.16,
                                ),
                              ),
                            ),

                            // The gear. Un-skewed so it stays a true circle
                            // inside the slanted button.
                            Center(
                              child: Transform(
                                transform: Matrix4.skewX(-_skewX),
                                alignment: Alignment.center,
                                child: CustomPaint(
                                  size: Size.square(gear),
                                  painter: const _GearPainter(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Divider line between face and bevel
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: currentDepth,
                      height: 1.0,
                      child: Container(color: const Color(0x33000000)),
                    ),

                    // Outer solid black border
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            compact ? 3.0 : 4.0,
                          ),
                          border: Border.all(
                            color: DashColors.pureBlack,
                            width: compact ? 2.5 : 2.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A cartoon gear: eight blunt teeth, a cream-to-steel face, a dark axle
/// hole, a hard ink outline and a drop shadow — the same treatment as the
/// wheel, flags and shop bag on the left rail.
class _GearPainter extends CustomPainter {
  const _GearPainter();

  static const _teeth = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rOuter = size.width * 0.5 - 1.5;
    final rRoot = rOuter * 0.76;
    final rHole = rOuter * 0.30;

    // Tooth outline: flat-topped trapezoids, a little narrower at the tip.
    final step = 2 * math.pi / _teeth;
    final path = Path();
    for (var i = 0; i < _teeth; i++) {
      final a = i * step - math.pi / 2;
      final points = [
        (a - step * 0.30, rRoot),
        (a - step * 0.17, rOuter),
        (a + step * 0.17, rOuter),
        (a + step * 0.30, rRoot),
      ];
      for (var j = 0; j < points.length; j++) {
        final (angle, r) = points[j];
        final p = c + Offset(math.cos(angle), math.sin(angle)) * r;
        i == 0 && j == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..color = DashColors.pureBlack;

    // Drop shadow.
    canvas.drawPath(
      path.shift(const Offset(0, 2.2)),
      Paint()..color = DashColors.pureBlack,
    );

    // Face.
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFD9E2FF), Color(0xFF8FA2D6)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: rOuter)),
    );
    canvas.drawPath(path, ink);

    // Gloss on the upper-left of the rim.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: rRoot * 0.86),
      math.pi * 1.05,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xCCFFFFFF),
    );

    // Axle hole: dark, ringed in ink, with a tiny lit edge underneath.
    canvas.drawCircle(
      c,
      rHole,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2A86), Color(0xFF3B4FC4)],
        ).createShader(Rect.fromCircle(center: c, radius: rHole)),
    );
    canvas.drawCircle(c, rHole, ink);
  }

  @override
  bool shouldRepaint(_GearPainter old) => false;
}
