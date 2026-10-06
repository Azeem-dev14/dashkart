import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_brawl_ink_text.dart';
import 'package:dashkart/core/widgets/dash_brawl_nav_buttons.dart';

/// Reusable Brawl Stars-style App Bar.
///
/// Features:
/// * Left: Back (`<`) button — automatically pops to the previous screen via
///   `Navigator.of(context).maybePop()` by default, or runs custom [onBack].
/// * Center: 3D cartoon title with downward block extrusion and ink stroke
///   ([BrawlTitleText] for plain [title], or custom [titleWidget] like [BrawlCountTitle]).
/// * Right: Home button — returns to root menu by default via
///   `Navigator.of(context).popUntil((route) => route.isFirst)`, or runs custom [onHome].
/// * Fully responsive: automatically detects compact mode from context if not specified.
class DashBrawlAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashBrawlAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.onBack,
    this.onHome,
    this.showBack = true,
    this.showHome = true,
    this.compact,
    this.trailing,
  }) : assert(
         title != null || titleWidget != null,
         'Either title or titleWidget must be provided',
       );

  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final bool showBack;
  final bool showHome;
  final bool? compact;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(42.0);

  @override
  Widget build(BuildContext context) {
    final isCompact = compact ?? DashBreakpoint.of(context).isCompact;
    final handleBack = onBack ?? () => Navigator.of(context).maybePop();
    final handleHome =
        onHome ??
        () => Navigator.of(context).popUntil((route) => route.isFirst);

    return SizedBox(
      height: isCompact ? 36.0 : 42.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: DashBrawlBackButton(
                onPressed: handleBack,
                compact: isCompact,
              ),
            ),
          titleWidget ??
              (title != null
                  ? BrawlTitleText(title!, fontSize: isCompact ? 20.0 : 24.0)
                  : const SizedBox.shrink()),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing!)
          else if (showHome)
            Align(
              alignment: Alignment.centerRight,
              child: DashBrawlHomeButton(
                onPressed: handleHome,
                compact: isCompact,
              ),
            ),
        ],
      ),
    );
  }
}

/// Backwards compatibility alias for [DashBrawlAppBar].
typedef DashBrawlTopBar = DashBrawlAppBar;
