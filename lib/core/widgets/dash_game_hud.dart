import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:dashkart/data/models.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_controls.dart';
import 'package:dashkart/core/widgets/dash_icon.dart';
import 'package:dashkart/core/widgets/dash_item_slot.dart';
import 'package:dashkart/core/widgets/dash_outlined_text.dart';

/// Live race state the HUD renders. Kept as a plain value type so the HUD can
/// be driven by the race loop, a replay, or a widget test without change.
class RaceHudState {
  const RaceHudState({
    required this.position,
    required this.totalRacers,
    required this.lap,
    required this.totalLaps,
    required this.speedKmh,
    this.item,
    this.itemState = ItemSlotState.empty,
    this.itemCooldown = 0,
    this.boosting = false,
    this.trackProgress = const [],
    this.playerIndex = 0,
    this.useMph = false,
  });

  final int position;
  final int totalRacers;
  final int lap;
  final int totalLaps;
  final double speedKmh;
  final RaceItem? item;
  final ItemSlotState itemState;
  final double itemCooldown;
  final bool boosting;

  /// Whether the speed readout should convert to and label as MPH, per
  /// [GameSettings.useMph].
  final bool useMph;

  /// 0..1 lap progress for every racer, used by the minimap.
  final List<double> trackProgress;
  final int playerIndex;

  bool get finalLap => lap == totalLaps;

  static String ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}TH';
    return switch (n % 10) {
      1 => '${n}ST',
      2 => '${n}ND',
      3 => '${n}RD',
      _ => '${n}TH',
    };
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

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.viewPaddingOf(context);
    // Landscape notches eat one horizontal edge; read the real inset rather
    // than assuming a symmetric gutter.
    final left = math.max(pad.left, DashSpace.x6);
    final right = math.max(pad.right, DashSpace.x6);

    return Stack(
      children: [
        const _Scrims(),
        Positioned(
          top: DashSpace.x4,
          left: left,
          child: _PositionPill(state: state),
        ),
        Positioned(
          top: DashSpace.x4,
          left: 0,
          right: 0,
          child: Center(child: _LapPill(state: state)),
        ),
        Positioned(
          top: DashSpace.x4,
          right: right,
          child: _Minimap(state: state),
        ),
        Positioned(
          top: DashSpace.x4 + 104,
          right: right,
          child: _PauseButton(onPause: onPause),
        ),
        if (showControls)
          Positioned(
            bottom: DashSpace.x6,
            left: left,
            child: DashSteering(onSteer: onSteer),
          ),
        Positioned(
          bottom: DashSpace.x6,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                DashItemSlot(
                  state: state.itemState,
                  item: state.item,
                  cooldown: state.itemCooldown,
                  onUse: onUseItem,
                ),
                const SizedBox(width: DashSpace.x4),
                _SpeedReadout(state: state),
              ],
            ),
          ),
        ),
        if (showControls)
          Positioned(
            bottom: DashSpace.x6,
            right: right,
            // The kart drives on its own — no throttle to hold — so this
            // corner only needs the two situational controls.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DashDriveButton(
                  shape: 'button_bean',
                  icon: DashIcons.drift,
                  semanticLabel: 'Drift',
                  size: DashTouch.drift,
                  tint: DashColors.orange.s300,
                  glowColor: DashColors.orange.s400,
                  onChanged: onDrift,
                ),
                const SizedBox(height: DashSpace.x2),
                DashDriveButton(
                  shape: 'button_circle_wide',
                  icon: DashIcons.pedalBrake,
                  semanticLabel: 'Brake',
                  size: DashTouch.accelerate,
                  tint: const Color(0xFFFF9AA8),
                  glowColor: DashColors.racingRed,
                  onChanged: onBrake,
                ),
              ],
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
        color: DashColors.surface.withValues(alpha: 0.82),
        borderRadius: DashRadius.pillAll,
        border: Border.all(
          color: DashColors.strokeStrong.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }
}

class _PositionPill extends StatelessWidget {
  const _PositionPill({required this.state});

  final RaceHudState state;

  @override
  Widget build(BuildContext context) {
    final label = RaceHudState.ordinal(state.position);
    return _HudPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          DashOutlinedText(
            label.substring(0, label.length - 2),
            style: DashType.position.copyWith(
              fontSize: 40,
              shadows: DashScrim.textShadow,
            ),
          ),
          DashOutlinedText(
            label.substring(label.length - 2),
            style: DashType.position.copyWith(
              fontSize: 20,
              color: DashColors.yellow.s500,
              shadows: DashScrim.textShadow,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: DashSpace.x2),
            child: Text('/${state.totalRacers}', style: DashType.label),
          ),
        ],
      ),
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
          Text('LAP', style: DashType.label.copyWith(color: accent)),
          const SizedBox(width: DashSpace.x2),
          DashOutlinedText(
            '${state.lap}/${state.totalLaps}',
            style: DashType.lap.copyWith(
              color: accent,
              shadows: DashScrim.textShadow,
            ),
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
      width: 132,
      height: 96,
      decoration: BoxDecoration(
        color: DashColors.surface.withValues(alpha: 0.78),
        borderRadius: DashRadius.mdAll,
        border: Border.all(
          color: DashColors.strokeStrong.withValues(alpha: 0.5),
        ),
      ),
      child: CustomPaint(
        painter: _MinimapPainter(
          progress: state.trackProgress,
          playerIndex: state.playerIndex,
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  const _MinimapPainter({required this.progress, required this.playerIndex});

  final List<double> progress;
  final int playerIndex;

  /// A closed loop, sampled so racer dots can be placed by lap fraction.
  static Offset _pointAt(double t, Size size) {
    final a = t * math.pi * 2;
    final cx = size.width / 2;
    final cy = size.height / 2;
    // A lopsided lissajous reads as a circuit rather than an oval.
    return Offset(
      cx + math.cos(a) * size.width * 0.34,
      cy +
          math.sin(a * 2) * size.height * 0.26 +
          math.sin(a) * size.height * 0.2,
    );
  }

  // The outline is a pure function of [size], which never changes for a
  // given minimap — cached so painting (every HUD frame while racing)
  // doesn't re-walk 90 trig samples to redraw a loop that never moves; only
  // the per-racer dots below are genuinely per-frame work.
  static Size? _outlineSize;
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

  static Path _outlineFor(Size size) {
    if (_outlineSize == size) return _outlinePath;
    final path = Path();
    for (var i = 0; i <= 90; i++) {
      final p = _pointAt(i / 90, size);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    _outlineSize = size;
    _outlinePath = path;
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _outlineFor(size);
    canvas.drawPath(path, _outlineShadowPaint);
    canvas.drawPath(path, _outlineStrokePaint);

    for (var i = 0; i < progress.length; i++) {
      final isPlayer = i == playerIndex;
      final p = _pointAt(progress[i] % 1.0, size);
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
      old.progress != progress || old.playerIndex != playerIndex;
}
