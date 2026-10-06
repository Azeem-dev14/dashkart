import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_icon.dart';

/// A driving control built on Kenney's Mobile Controls art.
///
/// The pack ships a matching `*_highlight` variant for every button shape, so
/// the pressed state is real artwork rather than a runtime tint — the face
/// genuinely changes, it does not just darken. Glow, scale, and haptics are
/// layered on top.
///
/// Held rather than tapped: [onChanged] fires true on press and false on
/// release, because steering and throttle are continuous inputs.
class DashDriveButton extends StatefulWidget {
  const DashDriveButton({
    super.key,
    required this.shape,
    required this.semanticLabel,
    required this.onChanged,
    this.icon,
    this.size = DashTouch.accelerate,
    this.tint,
    this.glowColor,
    this.enabled = true,
  });

  /// Basename in assets/images/ui/controls/, e.g. `button_circle_wide`.
  final String shape;
  final String semanticLabel;
  final ValueChanged<bool> onChanged;
  final DashIcons? icon;
  final double size;
  final Color? tint;
  final Color? glowColor;
  final bool enabled;

  @override
  State<DashDriveButton> createState() => _DashDriveButtonState();
}

class _DashDriveButtonState extends State<DashDriveButton> {
  bool _down = false;

  void _set(bool value) {
    if (!widget.enabled || _down == value) return;
    if (mounted) setState(() => _down = value);
    widget.onChanged(value);
    if (value) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: DashMotionScope.duration(context, DashMotion.tap),
          curve: DashMotionScope.curve(context, DashMotion.tapCurve),
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.35,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _down && widget.glowColor != null
                    ? [
                        DashElevation.glow(
                          widget.glowColor!,
                          opacity: 0.5,
                          blur: 26,
                        ),
                      ]
                    : null,
              ),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DashControlFace(
                      widget.shape,
                      size: widget.size,
                      pressed: _down,
                      tint: widget.tint,
                    ),
                    if (widget.icon != null)
                      Padding(
                        // The Kenney faces are visually top-weighted; nudging
                        // the glyph down centres it on the face rather than on
                        // the bounding box.
                        padding: EdgeInsets.only(bottom: widget.size * 0.06),
                        child: DashIcon(
                          widget.icon!,
                          size: widget.size * 0.42,
                          color: DashColors.darkNavy.withValues(
                            alpha: _down ? 0.9 : 0.75,
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
    );
  }
}

/// The steering cluster: two held direction buttons.
///
/// Reports -1, 0, or 1 so the race controller does not care which control
/// scheme produced it — a joystick or tilt source can feed the same signal.
class DashSteering extends StatefulWidget {
  const DashSteering({
    super.key,
    required this.onSteer,
    this.size = DashTouch.steer,
  });

  final ValueChanged<double> onSteer;
  final double size;

  @override
  State<DashSteering> createState() => _DashSteeringState();
}

class _DashSteeringState extends State<DashSteering> {
  bool _left = false;
  bool _right = false;

  void _emit() {
    widget.onSteer((_right ? 1.0 : 0.0) - (_left ? 1.0 : 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DashDriveButton(
          shape: 'direction_left',
          semanticLabel: 'Steer left',
          size: widget.size,
          tint: DashColors.blue.s200,
          glowColor: DashColors.blue.s400,
          onChanged: (v) {
            _left = v;
            _emit();
          },
        ),
        const SizedBox(width: DashSpace.x2),
        DashDriveButton(
          shape: 'direction_right',
          semanticLabel: 'Steer right',
          size: widget.size,
          tint: DashColors.blue.s200,
          glowColor: DashColors.blue.s400,
          onChanged: (v) {
            _right = v;
            _emit();
          },
        ),
      ],
    );
  }
}
