import 'package:flutter_test/flutter_test.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/track_shape.dart';
import 'package:dashkart/features/race/scene/race_scene.dart';

/// Circuit geometry is solved against the driving model, not drawn by hand: a
/// lap that merely *looks* like a good circuit is very easily tighter than the
/// kart can turn, and the player then cannot get round it at all. These hold
/// every track to that, and re-derive the limit from the handling constants,
/// so retuning the physics re-checks the circuits instead of quietly breaking
/// them.
void main() {
  test('every catalogue track has a shape of its own', () {
    // Identity is no good here: `const` values are canonicalised, so the
    // easiest circuit is literally the same instance as the fallback. What
    // matters is that each id is actually in the table.
    final defined = {for (final entry in TrackShape.all) entry.key};
    for (final track in Catalog.tracks) {
      expect(
        defined,
        contains(track.id),
        reason: '${track.id} has no shape and would fall back',
      );
    }
  });

  test('every corner can actually be got round', () {
    final limit = RaceScene.minimumTurnRadius;
    for (final entry in TrackShape.all) {
      expect(
        entry.value.tightestCornerRadius(),
        greaterThan(limit),
        reason:
            '${entry.key} has a corner tighter than the kart can turn '
            '(${limit.toStringAsFixed(1)} units at full lock, top speed)',
      );
    }
  });

  test('laps are a sensible length for a three-lap race', () {
    for (final entry in TrackShape.all) {
      final length = entry.value.lapLength();
      expect(length, greaterThan(200), reason: '${entry.key} lap is too short');
      expect(length, lessThan(500), reason: '${entry.key} lap is too long');
    }
  });

  test('the circuits are genuinely different from one another', () {
    final signatures = <String>{};
    for (final entry in TrackShape.all) {
      final shape = entry.value;
      signatures.add(
        '${shape.lobes}:${shape.lobe.toStringAsFixed(3)}:'
        '${shape.radius.toStringAsFixed(0)}',
      );
    }
    expect(signatures.length, TrackShape.all.length);
  });

  test('at least one circuit demands lifting off the boost', () {
    final boostLimit = RaceScene.boostingTurnRadius;
    final demanding = TrackShape.all.where(
      (e) => e.value.tightestCornerRadius() < boostLimit,
    );
    expect(demanding, isNotEmpty);
  });
}
