import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart' hide BoxShape;
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene/physics.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/kart_tuning.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/track_shape.dart';
import 'package:dashkart/features/race/race_telemetry.dart';
import 'package:dashkart/features/race/steering.dart';
import 'package:dashkart/features/race/scene/scene3d.dart';
import 'package:dashkart/features/race/scene/turbo_icon.dart';
import 'package:dashkart/features/settings/graphics_tier.dart';

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
/// How the kart drives comes from [tuning], which is derived once from the
/// selected kart's stat card — so the five numbers the
/// player compares on a kart card are the five numbers the physics runs on,
/// rather than the single hard-coded set every kart used to share.
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
    required this.drifting,
    required this.boosting,
    required this.tuning,
    this.kartTint,
    this.startLateral = 0,
    this.rivalTints = const [],
    this.graphics = GraphicsTier.medium,
    this.steeringSensitivity = 0.6,
    this.cameraShake = true,
    this.onTelemetry,
    this.onCollision,
    this.onPickup,
    this.onDriftBoost,
    this.onReady,
    this.onUnavailable,
    this.loading,
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

  /// The drift button is held. On its own this does nothing: a drift needs
  /// speed and a steering angle, so holding it down a straight neither slides
  /// the kart nor charges a mini-turbo.
  final bool drifting;

  final bool boosting;

  /// Everything about how this kart drives — top speed, acceleration, yaw
  /// rate, grip, drift behaviour, mass and braking — derived from its stat
  /// card.
  final KartTuning tuning;

  /// Livery tint multiplied into the player's kart materials, and one per
  /// rival in [rivalModels] order, so a field sharing a model is still
  /// readable at a glance.
  final Color? kartTint;

  /// Where across the road the player's kart starts, in world units from the
  /// centre line. Zero in a solo race; a live race starts each side in its
  /// own lane so the two karts are not spawned on top of each other.
  final double startLateral;
  final List<Color?> rivalTints;

  /// The render budget to build and draw this circuit to.
  final GraphicsTier graphics;

  /// 0..1 from settings. Scales how fast held steering ramps to full lock —
  /// low is deliberate and forgiving, high is immediate and twitchy.
  final double steeringSensitivity;

  /// Whether impacts and boosts kick the camera.
  final bool cameraShake;

  /// Called every physics step with everything measured off the live rigid
  /// body — see [RaceTelemetry].
  final ValueChanged<RaceTelemetry>? onTelemetry;

  /// Called once per *new* contact the player's kart registers — with a
  /// rival or a track barrier — courtesy of Rapier's own collision
  /// lifecycle, which already only fires once per contact begin (no manual
  /// debouncing needed the way the old lane-based check required).
  final VoidCallback? onCollision;

  /// Called when the player's kart drives through a turbo pickup on the
  /// track. The pickup then vanishes and respawns a few seconds later.
  final VoidCallback? onPickup;

  /// Called the moment a drift is released with a full charge — the mini
  /// turbo a kart racer's cornering lives on. The scene decides when it is
  /// earned (it is the only thing that knows the kart's real slip angle);
  /// the controller decides what a boost does.
  final VoidCallback? onDriftBoost;

  /// Fires once the circuit is built and the first real frame can be drawn.
  /// The caller holds the countdown until then — counting 3-2-1-GO over a
  /// stand-in and then swapping the world underneath the player is the
  /// single most jarring thing this screen can do.
  final VoidCallback? onReady;

  /// Fires once, when the circuit cannot be built at all — no Flutter GPU on
  /// this device, or a scene that failed to load. The caller has to be told
  /// rather than left to notice: the 2D [fallback] renders, but nothing is
  /// driving the player, so without this the kart sits still and the race can
  /// never finish.
  final VoidCallback? onUnavailable;

  /// Shown while the circuit is being built. Distinct from [fallback]: this
  /// is a short, expected wait on a device that *can* render 3D, so it wants
  /// a deliberate "getting ready" state, not the 2D stand-in track.
  final Widget? loading;

  /// Shown when 3D is unavailable on this device at all, in which case the
  /// 2D stand-in is the actual game rather than a placeholder.
  final Widget? fallback;

  /// The road piece every circuit is tiled from — exposed so the loading
  /// screen can warm it alongside the per-track props from [propsForTrack],
  /// instead of keeping its own copy of the path.
  static const roadModelPath =
      'assets/models/tracks/track-road-wide-straight.glb';

  /// Every kart the player can drive. Both limits below are worst-cased over
  /// this, because a circuit only has to defeat *one* of them to be
  /// undrivable.
  static Iterable<KartTuning> get _everyTuning => [
    for (final kart in Catalog.karts) KartTuning.of(kart),
  ];

  /// The tightest circle the *least agile* kart in the game can physically
  /// hold at top speed, in world units: full lock, flat out. A circuit with a
  /// corner tighter than this cannot be got round at all, so
  /// `track_shape_test.dart` holds every [TrackShape] above it — and derives
  /// the figure from the kart tuning, so rebalancing a kart re-checks the
  /// circuits rather than quietly making one impossible.
  static double get minimumTurnRadius => _everyTuning
      .map((t) => t.minimumTurnRadius)
      .reduce((a, b) => a > b ? a : b);

  /// The same, while a turbo is burning — a corner tighter than this has to
  /// be taken off boost.
  static double get boostingTurnRadius => _everyTuning
      .map((t) => t.boostingTurnRadius)
      .reduce((a, b) => a > b ? a : b);

  /// The environment prop names — basenames under `assets/models/environment/`
  /// — scattered along [trackId]'s circuit. Exposed statically so a loading
  /// screen can warm the exact same assets [_RaceSceneState._dressTrack] is
  /// about to load, rather than keeping a second, driftable copy of this list.
  static List<String> propsForTrack(String trackId) => switch (trackId) {
    'dash-valley' => const ['tree_default', 'rock_smallA'],
    'desert-rush' => const ['cactus_short', 'rock_largeA'],
    'frozen-peak' => const ['tree_pineDefaultA', 'rock_largeB'],
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

  /// This circuit's plan view — its size, how many corners it has and how
  /// tight they are. One per track, so the five no longer share a shape.
  late final TrackShape _shape = TrackShape.forTrack(widget.track.id);

  /// The road piece's own footprint, in world units — Toy Car Kit's
  /// `track-road-wide-straight`, which is centred on its own local X axis
  /// (unlike the narrower, off-centre Racing Kit straight), so it tiles
  /// cleanly along the centre-line with no lane markings baked in.
  static const _pieceWidth = 2.0;
  static const _pieceLength = 4.2;

  /// Height of the road model's tarmac above its own origin; the kerbs reach
  /// 0.3, the surface itself only about 0.1.
  static const _roadSurfaceHeight = 0.1;

  /// Total drivable road width, in world units — open enough that steering
  /// reads as free movement across the road rather than fixed lanes.
  static const _roadWidth = 15.0;

  /// Half-width used to place barriers and scenery just past the tarmac.
  static const _roadHalfWidth = 7.4;

  /// Kart collider footprint, shared by the player and every rival.
  static final vm.Vector3 _kartHalfExtents = vm.Vector3(0.85, 0.5, 0.95);

  /// Mass of an average-weight kart, which `KartTuning.mass` scales. Only
  /// the ratio between two karts matters — the driving model sets velocity
  /// directly, so mass is felt in collisions and nowhere else.
  static const _kartBaseMass = 220.0;

  /// A livery colour as a base-colour factor: multiplied into the model's
  /// own texture, and converted to linear first, since a raw sRGB value fed
  /// to a PBR factor bleaches the whole body pale.
  static vm.Vector4 _liveryFactor(Color c) =>
      vm.Vector4(_lin(c.r), _lin(c.g), _lin(c.b), 1);

  /// Per-level sky gradient — top colour to bottom colour. One entry per
  /// [Catalog.tracks] id.
  static const _skies = <String, List<Color>>{
    'dash-valley': [Color(0xFF7BD2F7), Color(0xFFA8E6B4)],
    'desert-rush': [Color(0xFFFFAE70), Color(0xFFD9701F)],
    'frozen-peak': [Color(0xFFD7EDFA), Color(0xFF7FB0CC)],
  };

  /// Per-level ground colour — the terrain the circuit sits on. One entry per
  /// [Catalog.tracks] id, matched to the sky so the horizon fog blends.
  static const _grounds = <String, Color>{
    'dash-valley': Color(0xFF4FA95B),
    'desert-rush': Color(0xFFD9A25A),
    'frozen-peak': Color(0xFFE8F3FA),
  };

  /// Per-level road tint, multiplied into the road model's texture (values
  /// above 1 brighten). Each circuit gets its own tarmac colour instead of the
  /// model's one blue-grey, matched to its biome.
  static final _roadTints = <String, vm.Vector4>{
    'dash-valley': vm.Vector4(1.7, 1.25, 0.85, 1), // warm sandy asphalt
    'desert-rush': vm.Vector4(1.8, 0.85, 0.55, 1), // red-clay
    'frozen-peak': vm.Vector4(0.7, 1.5, 2.2, 1), // glacier blue
  };

  /// Tints every PBR material under [node] — the road's tarmac and kerbs.
  static void _tint(Node node, vm.Vector4 colour) {
    for (final primitive in node.mesh?.primitives ?? const <MeshPrimitive>[]) {
      final material = primitive.material;
      if (material is PhysicallyBasedMaterial) {
        material.baseColorFactor = colour;
      }
    }
    for (final child in node.children) {
      _tint(child, colour);
    }
  }

  /// Last frame's spline projection, for lap-wrap detection in
  /// [_reportTelemetry] — a big forward jump means a new lap started.
  double _lastT = 0;
  int _playerLaps = 0;
  bool _telemetryStarted = false;

  /// Turbo pickups placed around the circuit, and the seconds left until each
  /// one respawns (0 = available).
  final List<Node> _pickups = [];
  final List<double> _pickupCooldown = [];
  double _clock = 0;
  static const _pickupRadius = 1.9;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void didUpdateWidget(RaceScene old) {
    super.didUpdateWidget(old);
    // The moment a turbo lights, not every frame it burns for.
    if (widget.boosting && !old.boosting && widget.cameraShake) {
      _kick(_boostKick);
    }
  }

  /// The circuit centre-line at lap fraction [t].
  vm.Vector3 _pointAt(double t) {
    final (x, z) = _shape.pointAt(t);
    return vm.Vector3(x, 0, z);
  }

  /// Forward direction along the centre-line, for orienting karts and pieces.
  double _headingAt(double t) => _shape.headingAt(t);

  Future<void> _build() async {
    try {
      if (!await Scene3D.ensureReady()) {
        _fail();
        return;
      }
      // No-op on native; awaited unconditionally so this also works on web.
      await RapierWorld.ensureInitialized();

      final scene = _scene = Scene();
      // Phones render at 2.5-3.5x device pixel ratio and the raster thread
      // is what janks first, so this is the single biggest lever the quality
      // setting has. The medium default of 0.78 keeps the image crisp enough
      // for a chase-cam arcade view while cutting filled pixels by ~39%.
      scene.renderScale = widget.graphics.renderScale;
      _applyLook(scene);
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
      final groundExtent = _shape.maxRadius + _roadHalfWidth + 20;
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

      // Road. One straight piece per segment, laid along the *chord* between
      // consecutive spline points (not the tangent at the start) and centred
      // on it, so neighbouring pieces meet instead of opening wedge gaps on
      // curves. The piece's real bounds are read at runtime: the model's
      // origin is at one end of its length and the file offsets it down, so
      // both are corrected for rather than assumed.
      final segments = widget.graphics.roadSegments;
      final road = await loadScene(RaceScene.roadModelPath);
      final tint = _roadTints[widget.track.id];
      if (tint != null) _tint(road, tint);
      final bounds = road.combinedLocalBounds;
      final zMin = bounds?.min.z ?? -0.2;
      final zMax = bounds?.max.z ?? _pieceLength;
      final xWidth = bounds == null ? _pieceWidth : bounds.max.x - bounds.min.x;
      final xCentre = bounds == null ? 0.0 : (bounds.min.x + bounds.max.x) / 2;
      // Put the *tarmac* flush with the physics ground at y = 0. Not the
      // model's bounds: its highest point is the kerb (0.3), not the road
      // surface (0.1), so aligning the bounds buries the tarmac. Assigning
      // `piece.position` below replaces the root node's own translation (the
      // file stores a -1 drop there), so only offsets on child nodes count.
      double surfaceY(Node n) {
        var y = n.mesh != null ? _roadSurfaceHeight : double.negativeInfinity;
        for (final c in n.children) {
          y = math.max(y, c.position.y + surfaceY(c));
        }
        return y;
      }

      final lift = -surfaceY(road);
      final pieceLength = zMax - zMin;
      final zCentre = (zMin + zMax) / 2;
      final widthScale = _roadWidth / xWidth;
      final up = vm.Vector3(0, 1, 0);

      for (var i = 0; i < segments; i++) {
        final p0 = _pointAt(i / segments);
        final p1 = _pointAt((i + 1) / segments);
        final chord = p1 - p0;
        final heading = math.atan2(chord.x, chord.z);
        final forward = vm.Vector3(math.sin(heading), 0, math.cos(heading));
        final right = vm.Vector3(math.cos(heading), 0, -math.sin(heading));
        final mid = (p0 + p1) * 0.5;

        // 25% overlap along the length covers the wedge that opens on the
        // outside of a bend; alternating a hair of height stops the
        // overlapped tops z-fighting.
        final lengthScale = chord.length * 1.25 / pieceLength;
        final piece = road.clone();
        piece.rotation = vm.Quaternion.axisAngle(up, heading);
        piece.scale = vm.Vector3(widthScale, 1, lengthScale);
        piece.position =
            mid -
            forward * (zCentre * lengthScale) -
            right * (xCentre * widthScale) +
            vm.Vector3(0, lift + (i.isEven ? 0.0 : 0.004), 0);
        // Flat tarmac never shadows anything; skip it in the shadow pass.
        piece.castsShadows = false;
        piece.shadowStatic = true;
        scene.add(piece);

        // Solid walls down both edges, one per *pair* of segments and a
        // little longer than the pair, so bends leave no gap to slip
        // through. Invisible: the road model's own kerbs mark the edge, and
        // this is what actually stops the kart. Pairing halves the number of
        // physics bodies the circuit has to build and step, which is most of
        // what the player waits for when a race starts.
        if (i.isEven) {
          final p2 = _pointAt((i + 2) / segments);
          final span = p2 - p0;
          final spanHeading = math.atan2(span.x, span.z);
          final spanMid = (p0 + p2) * 0.5;
          final spanRight = vm.Vector3(
            math.cos(spanHeading),
            0,
            -math.sin(spanHeading),
          );
          for (final side in [-1.0, 1.0]) {
            scene.add(
              Node(
                  name: 'wall',
                  localTransform: vm.Matrix4.compose(
                    spanMid +
                        spanRight * ((_roadHalfWidth + 0.5) * side) +
                        vm.Vector3(0, 1, 0),
                    vm.Quaternion.axisAngle(up, spanHeading),
                    vm.Vector3.all(1),
                  ),
                )
                ..addComponent(RigidBody(type: BodyType.fixed))
                ..addComponent(
                  Collider(
                    shape: BoxShape(
                      halfExtents: vm.Vector3(0.5, 1.0, span.length * 0.62),
                    ),
                    // Slippery and dead: clipping a barrier should slide the
                    // kart along it, never bounce it back into traffic.
                    material: const PhysicsMaterial(
                      friction: 0.05,
                      restitution: 0.0,
                    ),
                  ),
                ),
            );
          }
        }
      }

      await _dressTrack(scene, segments);
      Texture2D? turboIcon;
      try {
        turboIcon = await TurboIcon.load();
      } catch (_) {
        // Falls back to the plain glowing orb.
      }
      _placePickups(scene, turboIcon);
      _placeStartGantry(scene);

      // Player kart — a real dynamic body: its velocity is set outright
      // every physics tick in _drivePlayer, unlike every other node in this
      // scene, which is placed directly by setting its transform.
      _kart = await loadScene(widget.kartModel);
      final kartTint = widget.kartTint;
      if (kartTint != null) _tint(_kart!, _liveryFactor(kartTint));
      final startHeading = _headingAt(0);
      _kart!.position =
          _pointAt(0) +
          vm.Vector3(
            math.cos(startHeading) * widget.startLateral,
            0,
            -math.sin(startHeading) * widget.startLateral,
          );
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
            // No damping: _drivePlayer sets the velocity outright every
            // frame, so damping would only fight the model it is driving.
            linearDamping: 0,
            angularDamping: 0,
            // Prevents tunnelling through a barrier at high speed.
            ccdEnabled: true,
            // The weight stat, made real: a heavy kart shoves a light one
            // aside in a bump and is barely moved itself. Scales the mass
            // Rapier would otherwise derive from the collider volume.
            mass: _kartBaseMass * widget.tuning.mass,
          ),
        )
        ..addComponent(
          Collider(
            shape: BoxShape(halfExtents: _kartHalfExtents),
            // Low restitution: clipping a barrier should scrub speed and
            // scrape, never bounce the kart back across the road.
            material: const PhysicsMaterial(friction: 0.4, restitution: 0.05),
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
      for (var i = 0; i < widget.rivalModels.length; i++) {
        final r = await loadScene(widget.rivalModels[i]);
        final tint = i < widget.rivalTints.length ? widget.rivalTints[i] : null;
        // A field sharing one kart model is unreadable in a mirror glance;
        // a per-rival livery is what separates them at racing speed.
        if (tint != null) _tint(r, _liveryFactor(tint));
        r
          ..addComponent(RigidBody(type: BodyType.kinematic))
          ..addComponent(
            Collider(shape: BoxShape(halfExtents: _kartHalfExtents)),
          );
        _rivals.add(r);
        scene.add(r);
      }

      physicsWorld.collisions.listen(_onCollision);

      if (mounted) {
        setState(() => _ready = true);
        widget.onReady?.call();
      }
    } catch (_) {
      _fail();
    }
  }

  /// Gives up on 3D for this mount and tells the caller exactly once, so it
  /// can take over driving the player.
  void _fail() {
    if (!mounted || _failed) return;
    setState(() => _failed = true);
    widget.onUnavailable?.call();
  }

  /// sRGB channel → linear. Material factors and fog colour are linear, so
  /// feeding them raw sRGB values bleaches everything pale.
  static double _lin(double c) => math.pow(c, 2.2).toDouble();

  static vm.Vector3 _rgb(Color c) =>
      vm.Vector3(_lin(c.r), _lin(c.g), _lin(c.b));

  /// Gives the scene a deliberate look instead of a bare render: a real
  /// terrain plane, a shadow-casting sun, horizon fog that blends into the
  /// sky gradient behind the view, and a vivid graded, bloomed stylized
  /// finish. Kept to cheap effects (no AO/SSR/DoF) so it holds frame rate on
  /// phones.
  void _applyLook(Scene scene) {
    final sky =
        _skies[widget.track.id] ?? const [Color(0xFF6FC7F5), Color(0xFF4A88BF)];
    final groundColor = _grounds[widget.track.id] ?? const Color(0xFF4FA95B);

    // Terrain: one big plane just under the road, so the track sits on a
    // world instead of floating over a gradient.
    final groundMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(
        _lin(groundColor.r),
        _lin(groundColor.g),
        _lin(groundColor.b),
        1,
      )
      ..roughnessFactor = 1.0
      ..metallicFactor = 0.0;
    scene.add(
      Node(
          name: 'terrain',
          mesh: Mesh(PlaneGeometry(width: 1200, depth: 1200), groundMaterial),
          localTransform: vm.Matrix4.translation(vm.Vector3(0, -0.12, 0)),
        )
        ..castsShadows = false
        ..shadowStatic = true,
    );

    // One sun, one grade, one bloom for every circuit. The kart must look the
    // same colour wherever it races, and its colour is whatever the light and
    // the grade make of it — a cool moonlight or a lower bloom threshold on
    // the night tracks changed the kart's paint from circuit to circuit. The
    // biome comes from the sky, ground, road tint and scenery instead.
    scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.45, -0.85, -0.3),
      color: vm.Vector3(1.0, 0.94, 0.82),
      intensity: 2.4,
      castsShadow: widget.graphics.shadows,
      shadowMaxDistance: 70,
      shadowCascadeCount: widget.graphics.shadowCascades,
    );

    scene.environmentSettings = EnvironmentSettings(
      toneMapping: ToneMappingMode.aces,
      exposure: 1.0,
      colorGradingEnabled: true,
      saturation: 1.25,
      contrast: 1.1,
      brightness: 1.03,
      temperature: 0.1,
      bloomEnabled: widget.graphics.bloom,
      bloomThreshold: 1.3,
      bloomIntensity: 0.22,
      bloomScatter: 0.75,
      vignetteEnabled: true,
      vignetteIntensity: 0.22,
      fogEnabled: true,
      fogMode: FogMode.exponential,
      fogColor: _rgb(sky.last),
      fogDensity: widget.graphics.fogDensity,
    );
  }

  /// A start/finish gantry arching over the road just past the grid: two
  /// pillars, a glowing beam, and a chequered band — the one landmark every
  /// lap passes under, and a clear read of where the line is.
  void _placeStartGantry(Scene scene) {
    const t = 0.03;
    final heading = _headingAt(t);
    final half = _roadHalfWidth + 1.4;
    const height = 7.0;

    final pillar = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.08, 0.1, 0.25, 1)
      ..roughnessFactor = 0.5
      ..metallicFactor = 0.3;
    final beam = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(1.0, 0.3, 0.08, 1)
      ..emissiveFactor = vm.Vector4(1.6, 0.4, 0.05, 1)
      ..roughnessFactor = 0.4;
    final white = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.95, 0.95, 0.95, 1)
      ..roughnessFactor = 0.6;
    final black = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.03, 0.03, 0.04, 1)
      ..roughnessFactor = 0.6;

    final root = Node(
      name: 'start-gantry',
      localTransform: vm.Matrix4.compose(
        _pointAt(t),
        vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), heading),
        vm.Vector3.all(1),
      ),
    );

    Node box(vm.Vector3 size, vm.Vector3 at, Material m) => Node(
      mesh: Mesh(CuboidGeometry(size), m),
      localTransform: vm.Matrix4.translation(at),
    )..shadowStatic = true;

    for (final side in const [-1.0, 1.0]) {
      root.add(
        box(
          vm.Vector3(1.1, height, 1.1),
          vm.Vector3(half * side, height / 2, 0),
          pillar,
        ),
      );
    }
    root.add(
      box(
        vm.Vector3(half * 2 + 1.1, 1.3, 1.1),
        vm.Vector3(0, height + 0.2, 0),
        beam,
      ),
    );

    // Chequered band across both faces of the beam.
    const cells = 22;
    final cell = (half * 2) / cells;
    for (var i = 0; i < cells; i++) {
      for (final row in const [0, 1]) {
        for (final face in const [-1.0, 1.0]) {
          root.add(
            box(
              vm.Vector3(cell, 0.5, 0.06),
              vm.Vector3(
                -half + cell * (i + 0.5),
                height - 0.05 + 0.5 * row,
                0.58 * face,
              ),
              (i + row).isEven ? white : black,
            ),
          );
        }
      }
    }
    scene.add(root);
  }

  final math.Random _rng = math.Random();

  /// Turbo is meant to be scarce: only a handful of orbs exist, and a
  /// collected one stays gone for a long, randomised stretch.
  int get _pickupCount => widget.graphics.pickupCount;
  static const _pickupRespawnMin = 14.0;
  static const _pickupRespawnSpread = 16.0;
  double _respawnDelay() =>
      _pickupRespawnMin + _rng.nextDouble() * _pickupRespawnSpread;

  /// A random spot on the road: anywhere round the lap except right on the
  /// starting grid, and anywhere across the road's width.
  vm.Vector3 _randomPickupSpot() {
    final t = 0.06 + _rng.nextDouble() * 0.9;
    final heading = _headingAt(t);
    final right = vm.Vector3(math.cos(heading), 0, -math.sin(heading));
    final lane = (_rng.nextDouble() * 2 - 1) * (_roadHalfWidth - 1.5);
    return _pointAt(t) + right * lane + vm.Vector3(0, 1.9, 0);
  }

  /// Glowing turbo orbs scattered at random round the circuit. Different
  /// every race, and a collected orb reappears somewhere else.
  void _placePickups(Scene scene, Texture2D? icon) {
    // The icon pickup is a camera-facing sprite showing the turbo button's
    // own face; the orb is only the fallback if that texture can't be built.
    final orb = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(1.0, 0.45, 0.05, 1)
      ..emissiveFactor = vm.Vector4(2.2, 0.9, 0.1, 1)
      ..roughnessFactor = 0.3;
    final orbGeometry = SphereGeometry(radius: 0.9);
    for (var i = 0; i < _pickupCount; i++) {
      final Mesh mesh;
      if (icon != null) {
        mesh = Sprite(texture: icon, width: 3.2, height: 3.2 * 42 / 64).mesh;
      } else {
        mesh = Mesh(orbGeometry, orb);
      }
      final node = Node(
        name: 'turbo-pickup',
        mesh: mesh,
        localTransform: vm.Matrix4.translation(_randomPickupSpot()),
      )..castsShadows = false;
      // Only the first two exist at the green light; the rest turn up
      // later, at random.
      final startsHidden = i >= 2;
      node.visible = !startsHidden;
      _pickups.add(node);
      _pickupCooldown.add(startsHidden ? 8 + _rng.nextDouble() * 20 : 0);
      scene.add(node);
    }
  }

  /// Spins/bobs the orbs, hides collected ones until they respawn, and
  /// reports a collection when the kart passes through one.
  void _updatePickups(double dt) {
    final body = _playerBody;
    if (body == null || _pickups.isEmpty) return;
    _clock += dt;
    final kart = body.readSimulationPose().$1;
    for (var i = 0; i < _pickups.length; i++) {
      final node = _pickups[i];
      if (_pickupCooldown[i] > 0) {
        _pickupCooldown[i] -= dt;
        if (_pickupCooldown[i] <= 0) {
          _pickupCooldown[i] = 0;
          node.position = _randomPickupSpot();
          node.visible = true;
        }
        continue;
      }
      final pos = node.position;
      node.position = vm.Vector3(
        pos.x,
        1.9 + math.sin(_clock * 3 + i) * 0.2,
        pos.z,
      );
      final dx = pos.x - kart.x;
      final dz = pos.z - kart.z;
      if (dx * dx + dz * dz < _pickupRadius * _pickupRadius) {
        _pickupCooldown[i] = _respawnDelay();
        node.visible = false;
        widget.onPickup?.call();
      }
    }
  }

  void _onCollision(CollisionEvent event) {
    if (event is! CollisionBegan) return;
    final collider = _playerCollider;
    if (collider == null) return;
    if (identical(event.colliderA, collider) ||
        identical(event.colliderB, collider)) {
      // A hit interrupts a drift: the charge is lost, which is what makes
      // clipping a barrier mid-corner cost something beyond the speed.
      _driftCharge = 0;
      _driftActive = false;
      _kick(_impactKick);
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
      for (var i = 0; i < segments; i += widget.graphics.propStride) {
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
        clone.shadowStatic = true; // scenery never moves
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

  // --- Driving model ---------------------------------------------------
  //
  // An arcade kart model driven through the body's velocity, not through
  // forces. Forces plus damping gave no defined top speed, a vague throttle,
  // and — because a box collider sliding on a box ground has almost no
  // cornering grip — a kart that kept its old velocity through every turn
  // and slid off the road like it was on ice.
  //
  // Every quantity that differs between karts now comes from
  // [RaceScene.tuning]; only the handful below, which describe the *game*
  // rather than the machine, are shared by the whole grid.

  /// How hard the kart slows when it is over its current top speed — i.e.
  /// when a boost has just run out.
  static const _overspeedDecel = 9.0;

  /// Reverse, in world units per second squared, and its cap.
  static const _reverseAccel = 7.0;
  static const _reverseTopSpeed = 6.0;

  /// Below this speed the kart cannot turn at all, ramping in linearly, so
  /// it never pivots on the spot like a tank.
  static const _turnFadeInSpeed = 2.5;

  /// How fast held steering ramps to full lock, in units per second, at the
  /// lowest and highest sensitivity settings. The buttons report a hard
  /// -1/0/1; ramping it is what turns that into steering rather than a
  /// switch, and how fast it ramps is exactly what a sensitivity slider
  /// should mean.
  static const _steerRampSlow = 2.5;
  static const _steerRampFast = 7.0;

  /// Releasing the wheel recentres this many times faster than turning it
  /// in, so the kart straightens up promptly without the turn-in being
  /// abrupt — the sprung feel of a real wheel.
  static const _steerRecentre = 1.6;

  /// A drift needs real cornering to begin: below this speed, or with less
  /// steering lock than this, holding the button does nothing. Without the
  /// gate, a player could hold drift down a straight and collect a free
  /// mini-turbo every few seconds.
  static const _driftMinSpeedFraction = 0.45;
  static const _driftMinSteer = 0.35;

  /// Seconds of continuous, qualifying drift that fills the charge.
  static const _driftChargeSeconds = 1.15;

  /// Live, ramped steering position, -1..1 — [RaceScene.steer] smoothed.
  double _steer = 0;

  /// 0..1 progress towards a mini-turbo, and whether the kart is actually
  /// sliding rather than merely holding the button down.
  double _driftCharge = 0;
  bool _driftActive = false;

  /// The chase camera's own, eased heading, and the clock it was last
  /// updated on. See the camera builder.
  vm.Vector3? _camForward;
  double _camTime = 0;
  double _camSpeed = 0;

  /// How quickly the chase camera catches up with the kart's heading, per
  /// second. Higher is tighter; lower is floatier.
  static const _cameraFollow = 9.0;

  /// How hard each event kicks the camera, in world units. Deliberately
  /// small: the camera sits five units behind the kart, so a kick of a third
  /// of a unit swung the whole view and read as a fault, not as impact.
  static const _impactKick = 0.10;
  static const _boostKick = 0.05;

  /// Starts a kick — unless the camera is already visibly shaking. A kart
  /// scraping along a barrier begins and ends contact over and over, and
  /// restarting the kick on every one of those held the camera in a
  /// permanent rattle for as long as the wall was touched.
  void _kick(double amount) {
    if (!widget.cameraShake || _shake > 0.02) return;
    _shake = amount;
  }

  /// Decaying camera kick, in world units, set by a collision or the start
  /// of a boost and read by the camera builder.
  double _shake = 0;

  /// True while the kart is pointed back down the circuit — surfaced to the
  /// HUD so the player is told, rather than left wondering why their lap
  /// counter is going backwards.
  bool _wrongWay = false;

  /// Steering ramp rate for the current sensitivity setting.
  double get _steerRamp =>
      _steerRampSlow +
      (_steerRampFast - _steerRampSlow) *
          widget.steeringSensitivity.clamp(0.0, 1.0);

  /// Holds the kart still during the countdown and while paused.
  ///
  /// The physics world keeps stepping whether or not the race is running, and
  /// the driving model deliberately leaves the body undamped, so without this
  /// a paused kart would coast on across the circuit at whatever speed it was
  /// doing. Vertical motion is left alone so it still settles onto the road.
  void _holdPlayerStill() {
    final body = _playerBody;
    if (body == null) return;
    _steer = 0;
    _driftCharge = 0;
    _driftActive = false;
    final velocity = body.linearVelocity;
    if (velocity.x == 0 && velocity.z == 0) return;
    body.linearVelocity = vm.Vector3(0, velocity.y, 0);
    body.angularVelocity = vm.Vector3.zero();
  }

  /// Drives the player's kart for one frame of [dt] seconds.
  void _drivePlayer(double dt) {
    final body = _playerBody;
    if (body == null || dt <= 0) return;
    final tuning = widget.tuning;

    // Ramp the held button towards its target rather than snapping to it.
    final steerTarget = widget.steer.clamp(-1.0, 1.0);
    final returning = steerTarget.abs() < _steer.abs();
    final steerStep = _steerRamp * (returning ? _steerRecentre : 1.0) * dt;
    _steer += (steerTarget - _steer).clamp(-steerStep, steerStep);

    // The kart model's local nose points along -Z (see [_place]'s 180°
    // flip); the same axis read back from the live rotation gives the
    // kart's current real-world facing.
    final pose = body.readSimulationPose();
    final forward = pose.$2.asRotationMatrix().transformed(
      vm.Vector3(0, 0, -1),
    );
    forward.y = 0;
    if (forward.length2 < 1e-6) return;
    forward.normalize();
    // A perpendicular of a Y-up forward vector. Only used to split the velocity
    // into forward and sideways parts and put it back together, so which side
    // of the screen it points to does not matter here — steering direction is
    // decided by [yawRateForSteer].
    final right = vm.Vector3(-forward.z, 0, forward.x);

    // Split the live velocity into the three parts the model reasons about.
    final velocity = body.linearVelocity;
    var forwardSpeed = velocity.dot(forward);
    var lateralSpeed = velocity.dot(right);
    final verticalSpeed = velocity.y;

    // --- Drift --------------------------------------------------------
    // A drift is only a drift when the kart is genuinely cornering at
    // speed. While it holds, the tyres give up most of their sideways bite
    // and the kart rotates harder than it otherwise could, which is what
    // lets it carry speed through a corner it would have to brake for —
    // and it fills a charge that pays out as a mini-turbo on release.
    final wasDrifting = _driftActive;
    _driftActive =
        widget.drifting &&
        forwardSpeed > tuning.topSpeed * _driftMinSpeedFraction &&
        _steer.abs() > _driftMinSteer;

    if (_driftActive) {
      _driftCharge = math.min(1.0, _driftCharge + dt / _driftChargeSeconds);
    } else if (wasDrifting) {
      // Released, or the conditions stopped being met. A full charge pays
      // out; a partial one is simply lost, so a drift has to be committed to.
      if (_driftCharge >= 1.0) {
        widget.onDriftBoost?.call();
        _kick(_boostKick);
      }
      _driftCharge = 0;
    }

    // --- Grip ---------------------------------------------------------
    // Tyres cancel sideways motion at a fixed rate, the way a real contact
    // patch does, up to their limit. Capped rather than absolute so a hard
    // side-on hit still shoves the kart bodily sideways instead of being
    // silently erased.
    final grip = (_driftActive ? tuning.driftGrip : tuning.grip) * dt;
    lateralSpeed = lateralSpeed.abs() <= grip
        ? 0.0
        : lateralSpeed - grip * lateralSpeed.sign;

    // --- Throttle, brake, reverse -------------------------------------
    // There is no throttle button: the kart drives itself, and the brake is
    // the only longitudinal input.
    final topSpeed =
        tuning.topSpeed * (widget.boosting ? KartTuning.boostMultiplier : 1.0);
    if (widget.braking) {
      if (forwardSpeed > 0) {
        forwardSpeed = math.max(0, forwardSpeed - tuning.brakeDecel * dt);
      } else {
        forwardSpeed = math.max(
          -_reverseTopSpeed,
          forwardSpeed - _reverseAccel * dt,
        );
      }
    } else if (forwardSpeed < topSpeed) {
      forwardSpeed = math.min(
        topSpeed,
        forwardSpeed + tuning.acceleration * dt,
      );
    } else {
      // Over the cap — a boost that just ended, or a downhill run.
      forwardSpeed = math.max(topSpeed, forwardSpeed - _overspeedDecel * dt);
    }

    // --- Steering ------------------------------------------------------
    // Yaw rate is set directly instead of torqued, so the kart answers the
    // button on the same frame rather than spinning up against damping.
    final speed = forwardSpeed.abs();
    final fadeIn = math.min(1.0, speed / _turnFadeInSpeed);
    final calmDown =
        1.0 - tuning.highSpeedTurnLoss * math.min(1.0, speed / tuning.topSpeed);
    // Reversing swings the nose the other way, as a real car's does.
    final sign = forwardSpeed < -0.5 ? -1.0 : 1.0;
    final driftBonus = _driftActive ? tuning.driftTurnBonus : 1.0;
    body.angularVelocity = vm.Vector3(
      0,
      yawRateForSteer(
        steer: _steer,
        rate: tuning.turnRate * driftBonus * fadeIn * calmDown * sign,
      ),
      0,
    );

    body.linearVelocity =
        forward * forwardSpeed +
        right * lateralSpeed +
        vm.Vector3(0, verticalSpeed, 0);

    // Camera kick decays on its own clock so one impulse reads as one hit
    // rather than a rattle that lasts as long as the contact does.
    if (_shake > 0) _shake = math.max(0, _shake - dt * 0.9);
  }

  /// The spline parameter `t` closest to [position]. A plain sampled search
  /// over the whole lap every call — simplest correct approach, and cheap
  /// next to an actual physics step.
  static const _splineSamples = 180;

  /// This circuit never changes while it is mounted, so its sample points are
  /// computed once as a flat x,z table instead of costing trig calls and
  /// Vector3 allocations on every frame.
  late final Float64List _splineXZ = () {
    final table = Float64List(_splineSamples * 2);
    for (var i = 0; i < _splineSamples; i++) {
      final (x, z) = _shape.pointAt(i / _splineSamples);
      table[i * 2] = x;
      table[i * 2 + 1] = z;
    }
    return table;
  }();

  /// Last frame's nearest sample index, so the search starts where the kart
  /// actually is instead of re-walking the whole lap. A kart cannot cross
  /// more than a few samples in one physics tick, so a short window centred
  /// on the previous answer is both correct and a fraction of the work —
  /// except on the first call, which has nowhere to start from.
  int _lastSample = -1;
  static const _searchWindow = 14;

  double _projectOntoSpline(vm.Vector3 position) {
    var best = 0;
    var bestDist = double.infinity;

    void consider(int index) {
      final i = index % _splineSamples;
      final dx = _splineXZ[i * 2] - position.x;
      final dz = _splineXZ[i * 2 + 1] - position.z;
      final d = dx * dx + dz * dz;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }

    if (_lastSample < 0) {
      for (var i = 0; i < _splineSamples; i++) {
        consider(i);
      }
    } else {
      for (var o = -_searchWindow; o <= _searchWindow; o++) {
        consider(_lastSample + o + _splineSamples);
      }
      // A collision can teleport the kart further than the window covers —
      // if the best candidate is still at the window's edge, the answer is
      // probably outside it, so fall back to the full sweep.
      final drift = (best - _lastSample).abs() % _splineSamples;
      if (drift >= _searchWindow && _splineSamples - drift >= _searchWindow) {
        bestDist = double.infinity;
        for (var i = 0; i < _splineSamples; i++) {
          consider(i);
        }
      }
    }

    _lastSample = best;
    return best / _splineSamples;
  }

  /// Projects the player's live physics position onto the track spline and
  /// reports everything measured off the body to [RaceScene.onTelemetry].
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

    // Heading against the circuit while actually moving — see
    // [isGoingWrongWay] for exactly what counts.
    final velocity = body.linearVelocity;
    _wrongWay = isGoingWrongWay(
      heading: heading,
      vx: velocity.x,
      vz: velocity.z,
    );

    widget.onTelemetry?.call(
      RaceTelemetry(
        progress: _playerLaps + t,
        lateral: lateral,
        speedKmh: velocity.length * KartTuning.kmhPerWorldUnit,
        driftCharge: _driftCharge,
        drifting: _driftActive,
        wrongWay: _wrongWay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback ?? const SizedBox.shrink();
    if (!_ready || _scene == null) {
      return widget.loading ?? widget.fallback ?? const SizedBox.shrink();
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
        RepaintBoundary(
          child: SceneView(
            _scene!,
            onTick: (elapsed, deltaSeconds) {
              if (widget.running) {
                _drivePlayer(deltaSeconds);
              } else {
                _holdPlayerStill();
              }
              _scene!.update(deltaSeconds);
              if (widget.running) _updatePickups(deltaSeconds);
              if (widget.running) _reportTelemetry();
            },
            cameraBuilder: (elapsed) {
              // Chase camera: sits behind and above the kart.
              //
              // It follows the kart *node's* pose, not the physics body's
              // `readSimulationPose()`. The engine steps physics on a fixed
              // timestep and draws the kart at an interpolated pose between
              // steps; the simulation pose runs up to a step ahead of that.
              // A camera locked to the simulation pose therefore disagreed
              // with where the kart was drawn by a different amount every
              // frame, and the kart visibly juddered against the screen.
              final body = _playerBody;
              final node = _kart;
              final position = node?.position ?? _pointAt(0);
              final kartForward = node == null
                  ? vm.Vector3(0, 0, -1)
                  : node.rotation.asRotationMatrix().transformed(
                      vm.Vector3(0, 0, -1),
                    );

              // Ease the camera's heading towards the kart's rather than
              // welding it there, so a bump or a sharp flick of the wheel
              // turns the view smoothly instead of snapping it round.
              final t = elapsed.inMicroseconds / 1e6;
              final dt = (t - _camTime).clamp(0.0, 0.1);
              _camTime = t;
              final ease = 1 - math.exp(-dt * _cameraFollow);
              final forward = _camForward == null
                  ? kartForward
                  : (_camForward! + (kartForward - _camForward!) * ease);
              forward.y = 0;
              if (forward.length2 < 1e-6) forward.setFrom(kartForward);
              forward.normalize();
              _camForward = forward.clone();

              // The raw speed jumps whenever a collision changes the
              // velocity, which pumped the camera in and out; ease it too.
              final rawSpeed = ((body?.linearVelocity.length ?? 0) / 12.0)
                  .clamp(0.0, 1.5);
              _camSpeed += (rawSpeed - _camSpeed) * ease;
              final speedNorm = _camSpeed;

              var eye =
                  position -
                  forward * (5.0 + speedNorm * 2.0) +
                  vm.Vector3(0, 4.0 + speedNorm * 1.2, 0);
              final look = position + forward * 6.0 + vm.Vector3(0, 0.6, 0);

              // Impact and boost kick. Two detuned frequencies rather than
              // random noise, so a hit reads as one solid thump instead of
              // per-frame jitter that just looks like dropped frames.
              if (_shake > 0) {
                eye =
                    eye +
                    vm.Vector3(
                      math.sin(t * 34) * _shake,
                      math.sin(t * 27 + 1.7) * _shake * 0.7,
                      math.cos(t * 31) * _shake * 0.5,
                    );
              }

              return PerspectiveCamera(
                position: eye,
                target: look,
                // FOV widens with speed so motion feels fast, and snaps
                // wider still on a boost — the cheapest and most effective
                // "this is fast" cue there is.
                fovRadiansY:
                    0.78 + speedNorm * 0.12 + (widget.boosting ? 0.08 : 0),
                fovFar: 500,
              );
            },
          ),
        ),
      ],
    );
  }
}
