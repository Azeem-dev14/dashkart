import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';

/// Menu-to-menu transition: a plain fade, no slide.
class DashPageRoute<T> extends PageRouteBuilder<T> {
  DashPageRoute({required this.page})
    : super(
        pageBuilder: (_, _, _) => page,
        transitionDuration: DashMotion.slow,
        reverseTransitionDuration: DashMotion.slow,
        transitionsBuilder: (context, anim, secondary, child) {
          final enter = CurvedAnimation(
            parent: anim,
            curve: DashMotionScope.curve(context, DashMotion.slowCurve),
          );
          return FadeTransition(opacity: enter, child: child);
        },
      );

  final Widget page;
}
