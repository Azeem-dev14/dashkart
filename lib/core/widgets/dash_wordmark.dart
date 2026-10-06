import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';

/// The DASHKART lockup.
///
/// Original by necessity — brand identity cannot be sourced. Titan One set with
/// a forward italic lean, "DASH" in the speed gradient and "KART" in the turbo
/// gradient, with three speed lines trailing the leading edge. Drawn rather
/// than an SVG so it can animate its own reveal per letter.
///
/// See docs/asset-inventory.md § CREATE 1.
class DashWordmark extends StatelessWidget {
  const DashWordmark({
    super.key,
    this.fontSize = 64,
    this.reveal = 1,
    this.speedLines = true,
  });

  final double fontSize;

  /// 0..1. Letters rise and fade in left to right.
  final double reveal;
  final bool speedLines;

  static const _lean = -0.14; // ~8 degrees

  @override
  Widget build(BuildContext context) {
    const dash = 'DASH';
    const kart = 'KART';
    final letters = <(String, List<Color>)>[
      for (final c in dash.split('')) (c, DashGradients.speed),
      for (final c in kart.split('')) (c, DashGradients.turbo),
    ];

    return Semantics(
      label: 'DashKart',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (speedLines) _SpeedLines(height: fontSize, opacity: reveal),
            for (var i = 0; i < letters.length; i++)
              _Letter(
                char: letters[i].$1,
                gradient: letters[i].$2,
                fontSize: fontSize,
                lean: _lean,
                // Each letter has its own slice of the reveal, so the word
                // arrives as a run rather than all at once.
                t: _sliceFor(i, letters.length),
              ),
          ],
        ),
      ),
    );
  }

  double _sliceFor(int i, int count) {
    const overlap = 0.55;
    final span = 1 / (count * (1 - overlap) + overlap);
    final start = i * span * (1 - overlap);
    return ((reveal - start) / span).clamp(0.0, 1.0);
  }
}

class _Letter extends StatelessWidget {
  const _Letter({
    required this.char,
    required this.gradient,
    required this.fontSize,
    required this.lean,
    required this.t,
  });

  final String char;
  final List<Color> gradient;
  final double fontSize;
  final double lean;
  final double t;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..translateByDouble(0.0, (1 - eased) * fontSize * 0.35, 0.0, 1.0)
          ..setEntry(0, 1, lean)
          ..scaleByDouble(0.86 + eased * 0.14, 0.86 + eased * 0.14, 1.0, 1.0),
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ).createShader(rect),
          child: Text(
            char,
            style: DashType.brandXL.copyWith(
              fontSize: fontSize,
              letterSpacing: fontSize * 0.01,
              shadows: [
                Shadow(
                  color: DashColors.darkNavy.withValues(alpha: 0.9),
                  blurRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedLines extends StatelessWidget {
  const _SpeedLines({required this.height, required this.opacity});

  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: SizedBox(
        width: height * 0.62,
        height: height,
        child: CustomPaint(painter: _SpeedLinePainter(lean: -0.14)),
      ),
    );
  }
}

class _SpeedLinePainter extends CustomPainter {
  const _SpeedLinePainter({required this.lean});

  final double lean;

  @override
  void paint(Canvas canvas, Size size) {
    final widths = [1.0, 0.72, 0.46];
    final ys = [0.3, 0.52, 0.74];
    for (var i = 0; i < 3; i++) {
      final y = size.height * ys[i];
      final w = size.width * widths[i];
      final skew = lean * (size.height * (1 - ys[i]));
      final rect = RRect.fromLTRBR(
        size.width - w + skew,
        y - size.height * 0.045,
        size.width + skew,
        y + size.height * 0.045,
        Radius.circular(size.height * 0.05),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              DashColors.orange.s500.withValues(alpha: 0),
              DashColors.orange.s500.withValues(alpha: 0.9 - i * 0.22),
            ],
          ).createShader(rect.outerRect),
      );
    }
  }

  @override
  bool shouldRepaint(_SpeedLinePainter old) => old.lean != lean;
}

/// The loading indicator: a tyre-track arc that fills with progress.
class DashLoadingArc extends StatelessWidget {
  const DashLoadingArc({super.key, required this.progress, this.width = 280});

  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 8,
      child: CustomPaint(painter: _LoadingPainter(progress.clamp(0.0, 1.0))),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  const _LoadingPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(track, Paint()..color = DashColors.surfaceSunken);

    if (t <= 0) return;
    canvas.save();
    canvas.clipRRect(track);
    final w = size.width * t;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, size.height),
      Paint()
        ..shader = const LinearGradient(
          colors: DashGradients.turbo,
        ).createShader(Offset.zero & size),
    );

    // Tread marks, so the bar reads as a tyre track rather than a progress bar.
    final tread = Paint()..color = DashColors.darkNavy.withValues(alpha: 0.35);
    for (var x = 0.0; x < w; x += 10) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 3, size.height), tread);
    }
    canvas.restore();

    // Leading glow.
    canvas.drawCircle(
      Offset(w, size.height / 2),
      size.height * 1.4,
      Paint()
        ..color = DashColors.yellow.s400.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_LoadingPainter old) => old.t != t;
}

/// Ambient speed particles used behind the wordmark.
class DashSpeedField extends StatelessWidget {
  const DashSpeedField({super.key, required this.t, this.count = 22});

  final double t;
  final int count;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _SpeedFieldPainter(t: t, count: count),
      ),
    );
  }
}

class _SpeedFieldPainter extends CustomPainter {
  const _SpeedFieldPainter({required this.t, required this.count});

  final double t;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    for (var i = 0; i < count; i++) {
      final y = rng.nextDouble() * size.height;
      final speed = 0.5 + rng.nextDouble();
      final len = 40 + rng.nextDouble() * 120;
      final x =
          ((t * speed * size.width * 1.6) + rng.nextDouble() * size.width) %
              (size.width + len) -
          len;
      final alpha = 0.06 + rng.nextDouble() * 0.14;
      final rect = Rect.fromLTWH(x, y, len, 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              DashColors.skyBlue.withValues(alpha: 0),
              DashColors.skyBlue.withValues(alpha: alpha),
              DashColors.skyBlue.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_SpeedFieldPainter old) => old.t != t;
}
