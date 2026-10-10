import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/track_shape.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_brawl_ink_text.dart';
import 'package:dashkart/core/widgets/dash_controls.dart';
import 'package:dashkart/core/widgets/dash_icon.dart';
import 'package:dashkart/core/widgets/dash_outlined_text.dart';
import 'package:dashkart/features/settings/steering_mode.dart';

/// Live race state the HUD renders. Kept as a plain value type so the HUD can
/// be driven by the race loop, a replay, or a widget test without change.
class RaceHudState {
  const RaceHudState({
    required this.position,
    required this.totalRacers,
    required this.lap,
    required this.totalLaps,
    required this.speedKmh,
    this.itemState = ItemSlotState.empty,
    this.boosting = false,
    this.boostFraction = 0,
    this.driftCharge = 0,
    this.drifting = false,
    this.wrongWay = false,
    this.currentLap = Duration.zero,
    this.bestLap,
    this.flash,
    this.trackProgress = const [],
    this.playerIndex = 0,
    this.useMph = false,
    this.trackId = '',
  });

  final int position;
  final int totalRacers;
  final int lap;
  final int totalLaps;
  final double speedKmh;
  final ItemSlotState itemState;
  final bool boosting;

  /// 0..1 of the current boost left, for the bar under the speed readout.
  final double boostFraction;

  /// 0..1 of the way to a mini-turbo while drifting.
  final double driftCharge;

  /// The kart is actually sliding, not merely holding the button.
  final bool drifting;

  /// The kart is pointed back down the circuit.
  final bool wrongWay;

  /// The lap in progress, and the best lap so far.
  final Duration currentLap;
  final Duration? bestLap;

  /// A transient callout — an overtake, a mini turbo. Null most of the time.
  final String? flash;

  /// Whether the speed readout should convert to and label as MPH, per
  /// [GameSettings.useMph].
  final bool useMph;

  /// 0..1 lap progress for every racer, used by the minimap.
  final List<double> trackProgress;
  final int playerIndex;

  /// Which circuit is being raced, so the minimap can draw its real shape.
  final String trackId;

  bool get finalLap => lap == totalLaps;

  /// A drift charged all the way, waiting on the release that pays it out.
  bool get driftReady => driftCharge >= 1.0;

  static String ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}TH';
    return switch (n % 10) {
      1 => '${n}ST',
      2 => '${n}ND',
      3 => '${n}RD',
      _ => '${n}TH',
    };
  }

  /// `m:ss.cc` — the format every clock on the HUD and the results board
  /// shares, so a lap time means the same thing wherever it appears.
  static String clock(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    final centis = (d.inMilliseconds % 1000) ~/ 10;
    return '$minutes:${seconds.toString().padLeft(2, '0')}'
        '.${centis.toString().padLeft(2, '0')}';
  }
}

/// The race overlay.
///
/// Owns the two gradient scrims and the corner placement. The centre of the
/// screen stays clear — the track carries the drama, not the chrome.
class DashGameHUD extends StatelessWidget {
  const DashGameHUD({
    super.key,
    required this.state,
    required this.onSteer,
    required this.onBrake,
    required this.onDrift,
    required this.onUseItem,
    required this.onPause,
    this.showControls = true,
    this.steering = SteeringMode.buttons,
  });

  final RaceHudState state;
  final ValueChanged<double> onSteer;
  final ValueChanged<bool> onBrake;
  final ValueChanged<bool> onDrift;
  final VoidCallback onUseItem;
  final VoidCallback onPause;

  /// False when a phone is the controller: steering, drift and brake live on
  /// the phone, so the screen keeps only the readouts.
  final bool showControls;

  /// Which steering control to draw. Both report the same -1..1 signal to
  /// [onSteer], so nothing downstream of here changes with it.
  final SteeringMode steering;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.viewPaddingOf(context);
    // Landscape notches eat one horizontal edge; read the real inset rather
    // than assuming a symmetric gutter.
    final left = math.max(pad.left, DashSpace.x6);
    final right = math.max(pad.right, DashSpace.x6);
    final compact = DashBreakpoint.of(context).isCompact;
    // Four 80dp faces plus their gaps do not fit beside the steering cluster
    // on a 640dp screen; everything scales together rather than one control
    // being dropped, because every one of them is needed to drive.
    final buttonSize = compact ? 66.0 : 78.0;

    return Stack(
      children: [
        const _Scrims(),
        // --- Top: read-outs only, nothing to touch except pause. ---------
        Positioned(
          top: DashSpace.x3,
          left: left,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PositionBadge(state: state, compact: compact),
              const SizedBox(height: DashSpace.x1),
              _LapTimes(state: state),
            ],
          ),
        ),
        Positioned(
          top: DashSpace.x3,
          left: 0,
          right: 0,
          child: Center(child: _LapPill(state: state)),
        ),
        Positioned(
          top: DashSpace.x3,
          right: right,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Minimap(state: state),
              const SizedBox(width: DashSpace.x2),
              _PauseButton(onPause: onPause),
            ],
          ),
        ),
        // --- Centre: only ever transient, never chrome. ------------------
        if (state.wrongWay)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(child: _WrongWayWarning()),
          )
        else if (state.flash != null)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(child: _Flash(text: state.flash!)),
          ),
        // --- Bottom: every control lives here. ---------------------------
        if (showControls)
          Positioned(
            bottom: DashSpace.x4,
            left: left,
            child: Opacity(
              opacity: 0.78,
              child: switch (steering) {
                SteeringMode.buttons => DashSteering(
                  onSteer: onSteer,
                  size: compact ? 70 : 84,
                ),
                SteeringMode.analog => DashSteeringPad(
                  onSteer: onSteer,
                  width: compact ? 148 : 176,
                  height: compact ? 70 : 84,
                ),
              },
            ),
          ),
        Positioned(
          bottom: DashSpace.x3,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DriftMeter(state: state),
                _SpeedReadout(state: state),
                _BoostBar(state: state),
              ],
            ),
          ),
        ),
        if (showControls)
          Positioned(
            bottom: DashSpace.x4,
            right: right,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _LabelledControl(
                  label: 'BRAKE',
                  child: DashDriveButton(
                    shape: 'button_circle_wide',
                    icon: DashIcons.pedalBrake,
                    semanticLabel: 'Brake / reverse',
                    size: buttonSize,
                    tint: const Color(0xFFFF9AA8),
                    glowColor: DashColors.racingRed,
                    onChanged: onBrake,
                  ),
                ),
                SizedBox(width: compact ? DashSpace.x2 : DashSpace.x3),
                // Drift sits between brake and turbo because it is used with
                // both: held through a corner, then released into the boost.
                _LabelledControl(
                  label: state.driftReady ? 'RELEASE!' : 'DRIFT',
                  highlight: state.driftReady,
                  child: DashDriveButton(
                    shape: 'button_circle_wide',
                    icon: DashIcons.drift,
                    semanticLabel: 'Drift',
                    size: buttonSize,
                    tint: state.drifting
                        ? DashColors.cyan
                        : const Color(0xFFA8D8FF),
                    glowColor: DashColors.cyan,
                    onChanged: onDrift,
                  ),
                ),
                SizedBox(width: compact ? DashSpace.x2 : DashSpace.x3),
                _LabelledControl(
                  label: state.itemState == ItemSlotState.ready
                      ? 'TURBO READY'
                      : 'TURBO',
                  highlight: state.itemState == ItemSlotState.ready,
                  child: DashDriveButton(
                    shape: 'button_bean',
                    icon: DashIcons.boost,
                    semanticLabel: 'Turbo',
                    size: buttonSize,
                    enabled: state.itemState == ItemSlotState.ready,
                    tint: DashColors.orange.s300,
                    glowColor: DashColors.orange.s400,
                    onChanged: (down) {
                      if (down) onUseItem();
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The drift charge, as a bar that fills and then locks solid. A mechanic the
/// player cannot see the state of is a mechanic they will not use.
class _DriftMeter extends StatelessWidget {
  const _DriftMeter({required this.state});

  final RaceHudState state;

  @override
  Widget build(BuildContext context) {
    if (!state.drifting && state.driftCharge <= 0) {
      return const SizedBox(height: DashSpace.x3);
    }
    final ready = state.driftReady;
    return Padding(
      padding: const EdgeInsets.only(bottom: DashSpace.x1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ready ? 'MINI TURBO READY' : 'DRIFTING',
            style: DashType.label.copyWith(
              fontSize: 10,
              letterSpacing: 1.6,
              color: ready ? DashColors.orange.s400 : DashColors.cyan,
              shadows: DashScrim.textShadow,
            ),
          ),
          const SizedBox(height: 2),
          _Meter(
            value: state.driftCharge,
            width: 132,
            colors: ready
                ? [DashColors.orange.s300, DashColors.yellow.s500]
                : [DashColors.cyan, DashColors.skyBlue],
          ),
        ],
      ),
    );
  }
}

/// How much boost is left to burn.
class _BoostBar extends StatelessWidget {
  const _BoostBar({required this.state});

  final RaceHudState state;

  @override
  Widget build(BuildContext context) {
    if (state.boostFraction <= 0) return const SizedBox(height: 6);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: _Meter(
        value: state.boostFraction,
        width: 110,
        colors: DashGradients.turbo.take(2).toList(),
      ),
    );
  }
}

/// A small horizontal fill bar, shared by the drift and boost readouts so the
/// two read as one family.
class _Meter extends StatelessWidget {
  const _Meter({
    required this.value,
    required this.width,
    required this.colors,
  });

  final double value;
  final double width;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xCC0A0F28),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: DashColors.pureBlack, width: 1.4),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Driving the wrong way round the circuit.
///
/// The lap counter used to simply tick backwards with no explanation, which
/// reads as a bug rather than as the player's mistake.
class _WrongWayWarning extends StatelessWidget {
  const _WrongWayWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DashSpace.x5,
        vertical: DashSpace.x3,
      ),
      decoration: BoxDecoration(
        borderRadius: DashRadius.mdAll,
        color: const Color(0xE6B3122E),
        border: Border.all(color: DashColors.pureBlack, width: 3),
      ),
      child: BrawlInkText(
        'WRONG WAY',
        fontSize: 30,
        weight: BrawlInkWeight.heavy,
        color: DashColors.textPrimary,
      ),
    );
  }
}

/// A transient callout — an overtake, a mini turbo earned.
class _Flash extends StatelessWidget {
  const _Flash({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return BrawlTitleText(text, fontSize: 40, color: DashColors.yellow.s500);
  }
}

/// Race clock, the lap in progress, and the best lap so far.
class _LapTimes extends StatelessWidget {
  const _LapTimes({required this.state});

  final RaceHudState state;

  @override
  Widget build(BuildContext context) {
    final best = state.bestLap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimeLine(
          label: 'LAP',
          value: RaceHudState.clock(state.currentLap),
          color: DashColors.textPrimary,
        ),
        if (best != null)
          _TimeLine(
            label: 'BEST',
            value: RaceHudState.clock(best),
            color: DashColors.yellow.s500,
          ),
      ],
    );
  }
}

class _TimeLine extends StatelessWidget {
  const _TimeLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: DashType.label.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
              color: DashColors.textSecondary,
              shadows: DashScrim.textShadow,
            ),
          ),
        ),
        Text(
          value,
          style: DashType.timer.copyWith(
            fontSize: 15,
            color: color,
            shadows: DashScrim.textShadow,
          ),
        ),
      ],
    );
  }
}

/// A control with a small caption under it, so a button's job is never a
/// guess. [highlight] lights the caption when the control is ready to use.
class _LabelledControl extends StatelessWidget {
  const _LabelledControl({
    required this.label,
    required this.child,
    this.highlight = false,
  });

  final String label;
  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 2),
        Text(
          label,
          style: DashType.label.copyWith(
            fontSize: 11,
            letterSpacing: 1.2,
            color: highlight ? DashColors.orange.s400 : DashColors.textPrimary,
            shadows: DashScrim.textShadow,
          ),
        ),
      ],
    );
  }
}

class _Scrims extends StatelessWidget {
  const _Scrims();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: [
          Container(
            height: DashScrim.topHeight,
            decoration: const BoxDecoration(gradient: DashScrim.top),
          ),
          const Spacer(),
          Container(
            height: DashScrim.bottomHeight,
            decoration: const BoxDecoration(gradient: DashScrim.bottom),
          ),
        ],
      ),
    );
  }
}

/// A grounded pill. Every HUD readout sits on one — text over live 3D needs a
/// controlled ground, not just a shadow.
///
/// A plain translucent fill, not a `BackdropFilter` blur: this repaints every
/// frame for the whole race, and stacking blur-behind panels on top of a live
/// `SceneView` is one of the most expensive things Flutter can be asked to do
/// per frame — Android's raster path in particular pays for it in real
/// frame time. A flatter, more opaque fill reads almost as well without it.
class _HudPill extends StatelessWidget {
  const _HudPill({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: DashSpace.x4,
            vertical: DashSpace.x2,
          ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashColors.pureBlack, width: 2.6),
        boxShadow: const [
          BoxShadow(color: Color(0xFF0A1040), offset: Offset(0, 3)),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE63B4FC4), Color(0xE61B2A86)],
        ),
      ),
      child: child,
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.state, this.compact = false});

  final RaceHudState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = RaceHudState.ordinal(state.position);
    // 1st glows gold; everything else stays white, so leading reads at a
    // glance without reading the number.
    final leading = state.position == 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        DashOutlinedText(
          label.substring(0, label.length - 2),
          style: DashType.position.copyWith(
            fontSize: compact ? 60 : 76,
            color: leading ? DashColors.yellow.s500 : DashColors.textPrimary,
            shadows: DashScrim.textShadow,
          ),
        ),
        DashOutlinedText(
          label.substring(label.length - 2),
          style: DashType.position.copyWith(
            fontSize: compact ? 22 : 28,
            color: DashColors.yellow.s500,
            shadows: DashScrim.textShadow,
          ),
        ),
        // The field size, so a 3rd of 4 is not mistaken for 3rd of 8.
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            '/${state.totalRacers}',
            style: DashType.label.copyWith(
              fontSize: compact ? 11 : 13,
              color: DashColors.textSecondary,
              shadows: DashScrim.textShadow,
            ),
          ),
        ),
      ],
    );
  }
}

class _LapPill extends StatelessWidget {
  const _LapPill({required this.state});

  final RaceHudState state;

  @override
  Widget build(BuildContext context) {
    final accent = state.finalLap
        ? DashColors.yellow.s500
        : DashColors.textPrimary;
    return _HudPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrawlInkText(
            'LAP',
            fontSize: 14,
            color: state.finalLap ? accent : const Color(0xFFCBD6FF),
          ),
          const SizedBox(width: DashSpace.x2),
          BrawlInkText(
            '${state.lap}/${state.totalLaps}',
            fontSize: 24,
            weight: BrawlInkWeight.heavy,
            color: accent,
          ),
        ],
      ),
    );
  }
}

class _SpeedReadout extends StatelessWidget {
  const _SpeedReadout({required this.state});

  final RaceHudState state;

  @override
  Widget build(BuildContext context) {
    final color = state.boosting
        ? DashColors.orange.s500
        : DashColors.textPrimary;
    final speed = state.useMph ? state.speedKmh * 0.621371 : state.speedKmh;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        DashOutlinedText(
          speed.round().toString().padLeft(3),
          style: DashType.speed.copyWith(
            color: color,
            shadows: DashScrim.textShadow,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            state.useMph ? 'MPH' : 'KM/H',
            style: DashType.speedUnit.copyWith(shadows: DashScrim.textShadow),
          ),
        ),
      ],
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.onPause});

  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPause,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: 'Pause',
        child: _HudPill(
          padding: const EdgeInsets.all(DashSpace.x3),
          child: const DashIcon(DashIcons.pause, size: DashIconSize.md),
        ),
      ),
    );
  }
}

/// Track spline with a dot per racer.
///
/// The route is a closed loop derived from the track index, so each circuit has
/// a recognisable shape until real track splines exist.
class _Minimap extends StatelessWidget {
  const _Minimap({required this.state});

  final RaceHudState state;

  @override
  Widget build(BuildContext context) {
    // No BackdropFilter here either — see _HudPill's doc comment. The dots
    // move every frame regardless, so this repaints constantly through the
    // whole race; a real-time blur behind it would too.
    return Container(
      width: 104,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xCC12195A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashColors.pureBlack, width: 2.6),
        boxShadow: const [
          BoxShadow(color: Color(0xFF0A1040), offset: Offset(0, 3)),
        ],
      ),
      child: CustomPaint(
        painter: _MinimapPainter(
          progress: state.trackProgress,
          playerIndex: state.playerIndex,
          trackId: state.trackId,
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  const _MinimapPainter({
    required this.progress,
    required this.playerIndex,
    required this.trackId,
  });

  final List<double> progress;
  final int playerIndex;
  final String trackId;

  /// The circuit's own centre-line, fitted to the minimap box.
  ///
  /// This used to be a stand-in lissajous figure that looked like a circuit
  /// but matched no actual track, so the dots crossing it told the player
  /// nothing about where they were. It is now the same [TrackShape] the
  /// circuit is built from, so the map is the track.
  static Offset _pointAt(TrackShape shape, double t, Size size) {
    final (x, z) = shape.pointAt(t);
    final extent = shape.maxRadius;
    return Offset(
      size.width / 2 + (x / extent) * size.width * 0.40,
      size.height / 2 + (z / extent) * size.height * 0.40,
    );
  }

  // The outline is a pure function of the circuit and the box, neither of
  // which changes during a race — cached so painting (every HUD frame while
  // racing) doesn't re-walk 90 samples to redraw a loop that never moves;
  // only the per-racer dots below are genuinely per-frame work.
  static Size? _outlineSize;
  static String? _outlineTrackId;
  static late Path _outlinePath;
  static final Paint _outlineShadowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeJoin = StrokeJoin.round
    ..color = DashColors.bgBase.withValues(alpha: 0.7);
  static final Paint _outlineStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = DashColors.strokeStrong;

  static Path _outlineFor(String trackId, Size size) {
    if (_outlineSize == size && _outlineTrackId == trackId) return _outlinePath;
    final shape = TrackShape.forTrack(trackId);
    final path = Path();
    for (var i = 0; i <= 90; i++) {
      final p = _pointAt(shape, i / 90, size);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    _outlineSize = size;
    _outlineTrackId = trackId;
    _outlinePath = path;
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = TrackShape.forTrack(trackId);
    final path = _outlineFor(trackId, size);
    canvas.drawPath(path, _outlineShadowPaint);
    canvas.drawPath(path, _outlineStrokePaint);

    for (var i = 0; i < progress.length; i++) {
      final isPlayer = i == playerIndex;
      final p = _pointAt(shape, progress[i] % 1.0, size);
      canvas.drawCircle(
        p,
        isPlayer ? 5 : 3.5,
        Paint()
          ..color = isPlayer ? DashColors.orange.s500 : DashColors.textTertiary,
      );
      if (isPlayer) {
        canvas.drawCircle(
          p,
          5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = DashColors.textPrimary,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MinimapPainter old) =>
      old.progress != progress ||
      old.playerIndex != playerIndex ||
      old.trackId != trackId;
}
