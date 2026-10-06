import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dashkart/core/theme/theme.dart';

/// Renders a [DashIcons] at [size], tinted to [color].
///
/// The source art is white with a soft white-to-grey gradient. A flat
/// [BlendMode.srcIn] tint discards that shading, which is what an icon wants;
/// larger control art keeps it via [DashIcon.shaded].
class DashIcon extends StatelessWidget {
  const DashIcon(
    this.icon, {
    super.key,
    this.size = DashIconSize.md,
    this.color = DashColors.textPrimary,
  }) : _shaded = false;

  /// Keeps the source gradient, multiplying it by [color] so the art still
  /// reads as a lit, three-dimensional object. Use for large control faces.
  const DashIcon.shaded(
    this.icon, {
    super.key,
    this.size = DashIconSize.md,
    this.color = DashColors.textPrimary,
  }) : _shaded = true;

  final DashIcons icon;
  final double size;
  final Color color;
  final bool _shaded;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.path,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color,
        _shaded ? BlendMode.modulate : BlendMode.srcIn,
      ),
    );
  }
}

/// Raster counterpart to [DashIcon] for the Game Icons gap-fills.
class DashRasterIcon extends StatelessWidget {
  const DashRasterIcon(
    this.icon, {
    super.key,
    this.size = DashIconSize.md,
    this.color = DashColors.textPrimary,
  });

  final DashRasterIcons icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      icon.path,
      width: size,
      height: size,
      color: color,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// A Kenney Mobile Controls button face, with its shipped pressed state.
///
/// The pack ships a matching `*_highlight` variant for every button shape, so
/// the down state is real art rather than a runtime tint.
class DashControlFace extends StatelessWidget {
  const DashControlFace(
    this.shape, {
    super.key,
    required this.size,
    this.pressed = false,
    this.tint,
  });

  final String shape;
  final double size;
  final bool pressed;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final file = pressed ? '${shape}_highlight' : shape;
    return SvgPicture.asset(
      'assets/images/ui/controls/$file.svg',
      width: size,
      height: size,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint!, BlendMode.modulate),
    );
  }
}
