import 'package:flutter/widgets.dart';

import 'package:dashkart/core/feedback/haptics.dart';
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
    this.pressed,
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

  /// When non-null the button is *controlled*: it draws this state and ignores
  /// touches itself, because something above it owns the pointer. Steering
  /// does this so one thumb can slide across both buttons.
  final bool? pressed;

  @override
  State<DashDriveButton> createState() => _DashDriveButtonState();
}

class _DashDriveButtonState extends State<DashDriveButton> {
  bool _down = false;

  void _set(bool value) {
    if (widget.pressed != null) return;
    if (!widget.enabled || _down == value) return;
    if (mounted) setState(() => _down = value);
    widget.onChanged(value);
    if (value) Haptics.light();
  }

  @override
  Widget build(BuildContext context) {
    final down = widget.pressed ?? _down;
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
          scale: down ? 0.94 : 1,
          duration: DashMotionScope.duration(context, DashMotion.tap),
          curve: DashMotionScope.curve(context, DashMotion.tapCurve),
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.35,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: down && widget.glowColor != null
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
                      pressed: down,
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
                            alpha: down ? 0.9 : 0.75,
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
/// scheme produced it — the analog pad below and the phone gamepad feed the
/// same signal.
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

  /// The one pointer steering. A second finger landing on the cluster is
  /// ignored rather than fighting the first.
  int? _pointer;

  /// Width of the whole cluster: two faces and the gap between them.
  double get _width => widget.size * 2 + DashSpace.x2;

  void _apply(double dx) {
    // Whichever half the thumb is over, so sliding from one button to the
    // other hands over cleanly. Separate buttons each owned their own touch,
    // which left the first held and the second dead when a thumb slid across.
    final right = dx >= _width / 2;
    if (right == _right && _left == !right) return;
    setState(() {
      _right = right;
      _left = !right;
    });
    Haptics.light();
    _emit();
  }

  void _release() {
    _pointer = null;
    if (!_left && !_right) return;
    setState(() {
      _left = false;
      _right = false;
    });
    _emit();
  }

  void _emit() {
    widget.onSteer((_right ? 1.0 : 0.0) - (_left ? 1.0 : 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        if (_pointer != null) return;
        _pointer = e.pointer;
        _apply(e.localPosition.dx);
      },
      onPointerMove: (e) {
        if (e.pointer == _pointer) _apply(e.localPosition.dx);
      },
      onPointerUp: (e) {
        if (e.pointer == _pointer) _release();
      },
      onPointerCancel: (e) {
        if (e.pointer == _pointer) _release();
      },
      child: SizedBox(
        width: _width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DashDriveButton(
              shape: 'direction_left',
              semanticLabel: 'Steer left',
              size: widget.size,
              tint: DashColors.blue.s200,
              glowColor: DashColors.blue.s400,
              pressed: _left,
              onChanged: (_) {},
            ),
            const SizedBox(width: DashSpace.x2),
            DashDriveButton(
              shape: 'direction_right',
              semanticLabel: 'Steer right',
              size: widget.size,
              tint: DashColors.blue.s200,
              glowColor: DashColors.blue.s400,
              pressed: _right,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}

/// Analog steering: a thumb pad that reports how far it has been slid, not
/// merely which side was pressed.
///
/// The settings screen offered a steering mode for a control scheme that did
/// not exist. This is the one that does. Press anywhere on the pad and slide:
/// the signal is the horizontal distance from where the thumb landed, divided
/// by [travel], so a long sweeping bend can be held at a third of lock
/// instead of sawing full lock on and off.
///
/// Anchoring to the touch-down point rather than to the pad's centre is what
/// makes it usable without looking: there is no "centre" to find first.
class DashSteeringPad extends StatefulWidget {
  const DashSteeringPad({
    super.key,
    required this.onSteer,
    this.width = 170,
    this.height = 84,
  });

  final ValueChanged<double> onSteer;
  final double width;
  final double height;

  /// Thumb travel, in logical pixels, that corresponds to full lock. Short
  /// enough to reach without shifting grip.
  static const travel = 52.0;

  @override
  State<DashSteeringPad> createState() => _DashSteeringPadState();
}

class _DashSteeringPadState extends State<DashSteeringPad> {
  double? _anchorX;
  double _value = 0;

  void _emit(double value) {
    final clamped = value.clamp(-1.0, 1.0);
    if (clamped == _value) return;
    setState(() => _value = clamped);
    widget.onSteer(clamped);
  }

  void _down(Offset local) {
    _anchorX = local.dx;
    Haptics.light();
    _emit(0);
  }

  void _move(Offset local) {
    final anchor = _anchorX;
    if (anchor == null) return;
    _emit((local.dx - anchor) / DashSteeringPad.travel);
  }

  void _up() {
    _anchorX = null;
    // Centres on release, the way a sprung wheel does. Without this the kart
    // would hold the last lock the thumb happened to leave.
    _emit(0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: 'Steering',
      value: _value == 0
          ? 'centred'
          : '${(_value.abs() * 100).round()}% '
                '${_value < 0 ? 'left' : 'right'}',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _down(e.localPosition),
        onPointerMove: (e) => _move(e.localPosition),
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _SteeringPadPainter(
              value: _value,
              engaged: _anchorX != null,
            ),
          ),
        ),
      ),
    );
  }
}

class _SteeringPadPainter extends CustomPainter {
  const _SteeringPadPainter({required this.value, required this.engaged});

  final double value;
  final bool engaged;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final track = RRect.fromRectAndRadius(
      rect.deflate(2),
      Radius.circular(size.height / 2),
    );

    canvas.drawRRect(
      track,
      Paint()..color = DashColors.surfaceSunken.withValues(alpha: 0.72),
    );
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = DashColors.pureBlack,
    );

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Centre detent, so "straight ahead" is a visible place.
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.22),
      Offset(cx, cy + size.height * 0.22),
      Paint()
        ..strokeWidth = 2
        ..color = DashColors.strokeStrong.withValues(alpha: 0.8),
    );

    // The thumb, offset by the current lock.
    final knobX = cx + value * (size.width / 2 - size.height * 0.34);
    final knobR = size.height * 0.30;
    if (engaged) {
      canvas.drawCircle(
        Offset(knobX, cy),
        knobR * 1.5,
        Paint()..color = DashColors.blue.s400.withValues(alpha: 0.28),
      );
    }
    canvas.drawCircle(
      Offset(knobX, cy),
      knobR,
      Paint()..color = engaged ? DashColors.blue.s200 : DashColors.blue.s300,
    );
    canvas.drawCircle(
      Offset(knobX, cy),
      knobR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = DashColors.pureBlack,
    );

    // Two chevrons on the knob, matching the button art's direction glyphs.
    final chevron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = DashColors.darkNavy.withValues(alpha: 0.75);
    for (final side in const [-1.0, 1.0]) {
      final x = knobX + side * knobR * 0.42;
      canvas.drawPath(
        Path()
          ..moveTo(x - side * knobR * 0.18, cy - knobR * 0.26)
          ..lineTo(x + side * knobR * 0.18, cy)
          ..lineTo(x - side * knobR * 0.18, cy + knobR * 0.26),
        chevron,
      );
    }
  }

  @override
  bool shouldRepaint(_SteeringPadPainter old) =>
      old.value != value || old.engaged != engaged;
}
