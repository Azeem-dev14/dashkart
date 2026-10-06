import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';

/// A finished race, ready to be shown.
class RaceResult {
  const RaceResult({
    required this.position,
    required this.totalRacers,
    required this.time,
    required this.bestLap,
    required this.xp,
    required this.newRecord,
  });

  final int position;
  final int totalRacers;
  final Duration time;
  final Duration bestLap;
  final int xp;
  final bool newRecord;

  bool get won => position == 1;
}

/// The results screen.
///
/// Beat-by-beat timeline from docs/wireframes.md § 8. Confetti and the podium
/// celebration only fire on a win; fourth place gets a muted treatment rather
/// than the same fanfare.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.result,
    required this.onNext,
    required this.onReplay,
    required this.onHome,
  });

  final RaceResult result;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 2800);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _total,
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _beat(int fromMs, int toMs) {
    final ms = _c.value * _total.inMilliseconds;
    return ((ms - fromMs) / (toMs - fromMs)).clamp(0.0, 1.0);
  }

  List<Color> get _placeColors => switch (widget.result.position) {
    1 => DashGradients.victory,
    2 => const [Color(0xFFE8EFFA), Color(0xFF97A6C4)],
    3 => const [Color(0xFFE0A46A), Color(0xFFA8632B)],
    _ => const [Color(0xFFD6C2F5), Color(0xFF9E82CC)],
  };

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final bp = DashBreakpoint.of(context);
    final reduced = !DashMotionScope.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        const BrawlLobbyBackdrop(),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final podium = reduced ? 1.0 : _beat(200, 700);
            final title = reduced ? 1.0 : _beat(600, 1100);
            final stats = reduced ? 1.0 : _beat(1000, 2000);
            final buttons = reduced ? 1.0 : _beat(2400, 2800);

            return Stack(
              fit: StackFit.expand,
              children: [
                if (r.won && !reduced) DashConfetti(progress: _beat(800, 2800)),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: bp.gutter),
                    child: Column(
                      children: [
                        const SizedBox(height: DashSpace.x4),
                        Opacity(
                          opacity: title,
                          child: Transform.scale(
                            scale: reduced
                                ? 1
                                : 0.7 +
                                      Curves.elasticOut.transform(title) * 0.3,
                            child: _PlaceTitle(
                              position: r.position,
                              colors: _placeColors,
                            ),
                          ),
                        ),
                        const SizedBox(height: DashSpace.x4),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - podium) * 120),
                                  child: Opacity(
                                    opacity: podium,
                                    child: _Podium(
                                      position: r.position,
                                      colors: _placeColors,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: DashSpace.x4),
                              Expanded(
                                flex: 6,
                                child: DashCard(
                                  variant: DashCardVariant.raised,
                                  child: _StatSheet(result: r, progress: stats),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DashSpace.x4),
                        Opacity(
                          opacity: buttons,
                          child: Transform.translate(
                            offset: Offset(0, (1 - buttons) * 20),
                            // Three labelled buttons do not fit a 667dp screen
                            // side by side; drop the icons before the labels.
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: DashSpace.x3,
                              runSpacing: DashSpace.x2,
                              children: [
                                DashButton(
                                  label: 'Home',
                                  icon: bp.isCompact ? null : DashIcons.back,
                                  variant: DashButtonVariant.ghost,
                                  size: bp.isCompact
                                      ? DashButtonSize.sm
                                      : DashButtonSize.md,
                                  onPressed: widget.onHome,
                                ),
                                DashButton(
                                  label: 'Replay',
                                  icon: bp.isCompact ? null : DashIcons.restart,
                                  size: bp.isCompact
                                      ? DashButtonSize.sm
                                      : DashButtonSize.md,
                                  onPressed: widget.onReplay,
                                ),
                                DashButton(
                                  label: 'Next Race',
                                  icon: bp.isCompact ? null : DashIcons.play,
                                  variant: DashButtonVariant.turbo,
                                  size: bp.isCompact
                                      ? DashButtonSize.sm
                                      : DashButtonSize.md,
                                  glow: true,
                                  onPressed: widget.onNext,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: DashSpace.x4),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PlaceTitle extends StatelessWidget {
  const _PlaceTitle({required this.position, required this.colors});

  final int position;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final ordinal = RaceHudState.ordinal(position);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DashRasterIcon(
            DashRasterIcons.trophy,
            size: DashIconSize.xxl,
            color: colors.first,
          ),
          const SizedBox(width: DashSpace.x4),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ).createShader(rect),
            child: Text(
              '$ordinal PLACE',
              style: DashType.brandL.copyWith(
                fontSize: 40,
                // Matches the wordmark's cut-sticker treatment: a hard ink
                // shadow gives the gradient fill the same pop, since a
                // ShaderMask tint can't sit behind a DashOutlinedText stroke.
                shadows: [
                  Shadow(
                    color: DashColors.darkNavy.withValues(alpha: 0.9),
                    blurRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.position, required this.colors});

  final int position;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final label = switch (position) {
      1 => 'Champion!',
      2 => 'Runner-up',
      3 => 'Third place',
      _ => 'Finished #$position',
    };

    return DashCard(
      variant: DashCardVariant.gradient,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Center(
              child: CustomPaint(
                size: const Size(120, 120),
                painter: _CelebratePainter(accent: colors.first),
              ),
            ),
          ),
          Text(label, style: DashType.h2),
          const SizedBox(height: DashSpace.x2),
          Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: DashRadius.pillAll,
            ),
          ),
        ],
      ),
    );
  }
}

/// The racer celebrating. A stand-in for the `emote-yes` clip on the rigged
/// GLB — see docs/asset-inventory.md § 4.
class _CelebratePainter extends CustomPainter {
  const _CelebratePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = DashColors.blue.s400;

    // Arms raised.
    final arm = Paint()
      ..color = DashColors.blue.s300
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.34, h * 0.52),
      Offset(w * 0.16, h * 0.24),
      arm,
    );
    canvas.drawLine(
      Offset(w * 0.66, h * 0.52),
      Offset(w * 0.84, h * 0.24),
      arm,
    );

    // Torso.
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * 0.34,
        h * 0.42,
        w * 0.66,
        h * 0.80,
        Radius.circular(w * 0.12),
      ),
      body,
    );

    // Head and helmet.
    canvas.drawCircle(Offset(w * 0.5, h * 0.30), w * 0.16, body);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.5, h * 0.30), radius: w * 0.16),
      math.pi,
      math.pi,
      true,
      Paint()..color = accent,
    );

    // Legs.
    canvas.drawLine(
      Offset(w * 0.42, h * 0.78),
      Offset(w * 0.38, h * 0.96),
      arm,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.78),
      Offset(w * 0.62, h * 0.96),
      arm,
    );
  }

  @override
  bool shouldRepaint(_CelebratePainter old) => old.accent != accent;
}

class _StatSheet extends StatelessWidget {
  const _StatSheet({required this.result, required this.progress});

  final RaceResult result;
  final double progress;

  /// Each row appears on its own slice of [progress], and numbers count up
  /// within it.
  double _row(int i) => ((progress - i * 0.16) / 0.5).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          label: 'Race Time',
          value: DashTrackCard.formatTime(result.time),
          t: _row(0),
        ),
        _Row(
          label: 'Best Lap',
          value: DashTrackCard.formatTime(result.bestLap),
          t: _row(1),
          trailing: result.newRecord
              ? const DashChip(label: 'New Record', tone: DashChipTone.success)
              : null,
        ),
        _Row(
          label: 'XP',
          value: '+${(result.xp * _row(2)).round()}',
          t: _row(2),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.t,
    this.trailing,
  });

  final String label;
  final String value;
  final double t;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset((1 - t) * 16, 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DashSpace.x2),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: DashType.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: DashSpace.x2),
              const Spacer(),
              ?trailing,
              if (trailing != null) const SizedBox(width: DashSpace.x2),
              Text(value, style: DashType.timer),
            ],
          ),
        ),
      ),
    );
  }
}

/// Celebration confetti, reusing the sourced particle shapes as simple quads.
class DashConfetti extends StatelessWidget {
  const DashConfetti({super.key, required this.progress, this.count = 120});

  final double progress;
  final int count;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(t: progress, count: count),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.t, required this.count});

  final double t;
  final int count;

  static const _colors = [
    Color(0xFFFFC300),
    Color(0xFFFF3D9A),
    Color(0xFF8B3FFF),
    Color(0xFF9FF23A),
    Color(0xFF22D3FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final rng = math.Random(11);
    for (var i = 0; i < count; i++) {
      final x0 = rng.nextDouble() * size.width;
      final delay = rng.nextDouble() * 0.35;
      final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final drift = (rng.nextDouble() - 0.5) * 160;
      // Constant acceleration downward, matching the 380dp/s^2 in the spec.
      final y = -40 + local * local * (size.height + 120);
      final x = x0 + drift * local;
      final spin = rng.nextDouble() * 12 + local * 14;
      final w = 5 + rng.nextDouble() * 6;
      final h = w * (0.4 + rng.nextDouble() * 0.5);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Paint()
          ..color = _colors[i % _colors.length].withValues(
            alpha: (1 - local * 0.35).clamp(0.0, 1.0),
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
