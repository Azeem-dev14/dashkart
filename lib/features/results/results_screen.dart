import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:dashkart/features/race/scene/kart_viewer.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';

/// One racer's final standing, for the board on the results screen.
class RaceStanding {
  const RaceStanding({
    required this.name,
    required this.isPlayer,
    required this.laps,
  });

  final String name;
  final bool isPlayer;

  /// Laps completed, fractional — so a racer still mid-lap when the winner
  /// crossed is shown where they actually got to.
  final double laps;
}

/// A finished race, ready to be shown.
///
/// The reward fields are what [PlayerState.recordResult] actually banked, not
/// a second formula. The screen used to compute its own XP figure from an
/// eight-racer field while progression advanced by an unrelated flat amount,
/// so the number the player was shown was never the number they were paid.
class RaceResult {
  const RaceResult({
    required this.position,
    required this.totalRacers,
    required this.time,
    required this.bestLap,
    required this.trophies,
    required this.xp,
    required this.level,
    required this.levelledUp,
    required this.newRecord,
    required this.trackName,
    this.didFinish = true,
    this.unlocked = const [],
    this.standings = const [],
  });

  final int position;
  final int totalRacers;
  final Duration time;
  final Duration bestLap;

  /// Trophies banked. Zero off the podium, and zero in multiplayer, which is
  /// not the single-player ladder.
  final int trophies;
  final int xp;
  final int level;
  final bool levelledUp;
  final bool newRecord;
  final String trackName;

  /// False when the race ended before the player crossed the line — everyone
  /// else had already finished. There is no race time to show for that.
  final bool didFinish;

  /// Content this result put within reach.
  final List<String> unlocked;

  /// Final order, best first.
  final List<RaceStanding> standings;

  /// A podium finish — what the celebration treatment keys off, rather than
  /// a win alone. Beating at least one other racer counts; coming last does
  /// not, which matters in a field of three, where "top three" would be
  /// everyone.
  bool get podium => position <= 3 && position < totalRacers;
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
    required this.onReplay,
    required this.onHome,
    this.onNext,
    this.nextLabel,
    this.kartModelPath,
    this.kartTint,
  });

  final RaceResult result;

  /// Restarts the race just finished.
  final VoidCallback onReplay;

  /// Leaves to the main menu.
  final VoidCallback onHome;

  /// Rolls straight into the next circuit. Null when there is no next one to
  /// go to — a live multiplayer race, or every other circuit still locked —
  /// in which case the button is not offered rather than offered and inert.
  final VoidCallback? onNext;

  /// The circuit [onNext] leads to, named on the button so the player knows
  /// where they are about to go.
  final String? nextLabel;

  /// The player's kart, shown on the podium. Null falls back to a drawn
  /// figure.
  final String? kartModelPath;
  final Color? kartTint;

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
                if (r.podium && !reduced)
                  DashConfetti(progress: _beat(800, 2800)),
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
                        if (r.unlocked.isNotEmpty)
                          Opacity(
                            opacity: stats,
                            child: Padding(
                              padding: const EdgeInsets.only(top: DashSpace.x2),
                              child: Center(
                                child: _UnlockBanner(names: r.unlocked),
                              ),
                            ),
                          ),
                        const SizedBox(height: DashSpace.x3),
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
                                      kartModelPath: widget.kartModelPath,
                                      kartTint: widget.kartTint,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: DashSpace.x4),
                              Expanded(
                                flex: 6,
                                child: DashCard(
                                  variant: DashCardVariant.raised,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: _StatSheet(
                                          result: r,
                                          progress: stats,
                                        ),
                                      ),
                                      // Three rivals and no final order
                                      // leaves out the one thing that says
                                      // how close the race was — but a
                                      // 640dp screen has no width for both,
                                      // so the stats win there.
                                      if (r.standings.isNotEmpty &&
                                          !bp.isCompact) ...[
                                        const SizedBox(width: DashSpace.x3),
                                        const _Divider(),
                                        const SizedBox(width: DashSpace.x3),
                                        Expanded(
                                          flex: 4,
                                          child: _Standings(
                                            standings: r.standings,
                                            progress: stats,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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
                                BrawlActionButton(
                                  label: 'HOME',
                                  tone: BrawlButtonTone.blue,
                                  width: bp.isCompact ? 96 : 124,
                                  height: bp.isCompact ? 44 : 50,
                                  fontSize: bp.isCompact ? 16 : 19,
                                  onPressed: widget.onHome,
                                ),
                                BrawlActionButton(
                                  label: 'REPLAY',
                                  tone: BrawlButtonTone.yellow,
                                  width: bp.isCompact ? 104 : 136,
                                  height: bp.isCompact ? 44 : 50,
                                  fontSize: bp.isCompact ? 16 : 19,
                                  onPressed: widget.onReplay,
                                ),
                                if (widget.onNext != null)
                                  BrawlActionButton(
                                    label: widget.nextLabel == null
                                        ? 'NEXT RACE'
                                        : 'NEXT: ${widget.nextLabel}',
                                    tone: BrawlButtonTone.green,
                                    width: bp.isCompact ? 150 : 196,
                                    height: bp.isCompact ? 44 : 50,
                                    fontSize: bp.isCompact ? 15 : 18,
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
  const _Podium({
    required this.position,
    required this.colors,
    this.kartModelPath,
    this.kartTint,
  });

  final int position;
  final List<Color> colors;
  final String? kartModelPath;
  final Color? kartTint;

  Widget _figure() {
    final drawn = CustomPaint(
      size: const Size(120, 120),
      painter: _CelebratePainter(accent: colors.first),
    );
    final model = kartModelPath;
    if (model == null) return drawn;
    return KartViewer(
      modelPath: model,
      tint: kartTint,
      cameraTargetY: 0.6,
      cameraEyeY: 1.8,
      fallback: drawn,
    );
  }

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
          Expanded(child: Center(child: _figure())),
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

/// A drawn figure celebrating, shown only where the 3D kart cannot render.
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
  double _row(int i) => ((progress - i * 0.14) / 0.5).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          label: 'Race Time',
          value: r.didFinish ? DashTrackCard.formatTime(r.time) : 'DNF',
          t: _row(0),
        ),
        _Row(
          label: 'Best Lap',
          value: DashTrackCard.formatTime(r.bestLap),
          t: _row(1),
          trailing: r.newRecord
              ? const DashChip(label: 'New Record', tone: DashChipTone.success)
              : null,
        ),
        // Only shown when it paid: a row reading "+0 TROPHIES" after a
        // fourth-place finish rubs it in without telling the player anything.
        if (r.trophies > 0)
          _Row(
            label: 'Trophies',
            value: '+${(r.trophies * _row(2)).round()}',
            t: _row(2),
          ),
        _Row(
          label: 'XP',
          value: '+${(r.xp * _row(3)).round()}',
          t: _row(3),
          trailing: r.levelledUp
              ? DashChip(label: 'Level ${r.level}', tone: DashChipTone.brand)
              : null,
        ),
      ],
    );
  }
}

/// What this result just put within reach. Earning something and not being
/// told is the fastest way to make a progression system feel like it is not
/// there.
class _UnlockBanner extends StatelessWidget {
  const _UnlockBanner({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DashSpace.x3,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        borderRadius: DashRadius.pillAll,
        border: Border.all(color: const Color(0xFFFFD83A), width: 2),
        color: const Color(0x33FFD83A),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DashRasterIcon(
            DashRasterIcons.unlocked,
            size: DashIconSize.sm,
            color: Color(0xFFFFD83A),
          ),
          const SizedBox(width: DashSpace.x2),
          Flexible(
            child: BrawlInkText(
              'UNLOCKED: ${names.join(', ').toUpperCase()}',
              fontSize: 13,
              weight: BrawlInkWeight.heavy,
              color: const Color(0xFFFFD83A),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The final order. A race against three rivals that reports only the
/// player's own place leaves out the one thing that says how close it was.
class _Standings extends StatelessWidget {
  const _Standings({required this.standings, required this.progress});

  final List<RaceStanding> standings;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < standings.length; i++)
          Opacity(
            opacity: ((progress - i * 0.12) / 0.4).clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: BrawlInkText(
                      RaceHudState.ordinal(i + 1),
                      fontSize: 12,
                      weight: BrawlInkWeight.heavy,
                      color: i == 0
                          ? const Color(0xFFFFD83A)
                          : const Color(0xFFCBD6FF),
                    ),
                  ),
                  Expanded(
                    child: BrawlInkText(
                      standings[i].name.toUpperCase(),
                      fontSize: 13,
                      weight: standings[i].isPlayer
                          ? BrawlInkWeight.heavy
                          : BrawlInkWeight.light,
                      color: standings[i].isPlayer
                          ? const Color(0xFF6BF26B)
                          : DashColors.textPrimary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
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
          padding: const EdgeInsets.symmetric(vertical: DashSpace.x1),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  label.toUpperCase(),
                  style: DashType.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // A badge sits between the label and the figure, so all three
              // have to share one narrow column. Every one of them is given
              // a bounded share and scales down inside it rather than
              // pushing the row past its width.
              if (trailing != null) ...[
                Expanded(
                  flex: 4,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
                ),
                const SizedBox(width: DashSpace.x2),
              ],
              // A fixed, right-aligned value column so the figures line up
              // whatever sits beside them.
              SizedBox(
                width: 84,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(value, style: DashType.timer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A hairline between the stat rows and the final order.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 2,
    height: double.infinity,
    child: ColoredBox(color: Color(0x332E3B72)),
  );
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
