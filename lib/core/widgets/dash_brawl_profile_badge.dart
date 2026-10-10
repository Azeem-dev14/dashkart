import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';

/// Brawl Stars replica top-right profile badge.
///
/// Layout (inverted from Trophy Road banner):
/// * Left side: Yellow/golden hero tile with the blue snowman/bot avatar icon
/// * Right side: Dark slate tile with upright white "SNOWMAN" text label
/// * Skewed at `-0.09` with sharp corners (3.0 - 4.0dp)
/// * Sits proudly with no tap gesture (static display)
class DashBrawlProfileBadge extends StatelessWidget {
  const DashBrawlProfileBadge({
    super.key,
    this.name = 'DASH',
    this.compact = false,
  });

  final String name;
  final bool compact;

  static const _skewX = -0.09;

  @override
  Widget build(BuildContext context) {
    // Proportionally sleek profile badge dimensions
    final height = compact ? 42.0 : 50.0;
    final totalWidth = compact ? 146.0 : 178.0;
    final iconBoxWidth = compact ? 42.0 : 50.0;
    final fontSize = compact ? 14.5 : 17.0;
    final bevelDepth = compact ? 3.8 : 4.8;
    final borderRadius = BorderRadius.circular(compact ? 3.0 : 4.0);

    return Transform(
      transform: Matrix4.skewX(_skewX),
      alignment: Alignment.center,
      child: Container(
        width: totalWidth,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x8A000000),
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              // --- BASE ROW: LEFT YELLOW ICON BOX + RIGHT GREY NAME BOX ---
              Row(
                children: [
                  // 1. LEFT: Yellow Icon Box
                  SizedBox(
                    width: iconBoxWidth,
                    height: height,
                    child: Stack(
                      children: [
                        // Bevel background
                        Positioned.fill(
                          child: Container(color: const Color(0xFFA25128)),
                        ),
                        // Yellow Face
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: bevelDepth,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFFD600),
                                  Color(0xFFF7BD00),
                                  Color(0xFFEAA600),
                                  Color(0xFFDE9400),
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Top specular sheen
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: 2.2,
                                  child: Container(
                                    color: const Color(0xFFFFF25C)
                                        .withValues(alpha: 0.9),
                                  ),
                                ),
                                // Avatar Icon centered
                                Center(
                                  child: Transform(
                                    transform: Matrix4.skewX(-_skewX),
                                    alignment: Alignment.center,
                                    child: _SnowmanAvatarIcon(compact: compact),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bevel line
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: bevelDepth,
                          height: 1.0,
                          child: Container(color: const Color(0x33000000)),
                        ),
                      ],
                    ),
                  ),

                  // Divider between yellow and grey
                  Container(
                    width: 2.4,
                    height: height,
                    color: DashColors.pureBlack,
                  ),

                  // 2. RIGHT: Dark Slate Name Box
                  Expanded(
                    child: SizedBox(
                      height: height,
                      child: Stack(
                        children: [
                          // Bevel background
                          Positioned.fill(
                            child: Container(color: const Color(0xFF1B212D)),
                          ),
                          // Slate Face
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: bevelDepth,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF424D68),
                                    Color(0xFF37425B),
                                    Color(0xFF2D384E),
                                  ],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Top specular sheen
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: 1.8,
                                    child: Container(
                                      color: const Color(0xFF8697BD)
                                          .withValues(alpha: 0.80),
                                    ),
                                  ),
                                  // Right edge subtle specular sheen
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    bottom: 0,
                                    width: 2.0,
                                    child: Container(
                                      color: DashColors.textPrimary.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                  ),
                                  // Upright Name Text
                                  Center(
                                    child: Transform(
                                      transform: Matrix4.skewX(-_skewX),
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6.0,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: _ProfileText(
                                            text: name.toUpperCase(),
                                            fontSize: fontSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Bevel line
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: bevelDepth,
                            height: 1.0,
                            child: Container(color: const Color(0x33000000)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // --- SOLID BLACK BORDER ALL AROUND ---
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: DashColors.pureBlack,
                      width: compact ? 3.0 : 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Upright cartoon text with white fill, black outline, and extruded black shadow.
class _ProfileText extends StatelessWidget {
  const _ProfileText({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ProfileTextPainter(text: text, fontSize: fontSize),
      child: SizedBox(
        height: fontSize * 1.3,
        width: fontSize * text.length * 0.72 + 6,
      ),
    );
  }
}

class _ProfileTextPainter extends CustomPainter {
  _ProfileTextPainter({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final baseStyle = TextStyle(
      fontFamily: 'LilitaOne',
      fontSize: fontSize,
      letterSpacing: 0.5,
      height: 1.0,
    );

    void paintOffset(Offset offset, Paint paint) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: baseStyle.copyWith(foreground: paint),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      final x = (size.width - painter.width) / 2 + offset.dx;
      final y = (size.height - painter.height) / 2 + offset.dy;
      painter.paint(canvas, Offset(x, y));
    }

    final strokeWidth = (fontSize * 0.04).clamp(2.5, 3.5);
    final shadowDepth = (fontSize * 0.10).clamp(2.8, 4.0);

    final blackStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = DashColors.pureBlack;

    final blackFill = Paint()
      ..style = PaintingStyle.fill
      ..color = DashColors.pureBlack;

    // 1. Extruded black shadow downward
    for (double dy = shadowDepth; dy >= 0.8; dy -= 0.8) {
      paintOffset(Offset(0, dy), blackStroke);
      paintOffset(Offset(0, dy), blackFill);
    }

    // 2. Black outline
    paintOffset(Offset.zero, blackStroke);

    // 3. Pure white fill
    final whiteFill = Paint()
      ..style = PaintingStyle.fill
      ..color = DashColors.textPrimary;
    paintOffset(Offset.zero, whiteFill);
  }

  @override
  bool shouldRepaint(covariant _ProfileTextPainter old) =>
      old.text != text || old.fontSize != fontSize;
}

/// The blue snowman / robot avatar icon from the Brawl Stars trophy road banner.
class _SnowmanAvatarIcon extends StatelessWidget {
  const _SnowmanAvatarIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final w = compact ? 26.0 : 32.0;
    final h = compact ? 24.0 : 29.0;

    return CustomPaint(size: Size(w, h), painter: _SnowmanAvatarPainter());
  }
}

class _SnowmanAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final blackStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = DashColors.pureBlack;

    // 1. Head shape (RRect)
    final headRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: w * 0.90,
        height: h * 0.88,
      ),
      const Radius.circular(5.5),
    );

    // 2. Dual-tone fill: Cyan top, Royal Blue bottom collar
    canvas.save();
    canvas.clipRRect(headRRect);

    // Cyan top
    final cyanPaint = Paint()..color = const Color(0xFF62E4FD);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.64), cyanPaint);

    // Royal blue bottom collar
    final bluePaint = Paint()..color = const Color(0xFF1E38BA);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.64, w, h * 0.36), bluePaint);

    // Top-left shiny white glint oval
    final glintPaint = Paint()..color = DashColors.textPrimary;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.22, cy - h * 0.22),
        width: w * 0.24,
        height: h * 0.16,
      ),
      glintPaint,
    );

    canvas.restore();

    // 3. Dividing seam line between cyan and blue
    canvas.drawLine(
      Offset(cx - w * 0.44, cy + h * 0.14),
      Offset(cx + w * 0.44, cy + h * 0.14),
      blackStroke..strokeWidth = 1.4,
    );

    // 4. Black cartoon border around the head
    canvas.drawRRect(headRRect, blackStroke..strokeWidth = 1.8);

    // 5. Two round black eyes
    final eyePaint = Paint()..color = DashColors.pureBlack;
    final eyeRadius = w * 0.085;
    canvas.drawCircle(
      Offset(cx - w * 0.15, cy + h * 0.05),
      eyeRadius,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(cx + w * 0.15, cy + h * 0.05),
      eyeRadius,
      eyePaint,
    );

    // 6. Inverted triangular nose / mouth
    final mouthPath = Path()
      ..moveTo(cx, cy + h * 0.12)
      ..lineTo(cx - w * 0.07, cy + h * 0.04)
      ..lineTo(cx + w * 0.07, cy + h * 0.04)
      ..close();
    canvas.drawPath(mouthPath, eyePaint);

    // 7. Eyebrows (slanted determined expression)
    final browPaint = Paint()
      ..color = DashColors.pureBlack
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Left eyebrow
    canvas.drawLine(
      Offset(cx - w * 0.22, cy - h * 0.08),
      Offset(cx - w * 0.08, cy - h * 0.04),
      browPaint,
    );
    // Right eyebrow
    canvas.drawLine(
      Offset(cx + w * 0.22, cy - h * 0.08),
      Offset(cx + w * 0.08, cy - h * 0.04),
      browPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
