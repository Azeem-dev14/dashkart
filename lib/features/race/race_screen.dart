import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/core/audio/audio_manager.dart';
import 'package:dashkart/core/scaffold/dash_scaffold.dart';
import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/scaffold/dash_ui_scale.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/features/race/race_controller.dart';
import 'package:dashkart/features/race/speed_lines.dart';
import 'package:dashkart/features/race/scene/race_scene.dart';
import 'package:dashkart/features/race/scene/race_simulation.dart';
import 'package:dashkart/features/gamepad/pad_session.dart';
import 'package:dashkart/features/multiplayer/multiplayer_service.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/features/race/countdown_overlay.dart';
import 'package:dashkart/features/results/results_screen.dart';
import 'package:dashkart/features/settings/settings_screen.dart';

/// The race.
///
/// Composes the countdown, the live HUD, the pause menu and the results layer
/// over the 3D scene. Owns only the [Ticker] — that needs a `vsync`, which is
/// inherently a widget concern — plus the app-lifecycle listener, and forwards
/// both to [RaceController]. Every other piece of race logic (the simulation,
/// collisions, item and drift timing, audio, multiplayer telemetry) lives in
/// the controller; this class renders whatever the controller currently holds.
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

class _RaceScreenState extends ConsumerState<RaceScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  RaceController? _controller;

  /// Pauses the race when the app goes to the background, and keeps it paused
  /// on return rather than dropping the player straight back into traffic.
  /// Without this the race carried on being driven — and the engine loop
  /// carried on playing — behind whatever the player switched to.
  late final AppLifecycleListener _lifecycle;

  /// False until `RaceScene` reports the circuit is built. The countdown and
  /// the HUD both wait on it, so the player never counts down over a
  /// placeholder and then has the world swapped underneath them.
  bool _sceneReady = false;

  /// The phone controller, when the web game has one attached. Its held
  /// inputs are copied into [_controller] on every change; its one-shot
  /// buttons arrive on [_padPresses].
  PadHost? _pad;
  StreamSubscription<PadPress>? _padPresses;

  /// Laps the HUD has already played a cue for, so crossing the line fires
  /// once rather than on every frame of the lap that follows.
  int _announcedLap = 1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _lifecycle = AppLifecycleListener(
      onHide: _suspend,
      onPause: _suspend,
      onRestart: () => AudioManager.instance.setSuspended(false),
      onShow: () => AudioManager.instance.setSuspended(false),
    );
  }

  void _suspend() {
    AudioManager.instance.setSuspended(true);
    final controller = _controller;
    if (controller != null && controller.phase == RacePhase.racing) _pause();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = _controller;
    if (controller == null) {
      // A one-off read: the controller keeps its own reference to the
      // PlayerState instance rather than re-reading it every rebuild.
      _controller = RaceController(
        player: ref.read(playerProvider),
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
    controller.setDrifting(pad.drift);
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
    _lifecycle.dispose();
    _ticker.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onTick(Duration now) {
    final controller = _controller!;
    final finished = controller.tick(now);
    _announceLap(controller);
    if (finished) _ticker.stop();
  }

  /// Crossing the line, and the one lap that deserves its own announcement.
  void _announceLap(RaceController controller) {
    final lap = controller.sim.player.lap;
    if (lap <= _announcedLap) {
      // A lap lost to driving backwards re-arms the cue rather than
      // suppressing it for the rest of the race.
      _announcedLap = lap;
      return;
    }
    _announcedLap = lap;
    if (lap >= controller.sim.track.laps) {
      AudioManager.instance.playFinalLap();
    } else {
      AudioManager.instance.playLapComplete();
    }
  }

  void _pause() {
    _controller!.pause();
    _ticker.stop();
  }

  void _resume() {
    _controller!.resume();
    _ticker.start();
  }

  /// Restarts, optionally on a different circuit — what the results screen's
  /// REPLAY and NEXT RACE do, instead of both quitting to the menu the way
  /// every results button used to.
  void _restartRace({Track? track}) {
    _controller!.restart(track: track);
    _ticker.stop();
    // A restart remounts RaceScene (its key changes), so the circuit is
    // built again and the countdown waits again.
    setState(() {
      _sceneReady = false;
      _announcedLap = 1;
    });
  }

  void _quit() {
    _controller!.quit();
    _ticker.stop();
    widget.onExit();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      DashPageRoute<void>(
        page: SettingsScreen(onBack: () => Navigator.of(context).maybePop()),
      ),
    );
  }

  /// The circuit the player goes to next: the following one in running order
  /// that they have actually unlocked, which on a fresh save is the only
  /// other starter circuit rather than a locked one they cannot enter.
  Track? get _nextTrack {
    final player = _controller!.player;
    var candidate = Catalog.nextTrack(_controller!.sim.track);
    for (var i = 0; i < Catalog.tracks.length; i++) {
      if (player.isTrackUnlocked(candidate)) return candidate;
      candidate = Catalog.nextTrack(candidate);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final settings = ref.watch(gameSettingsProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final result = controller.result;
        if (controller.phase == RacePhase.results && result != null) {
          final next = _nextTrack;
          return ResultsScreen(
            result: result,
            // Each button now does the thing it says. All three used to call
            // the same exit callback, so REPLAY and NEXT RACE quit to the
            // menu exactly like HOME did.
            onReplay: () => _restartRace(),
            onNext: next == null || controller.isMultiplayer
                ? null
                : () => _restartRace(track: next),
            nextLabel: next?.name.toUpperCase(),
            onHome: _quit,
            kartModelPath: controller.player.kart.modelPath,
            kartTint: controller.player.kart.livery,
          );
        }

        final sim = controller.sim;
        final telemetry = controller.telemetry;
        final hud = RaceHudState(
          position: sim.position,
          totalRacers: sim.runs.length,
          lap: sim.player.lap.clamp(1, sim.track.laps),
          totalLaps: sim.track.laps,
          speedKmh: sim.speedKmh,
          itemState: controller.itemState,
          boosting: sim.boosting,
          boostFraction: sim.boostFraction,
          driftCharge: telemetry.driftCharge,
          drifting: telemetry.drifting,
          wrongWay: telemetry.wrongWay,
          currentLap: sim.currentLap,
          bestLap: sim.bestLap,
          flash: controller.flash,
          trackProgress: [for (final r in sim.runs) r.progress],
          useMph: settings.useMph,
          trackId: sim.track.id,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // The 3D view renders into a texture at whatever size it is
            // given, so it opts out of the UI scale rather than being
            // rasterised small and magnified into a blur.
            DashUiScale.unscaled(
              child: RaceScene(
                // Forces a clean remount on restart — see RaceController's
                // `generation` doc comment for why that matters now that the
                // kart's real position lives inside RaceScene's own physics
                // world instead of being handed in as a prop every frame.
                key: ValueKey(controller.generation),
                track: sim.track,
                kartModel: sim.playerKart.modelPath,
                kartTint: sim.playerKart.livery,
                startLateral: widget.multiplayer == null
                    ? 0
                    : RaceSimulation.multiplayerStartLane(
                        isHost:
                            widget.multiplayer!.role == MultiplayerRole.host,
                      ),
                // Reads the model straight off each rival's own id rather
                // than a separately-filtered kart list, so this can never
                // drift out of sync with who the controller actually put in
                // the field.
                rivalModels: [
                  for (final r in sim.runs.skip(1))
                    Catalog.kartById(r.id).modelPath,
                ],
                rivalTints: [
                  for (final r in sim.runs.skip(1))
                    Catalog.kartById(r.id).livery,
                ],
                rivalProgress: [for (final r in sim.runs.skip(1)) r.progress],
                rivalLateral: [for (final r in sim.runs.skip(1)) r.lateralLane],
                // The player is a real physics body, driven by these live
                // inputs rather than placed by a progress value.
                running: controller.phase == RacePhase.racing,
                steer: controller.steer,
                braking: controller.braking,
                drifting: controller.drifting,
                boosting: sim.boosting,
                tuning: sim.tuning,
                graphics: settings.graphics,
                steeringSensitivity: settings.steeringSensitivity,
                cameraShake: settings.cameraShake,
                onTelemetry: controller.reportTelemetry,
                onCollision: controller.onPlayerCollision,
                onPickup: controller.collectTurbo,
                onDriftBoost: controller.onDriftBoost,
                onReady: () {
                  if (mounted) setState(() => _sceneReady = true);
                },
                loading: _RaceLoading(track: sim.track),
                // Where Flutter GPU is unavailable the 2D stand-in is the
                // actual game, so the controller has to start driving the
                // player itself — otherwise the kart never moves and the
                // race can never end.
                onUnavailable: () {
                  if (!mounted) return;
                  controller.useKinematicFallback();
                  setState(() => _sceneReady = true);
                },
                fallback: _TrackBackdrop(
                  track: sim.track,
                  progress: sim.player.progress,
                  steer: controller.steer,
                  speed: sim.speedKmh / sim.topSpeed,
                  boosting: sim.boosting,
                ),
              ),
            ),
            if (settings.graphics.speedLines)
              SpeedLines(
                speed: sim.speedKmh / sim.topSpeed,
                boosting: sim.boosting,
                seconds: sim.elapsed.inMilliseconds / 1000.0,
              ),
            if (_sceneReady)
              RepaintBoundary(
                child: IgnorePointer(
                  ignoring: controller.phase != RacePhase.racing,
                  child: DashGameHUD(
                    state: hud,
                    onSteer: controller.setSteer,
                    onBrake: controller.setBraking,
                    onDrift: controller.setDrifting,
                    onUseItem: controller.useItem,
                    onPause: _pause,
                    showControls: _pad?.connected != true,
                    steering: settings.steering,
                  ),
                ),
              ),
            if (controller.phase == RacePhase.paused)
              _PauseOverlay(
                onResume: _resume,
                // Restart re-runs the sim locally with no way to bring the
                // opponent's device along, so it would desync a live race.
                onRestart: widget.multiplayer == null ? _restartRace : null,
                onSettings: _openSettings,
                onQuit: _quit,
                lap: sim.player.lap.clamp(1, sim.track.laps),
                totalLaps: sim.track.laps,
                position: sim.position,
                totalRacers: sim.runs.length,
              ),
            if (_sceneReady && controller.phase == RacePhase.countdown)
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
    'desert-rush': [Color(0xFFFFC17A), Color(0xFFE08A3C), Color(0xFF7A4620)],
    'frozen-peak': [Color(0xFFCFE8F7), Color(0xFF9FC0D8), Color(0xFF4A6A88)],
    'sky-harbor': [Color(0xFF8ED0FF), Color(0xFFD8ECFF), Color(0xFF5C93C9)],
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

/// The pause screen.
///
/// Sits over the frozen scene and HUD, offering Resume, Restart, Settings and
/// Quit — the race loop is stopped for the whole time this is on screen, so
/// nothing behind it is moving. It also states where the race stands, since
/// the HUD behind it is dimmed to the point of being unreadable.
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onSettings,
    required this.onQuit,
    required this.lap,
    required this.totalLaps,
    required this.position,
    required this.totalRacers,
  });

  final VoidCallback onResume;

  /// Null in multiplayer — restarting locally has no way to bring the
  /// opponent's device along, so the option is hidden rather than offered.
  final VoidCallback? onRestart;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final int lap;
  final int totalLaps;
  final int position;
  final int totalRacers;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xCC050A24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: DashSpace.x3),
                padding: EdgeInsets.fromLTRB(22, 14, 22, compact ? 16 : 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DashColors.pureBlack, width: 3.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF0A1040),
                      offset: Offset(0, 6),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: Color(0x80000000),
                      offset: Offset(0, 12),
                      blurRadius: 18,
                    ),
                  ],
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3B4FC4), Color(0xFF1B2A86)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: BrawlTitleText(
                        'PAUSED',
                        fontSize: compact ? 28 : 34,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: BrawlInkText(
                        '${RaceHudState.ordinal(position)} OF $totalRacers'
                        '   ·   LAP $lap/$totalLaps',
                        fontSize: 13,
                        color: const Color(0xFFCBD6FF),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    BrawlActionButton(
                      label: 'RESUME',
                      height: compact ? 44 : 50,
                      onPressed: onResume,
                    ),
                    if (onRestart != null) ...[
                      SizedBox(height: compact ? 8 : 12),
                      BrawlActionButton(
                        label: 'RESTART',
                        tone: BrawlButtonTone.yellow,
                        height: compact ? 44 : 50,
                        onPressed: onRestart,
                      ),
                    ],
                    SizedBox(height: compact ? 8 : 12),
                    BrawlActionButton(
                      label: 'SETTINGS',
                      tone: BrawlButtonTone.blue,
                      height: compact ? 44 : 50,
                      onPressed: onSettings,
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    BrawlActionButton(
                      label: 'QUIT TO MENU',
                      tone: BrawlButtonTone.red,
                      height: compact ? 44 : 50,
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

/// Shown for the moment it takes to build the circuit.
///
/// Deliberately *not* the 2D stand-in track: showing a different-looking
/// playable road and then swapping the real world in underneath read as a
/// glitch. This states plainly that the track is loading, over the same sky
/// the circuit itself uses, so the 3D scene fades in against a background
/// that is already the right colour.
class _RaceLoading extends StatelessWidget {
  const _RaceLoading({required this.track});

  final Track track;

  /// The upper sky colour each circuit opens on, matching `RaceScene`'s own.
  static const _skies = <String, List<Color>>{
    'dash-valley': [Color(0xFF7BD2F7), Color(0xFFA8E6B4)],
    'desert-rush': [Color(0xFFFFAE70), Color(0xFFD9701F)],
    'frozen-peak': [Color(0xFFD7EDFA), Color(0xFF7FB0CC)],
  };

  @override
  Widget build(BuildContext context) {
    final sky =
        _skies[track.id] ?? const [Color(0xFF6FC7F5), Color(0xFF4A88BF)];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashColors.pureBlack, width: 3.5),
            boxShadow: const [
              BoxShadow(color: Color(0xFF0A1040), offset: Offset(0, 5)),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B4FC4), Color(0xFF1B2A86)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrawlTitleText(track.name.toUpperCase(), fontSize: 26),
              const SizedBox(height: 6),
              BrawlInkText(
                'BUILDING THE TRACK...',
                fontSize: 13,
                color: const Color(0xFFCBD6FF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
