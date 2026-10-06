import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';

/// Cinematic, non-skippable Unity-style splash screen.
///
/// Features:
/// * Clean studio intro presentation featuring the Namma Flutter logo.
/// * Non-skippable sequence just like Unity-developed game splash screens.
/// * Smooth cinematic fade-in from black, steady hold, and smooth fade-out to black.
/// * Subtle majestic camera zoom-in/drift.
/// * Automatically hands off to [onDone] once the sequence completes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Total duration of the splash sequence:
  /// * 0ms - 700ms: Smooth fade-in from black
  /// * 700ms - 2100ms: Steady hold & subtle cinematic drift
  /// * 2100ms - 2800ms: Smooth fade-out to black
  static const _totalDuration = Duration(milliseconds: 2800);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _totalDuration,
  );

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finish();
        }
      })
      ..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm the splash image so it renders immediately with zero pop-in
    precacheImage(
      const AssetImage('assets/images/splash/namma_flutter_splash.png'),
      context,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  double get _opacity {
    final t = _controller.value;
    if (t < 0.25) {
      // 0ms - 700ms: Fade In
      return Curves.easeOutCubic.transform(t / 0.25);
    } else if (t < 0.75) {
      // 700ms - 2100ms: Hold
      return 1.0;
    } else {
      // 2100ms - 2800ms: Fade Out
      final p = (t - 0.75) / 0.25;
      return (1.0 - Curves.easeInCubic.transform(p)).clamp(0.0, 1.0);
    }
  }

  double _scale(bool reducedMotion) {
    if (reducedMotion) return 1.0;
    final t = _controller.value;
    if (t < 0.25) {
      final p = Curves.easeOutCubic.transform(t / 0.25);
      return 0.96 + 0.04 * p; // 0.96 -> 1.00
    } else {
      final p = (t - 0.25) / 0.75;
      return 1.00 + 0.025 * p; // 1.00 -> 1.025 slow drift
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = !DashMotionScope.of(context);

    // Non-skippable: No gesture listener, touches are consumed/ignored
    return ColoredBox(
      color: const Color(0xFF000000),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final opacity = reduced
              ? (_controller.value < 0.85 ? 1.0 : 0.0)
              : _opacity;
          final scale = _scale(reduced);

          return Center(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = math.min(constraints.maxWidth * 0.76, 680.0);
                    final maxH = math.min(constraints.maxHeight * 0.65, 260.0);

                    return SizedBox(
                      width: maxW,
                      height: maxH,
                      child: Image.asset(
                        'assets/images/splash/namma_flutter_splash.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
