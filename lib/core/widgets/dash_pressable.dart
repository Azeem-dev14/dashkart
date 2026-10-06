import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:dashkart/core/audio/audio_manager.dart';
import 'package:dashkart/core/theme/theme.dart';

/// Shared press behaviour for every DashKart control.
///
/// Gives its [builder] a 0..1 press value rather than a bool, so a component
/// can interpolate a bevel collapsing, a face sinking, and a glow dimming
/// together instead of snapping between two states.
///
/// Press-down is fast and linear-ish; release overshoots slightly. That
/// asymmetry is what makes an arcade button feel sprung.
class DashPressable extends StatefulWidget {
  const DashPressable({
    super.key,
    required this.builder,
    this.onPressed,
    this.onLongPress,
    this.enabled = true,
    this.haptic = HapticFeedback.lightImpact,
    this.semanticLabel,
  });

  final ValueWidgetBuilder<double> builder;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool enabled;

  /// Called once on press-down. Null disables haptics for this control.
  final Future<void> Function()? haptic;
  final String? semanticLabel;

  @override
  State<DashPressable> createState() => _DashPressableState();
}

class _DashPressableState extends State<DashPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: DashMotion.tap,
    reverseDuration: DashMotion.release,
  );

  bool get _interactive => widget.enabled && widget.onPressed != null;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) {
    if (!_interactive) return;
    _c.duration = DashMotionScope.duration(context, DashMotion.tap);
    _c.forward();
    widget.haptic?.call();
    AudioManager.instance.playUiTap();
  }

  void _up([_]) {
    if (!_interactive) return;
    _c.reverseDuration = DashMotionScope.duration(context, DashMotion.release);
    _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Overshoot on release only. Driving the whole controller through a
    // symmetric curve would make press-down bounce too, which reads as mushy.
    final curved = CurvedAnimation(
      parent: _c,
      curve: DashMotionScope.curve(context, DashMotion.tapCurve),
      reverseCurve: DashMotionScope.curve(context, DashMotion.releaseCurve),
    );

    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _up,
        onTap: _interactive ? widget.onPressed : null,
        onLongPress: _interactive ? widget.onLongPress : null,
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, child) {
            final val = curved.value.clamp(0.0, 1.0);
            return widget.builder(context, val, child);
          },
        ),
      ),
    );
  }
}

/// Enters its child with a fade and a short upward slide, offset by [index] so
/// a row or grid staggers in rather than appearing all at once.
class DashEnter extends StatefulWidget {
  const DashEnter({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 24,
    this.duration = DashMotion.base,
  });

  final Widget child;
  final int index;
  final double offset;
  final Duration duration;

  @override
  State<DashEnter> createState() => _DashEnterState();
}

class _DashEnterState extends State<DashEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motionEnabled = DashMotionScope.of(context);
    if (!motionEnabled) {
      _c.duration = Duration.zero;
      _c.value = 1.0;
      return;
    }
    final stagger = DashMotion.staggerFor(widget.index);
    final total = widget.duration + stagger;
    _c.duration = total;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stagger = DashMotion.staggerFor(widget.index);
    final total = widget.duration + stagger;
    final startFrac = total.inMicroseconds == 0
        ? 0.0
        : (stagger.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);

    final t = CurvedAnimation(
      parent: _c,
      curve: startFrac >= 1.0
          ? DashMotionScope.curve(context, DashMotion.baseCurve)
          : Interval(
              startFrac,
              1.0,
              curve: DashMotionScope.curve(context, DashMotion.baseCurve),
            ),
    );
    return AnimatedBuilder(
      animation: t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: t.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - t.value.clamp(0.0, 1.0))),
          child: child,
        ),
      ),
    );
  }
}
