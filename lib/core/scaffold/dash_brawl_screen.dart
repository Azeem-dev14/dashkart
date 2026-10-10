import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';

/// The Brawl-style screen frame: [BrawlLobbyBackdrop], notch-aware margins,
/// and a [DashBrawlAppBar], with [child] filling the rest.
///
/// The frame every menu screen shares: Main Menu, Kart Detail and the rest.
class DashBrawlScreen extends StatelessWidget {
  const DashBrawlScreen({
    super.key,
    this.title,
    this.titleWidget,
    required this.child,
    this.onBack,
    this.onHome,
    this.showBack = true,
    this.showHome = true,
    this.heroButton,
    this.marginSideCompact = 12.0,
    this.marginSideRegular = 16.0,
  }) : assert(
         title != null || titleWidget != null,
         'Either title or titleWidget must be provided',
       );

  final String? title;
  final Widget? titleWidget;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final bool showBack;
  final bool showHome;

  /// The one hero action (PLAY, SELECT/NEXT, GO, …), pinned bottom-right at
  /// the screen's own edge margin — the same spot on every Brawl-style
  /// screen, so every primary action in the app reads as one template. Sits
  /// above [child] in the same margin frame, not inset inside it, matching
  /// how Kart Detail and Main Menu place theirs.
  final Widget? heroButton;

  final double marginSideCompact;
  final double marginSideRegular;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    final margins = DashSafeMargins.of(
      context,
      sideCompact: marginSideCompact,
      sideRegular: marginSideRegular,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        const BrawlLobbyBackdrop(),
        Positioned(
          top: margins.top,
          left: margins.left,
          right: margins.right,
          child: DashBrawlAppBar(
            title: title,
            titleWidget: titleWidget,
            onBack: onBack,
            onHome: onHome,
            showBack: showBack,
            showHome: showHome,
            compact: compact,
          ),
        ),
        Positioned(
          top: margins.top + (compact ? 44.0 : 50.0),
          left: margins.left,
          right: margins.right,
          bottom: margins.bottom,
          child: child,
        ),
        if (heroButton != null)
          Positioned(
            right: margins.right,
            bottom: margins.bottom,
            child: heroButton!,
          ),
      ],
    );
  }
}
