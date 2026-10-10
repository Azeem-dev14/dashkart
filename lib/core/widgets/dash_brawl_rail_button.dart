import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_pressable.dart';

enum BrawlRailButtonType { karts, tracks, shop }

/// Exact replica of the Brawl Stars left-rail action button (e.g. SHOP / BRAWLERS).
///
/// Features:
/// * Compact proportions matching Brawl Stars landscape UI
/// * Parallelogram silhouette slanted at `-0.09` skew
/// * Dark slate gradient face (`#353E54` -> `#263347`) with top specular sheen
/// * Hard dark navy bottom bevel that sinks on press
/// * Solid black cartoon ink borders all around
/// * Rich 3D cartoon arcade icon popping above the top edge:
///   - Karts: 3D Racing Steering Wheel with red rim, chrome spokes & golden hub
///   - Tracks: Crossed Waving Checkered Flags with golden poles & center star
///   - Shop: 3D Striped Store Canopy with golden star badge & scalloped awning
/// * Upright white **Lilita One** all-caps label with black outline & extruded shadow
class DashBrawlRailButton extends StatelessWidget {
  const DashBrawlRailButton({
    super.key,
    required this.label,
    required this.type,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final BrawlRailButtonType type;
  final VoidCallback onPressed;
  final bool compact;

  static const _skewX = -0.09;
  static const _bevelDepth = 3.2;
  static const _bevelPressed = 0.8;

  @override
  Widget build(BuildContext context) {
    // Proportions tuned to match Brawl Stars left-rail buttons
    final boxWidth = compact ? 58.0 : 66.0;
    final boxHeight = compact ? 34.0 : 38.0;
    final popHeight = compact ? 14.0 : 16.0;
    final totalHeight = boxHeight + popHeight;

    // Font size tuned for punchy Brawl Stars proportions:
    // Short words like SHOP (4 letters) get large, chunky, dominant font size
    final fontSize = switch (label.length) {
      <= 4 => compact ? 12.5 : 14.5,
      5 => compact ? 11.5 : 13.0,
      _ => compact ? 10.5 : 11.8,
    };

    return DashPressable(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, rawPress, _) {
        final press = rawPress.clamp(0.0, 1.0);
        final currentDepth =
            _bevelDepth - (_bevelDepth - _bevelPressed) * press;
        final currentSink = _bevelDepth - currentDepth;

        return SizedBox(
          width: boxWidth + 10, // extra width for skew overhang
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // --- 1. SINKING CONTAINER (Dark Slate Parallelogram) ---
              Positioned(
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: currentSink,
                    bottom: currentDepth,
                  ),
                  child: Transform(
                    transform: Matrix4.skewX(_skewX),
                    alignment: Alignment.center,
                    child: Container(
                      width: boxWidth,
                      height: boxHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          compact ? 3.0 : 4.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x8A000000),
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          compact ? 3.0 : 4.0,
                        ),
                        child: Stack(
                          children: [
                            // Bevel background at bottom
                            Positioned.fill(
                              child: Container(color: const Color(0xFF1B212D)),
                            ),

                            // Main slate gradient face
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
                                      Color.fromARGB(
                                        104,
                                        53,
                                        62,
                                        84,
                                      ), // slate top
                                      Color(0xFF2E374A),
                                      Color(0xFF263347), // deep slate bottom
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
                                        color: const Color(0xFF8899C2)
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                    // Right edge subtle specular highlight
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      bottom: 0,
                                      width: 2.0,
                                      child: Container(
                                        color: DashColors.textPrimary
                                            .withValues(alpha: 0.22),
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
                                    width: compact ? 2.5 : 2.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- 2. POPPING ICON (Sits on top edge, overlapping) ---
              Positioned(
                top: currentSink,
                child: SizedBox(
                  width: boxWidth,
                  height: popHeight + (boxHeight * 0.44),
                  child: Center(
                    child: switch (type) {
                      BrawlRailButtonType.karts => _BrawlKartIcon(
                        compact: compact,
                      ),
                      BrawlRailButtonType.tracks => _BrawlTrackIcon(
                        compact: compact,
                      ),
                      BrawlRailButtonType.shop => _BrawlShopIcon(
                        compact: compact,
                      ),
                    },
                  ),
                ),
              ),

              // --- 3. UPRIGHT TEXT LABEL (At the bottom) ---
              Positioned(
                bottom: currentDepth + (compact ? 2.5 : 3.5),
                child: _BrawlRailText(
                  text: label.toUpperCase(),
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Upright cartoon text with white fill, black outline, and extruded black shadow.
class _BrawlRailText extends StatelessWidget {
  const _BrawlRailText({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BrawlRailTextPainter(text: text, fontSize: fontSize),
      child: SizedBox(
        height: fontSize * 1.35,
        width: fontSize * text.length * 0.85 + 10,
      ),
    );
  }
}

class _BrawlRailTextPainter extends CustomPainter {
  _BrawlRailTextPainter({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final baseStyle = TextStyle(
      fontFamily: 'LilitaOne',
      fontSize: fontSize,
      letterSpacing: 0.3,
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

    final strokeWidth = (fontSize * 0.18).clamp(2.2, 3.0);
    final shadowDepth = (fontSize * 0.16).clamp(1.8, 2.6);

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
    for (double dy = shadowDepth; dy >= 0.5; dy -= 0.5) {
      paintOffset(Offset(0, dy), blackStroke);
      paintOffset(Offset(0, dy), blackFill);
    }

    // 2. Black outline
    paintOffset(Offset.zero, blackStroke);

    // 3. Pure crisp white fill
    final whiteFill = Paint()
      ..style = PaintingStyle.fill
      ..color = DashColors.textPrimary;
    paintOffset(Offset.zero, whiteFill);
  }

  @override
  bool shouldRepaint(covariant _BrawlRailTextPainter old) =>
      old.text != text || old.fontSize != fontSize;
}

/// 3D Cartoon Arcade Steering Wheel Icon popping over the button edge.
class _BrawlKartIcon extends StatelessWidget {
  const _BrawlKartIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final w = compact ? 34.0 : 38.0;
    final h = compact ? 26.0 : 29.0;

    return CustomPaint(
      size: Size(w, h),
      painter: _ArcadeSteeringWheelPainter(),
    );
  }
}

class _ArcadeSteeringWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * 0.48;
    final rOuter = size.height * 0.44;
    final rInner = size.height * 0.25;
    final rMid = (rOuter + rInner) / 2;
    final rimThick = rOuter - rInner;

    canvas.save();
    // Dynamic tilt matching Brawl Stars perspective
    canvas.translate(cx, cy);
    canvas.rotate(-0.12); // ~ -7 degrees tilt

    final blackStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = DashColors.pureBlack;

    // 1. Drop shadow beneath wheel
    canvas.drawCircle(
      const Offset(0, 2.5),
      rOuter,
      Paint()..color = const Color(0x55000000),
    );

    // 2. Outer Rim (Vibrant Racing Red Gradient)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimThick
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF3355), Color(0xFFE2113A), Color(0xFFA50A25)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: rOuter));
    canvas.drawCircle(Offset.zero, rMid, rimPaint);

    // 3. Black borders on outer and inner edge of rim
    canvas.drawCircle(Offset.zero, rOuter, blackStroke);
    canvas.drawCircle(Offset.zero, rInner, blackStroke);

    // 4. Textured Grips on Left and Right (Dark Charcoal Pads)
    final gripPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimThick + 0.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1E212B);

    // Left grip (-160° to -130°)
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: rMid),
      math.pi * 0.72,
      math.pi * 0.22,
      false,
      gripPaint,
    );
    // Right grip (-20° to 10°)
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: rMid),
      -math.pi * 0.08,
      math.pi * 0.22,
      false,
      gripPaint,
    );

    // 5. Chrome Spokes (Left, Right, Bottom-center)
    final spokePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final spokeStroke = Paint()
      ..color = DashColors.pureBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    void drawSpoke(double angle) {
      canvas.save();
      canvas.rotate(angle);
      final spokePath = Path()
        ..moveTo(-rInner * 0.35, 0)
        ..lineTo(-rInner * 0.25, rInner)
        ..lineTo(rInner * 0.25, rInner)
        ..lineTo(rInner * 0.35, 0)
        ..close();
      canvas.drawPath(spokePath, spokePaint);
      canvas.drawPath(spokePath, spokeStroke);
      canvas.restore();
    }

    drawSpoke(math.pi * 0.5); // Bottom spoke
    drawSpoke(-math.pi * 0.42); // Top-left spoke
    drawSpoke(math.pi * 0.42 + math.pi); // Top-right spoke

    // 6. Center Horn Hub (Vibrant Golden Badge)
    final hubRadius = rInner * 0.65;
    final hubShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFE053), Color(0xFFFFB300), Color(0xFFE67E00)],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: hubRadius));

    canvas.drawCircle(Offset.zero, hubRadius, Paint()..shader = hubShader);
    canvas.drawCircle(Offset.zero, hubRadius, blackStroke);

    // 7. Center Star on Hub
    final starPath = _createStarPath(
      Offset.zero,
      hubRadius * 0.55,
      hubRadius * 0.26,
    );
    canvas.drawPath(starPath, Paint()..color = DashColors.textPrimary);
    canvas.drawPath(
      starPath,
      Paint()
        ..color = const Color(0xFF994D00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 8. Specular White Highlight Arc on top-left rim
    final glintPaint = Paint()
      ..color = const Color(0xEEFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: rOuter - 1.2),
      -math.pi * 0.85,
      math.pi * 0.35,
      false,
      glintPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Cartoon Crossed Checkered Racing Flags Icon popping over the button edge.
class _BrawlTrackIcon extends StatelessWidget {
  const _BrawlTrackIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final w = compact ? 36.0 : 40.0;
    final h = compact ? 26.0 : 29.0;

    return CustomPaint(
      size: Size(w, h),
      painter: _CrossedCheckeredFlagsPainter(),
    );
  }
}

class _CrossedCheckeredFlagsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * 0.52;

    final blackStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = DashColors.pureBlack;

    // 1. Soft base drop shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 8),
        width: size.width * 0.75,
        height: 6,
      ),
      Paint()..color = const Color(0x44000000),
    );

    // 2. Crossed Flagpoles (Left to Top-Right, Right to Top-Left)
    final poleLeftStart = Offset(cx - 11, cy + 9);
    final poleLeftEnd = Offset(cx + 12, cy - 9);
    final poleRightStart = Offset(cx + 11, cy + 9);
    final poleRightEnd = Offset(cx - 12, cy - 9);

    final goldPole = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // Right pole (slants up-left)
    canvas.drawLine(
      poleRightStart,
      poleRightEnd,
      blackStroke..strokeWidth = 3.2,
    );
    canvas.drawLine(poleRightStart, poleRightEnd, goldPole);

    // Left pole (slants up-right)
    canvas.drawLine(poleLeftStart, poleLeftEnd, blackStroke..strokeWidth = 3.2);
    canvas.drawLine(poleLeftStart, poleLeftEnd, goldPole);

    // Golden ball finials on top tips
    final finialGold = Paint()..color = const Color(0xFFFFD526);
    canvas.drawCircle(poleRightEnd, 2.5, finialGold);
    canvas.drawCircle(poleRightEnd, 2.5, blackStroke..strokeWidth = 1.6);
    canvas.drawCircle(poleLeftEnd, 2.5, finialGold);
    canvas.drawCircle(poleLeftEnd, 2.5, blackStroke..strokeWidth = 1.6);

    // 3. Checkered Flags Waving Outward
    // Left flag (waving left from the right pole)
    _drawFlag(
      canvas: canvas,
      poleTop: Offset(cx - 9, cy - 6),
      poleBottom: Offset(cx - 2, cy - 0.5),
      waveDir: -1.0,
      blackStroke: blackStroke,
    );

    // Right flag (waving right from the left pole)
    _drawFlag(
      canvas: canvas,
      poleTop: Offset(cx + 9, cy - 6),
      poleBottom: Offset(cx + 2, cy - 0.5),
      waveDir: 1.0,
      blackStroke: blackStroke,
    );

    // 4. Center Golden Racing Star Badge (at the crossing point)
    final starRadius = 4.2;
    final starPath = _createStarPath(
      Offset(cx, cy + 1),
      starRadius,
      starRadius * 0.48,
    );
    canvas.drawPath(
      starPath,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFEE55), Color(0xFFFFB300)],
            ).createShader(
              Rect.fromCircle(center: Offset(cx, cy + 1), radius: starRadius),
            ),
    );
    canvas.drawPath(starPath, blackStroke..strokeWidth = 1.6);

    // White glint dot in star center
    canvas.drawCircle(
      Offset(cx - 0.6, cy + 0.2),
      0.9,
      Paint()..color = DashColors.textPrimary,
    );
  }

  void _drawFlag({
    required Canvas canvas,
    required Offset poleTop,
    required Offset poleBottom,
    required double waveDir,
    required Paint blackStroke,
  }) {
    final flagW = 14.0 * waveDir;
    const flagH = 9.5;

    final p0 = poleTop;
    final p1 = Offset(p0.dx + flagW * 0.55, p0.dy - 1.5);
    final p2 = Offset(p0.dx + flagW, p0.dy + 1.0);
    final p3 = Offset(p2.dx, p2.dy + flagH);
    final p4 = Offset(p0.dx + flagW * 0.55, poleBottom.dy + flagH - 1.5);
    final p5 = poleBottom;

    final flagPath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..quadraticBezierTo(p4.dx, p4.dy, p5.dx, p5.dy)
      ..close();

    canvas.save();
    canvas.clipPath(flagPath);

    // Fill flag base white
    final minX = math.min(p0.dx, p2.dx) - 2;
    final maxX = math.max(p0.dx, p2.dx) + 2;
    final minY = math.min(p0.dy, p1.dy) - 2;
    final maxY = math.max(p3.dy, p5.dy) + 2;
    final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);

    canvas.drawRect(bounds, Paint()..color = DashColors.textPrimary);

    // 2 rows x 3 columns checkerboard
    const rows = 2;
    const cols = 3;
    final cw = (maxX - minX) / cols;
    final ch = (maxY - minY) / rows;
    final checkerBlack = Paint()..color = const Color(0xFF181B22);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final isBlack = waveDir < 0 ? ((r + c) % 2 == 0) : ((r + c) % 2 == 1);
        if (isBlack) {
          canvas.drawRect(
            Rect.fromLTWH(minX + c * cw, minY + r * ch, cw, ch),
            checkerBlack,
          );
        }
      }
    }

    // Top wave sheen
    final sheenPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p0, p2, sheenPaint);

    canvas.restore();

    // Black cartoon outline
    canvas.drawPath(flagPath, blackStroke..strokeWidth = 1.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A 10-point star outline, alternating [outerR] and [innerR] per point.
/// Shared by every icon painter in this file that draws a badge star.
Path _createStarPath(Offset center, double outerR, double innerR) {
  final path = Path();
  for (int i = 0; i < 10; i++) {
    final r = i.isEven ? outerR : innerR;
    final angle = (i * math.pi / 5) - (math.pi / 2);
    final x = center.dx + r * math.cos(angle);
    final y = center.dy + r * math.sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

/// Exact Brawl Stars replica Shop Icon: a cute tilted storefront building with red/white striped awning.
class _BrawlShopIcon extends StatelessWidget {
  const _BrawlShopIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final w = compact ? 34.0 : 38.0;
    final h = compact ? 28.0 : 32.0;

    return Transform.rotate(
      angle: -0.11, // Playful tilt matching Brawl Stars shop icon
      child: CustomPaint(size: Size(w, h), painter: _ShopStorefrontPainter()),
    );
  }
}

class _ShopStorefrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * 0.50;

    final blackStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = DashColors.pureBlack;

    // 1. Soft base drop shadow underneath the building
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 11.5),
        width: size.width * 0.72,
        height: 5.0,
      ),
      Paint()..color = const Color(0x55000000),
    );

    // 2. Building Body (sky cyan storefront)
    const buildW = 20.0;
    const buildH = 13.0;
    final buildL = cx - buildW / 2;
    final buildR = cx + buildW / 2;
    final buildTop = cy - 1.0;
    final buildBottom = buildTop + buildH;

    final buildRRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(buildL, buildTop, buildR, buildBottom),
      bottomLeft: const Radius.circular(2.5),
      bottomRight: const Radius.circular(2.5),
    );

    const buildShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF9AE0FE), Color(0xFF70D0FA), Color(0xFF53BDEC)],
    );
    canvas.drawRRect(
      buildRRect,
      Paint()..shader = buildShader.createShader(buildRRect.outerRect),
    );

    // Left Window (cyan glass with bright cyan frame)
    final winRect = Rect.fromLTRB(
      buildL + 2.5,
      buildTop + 3.0,
      buildL + 9.5,
      buildBottom - 3.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(winRect, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFF029EE8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(winRect, const Radius.circular(1.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFFC7EFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(winRect, const Radius.circular(1.5)),
      blackStroke..strokeWidth = 1.0,
    );

    // Right Door (deep blue)
    final doorRect = Rect.fromLTRB(
      buildL + 11.5,
      buildTop + 2.5,
      buildR - 2.5,
      buildBottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        doorRect,
        topLeft: const Radius.circular(1.5),
        topRight: const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF0073CE),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        doorRect,
        topLeft: const Radius.circular(1.5),
        topRight: const Radius.circular(1.5),
      ),
      blackStroke..strokeWidth = 1.0,
    );

    // Solid black outline around building
    canvas.drawRRect(buildRRect, blackStroke..strokeWidth = 1.8);

    // 3. Awning / Canopy on Top
    // 3D Left side facet (burgundy shade)
    const topW = 22.0;
    const botW = 26.0;
    final topY = cy - 12.0;
    final botY = cy + 2.0;

    final leftFacet = Path()
      ..moveTo(cx - topW / 2, topY)
      ..lineTo(cx - topW / 2 - 2.2, topY + 2.5)
      ..lineTo(cx - botW / 2 - 2.0, botY + 1.5)
      ..lineTo(cx - botW / 2, botY)
      ..close();
    canvas.drawPath(leftFacet, Paint()..color = const Color(0xFF75152F));
    canvas.drawPath(leftFacet, blackStroke..strokeWidth = 1.4);

    // 3 Main Stripes: Red, White, Red with scalloped flaps
    const stripeCount = 3;
    const redGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF4E40), Color(0xFFE2261C), Color(0xFFAC150E)],
    );
    const whiteGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [DashColors.textPrimary, Color(0xFFF0F5FA), Color(0xFFD4E2F0)],
    );

    for (int i = 0; i < stripeCount; i++) {
      final t0 = -topW / 2 + i * (topW / stripeCount);
      final t1 = -topW / 2 + (i + 1) * (topW / stripeCount);
      final b0 = -botW / 2 + i * (botW / stripeCount);
      final b1 = -botW / 2 + (i + 1) * (botW / stripeCount);
      final flapRadius = (b1 - b0) / 2;

      final isRed = i != 1; // 0: Red, 1: White, 2: Red
      final stripeRect = Rect.fromLTRB(
        cx + b0,
        topY,
        cx + b1,
        botY + flapRadius,
      );

      final stripePath = Path()
        ..moveTo(cx + t0, topY)
        ..lineTo(cx + t1, topY)
        ..lineTo(cx + b1, botY)
        ..arcToPoint(
          Offset(cx + b0, botY),
          radius: Radius.circular(flapRadius),
          clockwise: true,
        )
        ..close();

      canvas.drawPath(
        stripePath,
        Paint()
          ..shader = (isRed ? redGradient : whiteGradient).createShader(
            stripeRect,
          ),
      );
      canvas.drawPath(stripePath, blackStroke..strokeWidth = 1.6);
    }

    // Outer awning thick ink border
    final awningOuter = Path()
      ..moveTo(cx - topW / 2, topY)
      ..lineTo(cx + topW / 2, topY)
      ..lineTo(cx + botW / 2, botY)
      ..arcToPoint(
        Offset(cx - botW / 2, botY),
        radius: const Radius.circular(botW / 2),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(awningOuter, blackStroke..strokeWidth = 2.0);

    // Top specular glint highlight across awning roof
    final glintPaint = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - topW / 2 + 2, topY + 1.2),
      Offset(cx + topW / 2 - 2, topY + 1.2),
      glintPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
