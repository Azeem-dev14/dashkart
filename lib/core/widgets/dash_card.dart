import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';

enum DashCardVariant { flat, raised, outlined, gradient }

/// The base container. Everything that groups content sits in one of these.
///
/// Selection is signalled with three cues at once — a ring, a lift, and a
/// scale — because a single cue is ambiguous over a busy 3D backdrop.
class DashCard extends StatelessWidget {
  const DashCard({
    super.key,
    required this.child,
    this.variant = DashCardVariant.flat,
    this.selected = false,
    this.padding = const EdgeInsets.all(DashSpace.cardPadding),
    this.width,
    this.height,
    this.gradient,
    this.onTap,
    this.borderRadius = DashRadius.lgAll,
  });

  final Widget child;
  final DashCardVariant variant;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  /// Only read when [variant] is [DashCardVariant.gradient].
  final List<Color>? gradient;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  Color get _fill => switch (variant) {
    DashCardVariant.flat => DashColors.surface,
    DashCardVariant.raised => DashColors.surfaceRaised,
    DashCardVariant.outlined => const Color(0x00000000),
    DashCardVariant.gradient => DashColors.surface,
  };

  @override
  Widget build(BuildContext context) {
    final lifted = selected || variant == DashCardVariant.raised;

    final card = AnimatedContainer(
      duration: DashMotionScope.duration(context, DashMotion.base),
      curve: DashMotionScope.curve(context, DashMotion.baseCurve),
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: variant == DashCardVariant.gradient ? null : _fill,
        gradient: variant == DashCardVariant.gradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient ?? DashGradients.menuSky,
              )
            : null,
        borderRadius: borderRadius,
        // Every card sits on a border, not just the outlined/selected
        // states — a thick ink line at rest, brightening and thickening on
        // selection, so panels read as cut-out cards rather than flat fills.
        border: Border.all(
          color: variant == DashCardVariant.outlined
              ? DashColors.stroke
              : DashColors.pureBlack,
          width: selected ? DashStroke.chunky : DashStroke.thick,
        ),
        boxShadow: [
          // A hard bottom edge before the soft shadow, so a card is extruded
          // like the buttons rather than floating flat above the backdrop.
          DashElevation.bevel(DashColors.surfaceSunken, lifted ? 5 : 3),
          ...(lifted ? DashElevation.raised : DashElevation.card),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}
