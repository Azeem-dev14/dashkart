import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/core/scaffold/dash_brawl_screen.dart';

/// Last step of the pre-race flow, after kart and track: who the player is
/// racing. One tap commits — styled with high-energy Brawl Stars comic cards,
/// slanted badges, metallic hero emblems, and arcade action buttons.
class RaceModeScreen extends StatelessWidget {
  const RaceModeScreen({
    super.key,
    this.onBack,
    required this.onBots,
    required this.onMultiplayer,
  });

  final VoidCallback? onBack;
  final VoidCallback onBots;
  final VoidCallback onMultiplayer;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;

    return DashBrawlScreen(
      title: 'CHOOSE RACE',
      onBack: onBack,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16.0 : 24.0,
            vertical: 4.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BrawlModeCard(
                title: 'VS BOTS',
                emblemGradient: const [
                  Color(0xFF4EE2EC),
                  Color(0xFF7A1AE5),
                  Color(0xFF3B0075),
                ],
                emblemGlow: const Color(0x778A2BE2),
                icon: DashIcons.steeringWheel,
                chipsText: '🏁 3 LAPS',
                subtitle: 'Race the circuit solo anytime',
                buttonLabel: 'PLAY SOLO',
                buttonGradient: const [Color(0xFFFFDD00), Color(0xFFFFAE00)],
                buttonBevel: const Color(0xFFC77800),
                burstColors: const [
                  Color(0xFF9E2CFB),
                  Color(0xFF7614D9),
                  Color(0xFF4C0898),
                  Color(0xFF260252),
                ],
                onTap: onBots,
              ),
              SizedBox(width: compact ? 20.0 : 32.0),
              _BrawlModeCard(
                title: 'MULTIPLAYER',
                emblemGradient: const [
                  Color(0xFFFFEA60),
                  Color(0xFFFF4800),
                  Color(0xFF880500),
                ],
                emblemGlow: const Color(0x77FF4500),
                icon: DashIcons.target,
                chipsText: 'HOST / JOIN',
                subtitle: 'Head-to-head with friends',
                buttonLabel: 'PLAY ONLINE',
                buttonGradient: const [Color(0xFF00E65A), Color(0xFF00A83A)],
                buttonBevel: const Color(0xFF006B24),
                burstColors: const [
                  Color(0xFFFF8500),
                  Color(0xFFE84400),
                  Color(0xFFA61400),
                  Color(0xFF5E0500),
                ],
                onTap: onMultiplayer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrawlModeCard extends StatelessWidget {
  const _BrawlModeCard({
    required this.title,
    required this.emblemGradient,
    required this.emblemGlow,
    required this.icon,
    required this.chipsText,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonGradient,
    required this.buttonBevel,
    required this.burstColors,
    required this.onTap,
  });

  final String title;
  final List<Color> emblemGradient;
  final Color emblemGlow;
  final DashIcons icon;
  final String chipsText;
  final String subtitle;
  final String buttonLabel;
  final List<Color> buttonGradient;
  final Color buttonBevel;
  final List<Color> burstColors;
  final VoidCallback onTap;

  static const _skewX = -0.09;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    final width = compact ? 232.0 : 264.0;
    final height = compact ? 272.0 : 304.0;
    final cardRadius = compact ? 10.0 : 8.0;
    const strokeWidth = 3.5;
    final innerRadius = (cardRadius - strokeWidth).clamp(2.0, 10.0);

    return DashPressable(
      onPressed: onTap,
      semanticLabel: '$title, $subtitle',
      builder: (context, press, _) {
        final pressOffset = press.clamp(0.0, 1.0) * 4.0;
        return Padding(
          padding: EdgeInsets.only(
            top: pressOffset,
            bottom: 4.0 - pressOffset,
            left: 10.0,
            right: 10.0,
          ),
          child: Transform(
            transform: Matrix4.skewX(_skewX),
            alignment: Alignment.center,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(
                  color: DashColors.pureBlack,
                  width: strokeWidth,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x88000000),
                    offset: Offset(0, 5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(innerRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Comic radial burst background
                    CustomPaint(
                      painter: _CardBurstPainter(
                        colors: burstColors,
                        stops: const [0.0, 0.40, 0.75, 1.0],
                      ),
                    ),

                    // Top gloss highlight
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: height * 0.35,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x28FFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),

                    // Interior content (counter-skewed so text and icons stay upright)
                    Transform(
                      transform: Matrix4.skewX(-_skewX),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 12.0 : 16.0,
                          vertical: compact ? 12.0 : 14.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 3D Mode title
                            BrawlInkText(
                              title,
                              fontSize: compact ? 22.0 : 25.0,
                              weight: BrawlInkWeight.heavy,
                            ),

                            // Hero emblem with glowing backdrop
                            _ModeEmblem(
                              icon: icon,
                              gradient: emblemGradient,
                              glowColor: emblemGlow,
                              compact: compact,
                            ),

                            // Mode feature chips
                            _ModeChips(text: chipsText, compact: compact),

                            // Subtitle
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'LilitaOne',
                                fontStyle: FontStyle.italic,
                                fontSize: compact ? 10.5 : 12.0,
                                color: DashColors.textPrimary,
                                shadows: const [
                                  Shadow(
                                    color: DashColors.pureBlack,
                                    offset: Offset(1.2, 1.2),
                                    blurRadius: 0,
                                  ),
                                  Shadow(
                                    color: DashColors.pureBlack,
                                    offset: Offset(-1.2, 1.2),
                                    blurRadius: 0,
                                  ),
                                  Shadow(
                                    color: DashColors.pureBlack,
                                    offset: Offset(0, 1.5),
                                    blurRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),

                            // Bottom arcade action button
                            _ModeActionButton(
                              label: buttonLabel,
                              gradient: buttonGradient,
                              bevelColor: buttonBevel,
                              compact: compact,
                            ),
                          ],
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

class _ModeEmblem extends StatelessWidget {
  const _ModeEmblem({
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.compact,
  });

  final DashIcons icon;
  final List<Color> gradient;
  final Color glowColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 68.0 : 78.0;
    final iconSize = compact ? 36.0 : 42.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Outer glow aura
        Container(
          width: size * 1.3,
          height: size * 1.3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [glowColor, const Color(0x00000000)],
              stops: const [0.2, 1.0],
            ),
          ),
        ),

        // Main circular emblem
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            border: Border.all(color: DashColors.pureBlack, width: 2.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                offset: Offset(0, 4.0),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top gloss crescent
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size * 0.45,
                child: ClipOval(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              ),

              // Hero Icon with dark drop-shadow
              Transform.translate(
                offset: const Offset(0, 1.5),
                child: DashIcon(
                  icon,
                  size: iconSize,
                  color: DashColors.pureBlack,
                ),
              ),
              DashIcon(icon, size: iconSize, color: DashColors.textPrimary),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeChips extends StatelessWidget {
  const _ModeChips({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.0 : 12.0,
        vertical: compact ? 3.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC081224),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: DashColors.pureBlack, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(0, 2.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'LilitaOne',
          fontSize: compact ? 10.0 : 11.0,
          letterSpacing: 0.4,
          color: const Color(0xFF3DF2FF),
          shadows: const [
            Shadow(
              color: DashColors.pureBlack,
              offset: Offset(1.0, 1.0),
              blurRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeActionButton extends StatelessWidget {
  const _ModeActionButton({
    required this.label,
    required this.gradient,
    required this.bevelColor,
    required this.compact,
  });

  final String label;
  final List<Color> gradient;
  final Color bevelColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 38.0 : 42.0;
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 7.0 : 8.0),
        border: Border.all(color: DashColors.pureBlack, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: bevelColor,
            offset: const Offset(0, 3.0),
            blurRadius: 0,
          ),
          const BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 4.5),
            blurRadius: 0,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top shine highlight
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(compact ? 5.0 : 6.0),
                  topRight: Radius.circular(compact ? 5.0 : 6.0),
                ),
                color: const Color(0x35FFFFFF),
              ),
            ),
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -1.0),
              child: BrawlInkText(
                label,
                fontSize: compact ? 15.0 : 16.5,
                weight: BrawlInkWeight.heavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBurstPainter extends CustomPainter {
  const _CardBurstPainter({required this.colors, required this.stops});

  final List<Color> colors;
  final List<double> stops;

  static const _rayColor = Color(0x30000000);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);

    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(center, size.height * 0.75, colors, stops);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final rayPaint = Paint()..color = _rayColor;
    const rayCount = 12;
    final maxR = math.max(size.width, size.height) * 1.4;

    for (var i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi) / rayCount - 0.25;
      const spread = (2 * math.pi / rayCount) * 0.35;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + maxR * math.cos(angle - spread * 0.5),
          center.dy + maxR * math.sin(angle - spread * 0.5),
        )
        ..lineTo(
          center.dx + maxR * math.cos(angle + spread * 0.5),
          center.dy + maxR * math.sin(angle + spread * 0.5),
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardBurstPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
