import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Spacing scale, 4dp base. See docs/design-system.md § 4.
abstract final class DashSpace {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
  static const x16 = 64.0;
  static const x20 = 80.0;

  /// Screen gutter. Drops to [x4] on compact widths.
  static const gutter = x6;
  static const gutterCompact = x4;

  /// Padding inside a [DashCard].
  static const cardPadding = x5;
}

/// Corner radii following the Play Button and Brawl Stars proportions.
abstract final class DashRadius {
  static const sm = Radius.circular(6);
  static const md = Radius.circular(8);
  static const lg = Radius.circular(10);
  static const xl = Radius.circular(14);
  static const pill = Radius.circular(999);

  static const smAll = BorderRadius.all(sm);
  static const mdAll = BorderRadius.all(md);
  static const lgAll = BorderRadius.all(lg);
  static const xlAll = BorderRadius.all(xl);
  static const pillAll = BorderRadius.all(pill);
}

/// Outline widths. Every chunky shape — buttons, cards, dialogs, HUD pills —
/// sits on a thick ink border matching the Play Button recipe.
abstract final class DashStroke {
  static const thin = 1.5;
  static const regular = 2.0;
  static const thick = 2.5;
  static const chunky = 3.5;

  /// The light inner ring set just inside the ink outline. It is what makes a
  /// shape read as an applied sticker rather than a bordered box.
  static const innerRing = 1.5;
}

/// Icon sizes. Default 20.
abstract final class DashIconSize {
  static const xs = 12.0;
  static const sm = 16.0;
  static const md = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
  static const hero = 56.0;
}

/// Elevation in DashKart is an authentic cartoon arcade drop shadow:
/// dark ambient shadow under buttons and tiles matching the PLAY button recipe.
abstract final class DashElevation {
  /// The hard 3D bevel under an arcade element. [depth] collapses on press.
  static BoxShadow bevel(Color edgeColor, [double depth = 4.0]) => BoxShadow(
    color: edgeColor,
    offset: Offset(0, depth),
    blurRadius: 0,
    spreadRadius: 0,
  );

  /// The coloured halo that makes an element read as lit or active.
  static BoxShadow glow(
    Color glowColor, {
    double opacity = 0.55,
    double blur = 16.0,
  }) => BoxShadow(
    color: glowColor.withValues(alpha: opacity),
    offset: Offset.zero,
    blurRadius: blur,
    spreadRadius: 2,
  );

  /// Ambient drop shadow behind buttons & tiles, matching the PLAY button standard.
  static const ambient = BoxShadow(
    color: Color(0x8A000000),
    offset: Offset(0, 3),
    blurRadius: 6,
    spreadRadius: 0,
  );

  static const List<BoxShadow> dialog = [
    BoxShadow(color: Color(0x99000000), offset: Offset(0, 8), blurRadius: 16),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x8A000000), offset: Offset(0, 3), blurRadius: 6),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x8A000000), offset: Offset(0, 4), blurRadius: 8),
  ];

  static const List<BoxShadow> hero = [
    BoxShadow(color: Color(0x8A000000), offset: Offset(0, 4), blurRadius: 8),
  ];
}

/// Touch target sizes for driving controls and HUD slots.
abstract final class DashTouch {
  static const min = 48.0;
  static const itemSlot = 72.0;
  static const drift = 72.0;
  static const accelerate = 96.0;
  static const steer = 140.0;
}

/// Breakpoint helper for landscape screen responsiveness.
class DashBreakpoint {
  const DashBreakpoint({required this.width, this.height = 390.0});

  final double width;
  final double height;

  static DashBreakpoint of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return DashBreakpoint(width: size.width, height: size.height);
  }

  static bool isPortrait(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width < size.height;
  }

  bool get isCompact => width <= compact;
  bool get isRegular => width > compact && width <= maxContentWidth;
  bool get isExpanded => width > maxContentWidth;

  double get gutter => isCompact ? DashSpace.gutterCompact : DashSpace.gutter;
  double get maxContentWidth => 1100.0;

  static const compact = 740.0;
  static const maxContentWidthValue = 1100.0;
}

/// Notch-aware edge margins for screens that hand-place HUD-style corner
/// widgets (main menu, kart select) instead of using [DashScaffold]'s own
/// padding. A side with a real notch/Dynamic Island inset gets `max(inset,
/// 42)` clearance; a clear side gets the tighter compact/regular value.
///
/// Was two near-identical copies of this same formula living inline in
/// main_menu_screen.dart and kart_select_screen.dart, with left/right values
/// that had quietly drifted apart (10/14 vs 12/16) — one shared, parametrised
/// place instead, so drift like that can't happen again.
class DashSafeMargins {
  const DashSafeMargins({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  factory DashSafeMargins.of(
    BuildContext context, {
    double sideCompact = 12.0,
    double sideRegular = 16.0,
    double vCompact = 8.0,
    double vRegular = 12.0,
  }) {
    final compact = DashBreakpoint.of(context).isCompact;
    final viewPadding = MediaQuery.paddingOf(context);
    double side(double inset) => inset > 20.0
        ? math.max(inset, 42.0)
        : (compact ? sideCompact : sideRegular);
    return DashSafeMargins(
      left: side(viewPadding.left),
      right: side(viewPadding.right),
      top: compact ? vCompact : vRegular,
      bottom: compact ? vCompact : vRegular,
    );
  }

  final double left;
  final double right;
  final double top;
  final double bottom;
}
