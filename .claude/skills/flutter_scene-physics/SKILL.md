---
name: flutter_scene-physics
version: 1
description: Add or debug rigid-body physics in flutter_scene using the Rapier 3D backend (flutter_scene_rapier). Use whenever wiring up gravity, rigid bodies, colliders, joints, raycasts/overlap queries, collision or trigger events, or a kinematic character controller in this project's kart game — including when the ask is described in plain text or handed over as a reference image/screenshot (a ramp, a bumper, a swinging gate, a track layout) that needs to become a correct physics setup on the first try. Corrects the package's own stale README, which still shows a removed API.
---

# Physics in flutter_scene (Rapier backend)

flutter_scene's physics is a two-package split: `package:flutter_scene` (via `flutter_scene/physics.dart`) defines **generic, backend-agnostic components** — `PhysicsWorld`, `RigidBody`, `Collider`, the joint classes, `KinematicCharacterController`. `package:flutter_scene_rapier` supplies exactly one thing, the **`RapierWorld`** backend those generic components drive. There is no fscene.dev guide for this yet ("a physics guide is on the way"), so this skill is reconstructed from the package sources.

**The one thing to internalize: ignore flutter_scene_rapier's own README and any AI-generated summary of it — both describe a removed API.** Versions up to 0.2.x had backend-specific `RapierRigidBody` / `RapierCollider` / `RapierFixedJoint` / `RapierKinematicCharacterController` classes. As of **0.3.0** (current is 0.5.0) those were deleted; the CHANGELOG says so explicitly: *"the backend-specific `Rapier*` component classes are removed."* The README was never updated and still shows them, and a naive web fetch of the docs will repeat the stale names. There is no `RapierRigidBody` and no `RapierCollider` in this project's dependency (`flutter_scene_rapier: 0.5.0`, [pubspec.yaml](../../../pubspec.yaml)) — reaching for them is a compile error, not a typo to retry.

## Correct spelling

```dart
import 'package:flutter_scene/scene.dart' hide Material;   // Flutter's Material clashes
import 'package:flutter_scene/physics.dart' hide BoxShape;  // Flutter's BoxShape clashes
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:vector_math/vector_math.dart';

// Web only: await once at startup before constructing any RapierWorld.
// No-op on native, so it is always safe to call.
await RapierWorld.ensureInitialized();

final scene = Scene();
final world = RapierWorld(gravity: Vector3(0, -9.81, 0)); // this is the default
scene.root.addComponent(PhysicsWorld(world)); // must be on the scene ROOT, see below

final floor = Node(localTransform: Matrix4.translation(Vector3(0, -0.5, 0)));
floor.addComponent(RigidBody(type: BodyType.fixed));
floor.addComponent(Collider(shape: BoxShape(halfExtents: Vector3(10, 0.5, 10))));
scene.add(floor);

final box = Node(localTransform: Matrix4.translation(Vector3(0, 5, 0)));
box.addComponent(RigidBody(type: BodyType.dynamic_, mass: 1)); // trailing _, `dynamic` is reserved
box.addComponent(Collider(shape: BoxShape(halfExtents: Vector3.all(0.5))));
scene.add(box);
```

Everything downstream — bodies, colliders, joints, queries, events, the character controller — is `flutter_scene`'s generic surface, not Rapier-specific. `RapierWorld` only shows up once, at construction. `scene.update(dt)` steps physics (on a fixed timestep) and interpolates dynamic-body transforms automatically; nothing else to drive by hand.

## Traps specific to this backend

- **`BodyType.dynamic_`, not `BodyType.dynamic`.** `dynamic` is a Dart keyword; the enum value has a trailing underscore. The other two are `BodyType.fixed` and `BodyType.kinematic`.
- **`PhysicsWorld` must sit on the scene root, not just some ancestor node.** Component lookup for other physics components (`findAncestorWorld`) walks up from any node and would accept it deeper in the tree, but the scene's own per-frame driver only checks `scene.root.getComponent<PhysicsWorld>()` to decide whether to step at all. Put it one level too low and physics silently never advances — no error, bodies just never move.
- **`RigidBody` and `Collider` can be added to the same node in either order.** Both implement a pending-registration handshake; whichever mounts second finds the other already there. Do not add ordering logic of your own.
- **A `Collider` with no sibling `RigidBody` becomes static level geometry**, via an implicit fixed body created on its node. This is the normal way to build a track surface or walls — no need to pair every `Collider` with an explicit fixed `RigidBody`.
- **Import clash, not a typo.** `flutter_scene`'s physics `BoxShape` collides with Flutter's painting `BoxShape`; its `Material` collides with the Material widget. `hide` whichever one you are not using in that file (see imports above). This bites hardest in a widget file that also builds a scene inline.
- **No `--enable-experiment=native-assets` flag, and nothing to run before `flutter run`.** The prebuilt native library (or a from-source Rust build on exotic targets) is fetched by a Dart native-assets build hook automatically at build time — same mechanism as `flutter_scene`'s own asset build hook. Do not chase a "native-assets" experiment flag; per the idioms skill it actively breaks the build on recent Dart.
- **Web needs `RapierWorld.ensureInitialized()` awaited first.** It loads a WebAssembly module asynchronously; native targets return immediately, so calling it unconditionally at startup is always correct and cheap to call more than once.
- **`RigidBody.mass` left `null` derives mass from the collider's shape and material density**, not zero. Do not pass `mass: 0` expecting "auto" — that means an (invalid) zero-mass dynamic body. Omit `mass` for auto-derivation.

## The rest of the surface

Joints, the character controller, queries, collision/trigger events, and shape types are all generic `flutter_scene` components with the same "ignore RapierWorld once it's constructed" property. `references/api.md` has the full class/method table (constructors, per-axis joint config, `move()` semantics, query signatures, event types) pulled directly from the package sources rather than the docs site.

## Building from a text or image reference

When the ask is a description ("a bouncy ball drops onto a seesaw", "the finish line is a checkpoint, not a wall") or a reference image/screenshot (a track layout, a ramp, a gate), the failure mode is not syntax — it's picking the wrong component for what was described and never finding out, because a physics mistake is often silent (see the `PhysicsWorld`-not-on-root trap above: wrong setup, no error, nothing moves or it moves wrong). Two rules keep that from happening:

1. **Translate every noun and adjective in the reference to a specific component before writing code, not while writing it.** "Bouncy" is a `PhysicsMaterial.restitution`, not a shape choice. "Falls" is `BodyType.dynamic_`. "Swings" is a joint (`RevoluteJoint` for a hinge, not `FixedJoint`). Guessing the mapping mid-edit is how a described seesaw ends up welded solid or a described wall ends up a trigger. `references/mapping.md` is the phrase-to-API table — check it rather than recalling it from memory, since the wrong pick compiles fine and only fails at runtime.
2. **Never declare a reference-driven build done from reading the code back.** The point of a reference is a visual or behavioral target; confirming against it means running the scene and watching it, not re-reading the component list and reasoning it should work. Use the `flutter_scene-verification-loop` skill's run → settle → screenshot loop, and compare the actual behavior (does it bounce back roughly as high as described, does the gate swing rather than sit rigid, does the checkpoint pass through rather than block) against the reference before calling it correct. For an image reference, also sanity-check scale and placement against the picture, not just shape choice — a ramp modeled as a `BoxShape` at the wrong rotation or the wrong `halfExtents` still compiles and still "is a ramp," just not the one shown.

## This project

[lib/game/race_simulation.dart](../../../lib/game/race_simulation.dart) currently integrates kart motion by hand (`advance(dt)`) and says explicitly in its doc comment: *"Physics will replace `advance`'s integration, not its interface."* When that lands, the kart is the natural fit for a `RigidBody` + `Collider` pair (likely `BodyType.dynamic_` with locked roll/pitch via `angularAxisLocks`, or a `KinematicCharacterController` if arcade-style move-and-slide is preferred over a full rigid-body car), and the track surface/walls are `Collider`-only static geometry as described above.
