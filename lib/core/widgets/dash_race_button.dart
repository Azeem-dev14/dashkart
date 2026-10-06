import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_pressable.dart';

/// Arcade PLAY action button inspired by Brawl Stars.
///
/// Features:
/// * Horizontally slanted parallelogram silhouette (-0.09 skew)
/// * Pure upright (non-italic) cartoon text via counter-skew
/// * Chunky golden-yellow button face with top specular sheen
/// * Warm burnt-orange/brown 3D bevel bottom that physically sinks on press
/// * Heavy solid black borders with ambient drop shadow
/// * Pure white LilitaOne cartoon text with black outline and 3D extruded drop shadow
class DashRaceButton extends StatelessWidget {
  const DashRaceButton({
    super.key,
    required this.onPressed,
    this.label = 'PLAY',
    this.compact = false,
    this.glow = false,
    this.enabled = true,
    this.width,
    this.height,
    this.fontSize,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool compact;
  final bool glow;
  final bool enabled;
  final double? width;
  final double? height;
  final double? fontSize;

  static const _skewX = -0.09;
  static const _bevelDepth = 7.0;
  static const _bevelPressed = 2.0;

  @override
  Widget build(BuildContext context) {
    // 20% width reduction for punchier arcade footprint
    final resolvedWidth = width ?? (compact ? 152.0 : 192.0);
    final buttonHeight = height ?? (compact ? 56.0 : 68.0);
    final strokeWidth = compact ? 3.5 : 2.5;
    final borderRadius = compact ? 10.0 : 8.0;
    final innerRadius = (borderRadius - strokeWidth).clamp(2.0, 16.0);

    return SizedBox(
      width: resolvedWidth,
      height: buttonHeight,
      child: DashPressable(
        onPressed: enabled ? onPressed : null,
        enabled: enabled && onPressed != null,
        semanticLabel: label,
        builder: (context, rawPress, _) {
          final press = rawPress.clamp(0.0, 1.0);
          final currentDepth =
              (_bevelDepth - (_bevelDepth - _bevelPressed) * press).clamp(
                _bevelPressed,
                _bevelDepth,
              );
          final sink = (_bevelDepth - currentDepth);

          return Transform(
            transform: Matrix4.skewX(_skewX),
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Bottom drop shadow under the button
                Positioned(
                  left: 2,
                  right: 2,
                  bottom: -3,
                  top: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0x8A000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                        if (glow && enabled)
                          const BoxShadow(
                            color: Color(0x44FFC700),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                ),

                // Main Button Container with thick black frame
                Container(
                  width: resolvedWidth,
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: DashColors.pureBlack,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: DashColors.pureBlack,
                      width: strokeWidth,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(innerRadius),
                    child: Stack(
                      children: [
                        // 1. Bottom 3D bevel / extrusion lip (burnt amber / brown)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: buttonHeight * 0.36,
                          child: Container(color: const Color(0xFFA25128)),
                        ),

                        // 2. Yellow button face that physically sinks into the bevel
                        Positioned(
                          left: 0,
                          right: 0,
                          top: sink,
                          bottom: currentDepth,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFFD600), // bright yellow top
                                  Color(0xFFF7BD00), // rich golden yellow
                                  Color(0xFFEAA600), // warm amber
                                  Color(0xFFDE9400), // deep amber bottom
                                ],
                                stops: [0.0, 0.3, 0.7, 1.0],
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Top bright specular rim highlight
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: 2.5,
                                  child: Container(
                                    color: const Color(
                                      0xFFFFF25C,
                                    ).withValues(alpha: 0.9),
                                  ),
                                ),

                                // Right edge subtle specular highlight
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  bottom: 0,
                                  width: 2.5,
                                  child: Container(
                                    color: DashColors.textPrimary.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),

                                // Centered PLAY text: Counter-skewed so text stays strictly UPRIGHT (no italic)
                                Center(
                                  child: Transform(
                                    transform: Matrix4.skewX(-_skewX),
                                    alignment: Alignment.center,
                                    child: _BrawlButtonText(
                                      text: label,
                                      fontSize:
                                          fontSize ?? (compact ? 22.0 : 27.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Crisp divider line between yellow face and bottom bevel
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: currentDepth,
                          height: 1.0,
                          child: Container(color: const Color(0x33000000)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Upright 3D cartoon text: pure white fill, solid black outline, and extruded black drop shadow.
class _BrawlButtonText extends StatelessWidget {
  const _BrawlButtonText({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final strokeWidth = (fontSize * 0.04).clamp(3.0, 4.5);
    final shadowDepth = (fontSize * 0.10).clamp(3.5, 5.0);

    return CustomPaint(
      painter: _BrawlTextPainter(
        text: text,
        fontSize: fontSize,
        strokeWidth: strokeWidth,
        shadowDepth: shadowDepth,
      ),
      child: SizedBox(height: fontSize * 1.3, child: const SizedBox.expand()),
    );
  }
}

class _BrawlTextPainter extends CustomPainter {
  _BrawlTextPainter({
    required this.text,
    required this.fontSize,
    required this.strokeWidth,
    required this.shadowDepth,
  });

  final String text;
  final double fontSize;
  final double strokeWidth;
  final double shadowDepth;

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
  bool shouldRepaint(covariant _BrawlTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.shadowDepth != shadowDepth;
  }
}
