import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_outlined_text.dart';

/// The 3 · 2 · 1 · GO! overlay.
///
/// Sits over the live race with controls disabled. Beats and timings from
/// docs/wireframes.md § 7; a single controller keeps them locked together.
class CountdownOverlay extends StatefulWidget {
  const CountdownOverlay({super.key, required this.onGo, this.onBeat});

  final VoidCallback onGo;

  /// Fires on each number so the caller can play the matching tone — the tones
  /// rise a full step per beat.
  final ValueChanged<int>? onBeat;

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 4200);
  static const _beats = [400, 1400, 2400, 3400];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _total,
  );
  int _lastBeat = -1;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _c
      ..addListener(_tick)
      ..forward();
  }

  void _tick() {
    final ms = _c.value * _total.inMilliseconds;
    for (var i = _beats.length - 1; i >= 0; i--) {
      if (ms >= _beats[i] && _lastBeat < i) {
        _lastBeat = i;
        widget.onBeat?.call(i);
        break;
      }
    }
    if (!_fired && ms >= _beats.last) {
      _fired = true;
      widget.onGo();
    }
  }

  @override
  void dispose() {
    _c
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final ms = _c.value * _total.inMilliseconds;
          final index = _beats.lastIndexWhere((b) => ms >= b);
          if (index < 0) return const SizedBox.shrink();

          final since = ms - _beats[index];
          final isGo = index == 3;
          // Each beat lives ~900ms; GO holds a little longer.
          final life = (since / (isGo ? 800 : 900)).clamp(0.0, 1.0);
          if (life >= 1) return const SizedBox.shrink();

          final label = isGo ? 'GO!' : '${3 - index}';
          final color = isGo ? DashColors.neonGreen : DashColors.yellow.s500;

          // Numbers punch in and settle; GO overshoots harder.
          final t = Curves.easeOutBack.transform(
            (since / (isGo ? 260 : 200)).clamp(0.0, 1.0),
          );
          final scale = isGo
              ? 0.6 + t * 0.8 - math.max(0.0, life - 0.4) * 0.3
              : 2.2 - t * 1.2;
          final opacity = 1 - math.pow(life, 3).toDouble();

          return Stack(
            fit: StackFit.expand,
            children: [
              // White flash on GO.
              if (isGo)
                Opacity(
                  opacity: (1 - life * 6).clamp(0.0, 1.0) * 0.12,
                  child: const ColoredBox(color: DashColors.textPrimary),
                ),
              Center(
                child: CustomPaint(
                  painter: _ShockwavePainter(progress: life, color: color),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: DashOutlinedText(
                        label,
                        style: DashType.countdown.copyWith(
                          color: color,
                          shadows: [
                            Shadow(
                              color: color.withValues(alpha: 0.7),
                              blurRadius: 40,
                            ),
                            const Shadow(
                              color: DashColors.darkNavy,
                              blurRadius: 0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The expanding ring each number leaves behind.
class _ShockwavePainter extends CustomPainter {
  const _ShockwavePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 0.7) return;
    final t = progress / 0.7;
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide * (0.4 + t * 1.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * (1 - t)
        ..color = color.withValues(alpha: 0.5 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_ShockwavePainter old) =>
      old.progress != progress || old.color != color;
}
