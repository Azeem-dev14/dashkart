import 'package:flutter/widgets.dart';

/// Scales the whole UI with the screen, the way a game's canvas does.
///
/// Every size in this app — type, button faces, HUD plates, gutters — is a
/// fixed number of logical pixels, which is what makes the layout stable and
/// readable on a phone. On its own that is *not* responsive: a 1366x1024
/// iPad hands those same numbers twice the screen, so the UI shrinks into one
/// corner and leaves the middle empty, while a 640x360 Android is left
/// cramped.
///
/// Rather than thread a multiplier through hundreds of call sites, this does
/// what Unity's "scale with screen size" canvas does: it lays the UI out on a
/// *logical* canvas sized to a reference device, then scales that canvas to
/// fill the real screen. One factor, applied once, and every screen below
/// inherits it — including ones written later, which cannot forget to opt in.
///
/// Layout still adapts as well as scales: the logical canvas keeps the real
/// screen's aspect ratio (so nothing is letterboxed or stretched), and
/// `MediaQuery` below reports the logical size, so `DashBreakpoint` and the
/// safe-area insets stay honest.
///
/// The one thing that must *not* be scaled is the 3D race view: it renders
/// into a texture at whatever size it is given, so magnifying it would cost
/// real resolution. [DashUiScale.unscaled] is the escape hatch for that.
class DashUiScale extends StatelessWidget {
  const DashUiScale({super.key, required this.child});

  final Widget child;

  /// The shortest side, in logical pixels, the UI's fixed sizes were chosen
  /// against — a standard landscape phone. A screen this shape scales by
  /// exactly 1.0 and is left completely untouched.
  static const referenceShortestSide = 390.0;

  /// Bounds on the factor. The floor keeps touch targets tappable on a small
  /// phone; the ceiling stops a large tablet from looking like a phone
  /// screenshot blown up, since past this point the extra room is better
  /// spent on layout than on magnification.
  static const minScale = 0.9;
  static const maxScale = 1.5;

  static double scaleFor(Size size) =>
      (size.shortestSide / referenceShortestSide).clamp(minScale, maxScale);

  /// Renders [child] at the device's true resolution from inside a scaled
  /// subtree, by handing it the real size and letting the ambient scale undo
  /// the shrink. For the `SceneView`, whose texture would otherwise be
  /// rasterised at the smaller logical size and magnified into a blur.
  static Widget unscaled({required Widget child}) => _Unscaled(child: child);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    if (size.isEmpty) return child;

    final scale = scaleFor(size);
    // Phones land here, and a no-op keeps them byte-for-byte as they were.
    if ((scale - 1.0).abs() < 0.005) return child;

    final logical = size / scale;
    return MediaQuery(
      data: media.copyWith(
        size: logical,
        padding: media.padding / scale,
        viewPadding: media.viewPadding / scale,
        viewInsets: media.viewInsets / scale,
      ),
      // The logical canvas is the real size divided by a scalar, so it has
      // the identical aspect ratio and `fill` scales it uniformly.
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: logical.width,
          height: logical.height,
          child: child,
        ),
      ),
    );
  }
}

class _Unscaled extends StatelessWidget {
  const _Unscaled({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final view = View.of(context);
    final real = view.physicalSize / view.devicePixelRatio;
    if (real.isEmpty || media.size.isEmpty) return child;

    // Already unscaled — nothing to undo.
    if ((real.width - media.size.width).abs() < 0.5) return child;

    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: real.width,
        height: real.height,
        child: MediaQuery(
          data: media.copyWith(size: real),
          child: child,
        ),
      ),
    );
  }
}
