import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/data/track_shape.dart';
import 'package:dashkart/features/race/race_controller.dart';
import 'package:dashkart/features/race/scene/race_simulation.dart';

/// A solo race is three karts, and they used to start in a scrum: every rival
/// on the same spot on the line as the player, two units out, bumpers almost
/// touching. These hold the start — and the race — to leaving karts room.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// A kart's world position on [shape], at lap fraction [progress] and
  /// [lateral] units across the road.
  (double, double) worldPosition(
    TrackShape shape,
    double progress,
    double lateral,
  ) {
    final t = progress % 1.0;
    final (x, z) = shape.pointAt(t);
    final heading = shape.headingAt(t);
    return (x + math.cos(heading) * lateral, z - math.sin(heading) * lateral);
  }

  double distance((double, double) a, (double, double) b) =>
      math.sqrt(math.pow(a.$1 - b.$1, 2) + math.pow(a.$2 - b.$2, 2));

  RaceController soloController() =>
      RaceController(player: PlayerState(), multiplayer: null);

  group('the solo field', () {
    test('is the player and two rivals', () {
      expect(soloController().sim.runs.length, 3);
    });

    test('is three racers on every circuit', () {
      for (final track in Catalog.tracks) {
        final player = PlayerState()..selectTrack(track);
        // Locked circuits cannot be selected, so build the sim directly too.
        final sim = RaceSimulation(
          track: track,
          playerKart: player.kart,
          playerName: 'P',
          rivals: [Catalog.karts.first, Catalog.karts.first],
        );
        expect(sim.runs.length, 3, reason: track.id);
      }
    });
  });

  group('the starting grid', () {
    for (final track in Catalog.tracks) {
      test('${track.id}: every kart has room at the start', () {
        final shape = TrackShape.forTrack(track.id);
        final sim = RaceSimulation(
          track: track,
          playerKart: Catalog.karts.first,
          playerName: 'P',
          rivals: [Catalog.karts.first, Catalog.karts.first],
        );
        final spots = [
          for (final run in sim.runs)
            worldPosition(
              shape,
              run.progress,
              run.isPlayer ? 0 : run.lateralLane,
            ),
        ];
        for (var i = 0; i < spots.length; i++) {
          for (var j = i + 1; j < spots.length; j++) {
            expect(
              distance(spots[i], spots[j]),
              greaterThan(3.2),
              reason:
                  '${track.id}: karts $i and $j start '
                  '${distance(spots[i], spots[j]).toStringAsFixed(1)} units apart',
            );
          }
        }
      });
    }

    test('is staggered: no two karts share a row', () {
      final sim = RaceSimulation(
        track: Catalog.tracks.first,
        playerKart: Catalog.karts.first,
        playerName: 'P',
        rivals: [Catalog.karts.first, Catalog.karts.first],
      );
      final rows = {for (final r in sim.runs) r.progress};
      expect(rows.length, sim.runs.length);
    });

    test('puts the player at the back, in the middle', () {
      final sim = RaceSimulation(
        track: Catalog.tracks.first,
        playerKart: Catalog.karts.first,
        playerName: 'P',
        rivals: [Catalog.karts.first, Catalog.karts.first],
      );
      expect(sim.player.lateralLane, 0);
      expect(sim.position, sim.runs.length);
      // And the rivals are either side of them, not both on one side.
      final lanes = sim.runs.skip(1).map((r) => r.lateralLane.sign).toSet();
      expect(lanes, {1.0, -1.0});
    });

    test('gives every rival its own row, whatever the field size', () {
      for (var count = 1; count <= 5; count++) {
        final rows = [
          for (var i = 0; i < count; i++)
            RaceSimulation.gridProgressFor(i, count),
        ];
        expect(rows.toSet().length, count, reason: '$count rivals share a row');
        // All strictly ahead of the player, who is on the line at 0.
        expect(rows.every((r) => r > 0), isTrue, reason: '$count rivals');
      }
    });

    test('rivals start well inside the road', () {
      for (var i = 0; i < 4; i++) {
        expect(RaceSimulation.laneFor(i).abs(), lessThan(5.6));
        expect(RaceSimulation.laneFor(i).abs(), greaterThan(3.0));
      }
    });
  });

  group('while racing', () {
    for (final id in ['dash-valley', 'desert-rush', 'frozen-peak']) {
      test('$id: the rivals stay clear of each other', () {
        final track = Catalog.trackById(id);
        final shape = TrackShape.forTrack(id);
        final sim = RaceSimulation(
          track: track,
          playerKart: Catalog.karts.first,
          playerName: 'P',
          rivals: [Catalog.karts.first, Catalog.karts.first],
        );
        var closest = double.infinity;
        for (var i = 0; i < 60 * 90; i++) {
          sim.advance(1 / 60);
          closest = math.min(
            closest,
            distance(
              worldPosition(
                shape,
                sim.runs[1].progress,
                sim.runs[1].lateralLane,
              ),
              worldPosition(
                shape,
                sim.runs[2].progress,
                sim.runs[2].lateralLane,
              ),
            ),
          );
        }
        expect(
          closest,
          greaterThan(2.5),
          reason: '$id: rivals got within $closest',
        );
      });
    }
  });

  group('multiplayer', () {
    test('the two sides start in opposite lanes, well apart', () {
      final host = RaceSimulation.multiplayerStartLane(isHost: true);
      final guest = RaceSimulation.multiplayerStartLane(isHost: false);
      expect(host.sign, isNot(guest.sign));
      expect((host - guest).abs(), greaterThan(3.2));
    });
  });

  group('callouts', () {
    test('overtakes and lost places are not announced', () {
      final c = soloController()..startRacing();
      var t = const Duration(milliseconds: 16);
      c.tick(t);
      // Put every rival well ahead, then well behind: the player's place
      // changes both ways.
      for (final bot in c.sim.runs.skip(1)) {
        bot.progress = 5;
      }
      for (var i = 0; i < 5; i++) {
        t += const Duration(milliseconds: 16);
        c.tick(t);
      }
      expect(c.flash, isNull, reason: 'a lost place was announced');
      for (final bot in c.sim.runs.skip(1)) {
        bot.progress = -5;
      }
      for (var i = 0; i < 5; i++) {
        t += const Duration(milliseconds: 16);
        c.tick(t);
      }
      expect(c.flash, isNull, reason: 'an overtake was announced');
    });

    test('a mini turbo is still announced, and clears itself', () {
      final c = soloController()..startRacing();
      var t = const Duration(milliseconds: 16);
      c.tick(t);
      c.onDriftBoost();
      expect(c.flash, 'MINI TURBO');
      for (var i = 0; i < 90; i++) {
        t += const Duration(milliseconds: 16);
        c.tick(t);
      }
      expect(c.flash, isNull);
    });
  });
}
