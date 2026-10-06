import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/features/race/race_controller.dart';
import 'package:dashkart/features/race/scene/race_scene.dart';
import 'package:dashkart/features/gamepad/pad_session.dart';
import 'package:dashkart/features/multiplayer/multiplayer_service.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/features/race/countdown_overlay.dart';
import 'package:dashkart/features/results/results_screen.dart';
import 'package:dashkart/features/settings/settings_screen.dart';

/// The race.
///
/// Composes the countdown, the live HUD, and the results layer over a scene
/// layer. That scene layer is currently a painted track; swapping in a
/// `flutter_scene` `SceneView` is a change to [_TrackBackdrop] alone — the
/// simulation and HUD do not know how the race is drawn.
class RaceScreen extends ConsumerStatefulWidget {
  const RaceScreen({super.key, required this.onExit, this.multiplayer});

  final VoidCallback onExit;

  /// Non-null for a live 1v1 race — the sole rival becomes the human
  /// opponent instead of AI, mirrored from the network every tick instead of
  /// advancing on its own pace.
  final MultiplayerSession? multiplayer;

  @override
  ConsumerState<RaceScreen> createState() => _RaceScreenState();
}

/// Owns only the [Ticker] — that needs a `vsync`, which is inherently a
/// widget concern — and forwards frames to [RaceController.tick]. Every
/// other piece of race logic (the simulation, collisions, item timing,
/// audio, multiplayer telemetry) lives in [RaceController]; this class just
/// renders whatever the controller currently holds.
class _RaceScreenState extends ConsumerState<RaceScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  RaceController? _controller;

  /// The phone controller, when the web game has one attached. Its held
  /// inputs are copied into [_controller] on every change; its one-shot
  /// buttons arrive on [_padPresses].
  PadHost? _pad;
  StreamSubscription<PadPress>? _padPresses;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = _controller;
    if (controller == null) {
      // A one-off read: the controller keeps its own reference to the
      // PlayerState instance rather than re-reading it every rebuild, the
      // same way it held onto the value `PlayerScope.of(context)` returned.
      final player = ref.read(playerProvider);
      _controller = RaceController(
        player: player,
        multiplayer: widget.multiplayer,
      );
      final pad = ref.read(padHostProvider);
      if (pad != null) {
        _pad = pad;
        pad.addListener(_onPadChange);
        _padPresses = pad.presses.listen(_onPadPress);
        _onPadChange();
      }
    } else {
      controller.refreshSimIfIdle();
    }
  }

  void _onPadChange() {
    final pad = _pad!;
    final controller = _controller!;
    controller.setSteer(pad.steer);
    controller.setBraking(pad.brake);
    if (pad.drift != controller.drifting) controller.setDrifting(pad.drift);
    // Losing the phone mid-race would leave the kart steering blind.
    if (!pad.connected && controller.phase == RacePhase.racing) _pause();
    if (mounted) setState(() {});
  }

  void _onPadPress(PadPress press) {
    final controller = _controller!;
    switch (press) {
      case PadPress.item:
        controller.useItem();
      case PadPress.pause:
        if (controller.phase == RacePhase.racing) {
          _pause();
        } else if (controller.phase == RacePhase.paused) {
          _resume();
        }
    }
  }

  @override
  void dispose() {
    _padPresses?.cancel();
    _pad?.removeListener(_onPadChange);
    _ticker.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onTick(Duration now) {
    final finished = _controller!.tick(now);
    if (finished) _ticker.stop();
  }

  void _pause() {
    _controller!.pause();
    _ticker.stop();
  }

  void _resume() {
    _controller!.resume();
    _ticker.start();
  }

  void _restartRace() {
    _controller!.restart();
    _ticker.stop();
  }

  void _quit() {
    _controller!.quit();
    _ticker.stop();
    widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final useMph = ref.watch(gameSettingsProvider).useMph;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final result = controller.result;
        if (controller.phase == RacePhase.results && result != null) {
          return ResultsScreen(
            result: result,
            onNext: widget.onExit,
            onReplay: widget.onExit,
            onHome: widget.onExit,
          );
        }

        final sim = controller.sim;
        final hud = RaceHudState(
          position: sim.position,
          totalRacers: sim.runs.length,
          lap: sim.player.lap.clamp(1, sim.track.laps),
          totalLaps: sim.track.laps,
          speedKmh: sim.speedKmh,
          item: controller.item,
          itemState: controller.itemState,
          boosting: sim.boosting || controller.drifting,
          trackProgress: [for (final r in sim.runs) r.progress],
          useMph: useMph,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            RaceScene(
              // Forces a clean remount on restart — see RaceController's
              // `generation` doc comment for why that matters now that the
              // kart's real position lives inside RaceScene's own physics
              // world instead of being handed in as a prop every frame.
              key: ValueKey(controller.generation),
              track: sim.track,
              kartModel: sim.playerKart.modelPath,
              // Reads the model straight off each rival's own id rather than a
              // separately-filtered kart list, so this can never drift out of
              // sync with who the controller actually put in the field.
              rivalModels: [
                for (final r in sim.runs.skip(1))
                  Catalog.kartById(r.id).modelPath,
              ],
              rivalProgress: [for (final r in sim.runs.skip(1)) r.progress],
              rivalLateral: [for (final r in sim.runs.skip(1)) r.lateralLane],
              // The player is a real physics body now, driven by these three
              // live inputs rather than placed by a progress/lateral value —
              // see RaceScene's own doc comment.
              running: controller.phase == RacePhase.racing,
              steer: controller.steer,
              braking: controller.braking,
              boosting: sim.boosting,
              accelStat: sim.playerKart.stat(KartStat.acceleration),
              onTelemetry: (progress, lateral, speedKmh) =>
                  controller.reportPlayerTelemetry(
                    progress: progress,
                    lateral: lateral,
                    speedKmh: speedKmh,
                  ),
              onCollision: controller.onPlayerCollision,
              // Shown while the scene loads, and on any device where Flutter
              // GPU is unavailable.
              fallback: _TrackBackdrop(
                track: sim.track,
                progress: sim.player.progress,
                steer: controller.steer,
                speed: sim.speedKmh / sim.topSpeed,
                boosting: sim.boosting,
              ),
            ),
            IgnorePointer(
              ignoring: controller.phase == RacePhase.paused,
              child: DashGameHUD(
                state: hud,
                onSteer: controller.setSteer,
                onBrake: controller.setBraking,
                onDrift: controller.setDrifting,
                onUseItem: controller.useItem,
                onPause: _pause,
                showControls: _pad?.connected != true,
              ),
            ),
            if (controller.phase == RacePhase.paused)
              _PauseOverlay(
                onResume: _resume,
                // Restart re-runs the sim locally with no way to bring the
                // opponent's device along, so it would desync a live race.
                onRestart: widget.multiplayer == null ? _restartRace : null,
                onQuit: _quit,
              ),
            if (controller.phase == RacePhase.countdown)
              CountdownOverlay(
                onBeat: controller.onCountdownBeat,
                onGo: () {
                  controller.startRacing();
                  _ticker.start();
                },
              ),
          ],
        );
      },
    );
  }
}

/// The race view.
///
/// A painted road that scrolls with progress and leans with steering — enough
/// to read as motion and to prove the HUD against a live background. This is
/// the single widget a `flutter_scene` `SceneView` replaces.
class _TrackBackdrop extends StatelessWidget {
  const _TrackBackdrop({
    required this.track,
    required this.progress,
    required this.steer,
    required this.speed,
    required this.boosting,
  });

  final Track track;
  final double progress;
  final double steer;
  final double speed;
  final bool boosting;

  static const _skies = <String, List<Color>>{
    'dash-valley': [Color(0xFF6FC7F5), Color(0xFF9EDCA8), Color(0xFF2F6B3E)],
    'neon-circuit': [Color(0xFF160E38), Color(0xFF3B1C6B), Color(0xFF1A0733)],
    'desert-rush': [Color(0xFFFFC17A), Color(0xFFE08A3C), Color(0xFF7A4620)],
    'frozen-peak': [Color(0xFFCFE8F7), Color(0xFF9FC0D8), Color(0xFF4A6A88)],
    'sky-harbor': [Color(0xFF8ED0FF), Color(0xFFD8ECFF), Color(0xFF5C93C9)],
    'cyber-coast': [Color(0xFFFF9E64), Color(0xFF9B5DE5), Color(0xFF1E2C63)],
  };

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _RoadPainter(
        palette: _skies[track.id] ?? DashGradients.menuSky,
        progress: progress,
        steer: steer,
        speed: speed,
        boosting: boosting,
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter({
    required this.palette,
    required this.progress,
    required this.steer,
    required this.speed,
    required this.boosting,
  });

  final List<Color> palette;
  final double progress;
  final double steer;
  final double speed;
  final bool boosting;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final horizon = size.height * 0.42;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette,
        ).createShader(rect),
    );

    // The vanishing point shifts against the steer, which is what sells a turn.
    final vp = size.width * (0.5 - steer * 0.12);

    // Ground.
    canvas.drawRect(
      Rect.fromLTRB(0, horizon, size.width, size.height),
      Paint()..color = palette.last.withValues(alpha: 0.9),
    );

    // Road surface.
    final road = Path()
      ..moveTo(vp - size.width * 0.035, horizon)
      ..lineTo(vp + size.width * 0.035, horizon)
      ..lineTo(size.width * 1.15, size.height)
      ..lineTo(-size.width * 0.15, size.height)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF2B2F3D));

    // Lane stripes, scrolling with distance travelled.
    canvas.save();
    canvas.clipPath(road);
    const bands = 16;
    for (var i = 0; i < bands; i++) {
      // Perspective: rows bunch up toward the horizon.
      final t0 = ((i + (progress * 40) % 1) / bands);
      final t1 = ((i + 0.5 + (progress * 40) % 1) / bands);
      double depth(double t) => math.pow(t, 2.4).toDouble();
      final y0 = horizon + (size.height - horizon) * depth(t0);
      final y1 = horizon + (size.height - horizon) * depth(t1);
      final halfW0 = size.width * (0.035 + 0.58 * depth(t0));
      final halfW1 = size.width * (0.035 + 0.58 * depth(t1));
      final x0 = vp + (size.width * 0.5 - vp) * depth(t0);
      final x1 = vp + (size.width * 0.5 - vp) * depth(t1);

      // Alternating tarmac bands give the road motion even when stripes are
      // too small to read.
      if (i.isEven) {
        canvas.drawPath(
          Path()
            ..moveTo(x0 - halfW0, y0)
            ..lineTo(x0 + halfW0, y0)
            ..lineTo(x1 + halfW1, y1)
            ..lineTo(x1 - halfW1, y1)
            ..close(),
          Paint()..color = const Color(0x14FFFFFF),
        );
      }
      // Centre line.
      canvas.drawPath(
        Path()
          ..moveTo(x0 - halfW0 * 0.02, y0)
          ..lineTo(x0 + halfW0 * 0.02, y0)
          ..lineTo(x1 + halfW1 * 0.03, y1)
          ..lineTo(x1 - halfW1 * 0.03, y1)
          ..close(),
        Paint()..color = const Color(0x99FFFFFF),
      );
    }
    canvas.restore();

    // Speed lines at the edges, intensifying with speed and boost.
    final intensity = (speed * (boosting ? 1.6 : 1.0)).clamp(0.0, 1.4);
    if (intensity > 0.35) {
      final rng = math.Random(3);
      final paint = Paint()..strokeCap = StrokeCap.round;
      for (var i = 0; i < 14; i++) {
        final side = i.isEven ? -1 : 1;
        final y = horizon + rng.nextDouble() * (size.height - horizon);
        final len = size.width * (0.08 + rng.nextDouble() * 0.16) * intensity;
        final x =
            size.width * 0.5 +
            side * (size.width * (0.28 + rng.nextDouble() * 0.22));
        paint
          ..strokeWidth = 2 + rng.nextDouble() * 2
          ..color = (boosting ? DashColors.orange.s300 : DashColors.textPrimary)
              .withValues(alpha: 0.10 + 0.14 * intensity);
        canvas.drawLine(Offset(x, y), Offset(x + side * len, y), paint);
      }
    }

    // Kart silhouette — makes it obvious the player is behind the wheel.
    _drawKartSilhouette(canvas, size, horizon, boosting);
  }

  void _drawKartSilhouette(
    Canvas canvas,
    Size size,
    double horizon,
    bool boosting,
  ) {
    final cx = size.width * 0.5;
    final base = size.height * 0.97;
    final w = size.width * 0.13;
    final h = size.height * 0.09;

    final shadow = Paint()..color = const Color(0x40000000);
    // Drop shadow ellipse.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, base - h * 0.1),
        width: w * 1.8,
        height: h * 0.35,
      ),
      shadow,
    );

    // Kart body.
    final bodyPaint = Paint()..color = const Color(0xFFD0D8F8);
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, base - h * 0.6),
      width: w * 1.6,
      height: h * 0.7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(6)),
      bodyPaint,
    );

    // Cockpit/visor.
    final cockpitPaint = Paint()..color = const Color(0xFF7B90E0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, base - h * 1.05),
          width: w * 0.7,
          height: h * 0.5,
        ),
        const Radius.circular(8),
      ),
      cockpitPaint,
    );

    // Wheels (four corners).
    final wheelPaint = Paint()..color = const Color(0xFF22232E);
    for (final dx in [-0.9, 0.9]) {
      for (final dy in [0.15, 0.65]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + w * dx * 0.8, base - h * dy),
            width: w * 0.36,
            height: h * 0.28,
          ),
          wheelPaint,
        );
      }
    }

    // Boost glow under exhaust.
    if (boosting) {
      final glow = Paint()
        ..color = DashColors.orange.s300.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, base - h * 0.05),
          width: w * 0.6,
          height: h * 0.2,
        ),
        glow,
      );
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.progress != progress ||
      old.steer != steer ||
      old.speed != speed ||
      old.boosting != boosting;
}

/// The pause screen. Sits over the frozen scene and HUD, offering Resume,
/// Restart, and Quit — the race loop is stopped for the whole time this is
/// on screen, so nothing behind it is moving.
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  final VoidCallback onResume;

  /// Null in multiplayer — restarting locally has no way to bring the
  /// opponent's device along, so the option is hidden rather than offered.
  final VoidCallback? onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: DashColors.scrim,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DashSpace.x6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(DashSpace.x6),
                decoration: BoxDecoration(
                  color: DashColors.surfaceRaised,
                  borderRadius: DashRadius.xlAll,
                  border: Border.all(color: DashColors.stroke),
                  boxShadow: DashElevation.dialog,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'PAUSED',
                      style: DashType.h1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DashSpace.x6),
                    DashButton(
                      label: 'Resume',
                      icon: DashIcons.pedal,
                      variant: DashButtonVariant.primary,
                      expand: true,
                      glow: true,
                      onPressed: onResume,
                    ),
                    if (onRestart != null) ...[
                      const SizedBox(height: DashSpace.x3),
                      DashButton(
                        label: 'Restart',
                        variant: DashButtonVariant.ghost,
                        expand: true,
                        onPressed: onRestart,
                      ),
                    ],
                    const SizedBox(height: DashSpace.x3),
                    DashButton(
                      label: 'Quit to Menu',
                      variant: DashButtonVariant.danger,
                      expand: true,
                      onPressed: onQuit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
