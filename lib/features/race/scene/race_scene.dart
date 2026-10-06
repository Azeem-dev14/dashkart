import 'dart:math' as math;

import 'package:flutter/widgets.dart' hide BoxShape;
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene/physics.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'package:dashkart/data/models.dart';
import 'package:dashkart/features/race/scene/scene3d.dart';

/// The 3D race view.
///
/// Builds a closed circuit out of the Kenney Racing Kit road pieces and
/// drives a *real* Rapier physics simulation on top of it: the player's kart
/// is a dynamic rigid body pushed around by [steer]/[braking]/[boosting]
/// each physics tick, rival karts are kinematic bodies placed by
/// [rivalProgress]/[rivalLateral] (still decided by `RaceSimulation`'s
/// pace-based AI, unchanged), and the track's barriers plus a ground plane
/// are static colliders. Crashing into a rival or a wall is resolved by the
/// physics engine itself, not by hand-rolled lane math — see [onCollision].
///
/// Since the player's position is no longer a scalar the caller hands in,
/// this widget derives it — [onTelemetry] reports the player's projected lap
/// progress and speed every physics step, which `RaceController` feeds back
/// into `RaceSimulation` for the HUD, lap timing, and finish detection.
///
/// The force/torque/damping constants below are a reasoned starting point
/// (matched to the old kinematic model's rough top-speed and lap-time
/// figures), not the result of feel-testing on a device — expect to retune
/// them once you can actually drive this.
class RaceScene extends StatefulWidget {
  const RaceScene({
    super.key,
    required this.track,
    required this.kartModel,
    required this.rivalModels,
    required this.rivalProgress,
    required this.rivalLateral,
    required this.running,
    required this.steer,
    required this.braking,
    required this.boosting,
    required this.accelStat,
    this.onTelemetry,
    this.onCollision,
    this.fallback,
  });

  /// Whether the player's kart should actually be driven this frame. False
  /// during the countdown and while paused — the physics world still steps
  /// every frame regardless (so a kart already settled onto the ground stays
  /// settled), but with this false no driving force/torque is applied and no
  /// telemetry is reported, matching how the race used to sit motionless
  /// before GO and freeze in place on pause.
  final bool running;

  final Track track;

  /// Path to the player's kart GLB.
  final String kartModel;

  final List<String> rivalModels;

  /// Each rival's current lap progress (fractional laps) — still decided by
  /// `RaceSimulation`'s pace formula; this scene only turns it into a
  /// kinematic pose.
  final List<double> rivalProgress;

  /// Each rival's fixed lane offset across the road, in world units — one
  /// entry per [rivalModels], indexed the same way. Comes from
  /// `RaceSimulation.laneFor` so the field this places matches the one the
  /// sim reasons about.
  final List<double> rivalLateral;

  /// Live steering input, -1 (full left) .. 1 (full right) — read every
  /// physics tick to torque the player's real rigid body. Not a one-shot
  /// event: held at its current value until the HUD reports a new one.
  final double steer;
  final bool braking;
  final bool boosting;

  /// The player kart's acceleration stat (1-10) — scales driving force so a
  /// nimbler kart still feels distinct under real physics.
  final int accelStat;

  /// Called every physics step with the player's projected lap progress
  /// (fractional laps — 2.4 means lap 3, 40% round, same meaning
  /// `RaceSimulation.player.progress` used to have), its signed offset from
  /// the spline at that point (world units — the same quantity the old
  /// `lateral` field used to be, kept only for multiplayer telemetry sync),
  /// and current speed in km/h. All three derived from the live physics body.
  final void Function(double progress, double lateral, double speedKmh)?
  onTelemetry;

  /// Called once per *new* contact the player's kart registers — with a
  /// rival or a track barrier — courtesy of Rapier's own collision
  /// lifecycle, which already only fires once per contact begin (no manual
  /// debouncing needed the way the old lane-based check required).
  final VoidCallback? onCollision;

  final Widget? fallback;

  /// The road piece and barrier GLBs every track is built from — exposed so
  /// a loading screen can warm them once alongside the per-track props from
  /// [propsForTrack], instead of keeping its own copy of these two paths.
  static const roadModelPath =
      'assets/models/tracks/track-road-wide-straight.glb';
  static const barrierModelPath = 'assets/models/environment/barrierRed.glb';

  /// The environment prop names — basenames under `assets/models/environment/`
  /// — scattered along [trackId]'s circuit. Exposed statically so a loading
  /// screen can warm the exact same assets [_RaceSceneState._dressTrack] is
  /// about to load, rather than keeping a second, driftable copy of this list.
  static List<String> propsForTrack(String trackId) => switch (trackId) {
    'dash-valley' => const ['tree_default', 'rock_smallA'],
    'desert-rush' => const ['cactus_short', 'rock_largeA'],
    'frozen-peak' => const ['tree_pineDefaultA', 'rock_largeB'],
    'neon-circuit' => const ['lightPostModern'],
    'cyber-coast' => const ['tent'],
    _ => const <String>[],
  };

  @override
  State<RaceScene> createState() => _RaceSceneState();
}

class _RaceSceneState extends State<RaceScene> {
  // Created only once 3D is known to work: the Scene constructor itself
  // initialises the engine's static resources.
  Scene? _scene;
  final List<Node> _rivals = [];
  Node? _kart;
  RigidBody? _playerBody;
  Collider? _playerCollider;
  bool _ready = false;
  bool _failed = false;

  /// Radius of the circuit's centre-line, in world units.
  static const _radius = 46.0;

  /// How much the lap deforms from a circle. 0 is an oval, higher is a
  /// recognisable circuit with a hairpin.
  static const _lobe = 0.22;

  /// The road piece's own footprint, in world units — Toy Car Kit's
  /// `track-road-wide-straight`, which is centred on its own local X axis
  /// (unlike the narrower, off-centre Racing Kit straight), so it tiles
  /// cleanly along the centre-line with no lane markings baked in.
  static const _pieceWidth = 2.0;
  static const _pieceLength = 4.2;

  /// Total drivable road width, in world units — open enough that steering
  /// reads as free movement across the road rather than fixed lanes.
  static const _roadWidth = 15.0;

  /// Half-width used to place barriers and scenery just past the tarmac.
  static const _roadHalfWidth = 7.4;

  /// Kart collider footprint, shared by the player and every rival — matches
  /// `KartPhysicsArena`'s footprint for the same models.
  static final vm.Vector3 _kartHalfExtents = vm.Vector3(0.85, 0.5, 0.95);

  /// Rough world-units-per-second → km/h conversion, derived from the old
  /// kinematic model's own numbers: a "fast" kart's pace implied about 9.6
  /// units/s around a ~289-unit lap (see `RaceSimulation._paceFor`'s "~30s
  /// lap" comment) against a top speed around 200 km/h. Cosmetic only — it
  /// only affects the HUD readout, not how the kart actually drives — but
  /// still worth a real-device check.
  static const _worldUnitToKmh = 21.0;

  /// Per-level sky gradient — top colour to bottom colour. One entry per
  /// [Catalog.tracks] id.
  static const _skies = <String, List<Color>>{
    'dash-valley': [Color(0xFF7BD2F7), Color(0xFFA8E6B4)],
    'neon-circuit': [Color(0xFF1A0640), Color(0xFF5B21B6)],
    'desert-rush': [Color(0xFFFFAE70), Color(0xFFD9701F)],
    'frozen-peak': [Color(0xFFD7EDFA), Color(0xFF7FB0CC)],
    'cyber-coast': [Color(0xFF22084F), Color(0xFF8B3FFF)],
  };

  /// Last frame's spline projection, for lap-wrap detection in
  /// [_reportTelemetry] — a big forward jump means a new lap started.
  double _lastT = 0;
  int _playerLaps = 0;
  bool _telemetryStarted = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  /// The circuit centre-line at lap fraction [t].
  static vm.Vector3 _pointAt(double t) {
    final a = t * math.pi * 2;
    final r = _radius * (1 + _lobe * math.sin(a * 2));
    return vm.Vector3(r * math.cos(a), 0, r * math.sin(a));
  }

  /// Forward direction along the centre-line, for orienting karts and pieces.
  static double _headingAt(double t) {
    const eps = 0.002;
    final a = _pointAt(t - eps);
    final b = _pointAt(t + eps);
    return math.atan2(b.x - a.x, b.z - a.z);
  }

  Future<void> _build() async {
    try {
      if (!await Scene3D.ensureReady()) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      // No-op on native; awaited unconditionally so this also works on web.
      await RapierWorld.ensureInitialized();

      final scene = _scene = Scene();
      final world = RapierWorld(gravity: vm.Vector3(0, -9.81, 0));
      // Collision events come off this wrapper, not the raw RapierWorld:
      // PhysicsWorld.collisions resolves handles to actual Node/Collider
      // objects (Stream<CollisionEvent>); RapierWorld.collisions is the
      // low-level, handle-keyed backend stream (Stream<SimCollisionEvent>).
      final physicsWorld = PhysicsWorld(world);
      scene.root.addComponent(physicsWorld);

      // Ground: one big flat static collider under the whole circuit —
      // simpler and far more robust than colliding against 96 individual
      // (purely visual) road-piece meshes, and the road never leaves this
      // footprint since it's laid out from the same centre-line.
      final groundExtent = _radius * (1 + _lobe) + _roadHalfWidth + 20;
      scene.add(
        Node(
            name: 'ground',
            localTransform: vm.Matrix4.translation(vm.Vector3(0, -0.5, 0)),
          )
          ..addComponent(RigidBody(type: BodyType.fixed))
          ..addComponent(
            Collider(
              shape: BoxShape(
                halfExtents: vm.Vector3(groundExtent, 0.5, groundExtent),
              ),
            ),
          ),
      );

      // Road. One straight piece per segment, rotated to follow the curve
      // and spaced so the pieces meet. Purely visual — the ground collider
      // above is what the player actually drives and crashes on.
      const segments = 96;
      final road = await loadScene(RaceScene.roadModelPath);
      for (var i = 0; i < segments; i++) {
        final t = i / segments;
        final piece = road.clone();
        final p = _pointAt(t);
        piece.position = p;
        piece.rotation = vm.Quaternion.axisAngle(
          vm.Vector3(0, 1, 0),
          _headingAt(t),
        );
        // Scale the piece's own footprint up to the open road width, and
        // along its length to close the gap to the next piece.
        final span = (_pointAt(t + 1 / segments) - p).length;
        piece.scale = vm.Vector3(
          _roadWidth / _pieceWidth,
          1,
          span * 1.06 / _pieceLength,
        );
        scene.add(piece);
      }

      // Trackside barriers, every few segments, on both sides — now real,
      // solid geometry: a static body + collider on each one, so driving
      // into the wall is an actual physics stop, not a pass-through.
      final barrier = await loadScene(RaceScene.barrierModelPath);
      for (var i = 0; i < segments; i += 3) {
        final t = i / segments;
        final heading = _headingAt(t);
        for (final side in [-1.0, 1.0]) {
          final b = barrier.clone();
          final offset = vm.Vector3(
            math.cos(heading) * _roadHalfWidth * side,
            0,
            -math.sin(heading) * _roadHalfWidth * side,
          );
          b.position = _pointAt(t) + offset;
          b.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), heading);
          b
            ..addComponent(RigidBody(type: BodyType.fixed))
            ..addComponent(
              Collider(shape: BoxShape(halfExtents: vm.Vector3(1.4, 1.0, 0.3))),
            );
          scene.add(b);
        }
      }

      await _dressTrack(scene, segments);

      // Player kart — a real dynamic body: driven by applyForce/applyTorque
      // every physics tick in _drivePlayer, unlike every other node in this
      // scene, which is placed directly by setting its transform.
      _kart = await loadScene(widget.kartModel);
      _kart!.position = _pointAt(0);
      _kart!.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 1, 0),
        _headingAt(0) + math.pi,
      );
      _kart!
        ..addComponent(
          RigidBody(
            type: BodyType.dynamic_,
            // Free to yaw only — locked pitch/roll so a side-swipe scrapes
            // and spins instead of tipping the kart over, which the model
            // has no wheel articulation to sell.
            angularAxisLocks: vm.Vector3(0, 1, 0),
            linearDamping: 0.8,
            angularDamping: 0.9,
            // Prevents tunnelling through a barrier at high speed.
            ccdEnabled: true,
          ),
        )
        ..addComponent(
          Collider(
            shape: BoxShape(halfExtents: _kartHalfExtents),
            material: const PhysicsMaterial(friction: 0.3, restitution: 0.35),
          ),
        );
      scene.add(_kart!);
      _playerBody = _kart!.getComponent<RigidBody>();
      _playerCollider = _kart!.getComponent<Collider>();

      // Rival karts — kinematic: `RaceController`/`RaceSimulation` still
      // decide where they are each tick (the same pace-based path as
      // before, via rivalProgress/rivalLateral); this scene just pushes
      // that pose onto a real body so the player's dynamic kart collides
      // with, and is pushed back by, something solid instead of clipping
      // through a purely visual node. A kinematic body pushes dynamic
      // bodies it touches but is never itself pushed — exactly what a bot
      // that isn't supposed to be knocked off its own line needs.
      for (final path in widget.rivalModels) {
        final r = await loadScene(path);
        r
          ..addComponent(RigidBody(type: BodyType.kinematic))
          ..addComponent(
            Collider(shape: BoxShape(halfExtents: _kartHalfExtents)),
          );
        _rivals.add(r);
        scene.add(r);
      }

      physicsWorld.collisions.listen(_onCollision);

      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onCollision(CollisionEvent event) {
    if (event is! CollisionBegan) return;
    final collider = _playerCollider;
    if (collider == null) return;
    if (identical(event.colliderA, collider) ||
        identical(event.colliderB, collider)) {
      widget.onCollision?.call();
    }
  }

  /// Per-track scenery. Each circuit reads differently because the prop set
  /// changes, not because the road does.
  Future<void> _dressTrack(Scene scene, int segments) async {
    // Every name here must exist under assets/models/environment/ — the prop
    // set is pruned to exactly these, so a miss is a bug rather than a
    // per-kit gap to shrug off.
    final props = RaceScene.propsForTrack(widget.track.id);

    for (final name in props) {
      Node prop;
      try {
        prop = await loadScene('assets/models/environment/$name.glb');
      } catch (_) {
        continue;
      }

      final rng = math.Random(widget.track.index * 31 + name.hashCode);
      for (var i = 0; i < segments; i += 4) {
        final t = i / segments + rng.nextDouble() * 0.005;
        final heading = _headingAt(t);
        final side = rng.nextBool() ? 1.0 : -1.0;
        final dist = _roadHalfWidth + 3 + rng.nextDouble() * 16;
        final clone = prop.clone();
        clone.position =
            _pointAt(t) +
            vm.Vector3(
              math.cos(heading) * dist * side,
              0,
              -math.sin(heading) * dist * side,
            );
        clone.rotation = vm.Quaternion.axisAngle(
          vm.Vector3(0, 1, 0),
          rng.nextDouble() * math.pi * 2,
        );
        final s = 0.8 + rng.nextDouble() * 0.8;
        clone.scale = vm.Vector3(s, s, s);
        scene.add(clone);
      }
    }
  }

  /// Places a kinematic rival on the circuit at lap fraction [t], offset
  /// [lateral] units across the road. Rival karts face the opposite way to
  /// the road heading, so flip them 180° — matches the player kart's own
  /// starting orientation in [_build].
  void _place(Node node, double t, double lateral) {
    final heading = _headingAt(t);
    node.position =
        _pointAt(t) +
        vm.Vector3(
          math.cos(heading) * lateral,
          0,
          -math.sin(heading) * lateral,
        );
    node.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(0, 1, 0),
      heading + math.pi,
    );
  }

  /// Applies this frame's steering/throttle/brake input as real forces and
  /// torque to the player's dynamic body.
  void _drivePlayer() {
    final body = _playerBody;
    if (body == null) return;

    final pose = body.readSimulationPose();
    // The kart model's local nose points along -Z (see [_place]'s 180°
    // flip); the same axis read back from the live rotation gives the
    // kart's current real-world facing.
    final forward = pose.$2.asRotationMatrix().transformed(
      vm.Vector3(0, 0, -1),
    );
    forward.y = 0;
    if (forward.length2 > 0) forward.normalize();

    final accelStat = widget.accelStat.clamp(1, 10);
    final baseForce = 40.0 + accelStat * 6.0;
    if (!widget.braking) {
      final thrust = baseForce * (widget.boosting ? 1.6 : 1.0);
      body.applyForce(forward * thrust);
    } else {
      // Brake: cut velocity directly rather than guessing an opposing
      // force magnitude — reads as a real stop, not a slow coast-down.
      body.linearVelocity = body.linearVelocity * 0.9;
    }

    // Steering torque scales with current speed, capped, so the kart
    // doesn't spin in place at a standstill and turns sharper the faster
    // it's going, up to a limit.
    final speed = body.linearVelocity.length;
    final steerTorque = -widget.steer * math.min(speed, 12.0) * 6.0;
    body.applyTorque(vm.Vector3(0, steerTorque, 0));
  }

  /// The spline parameter `t` closest to [position]. A plain sampled search
  /// over the whole lap every call — simplest correct approach, and cheap
  /// next to an actual physics step.
  double _projectOntoSpline(vm.Vector3 position) {
    const samples = 180;
    var bestT = 0.0;
    var bestDist = double.infinity;
    for (var i = 0; i < samples; i++) {
      final t = i / samples;
      final d = (_pointAt(t) - position).length2;
      if (d < bestDist) {
        bestDist = d;
        bestT = t;
      }
    }
    return bestT;
  }

  /// Projects the player's live physics position onto the track spline and
  /// reports lap progress + lateral offset + speed to
  /// [RaceScene.onTelemetry].
  void _reportTelemetry() {
    final body = _playerBody;
    if (body == null) return;

    final pose = body.readSimulationPose();
    final position = pose.$1;
    final t = _projectOntoSpline(position);

    if (_telemetryStarted) {
      // A big forward jump (near the end of the lap to near the start)
      // means a new lap began; the reverse means driving backward across
      // the line.
      if (_lastT > 0.75 && t < 0.25) {
        _playerLaps++;
      } else if (_lastT < 0.25 && t > 0.75) {
        _playerLaps--;
      }
    }
    _telemetryStarted = true;
    _lastT = t;

    // Signed distance from the spline at t, along the road's right vector —
    // the same quantity the old integrated `lateral` field represented.
    final heading = _headingAt(t);
    final right = vm.Vector3(math.cos(heading), 0, -math.sin(heading));
    final lateral = (position - _pointAt(t)).dot(right);

    final speedKmh = body.linearVelocity.length * _worldUnitToKmh;
    widget.onTelemetry?.call(_playerLaps + t, lateral, speedKmh);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !_ready || _scene == null) {
      return widget.fallback ?? const SizedBox.shrink();
    }

    for (var i = 0; i < _rivals.length; i++) {
      final rt =
          (i < widget.rivalProgress.length ? widget.rivalProgress[i] : 0.0) %
          1.0;
      final lane = i < widget.rivalLateral.length
          ? widget.rivalLateral[i]
          : 0.0;
      _place(_rivals[i], rt, lane);
    }

    final skyColors =
        _skies[widget.track.id] ?? const [Color(0xFF6FC7F5), Color(0xFF4A88BF)];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Sky gradient fills the void that SceneView leaves transparent.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: skyColors,
            ),
          ),
        ),
        // Ground plane colour (lower half) matches the track biome.
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.38,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    skyColors.last.withValues(alpha: 0),
                    skyColors.last.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
        ),
        SceneView(
          _scene!,
          onTick: (elapsed, deltaSeconds) {
            if (widget.running) _drivePlayer();
            _scene!.update(deltaSeconds);
            if (widget.running) _reportTelemetry();
          },
          cameraBuilder: (elapsed) {
            // Chase camera: sits behind and above the kart along its real,
            // physics-driven facing — no longer the spline tangent, since
            // the kart is free to slide/spin off it on a hard hit.
            final body = _playerBody;
            final pose = body?.readSimulationPose();
            final position = pose?.$1 ?? _pointAt(0);
            final forward = pose == null
                ? vm.Vector3(0, 0, -1)
                : pose.$2.asRotationMatrix().transformed(vm.Vector3(0, 0, -1));
            final speedNorm = ((body?.linearVelocity.length ?? 0) / 12.0).clamp(
              0.0,
              1.5,
            );

            final eye =
                position -
                forward * (5.0 + speedNorm * 2.0) +
                vm.Vector3(0, 4.0 + speedNorm * 1.2, 0);
            final look = position + forward * 6.0 + vm.Vector3(0, 0.6, 0);

            return PerspectiveCamera(
              position: eye,
              target: look,
              // FOV widens with speed so motion feels fast.
              fovRadiansY:
                  0.78 + speedNorm * 0.12 + (widget.boosting ? 0.08 : 0),
              fovFar: 500,
            );
          },
        ),
      ],
    );
  }
}
