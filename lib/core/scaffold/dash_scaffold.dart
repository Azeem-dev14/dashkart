import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';

/// The standard menu frame: gradient backdrop, safe area, and a floating header
/// composed from a back button and a title.
///
/// Deliberately not a Material Scaffold with an AppBar — DashKart's header
/// floats over the backdrop rather than sitting in an opaque bar.
class DashScaffold extends StatelessWidget {
  const DashScaffold({
    super.key,
    required this.child,
    this.title,
    this.onBack,
    this.trailing,
    this.backdrop,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Replaces the gradient, e.g. with a live 3D scene.
  final Widget? backdrop;

  static const headerHeight = 68.0;

  @override
  Widget build(BuildContext context) {
    final bp = DashBreakpoint.of(context);
    final hasHeader = title != null || onBack != null || trailing != null;

    return DecoratedBox(
      decoration: dashMenuBackdrop,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ?backdrop,
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: bp.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasHeader)
                    SizedBox(
                      height: headerHeight,
                      child: Row(
                        children: [
                          if (onBack != null)
                            DashIconButton(
                              icon: DashIcons.back,
                              semanticLabel: 'Back',
                              size: 44,
                              onPressed: onBack,
                            )
                          else
                            const SizedBox(width: 44),
                          Expanded(
                            child: title == null
                                ? const SizedBox.shrink()
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: Text(
                                      title!.toUpperCase(),
                                      style: DashType.brandL.copyWith(
                                        fontSize: bp.isCompact ? 26 : 32,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                  ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: trailing,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: bp.maxContentWidth,
                            maxHeight: constraints.maxHeight,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
