# flutter_scene physics API reference

Pulled from `package:flutter_scene/physics.dart`, `package:scene/physics.dart`, and
`package:flutter_scene_rapier` sources (flutter_scene 0.22.2 / scene 0.2.0 /
flutter_scene_rapier 0.5.0, as pinned in this project's `pubspec.lock`). All of
this except `RapierWorld` itself is backend-agnostic.

## Setup

```dart
final world = RapierWorld(gravity: Vector3(0, -9.81, 0)); // default gravity shown
scene.root.addComponent(PhysicsWorld(world));             // must be scene root
```

`PhysicsWorld` fields: `gravity`, `fixedTimestep`, `maxSubsteps` (all settable),
`backendName` ('rapier3d'), `interpolationAlpha` (read-only, current lerp fraction
between physics steps — useful if a component wants to smooth its own visuals in
step with dynamic bodies).

## RigidBody

```dart
RigidBody({
  BodyType type = BodyType.dynamic_,      // .fixed, .kinematic, .dynamic_
  double? mass,                            // null = derive from colliders
  Matrix3? inertiaTensor,                  // stored only, not yet forwarded to backend
  Vector3? linearVelocity,
  Vector3? angularVelocity,
  double linearDamping = 0,
  double angularDamping = 0,
  bool useGravity = true,
  bool ccdEnabled = false,                 // continuous collision, fast/thin bodies
  Vector3? linearAxisLocks,                // per-axis 0..1, 1 = free
  Vector3? angularAxisLocks,
})
```

Methods: `applyForce(f, {atWorldPoint})`, `applyImpulse(i, {atWorldPoint})`,
`applyTorque(t)`, `applyAngularImpulse(i)`, `wakeUp()`, `putToSleep()`,
`readSimulationPose()` (exact mid-step pose — use this inside `fixedUpdate`, where
the node's interpolated transform still lags). `isSleeping`, `handle` (backend
handle, for downcasting to `RapierWorld` and calling something outside the
contract), `type` is settable live (e.g. flip a prop from kinematic to dynamic on
release).

A **kinematic** body follows its node's transform every fixed step (you move the
node, physics pushes a target pose so contacts see correct velocity) rather than
the reverse. A **dynamic** body's node transform is written by the simulation;
setting it yourself is treated as a teleport.

## Collider

```dart
Collider({
  required Shape shape,
  PhysicsMaterial material = PhysicsMaterial.defaultMaterial,
  int collisionLayer = 0xFFFFFFFF,
  int collisionMask = 0xFFFFFFFF,
  bool isTrigger = false,
  Matrix4? localPose,      // offset from the owning node
})
```

A node may carry several `Collider`s (a compound). A contact is generated only
when each side's `collisionLayer` is set in the other side's `collisionMask`.
`isTrigger: true` emits `TriggerEntered`/`TriggerExited` with no physical
response. `shape`, `material`, `isTrigger`, `localPose` are all live-settable and
rebuild the underlying simulation collider(s).

## Shapes (`sealed class Shape`, immutable, shareable across colliders)

- `SphereShape({radius})`
- `BoxShape({halfExtents})` — half-extents, not full size
- `CapsuleShape({radius, halfHeight})` — Y-axis aligned, `halfHeight` excludes the caps
- `CylinderShape({radius, halfHeight})` — Y-axis aligned
- `ConvexHullShape({points})` — packed xyz `Float32List`
- `TriMeshShape({vertices, indices})` — static geometry only, expensive for dynamics
- `HeightFieldShape({width, depth, heights, scale})` — row-major, XZ plane
- `CompoundShape({children})` where each `CompoundChild(shape, localPose)` — for
  a non-convex volume built from primitives (an L-block from two boxes)

## Joints

All extend `Joint({otherNode, collisionsEnabled = false})`. `otherNode: null`
anchors against a world anchor body instead of another `RigidBody`. Every
property setter reconfigures the live joint (`push()` internally); no rebuild
needed.

- `FixedJoint({otherNode, localAnchorA, localAnchorB, collisionsEnabled})` —
  welds current relative pose.
- `SphericalJoint({...})` — ball-and-socket, same anchor params.
- `RevoluteJoint({otherNode, required axis, localAnchorA, localAnchorB, lowerLimit, upperLimit, motorTargetVelocity, motorMaxForce, collisionsEnabled})` —
  hinge about `axis`. Omit limits for a free hinge, set both for a limited one, set
  the motor pair to drive it.
- `PrismaticJoint({...same shape as RevoluteJoint...})` — slider along `axis`
  instead of a hinge.
- `GenericJoint({otherNode, localAnchorA, localAnchorB, localBasisA, localBasisB, axes, collisionsEnabled})` —
  full 6DOF; `axes` is `Map<JointAxis, JointAxisConfig>`, unset axes default to
  `JointAxisConfig.free()`. Read/write per-axis config live with `configForAxis` /
  `setAxisConfig`.

`Joint.handle` is the backend handle if a Rapier-specific joint feature beyond
this contract is ever needed.

## KinematicCharacterController

```dart
KinematicCharacterController({
  Vector3? up,                  // defaults to Vector3(0, 1, 0)
  double offset = 0.01,
  bool slide = true,
  double maxSlopeClimbAngle = pi / 4,
  double minSlopeSlideAngle = pi / 4,
  double? snapToGround = 0.1,   // null disables snapping off edges
  bool autostep = false,
  double autostepMaxHeight = 0.3,
  double autostepMinWidth = 0.1,
  bool autostepIncludeDynamicBodies = true,
  double mass = 0.0,            // 0 = pushes no dynamic bodies it collides with
})
```

Attach on the same node as a `Collider` describing the character's volume (no
`RigidBody` needed — this is move-and-slide against the world, not a simulated
body). Call `move(desiredTranslation, {deltaSeconds})` once per fixed step,
typically from `fixedUpdate`; it applies the corrected translation to the node
and returns a `CharacterMovement(translation, grounded, slidingDownSlope)`.
`deltaSeconds` defaults to the world's fixed timestep.

## Queries (methods on `PhysicsWorld`)

```dart
world.raycast(ray, {maxDistance, layerMask, includeFixed, includeKinematic, includeDynamic, includeTriggers})
world.raycastAll(ray, {...})            // -> List<RaycastHit>
world.overlapSphere(center, radius, {...})   // -> List<OverlapHit>
world.overlapBox(center, halfExtents, rotation, {...})
world.shapeCast(shape, from, direction, distance, {...})
```

Hits carry `node`, `collider`, plus `worldPoint`/`worldNormal`/`distance` where
applicable. All default to including fixed, kinematic, and dynamic bodies but
excluding triggers (`includeTriggers: false`). Rapier's caveat: queries run
against the broad-phase structure as of the *last* `step()`, so a collider added
since the last step, or a query issued before the first step, will not be seen —
step every frame before querying and this is never noticeable.

## Collision / trigger events

```dart
world.collisions.listen((event) {
  switch (event) {
    case CollisionBegan(:final nodeA, :final nodeB, :final contacts): ...
    case CollisionEnded(:final nodeA, :final nodeB): ...
    case TriggerEntered(:final nodeA, :final nodeB): ...
    case TriggerExited(:final nodeA, :final nodeB): ...
  }
});
```

`CollisionBegan.contacts` is `List<ContactPoint>` (`worldPosition`, `worldNormal`,
`impulse`) — the solved contact manifold.

## Rollback / snapshot (Rapier-specific, not in the generic contract)

`RapierWorld.snapshot()` → `Uint8List`, `RapierWorld.restore(bytes)` → `bool`,
`RapierWorld.setBodyPose(...)` for immediate teleport. Added in 0.4.0 for
rollback netcode / lag compensation. Reach these by downcasting
`(physicsWorld.simulation as RapierWorld)`.

## Testing without the native backend

`BasicSimulation` (`package:scene/physics.dart`, re-exported from
`flutter_scene/physics.dart`) is a pure-Dart `PhysicsSimulation` — no FFI, no
native binary, no build hook. It implements queries and the pose/trigger
contract but not full rigid-body dynamics. Useful for widget/unit tests that
need `PhysicsWorld` present without pulling in Rapier's native asset build.
