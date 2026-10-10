import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'package:dashkart/data/track_shape.dart';
import 'package:dashkart/features/race/race_telemetry.dart';

/// The WRONG WAY banner once appeared for a player driving the right way
/// round: the check compared their velocity to the track direction with the
/// sign flipped. These pin it to the real circuits, and to how the scene
/// actually points the kart on the grid, so it cannot drift back.
void main() {
  /// Velocity of a kart driving the circuit the right way at lap fraction [t]
  /// — towards increasing spline position, which is how laps are counted.
  (double, double) forwardVelocity(TrackShape shape, double t, double speed) {
    const dt = 0.001;
    final (x0, z0) = shape.pointAt(t);
    final (x1, z1) = shape.pointAt(t + dt);
    final length = math.sqrt((x1 - x0) * (x1 - x0) + (z1 - z0) * (z1 - z0));
    return ((x1 - x0) / length * speed, (z1 - z0) / length * speed);
  }

  group('on every circuit, all the way round', () {
    for (final entry in TrackShape.all) {
      test('${entry.key}: driving forwards is never wrong way', () {
        for (var i = 0; i < 200; i++) {
          final t = i / 200;
          final (vx, vz) = forwardVelocity(entry.value, t, 15);
          expect(
            isGoingWrongWay(heading: entry.value.headingAt(t), vx: vx, vz: vz),
            isFalse,
            reason: '${entry.key} at t=$t warned a correctly driven kart',
          );
        }
      });

      test('${entry.key}: driving backwards always is', () {
        for (var i = 0; i < 200; i++) {
          final t = i / 200;
          final (vx, vz) = forwardVelocity(entry.value, t, -15);
          expect(
            isGoingWrongWay(heading: entry.value.headingAt(t), vx: vx, vz: vz),
            isTrue,
            reason: '${entry.key} at t=$t missed a kart driving backwards',
          );
        }
      });
    }
  });

  test('a kart on the grid, as the scene spawns it, is going the right way', () {
    // The scene rotates the kart by heading + pi about Y, and the kart model's
    // nose points down -Z. Whatever way that leaves it facing is "forwards",
    // and driving where it faces must not be wrong way.
    for (final entry in TrackShape.all) {
      final heading = entry.value.headingAt(0);
      final nose = vm.Quaternion.axisAngle(
        vm.Vector3(0, 1, 0),
        heading + math.pi,
      ).asRotationMatrix().transformed(vm.Vector3(0, 0, -1));
      expect(
        isGoingWrongWay(heading: heading, vx: nose.x * 12, vz: nose.z * 12),
        isFalse,
        reason: '${entry.key}: the kart spawns facing the wrong way round',
      );
    }
  });

  group('edge cases', () {
    test('sideways across the road is not wrong way', () {
      expect(isGoingWrongWay(heading: 0, vx: 15, vz: 0), isFalse);
    });

    test('a gentle angle against the track is tolerated', () {
      // About 100 degrees off: only slightly against, as in a wide drift.
      final a = 100 * math.pi / 180;
      expect(
        isGoingWrongWay(heading: 0, vx: math.sin(a) * 15, vz: math.cos(a) * 15),
        isFalse,
      );
    });

    test('a kart spun round but barely moving is not yet wrong way', () {
      expect(isGoingWrongWay(heading: 0, vx: 0, vz: -2), isFalse);
      expect(isGoingWrongWay(heading: 0, vx: 0, vz: -3.5), isTrue);
    });

    test('standing still never is', () {
      expect(isGoingWrongWay(heading: 1.2, vx: 0, vz: 0), isFalse);
    });

    test('works for every compass heading', () {
      for (var deg = 0; deg < 360; deg += 15) {
        final h = deg * math.pi / 180;
        expect(
          isGoingWrongWay(
            heading: h,
            vx: math.sin(h) * 14,
            vz: math.cos(h) * 14,
          ),
          isFalse,
          reason: 'forwards at $deg°',
        );
        expect(
          isGoingWrongWay(
            heading: h,
            vx: -math.sin(h) * 14,
            vz: -math.cos(h) * 14,
          ),
          isTrue,
          reason: 'backwards at $deg°',
        );
      }
    });
  });
}
