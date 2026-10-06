import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_button.dart';
import 'package:dashkart/core/widgets/dash_icon.dart';
import 'package:dashkart/core/widgets/dash_pressable.dart';

/// Icon-only counterpart to [DashButton]. Same bevel, same sink, same variants.
///
/// Used for back, pause, carousel arrows, and anything where a label would be
/// noise. Always carries a [semanticLabel] because the glyph alone tells a
/// screen reader nothing.
class DashIconButton extends StatelessWidget {
  const DashIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.variant = DashButtonVariant.ghost,
    this.size = 52,
    this.round = true,
    this.glow = false,
  });

  final DashIcons icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final DashButtonVariant variant;
  final double size;
  final bool round;
  final bool glow;

  static const _bevelDepth = 4.0;

  List<Color> get _face => switch (variant) {
    DashButtonVariant.primary => DashGradients.speed,
    DashButtonVariant.turbo => DashGradients.turbo,
    DashButtonVariant.success => const [
      Color(0xFF4DEE8C),
      DashColors.neonGreen,
    ],
    DashButtonVariant.danger => const [Color(0xFFFF6B80), DashColors.racingRed],
    DashButtonVariant.ghost => const [Color(0xCC151D45), Color(0xCC0F1636)],
  };

  Color get _edge => switch (variant) {
    DashButtonVariant.primary => DashColors.blue.s700,
    DashButtonVariant.turbo => DashColors.orange.s700,
    DashButtonVariant.success => const Color(0xFF0B6E33),
    DashButtonVariant.danger => const Color(0xFF8E1022),
    DashButtonVariant.ghost => DashColors.surfaceSunken,
  };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return DashPressable(
      onPressed: onPressed,
      enabled: enabled,
      semanticLabel: semanticLabel,
      builder: (context, press, _) {
        final depth = _bevelDepth - 3 * press;
        final sink = _bevelDepth - depth;

        return Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Padding(
            padding: EdgeInsets.only(top: sink, bottom: depth),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _face,
                ),
                borderRadius: round
                    ? BorderRadius.circular(size / 2)
                    : DashRadius.mdAll,
                border: Border.all(
                  color: variant == DashButtonVariant.ghost
                      ? DashColors.stroke
                      : DashColors.pureBlack,
                  width: 2.2,
                ),
                boxShadow: [
                  DashElevation.bevel(_edge, depth),
                  DashElevation.ambient,
                  if (glow && enabled)
                    DashElevation.glow(
                      variant == DashButtonVariant.turbo
                          ? DashColors.orange.s400
                          : DashColors.blue.s400,
                      opacity: 0.4 * (1 - press * 0.5),
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Top specular highlight sheen
                  if (variant != DashButtonVariant.ghost)
                    Positioned(
                      left: 4,
                      right: 4,
                      top: 0,
                      height: 1.8,
                      child: Container(
                        color: DashColors.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  DashIcon(
                    icon,
                    size: size * 0.42,
                    color: DashColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
