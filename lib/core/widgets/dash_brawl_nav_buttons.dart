import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_pressable.dart';

/// Brawl Stars replica top-bar navigation button (e.g. Back, Home).
///
/// Features:
/// * Parallelogram silhouette slanted at `-0.09` skew
/// * Dark slate gradient face (`#353C4E` -> `#1E2330`)
/// * Top specular sheen line & right-edge specular highlight
/// * Sinking dark navy bottom bevel on press
/// * Thick cartoon black ink border (`2.4dp`)
class DashBrawlNavButton extends StatelessWidget {
  const DashBrawlNavButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.semanticLabel,
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String? semanticLabel;
  final bool compact;

  static const _skewX = -0.09;
  static const _bevelDepth = 3.5;
  static const _bevelPressed = 1.0;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 44.0 : 52.0;
    final height = compact ? 30.0 : 36.0;

    return DashPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
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
                              height: 1.8,
                              child: Container(color: const Color(0xFF56546E)),
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

                            // Centered Icon
                            Center(child: icon),
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
                            width: compact ? 2.4 : 2.2,
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

/// Exact replica of the Brawl Stars Back Button (`<` arrow).
class DashBrawlBackButton extends StatelessWidget {
  const DashBrawlBackButton({super.key, this.onPressed, this.compact = false});

  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DashBrawlNavButton(
      onPressed: onPressed,
      compact: compact,
      semanticLabel: 'Back',
      icon: CustomPaint(
        size: Size(compact ? 18.0 : 22.0, compact ? 18.0 : 22.0),
        painter: _BackChevronPainter(),
      ),
    );
  }
}

class _BackChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;

    // Bold cartoon left chevron `<`
    final p = Path()
      ..moveTo(cx + w * 0.22, cy - w * 0.40)
      ..lineTo(cx - w * 0.28, cy)
      ..lineTo(cx + w * 0.22, cy + w * 0.40)
      ..lineTo(cx + w * 0.38, cy + w * 0.24)
      ..lineTo(cx + w * 0.04, cy)
      ..lineTo(cx + w * 0.38, cy - w * 0.24)
      ..close();

    // Solid black drop shadow
    canvas.drawPath(
      p.shift(const Offset(0, 1.8)),
      Paint()..color = DashColors.pureBlack,
    );

    // Solid black stroke outline
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = DashColors.pureBlack,
    );

    // Pure white fill
    canvas.drawPath(p, Paint()..color = DashColors.textPrimary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Exact replica of the Brawl Stars Home Button (house glyph).
class DashBrawlHomeButton extends StatelessWidget {
  const DashBrawlHomeButton({super.key, this.onPressed, this.compact = false});

  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DashBrawlNavButton(
      onPressed: onPressed,
      compact: compact,
      semanticLabel: 'Home',
      icon: CustomPaint(
        size: Size(compact ? 20.0 : 24.0, compact ? 18.0 : 22.0),
        painter: _HomeHousePainter(),
      ),
    );
  }
}

class _HomeHousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;

    // Cartoon house with pitched roof and doorway notch
    final p = Path()
      ..moveTo(cx, cy - w * 0.38) // roof peak
      ..lineTo(cx + w * 0.44, cy - w * 0.04) // right roof eave
      ..lineTo(cx + w * 0.32, cy + w * 0.08) // right inset
      ..lineTo(cx + w * 0.32, cy + w * 0.36) // right bottom
      ..lineTo(cx + w * 0.11, cy + w * 0.36) // right door
      ..lineTo(cx + w * 0.11, cy + w * 0.16) // top of door
      ..lineTo(cx - w * 0.11, cy + w * 0.16)
      ..lineTo(cx - w * 0.11, cy + w * 0.36) // left door
      ..lineTo(cx - w * 0.32, cy + w * 0.36) // left bottom
      ..lineTo(cx - w * 0.32, cy + w * 0.08) // left inset
      ..lineTo(cx - w * 0.44, cy - w * 0.04) // left roof eave
      ..close();

    // Solid black drop shadow
    canvas.drawPath(
      p.shift(const Offset(0, 1.8)),
      Paint()..color = DashColors.pureBlack,
    );

    // Solid black stroke outline
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = DashColors.pureBlack,
    );

    // Pure white fill
    canvas.drawPath(p, Paint()..color = DashColors.textPrimary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
