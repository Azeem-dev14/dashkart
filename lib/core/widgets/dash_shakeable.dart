import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';

/// Nudges its child side to side whenever [trigger] changes — used to answer
/// a tap on locked content, which would otherwise look like a dead control.
///
/// Bump [trigger] (e.g. a counter incremented in `setState`) to replay the
/// shake; `trigger == 0` never plays, so a screen's initial state is still.
class DashShakeable extends StatefulWidget {
  const DashShakeable({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<DashShakeable> createState() => _DashShakeableState();
}

class _DashShakeableState extends State<DashShakeable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(DashShakeable old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger != 0) {
      if (DashMotionScope.of(context)) _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // Three decaying swings.
        final t = _c.value;
        final dx = t == 0 ? 0.0 : (1 - t) * 6 * _sin3(t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }

  static double _sin3(double t) {
    const twoPi = 6.283185307179586;
    return (t * twoPi * 3).remainder(twoPi) < 3.14159 ? 1 : -1;
  }
}
