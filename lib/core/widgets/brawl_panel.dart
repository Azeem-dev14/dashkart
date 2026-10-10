import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';

/// A black-bordered gradient plate with a hard bevel beneath it — the surface
/// the shop rows, the pause menu, the settings screen and the multiplayer
/// lobby are all built from, so they read as one family.
class BrawlPanel extends StatelessWidget {
  const BrawlPanel({
    super.key,
    required this.child,
    this.colors = panelGradient,
    this.radius = 16,
    this.borderWidth = 3.5,
    this.depth = 5,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final List<Color> colors;
  final double radius;
  final double borderWidth;

  /// How far the hard bevel sits below the plate.
  final double depth;
  final EdgeInsets padding;

  /// The default blue face, top to bottom.
  static const panelGradient = [Color(0xFF3B4FC4), Color(0xFF1B2A86)];

  /// The colour of the bevel, and of any sunken tray set into a panel.
  static const bevel = Color(0xFF0A1040);

  /// Secondary text on a panel: readable on the blue, softer than white.
  static const softText = Color(0xFFCBD6FF);

  /// Highlights and values — trophies, selected states, room codes.
  static const gold = Color(0xFFFFD83A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: DashColors.pureBlack, width: borderWidth),
        boxShadow: [BoxShadow(color: bevel, offset: Offset(0, depth))],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
