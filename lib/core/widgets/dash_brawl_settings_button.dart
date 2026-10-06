import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_pressable.dart';

/// Exact replica of the Brawl Stars top-right menu/settings button.
///
/// Features:
/// * Parallelogram silhouette slanted at `-0.09` skew
/// * Dark slate gradient face (`#353E54` -> `#263347`) with top specular sheen
/// * Right-edge subtle specular sheen line
/// * Hard dark bottom bevel that collapses on press
/// * Heavy solid black border all around
/// * Three iconic horizontal white bars with rounded ends
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
    final barW = compact ? 21.0 : 25.0;
    final barH = compact ? 4.0 : 4.6;
    final barGap = compact ? 2.4 : 2.8;

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

                            // The 3 Horizontal White Hamburger Bars (Brawl Stars replica)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildBar(barW, barH),
                                  SizedBox(height: barGap),
                                  _buildBar(barW, barH),
                                  SizedBox(height: barGap),
                                  _buildBar(barW, barH),
                                ],
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

  Widget _buildBar(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: DashColors.textPrimary,
        borderRadius: BorderRadius.circular(1.6),
        border: Border.all(color: DashColors.pureBlack, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: DashColors.pureBlack,
            offset: Offset(0, 1.8),
            blurRadius: 0,
          ),
        ],
      ),
    );
  }
}
