import 'dart:math' as math;

import 'package:flutter/widgets.dart' hide BoxShape;
import 'package:flutter_scene/scene.dart' hide Material;
import 'package:flutter_scene/physics.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/features/race/scene/scene3d.dart';

/// A real Rapier rigid-body physics scene: the roster's karts dropped into a
/// walled arena, falling under gravity and colliding with the floor, the
/// walls, and each other.
///
/// Unlike [RaceScene], which scripts kart motion along a hand-authored
/// spline, every kart here carries a [RigidBody] and [Collider] driven by
/// `flutter_scene_rapier`'s `RapierWorld` — position and rotation each frame
/// come out of the physics simulation, not from code that sets them.
class KartPhysicsArena extends StatefulWidget {
  const KartPhysicsArena({super.key, this.fallback});

  final Widget? fallback;

  @override
  State<KartPhysicsArena> createState() => _KartPhysicsArenaState();
}

class _KartPhysicsArenaState extends State<KartPhysicsArena> {
  /// The arena drops the whole roster — three karts, three liveries. Reading
  /// it from [Catalog] rather than a local copy means the arena can never
  /// drift from what the rest of the app ships.
  static List<Kart> get _roster => Catalog.karts;

  /// Half the arena's floor footprint, in world units.
  static const _arenaHalf = 8.0;
  static const _wallHeight = 2.0;
  static const _wallThickness = 0.4;

  Scene? _scene;
  bool _ready = false;
  bool _failed = false;
  int _impacts = 0;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    try {
      if (!await Scene3D.ensureReady()) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      // No-op on native; awaited unconditionally so this also works on web.
      await RapierWorld.ensureInitialized();

      final scene = Scene();
      final world = RapierWorld(gravity: vm.Vector3(0, -9.81, 0));
      scene.root.addComponent(PhysicsWorld(world));

      scene.add(
        _staticBox(
          name: 'floor',
          extents: vm.Vector3(_arenaHalf * 2, 0.5, _arenaHalf * 2),
          center: vm.Vector3(0, -0.25, 0),
          color: DashColors.surface,
        ),
      );
      final wallSpan = _arenaHalf * 2 + _wallThickness;
      final wallY = _wallHeight / 2;
      scene
        ..add(
          _staticBox(
            name: 'wall-north',
            extents: vm.Vector3(wallSpan, _wallHeight, _wallThickness),
            center: vm.Vector3(0, wallY, -_arenaHalf - _wallThickness / 2),
            color: DashColors.strokeStrong,
          ),
        )
        ..add(
          _staticBox(
            name: 'wall-south',
            extents: vm.Vector3(wallSpan, _wallHeight, _wallThickness),
            center: vm.Vector3(0, wallY, _arenaHalf + _wallThickness / 2),
            color: DashColors.strokeStrong,
          ),
        )
        ..add(
          _staticBox(
            name: 'wall-east',
            extents: vm.Vector3(_wallThickness, _wallHeight, wallSpan),
            center: vm.Vector3(_arenaHalf + _wallThickness / 2, wallY, 0),
            color: DashColors.strokeStrong,
          ),
        )
        ..add(
          _staticBox(
            name: 'wall-west',
            extents: vm.Vector3(_wallThickness, _wallHeight, wallSpan),
            center: vm.Vector3(-_arenaHalf - _wallThickness / 2, wallY, 0),
            color: DashColors.strokeStrong,
          ),
        );

      final rng = math.Random(7);
      for (var i = 0; i < _roster.length; i++) {
        final def = _roster[i];
        final kart = await loadScene(def.modelPath);
        if (def.livery != null) {
          _tint(kart, def.livery!);
        }

        // Staggered drop heights and a little lateral jitter so the three
        // fall and land on each other instead of overlapping in place.
        kart.position = vm.Vector3(
          (i - (_roster.length - 1) / 2) * 2.4,
          3.5 + i * 1.6,
          (rng.nextDouble() - 0.5) * 0.8,
        );
        kart.rotation = vm.Quaternion.axisAngle(
          vm.Vector3(0, 1, 0),
          rng.nextDouble() * math.pi * 2,
        );

        kart
          ..addComponent(
            RigidBody(
              type: BodyType.dynamic_,
              // Free to slide and spin around Y (yaw); locked on X/Z so a kart
              // that clips another doesn't tumble nose-over-tail, since the
              // model has no wheel articulation to sell that.
              angularAxisLocks: vm.Vector3(0, 1, 0),
            ),
          )
          ..addComponent(
            Collider(shape: BoxShape(halfExtents: vm.Vector3(0.85, 0.5, 0.95))),
          );

        scene.add(kart);
      }

      world.collisions.listen((event) {
        if (event is CollisionBegan && mounted) {
          setState(() => _impacts++);
        }
      });

      if (mounted) {
        setState(() {
          _scene = scene;
          _ready = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// A static (fixed-body) coloured box: the floor and the four arena walls.
  Node _staticBox({
    required String name,
    required vm.Vector3 extents,
    required vm.Vector3 center,
    required Color color,
  }) {
    final geometry = CuboidGeometry(extents);
    final material = UnlitMaterial()
      ..baseColorFactor = vm.Vector4(color.r, color.g, color.b, 1.0);
    return Node(
        name: name,
        localTransform: vm.Matrix4.translation(center),
        mesh: Mesh(geometry, material),
      )
      ..addComponent(RigidBody(type: BodyType.fixed))
      ..addComponent(Collider(shape: geometry.collisionShape));
  }

  /// Tints every mesh primitive under [node] with [color], multiplying the
  /// kart's own texture the way a livery recolour would.
  void _tint(Node node, Color color) {
    final tint = vm.Vector4(color.r, color.g, color.b, 1.0);
    for (final meshNode in node.meshNodes) {
      for (final primitive in meshNode.mesh!.primitives) {
        final material = primitive.material;
        if (material is PhysicallyBasedMaterial) {
          material.baseColorFactor = tint;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !_ready || _scene == null) {
      return widget.fallback ?? const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [DashColors.bgGradientTop, DashColors.bgGradientBottom],
            ),
          ),
        ),
        SceneView(
          _scene!,
          onTick: (elapsed, deltaSeconds) => _scene!.update(deltaSeconds),
          cameraBuilder: (elapsed) {
            // Slow orbit around the arena so the drop and the collisions
            // read from a moving angle instead of a static screenshot.
            final angle = elapsed.inMilliseconds / 9000 * math.pi * 2;
            const radius = 15.0;
            return PerspectiveCamera(
              position: vm.Vector3(
                radius * math.cos(angle),
                9.0,
                radius * math.sin(angle),
              ),
              target: vm.Vector3(0, 1.0, 0),
              fovRadiansY: 0.7,
              fovFar: 200,
            );
          },
        ),
        Positioned(
          left: DashSpace.x3,
          top: DashSpace.x3,
          child: _ImpactBadge(count: _impacts),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: DashSpace.x4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _roster.length; i++) ...[
                if (i > 0) const SizedBox(width: DashSpace.x2),
                _KartBadge(
                  name: _roster[i].name,
                  color: _roster[i].livery ?? DashColors.textPrimary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DashColors.surface.withValues(alpha: 0.85),
        borderRadius: DashRadius.pillAll,
        border: Border.all(color: DashColors.stroke),
      ),
      child: Text(
        'IMPACTS  $count',
        style: DashType.label.copyWith(color: DashColors.textSecondary),
      ),
    );
  }
}

class _KartBadge extends StatelessWidget {
  const _KartBadge({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DashColors.surface.withValues(alpha: 0.85),
        borderRadius: DashRadius.pillAll,
        border: Border.all(color: DashColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: DashType.label.copyWith(color: DashColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
