import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_icon.dart';
import 'package:dashkart/core/widgets/dash_outlined_text.dart';
import 'package:dashkart/core/widgets/dash_pressable.dart';

enum DashButtonVariant { primary, turbo, success, danger, ghost }

enum DashButtonSize {
  sm(height: 40, padding: 18, gap: 6),
  md(height: 52, padding: 20, gap: 8),
  lg(height: 64, padding: 28, gap: 10),

  /// Reserved for RACE. There is exactly one hero button in the app.
  hero(height: 76, padding: 36, gap: 12);

  const DashButtonSize({
    required this.height,
    required this.padding,
    required this.gap,
  });

  final double height;
  final double padding;
  final double gap;
}

/// The primary DashKart action button.
///
/// A gradient face sitting on a hard, unblurred bevel — a solid darker edge
/// beneath it, not a soft drop shadow. Pressing collapses the bevel from 4dp to
/// 1dp and drops the face by the difference, so the button physically sinks
/// into its own edge rather than just dimming. That is the whole trick behind
/// the arcade feel.
class DashButton extends StatelessWidget {
  const DashButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = DashButtonVariant.primary,
    this.size = DashButtonSize.md,
    this.glow = false,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final DashIcons? icon;
  final DashButtonVariant variant;
  final DashButtonSize size;

  /// Adds the coloured halo that makes a button read as lit. Reserve it for the
  /// primary action on a screen; every button glowing is the same as none.
  final bool glow;
  final bool expand;
  final bool loading;

  static const _bevelDepth = 8.0;
  static const _bevelPressed = 2.0;

  List<Color> get _face => switch (variant) {
    DashButtonVariant.primary => DashGradients.speed,
    DashButtonVariant.turbo => DashGradients.turbo,
    DashButtonVariant.success => const [
      Color(0xFF4DEE8C),
      DashColors.neonGreen,
      Color(0xFF13A44B),
    ],
    DashButtonVariant.danger => const [
      Color(0xFFFF6B80),
      DashColors.racingRed,
      Color(0xFFC4172F),
    ],
    DashButtonVariant.ghost => const [Color(0x00000000), Color(0x00000000)],
  };

  Color get _edge => switch (variant) {
    DashButtonVariant.primary => DashColors.purple.s700,
    DashButtonVariant.turbo => DashColors.orange.s700,
    DashButtonVariant.success => DashColors.green.s700,
    DashButtonVariant.danger => DashColors.red.s700,
    DashButtonVariant.ghost => DashColors.stroke,
  };

  Color get _glowColor => switch (variant) {
    DashButtonVariant.primary => DashColors.purple.s400,
    DashButtonVariant.turbo => DashColors.orange.s400,
    DashButtonVariant.success => DashColors.neonGreen,
    DashButtonVariant.danger => DashColors.racingRed,
    DashButtonVariant.ghost => DashColors.strokeStrong,
  };

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        (size == DashButtonSize.sm ? DashType.buttonSm : DashType.button)
            .copyWith(
              fontSize: size == DashButtonSize.hero ? 24 : null,
              color: variant == DashButtonVariant.ghost
                  ? DashColors.textPrimary
                  : DashColors.textOnBrand,
              // A hard ink shadow under the label. Party-game lettering is never set
              // flat on its face; it sits proud of it.
              shadows: variant == DashButtonVariant.ghost
                  ? null
                  : const [
                      Shadow(color: Color(0x8A1A0733), offset: Offset(0, 2)),
                    ],
            );

    return DashPressable(
      onPressed: _enabled ? onPressed : null,
      enabled: _enabled,
      semanticLabel: label,
      builder: (context, rawPress, _) {
        final press = rawPress.clamp(0.0, 1.0);
        final depth = (_bevelDepth - (_bevelDepth - _bevelPressed) * press)
            .clamp(0.0, double.infinity);
        final sink = (_bevelDepth - depth).clamp(0.0, double.infinity);

        return Opacity(
          opacity: _enabled ? 1 : 0.4,
          // Reserve the full bevel height at every press depth, so the button
          // sinks in place instead of nudging its neighbours as it animates.
          child: Padding(
            padding: EdgeInsets.only(top: sink, bottom: depth),
            child: Container(
              height: size.height,
              width: expand ? double.infinity : null,
              // No padding here: the gloss and inner ring below are painted on
              // the full face, so the label's inset is applied to the label
              // alone, further in.
              decoration: BoxDecoration(
                gradient: variant == DashButtonVariant.ghost
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _face,
                      ),
                borderRadius: DashRadius.mdAll,
                // Every face — not just ghost — sits on a thick ink line, so
                // the button reads as a cut-out sticker rather than a flat
                // gradient chip.
                border: Border.all(
                  color: variant == DashButtonVariant.ghost
                      ? DashColors.stroke
                      : DashColors.pureBlack,
                  width: DashStroke.thick,
                ),
                boxShadow: [
                  DashElevation.bevel(_edge, depth),
                  if (variant != DashButtonVariant.ghost) DashElevation.ambient,
                  if (glow && _enabled)
                    DashElevation.glow(
                      _glowColor,
                      opacity: 0.45 * (1 - press * 0.5),
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Top specular sheen band across the face
                  if (variant != DashButtonVariant.ghost)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 2.0,
                      child: Container(
                        color: DashColors.textPrimary.withValues(alpha: 0.65),
                      ),
                    ),
                  // Right edge subtle specular highlight
                  if (variant != DashButtonVariant.ghost)
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      width: 2.0,
                      child: Container(
                        color: DashColors.textPrimary.withValues(alpha: 0.22),
                      ),
                    ),
                  // The Row itself — not a Center wrapper — is the Stack's
                  // sizing child, so it must handle its own centering: its
                  // mainAxisAlignment does that without risking unbounded
                  // constraints when this button sits in a width-unbounded
                  // parent (e.g. an unconstrained Row of buttons).
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.padding),
                    child: Row(
                      mainAxisSize: expand
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (loading)
                          _ButtonSpinner(color: textStyle.color!)
                        else ...[
                          if (icon != null) ...[
                            DashIcon(
                              icon!,
                              size: size == DashButtonSize.sm
                                  ? DashIconSize.sm
                                  : DashIconSize.md,
                              color: textStyle.color!,
                            ),
                            SizedBox(width: size.gap),
                          ],
                          Flexible(
                            child: variant == DashButtonVariant.ghost
                                // Ghost is the one button with no chrome — a
                                // sticker outline on its label would fight
                                // that flatness, so it stays plain.
                                ? Text(
                                    label.toUpperCase(),
                                    style: textStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : DashOutlinedText(
                                    label.toUpperCase(),
                                    style: textStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ],
                    ),
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

class _ButtonSpinner extends StatefulWidget {
  const _ButtonSpinner({required this.color});

  final Color color;

  @override
  State<_ButtonSpinner> createState() => _ButtonSpinnerState();
}

class _ButtonSpinnerState extends State<_ButtonSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) =>
            CustomPaint(painter: _SpinnerPainter(_c.value, widget.color)),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect.deflate(1.5), t * 6.283185, 2.4, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.t != t || old.color != color;
}
