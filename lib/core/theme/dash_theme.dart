import 'package:dashkart/core/theme/dash_colors.dart';
import 'package:dashkart/core/theme/dash_metrics.dart';
import 'package:dashkart/core/theme/dash_motion.dart';
import 'package:dashkart/core/theme/dash_typography.dart';

/// The DashKart Theme configuration and registry.
///
/// Bundles color tokens, typography (powered by [Lilita One]), metrics,
/// and motion into a unified, coherent theme structure.
abstract final class DashTheme {
  /// The global font family.
  static const fontFamily = DashType.font;

  /// Default background color.
  static const backgroundColor = DashColors.bgBase;

  /// Primary accent color.
  static const primaryColor = DashColors.purple;

  /// Default text style for root / unstyled widgets.
  static const defaultTextStyle = DashType.body;

  /// Quick accessors for core theme token classes.
  static const typography = DashType;
  static const colors = DashColors;
  static const gradients = DashGradients;
  static const metrics = DashSpace;
  static const radius = DashRadius;
  static const stroke = DashStroke;
  static const motion = DashMotion;
}
