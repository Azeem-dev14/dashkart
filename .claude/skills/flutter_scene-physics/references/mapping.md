# Description / image → component mapping

Use this before writing code for a text- or image-described physics setup. Each
row is a phrase or visual cue and the component/property it actually maps to —
not the first component that comes to mind for it.

## Motion — which `BodyType`

| Description says | Use | Not |
| --- | --- | --- |
| "falls", "rolls", "gets knocked", "is thrown" | `RigidBody(type: BodyType.dynamic_)` | `.kinematic` — kinematic ignores gravity and forces entirely |
| "never moves" (wall, floor, track surface) | `Collider` alone (implicit fixed body) or `RigidBody(type: BodyType.fixed)` if you need the node addressable | a dynamic body with locked axes — heavier and pointless |
| "moves on a fixed path" (elevator, moving platform, gate that opens on a script) | `RigidBody(type: BodyType.kinematic)`, drive it by setting the node transform each frame | dynamic + a joint fighting the animation |
| "player/character walks, jumps, is pushed by the environment" | `KinematicCharacterController` + a `Collider` (no `RigidBody`) | a dynamic `RigidBody` — tips over, feels wrong for arcade movement |
| "a car/kart with a chassis and wheels that roll" | dynamic `RigidBody` chassis + `RevoluteJoint` wheels (or a `KinematicCharacterController`/hand-integration for arcade feel, see the idioms note on this project's `race_simulation.dart`) | a single rigid body with no wheel joints if rolling contact matters |

## Surface feel — `PhysicsMaterial`

| Description says | Use |
| --- | --- |
| "bouncy", "springy", "rubber" | high `restitution` (near 1.0) |
| "dead", "absorbs impact", "sandbag" | low `restitution` (near 0) |
| "icy", "slippery" | low `friction` |
| "sticky", "grippy", "rubber tires on tarmac" | high `friction` |
| two surfaces disagree (rubber ball on ice) | check `CombineRule` on `PhysicsMaterial` — it decides how the two sides' friction/restitution combine, don't just tune one side and hope |

## Shape from a picture

| Looks like | Shape |
| --- | --- |
| ball, wheel (for broad-phase, not rolling detail) | `SphereShape(radius)` |
| crate, wall panel, ramp segment | `BoxShape(halfExtents)` — remember these are **half**-extents, a picture's full width/height/depth halves before it goes in |
| character body, pillar with rounded caps | `CapsuleShape(radius, halfHeight)` — Y-axis aligned only; rotate the node, not the shape, for a capsule lying on its side |
| barrel, drum, silo | `CylinderShape(radius, halfHeight)` — same Y-axis constraint |
| irregular but convex prop | `ConvexHullShape(points)` |
| static terrain/ground mesh from art, non-convex | `TriMeshShape(vertices, indices)` — static only, do not put this on a dynamic body |
| rolling landscape / heightmap art | `HeightFieldShape(width, depth, heights, scale)` |
| an L-shape, T-shape, anything non-convex that needs to *move* (so `TriMeshShape` is off the table) | `CompoundShape(children)` of primitive pieces |

A ramp in a reference image is almost always a single rotated `BoxShape`, not a
custom mesh — rotate the node's transform, don't reach for a convex hull unless
the picture shows a shape no box/capsule/cylinder combination approximates.

## Connections — which joint

| Description says | Use |
| --- | --- |
| "welded", "rigidly attached", "doesn't move relative to" | `FixedJoint` |
| "swings", "hinges", "flaps" (a gate, a door, a seesaw pivot) | `RevoluteJoint` with `axis` set to the hinge axis; add `lowerLimit`/`upperLimit` if it should not swing all the way around |
| "slides", "a piston", "a drawer" | `PrismaticJoint` along the slide axis |
| "dangles", "on a rope/chain from one point", "ragdoll shoulder" | `SphericalJoint` |
| "a motorized/driven" version of any of the above | set `motorTargetVelocity` + `motorMaxForce` on the revolute/prismatic joint rather than driving it by setting velocity on the body directly |
| anything combining limited rotation on some axes and free translation on others (a suspension strut) | `GenericJoint` with per-axis `JointAxisConfig` |

## Zones and events

| Description says | Use |
| --- | --- |
| "checkpoint", "finish line", "trigger zone", "detects but doesn't block" | `Collider(isTrigger: true)`, listen for `TriggerEntered`/`TriggerExited` on `world.collisions` |
| "explodes on contact", "damage on hit", "plays a sound when it lands" | `Collider(isTrigger: false)` (normal solid collider), listen for `CollisionBegan`/`CollisionEnded` |
| "only hits the player, not other karts" / "walls block karts but not pickups" | `collisionLayer` / `collisionMask` bitmasks on the relevant colliders, not a runtime `if` in the collision handler |

## Scale sanity check (for an image reference specifically)

flutter_scene / Rapier units are meters and kilograms in the sense that default
gravity is `9.81 m/s²` and defaults assume that scale. Before trusting shape
sizes read off an image: pick one recognizable object in the picture (a kart is
roughly car-sized, a character roughly 1.7-2m tall) and derive every other
`halfExtents`/`radius` in the scene relative to it, rather than eyeballing each
one independently — independent eyeballing is how a ramp ends up either
toy-sized or building-sized relative to the kart that's supposed to drive up it.
