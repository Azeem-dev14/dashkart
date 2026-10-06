import 'package:flutter/widgets.dart';

/// Motion tokens. Everything is eased-out or spring-like; nothing uses a linear
/// curve except continuous loops. See docs/design-system.md § 5.
abstract final class DashMotion {
  static const tap = Duration(milliseconds: 90);
  static const release = Duration(milliseconds: 180);
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const hero = Duration(milliseconds: 650);
  static const celebrate = Duration(milliseconds: 900);

  static const tapCurve = Curves.easeOutQuad;
  static const releaseCurve = Cubic(0.34, 1.56, 0.64, 1); // easeOutBack ~1.4
  static const fastCurve = Curves.easeOutCubic;
  static const baseCurve = Curves.easeOutCubic;
  static const slowCurve = Curves.easeOutQuint;
  static const heroCurve = Cubic(0.34, 1.42, 0.64, 1); // easeOutBack ~1.2
  static const celebrateCurve = Curves.elasticOut;

  /// Children of a list or grid enter this far apart, capped so a long list
  /// does not crawl in.
  static const stagger = Duration(milliseconds: 40);
  static const maxStaggered = 8;

  static Duration staggerFor(int index) =>
      stagger * (index.clamp(0, maxStaggered - 1));
}

/// Honours the platform "reduce motion" setting.
///
/// Durations collapse to zero and spring curves become plain eases, so a
/// bouncing overshoot never fires for a viewer who asked for stillness.
/// Confetti and camera shake check [enabled] and skip entirely.
class DashMotionScope extends InheritedWidget {
  const DashMotionScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static bool of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DashMotionScope>();
    if (scope != null) return scope.enabled;
    return !MediaQuery.disableAnimationsOf(context);
  }

  /// Zero when motion is reduced, otherwise [d].
  static Duration duration(BuildContext context, Duration d) =>
      of(context) ? d : Duration.zero;

  /// Overshoot curves are replaced rather than merely shortened — a 0ms
  /// elastic still lands wrong if it ever runs at a non-zero duration.
  static Curve curve(BuildContext context, Curve c) =>
      of(context) ? c : Curves.easeOut;

  @override
  bool updateShouldNotify(DashMotionScope oldWidget) =>
      enabled != oldWidget.enabled;
}
