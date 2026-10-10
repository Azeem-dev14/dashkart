import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'package:dashkart/features/race/steering.dart';

/// Left and right came out swapped on the phone. The cause was a sign taken
/// from right-handed intuition in a left-handed engine. This does not argue
/// from that: it asks the engine's own camera which way the screen's right is,
/// turns a kart with the real steering function, and checks which side of the
/// screen the nose ends up on — at every heading, so no direction is special.
void main() {
  wiringGuard();

  /// Screen-space x of a world-space direction, as the game's chase camera
  /// would draw it: positive is the right-hand side of the screen.
  double screenX(vm.Vector3 direction, vm.Vector3 forward) {
    final camera = PerspectiveCamera(
      // The chase camera sits behind and above the kart, looking ahead.
      position: forward * -5 + vm.Vector3(0, 4, 0),
      target: forward * 6 + vm.Vector3(0, 0.6, 0),
      up: vm.Vector3(0, 1, 0),
    );
    return camera.getViewMatrix().transformed3(direction.clone()..y = 0).x -
        camera.getViewMatrix().transformed3(vm.Vector3.zero()).x;
  }

  /// The kart's nose after [seconds] of turning at [rate] rad/s about +Y, by
  /// the definition physics uses: angular velocity ω turns a vector v at
  /// ω × v. This is what the Rapier body does when it is given the yaw rate.
  ///
  /// Deliberately not `Quaternion.rotated`: vector_math's version rotates the
  /// opposite way to the right-hand rule, which is exactly the kind of thing
  /// that makes a sign look right in a test and wrong on the phone.
  vm.Vector3 turned(vm.Vector3 nose, double rate, double seconds) =>
      nose + vm.Vector3(0, rate, 0).cross(nose) * seconds;

  for (var deg = 0; deg < 360; deg += 15) {
    final heading = deg * math.pi / 180;
    final nose = vm.Vector3(math.sin(heading), 0, math.cos(heading));

    test(
      'steering right turns the nose to the right of the screen @ $deg°',
      () {
        final rate = yawRateForSteer(steer: 1, rate: 2.0);
        final after = turned(nose, rate, 0.1);
        final shift = after - nose;
        expect(
          screenX(shift, nose),
          greaterThan(0),
          reason: 'steering right moved the nose to the LEFT of the screen',
        );
      },
    );

    test('steering left turns the nose to the left of the screen @ $deg°', () {
      final rate = yawRateForSteer(steer: -1, rate: 2.0);
      final after = turned(nose, rate, 0.1);
      final shift = after - nose;
      expect(
        screenX(shift, nose),
        lessThan(0),
        reason: 'steering left moved the nose to the RIGHT of the screen',
      );
    });
  }

  test('the turn is proportional to how far the wheel is turned', () {
    expect(yawRateForSteer(steer: 0.5, rate: 2.0), 1.0);
    expect(yawRateForSteer(steer: 0, rate: 2.0), 0);
    expect(
      yawRateForSteer(steer: -1, rate: 2.0),
      -yawRateForSteer(steer: 1, rate: 2.0),
    );
  });

  test('reversing swings the nose the other way, as a car does', () {
    // The caller passes a negative rate when reversing.
    final forwards = yawRateForSteer(steer: 1, rate: 2.0);
    final backwards = yawRateForSteer(steer: 1, rate: -2.0);
    expect(forwards.sign, -backwards.sign);
  });

  test(
    'the engine camera is left-handed: looking along -Z, -X is on the right',
    () {
      // The premise of the fix. A right-handed camera looking down -Z has +X on
      // the right; this engine's has -X there, so "right" in world coordinates
      // is the opposite of what steering code written from habit assumes.
      final looking = vm.Vector3(0, 0, -1);
      expect(screenX(vm.Vector3(-1, 0, 0), looking), greaterThan(0));
      expect(screenX(vm.Vector3(1, 0, 0), looking), lessThan(0));
      // And looking along +Z it flips back.
      final other = vm.Vector3(0, 0, 1);
      expect(screenX(vm.Vector3(1, 0, 0), other), greaterThan(0));
    },
  );

  test('the nose the game reads agrees with how physics turns it', () {
    // _drivePlayer and the camera read the nose through asRotationMatrix, and
    // the renderer composes the same quaternion into a matrix. If either
    // disagreed with ω × v, the kart would steer one way on screen and be
    // pushed another.
    const theta = 0.02;
    final q = vm.Quaternion(0, math.sin(theta / 2), 0, math.cos(theta / 2));
    final nose = vm.Vector3(0, 0, -1);
    final viaMatrix = q.asRotationMatrix().transformed(nose);
    final viaRenderer = vm.Matrix4.compose(
      vm.Vector3.zero(),
      q,
      vm.Vector3.all(1),
    ).transformed3(nose);
    final viaPhysics = turned(nose, 1, theta);
    expect(viaMatrix.x, closeTo(viaPhysics.x, 0.001));
    expect(viaMatrix.z, closeTo(viaPhysics.z, 0.001));
    expect(viaRenderer.x, closeTo(viaMatrix.x, 1e-9));
    expect(viaRenderer.z, closeTo(viaMatrix.z, 1e-9));
  });
}

/// A guard on the wiring, not the maths. The steering fix was once written
/// over by a stale editor buffer: the function and its tests stayed, the scene
/// went back to the old sign, every test still passed, and an APK shipped with
/// left and right swapped. This fails if the scene stops using the function.
void wiringGuard() {
  test('the race scene steers through yawRateForSteer, not its own sign', () {
    final source = File('lib/features/race/scene/race_scene.dart')
        .readAsStringSync();
    expect(
      source,
      contains('yawRateForSteer('),
      reason: 'race_scene.dart no longer uses the tested steering function',
    );
    expect(
      source,
      isNot(contains('-_steer *')),
      reason: 'race_scene.dart has its own negated steer — the swapped sign',
    );
  });
}
