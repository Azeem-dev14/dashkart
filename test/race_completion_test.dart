import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/features/race/race_controller.dart';
import 'package:dashkart/features/race/race_telemetry.dart';
import 'package:dashkart/features/race/scene/race_simulation.dart';
import 'package:dashkart/features/race/scene/scene3d.dart';
import 'package:dashkart/features/results/results_screen.dart';

/// A race is over when the player finishes *or* when every other racer has.
/// Before, only the player's own finish ended it: the bots never registered a
/// finish and just kept circling, and a multiplayer opponent's `finished` flag
/// was sent over the network and never read — so a race whose other racers
/// had all crossed the line carried on regardless.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  RaceSimulation build({bool network = false, int rivals = 2}) =>
      RaceSimulation(
        track: Catalog.tracks.first,
        playerKart: Catalog.karts.first,
        playerName: 'P',
        rivals: List.generate(rivals, (_) => Catalog.karts.first),
        networkOpponents: network,
      );

  /// Runs the race with a player who never moves, until [done] or [limit]
  /// seconds. Returns the seconds run.
  double runUntil(
    RaceSimulation sim,
    bool Function() done, {
    double limit = 600,
  }) {
    var t = 0.0;
    while (!done() && t < limit) {
      sim.advance(1 / 60);
      t += 1 / 60;
    }
    return t;
  }

  group('bots finish', () {
    test('a bot is finished once it completes its laps, and not before', () {
      final sim = build();
      final bot = sim.runs[1];
      expect(bot.finishTime, isNull);
      runUntil(sim, () => bot.finishTime != null);
      expect(bot.finishTime, isNotNull);
      expect(bot.progress, greaterThanOrEqualTo(sim.track.laps));
    });

    test('and rolls to a stop instead of circling for ever', () {
      final sim = build();
      final fast = sim.runs[1];
      // Make the other rival slow, so the race is still going on after the
      // first one is home — otherwise the clock stops the moment it crosses.
      sim.runs[2].skill = 0.1;
      runUntil(sim, () => fast.finishTime != null);
      expect(sim.finished, isFalse, reason: 'the slow rival is still racing');
      final lineAt = fast.progress;
      for (var i = 0; i < 60 * 6; i++) {
        sim.advance(1 / 60);
      }
      expect(fast.speed, lessThan(0.1), reason: 'still moving after finishing');
      // It rolled to a halt just past the line, not another lap.
      expect(fast.progress - lineAt, lessThan(0.05));
      expect(fast.progress, lessThan(sim.track.laps + 0.1));
    });
  });

  group('when the race is over', () {
    test('the player finishing first ends it, in first place', () {
      final sim = build();
      sim.applyPlayerTelemetry(progress: 3.0, speedKmh: 150);
      expect(sim.finished, isTrue);
      expect(sim.player.finishTime, isNotNull);
      expect(sim.position, 1);
      expect(sim.runs.skip(1).every((r) => r.finishTime == null), isTrue);
    });

    test('one rival finishing does not end it while another is racing', () {
      final sim = build();
      final seconds = runUntil(
        sim,
        () => sim.runs.skip(1).any((r) => r.finishTime != null),
      );
      expect(seconds, lessThan(600));
      final stillRacing = sim.runs.skip(1).where((r) => r.finishTime == null);
      // The two bots have different skill, so they cannot cross on the same
      // frame; if they somehow did, there is nothing to assert about.
      if (stillRacing.isNotEmpty) {
        expect(
          sim.finished,
          isFalse,
          reason: 'ended with a rival still racing',
        );
      }
    });

    test('every rival finishing ends it, even though the player has not', () {
      final sim = build();
      runUntil(sim, () => sim.finished);
      expect(sim.finished, isTrue);
      expect(sim.runs.skip(1).every((r) => r.finishTime != null), isTrue);
      expect(
        sim.player.finishTime,
        isNull,
        reason: 'the player never finished',
      );
      expect(sim.position, sim.runs.length, reason: 'unfinished comes last');
    });

    test('among those still racing, whoever got furthest is placed best', () {
      final sim = build(rivals: 3);
      sim.runs[1].finishTime = const Duration(seconds: 50);
      sim.runs[2].finishTime = const Duration(seconds: 55);
      sim.player.progress = 2.5;
      sim.runs[3].progress = 1.0;
      sim.advance(1 / 60);
      expect(sim.order[0], sim.runs[1]);
      expect(sim.order[1], sim.runs[2]);
      expect(sim.order[2].isPlayer, isTrue);
      expect(sim.order[3], sim.runs[3]);
      expect(sim.finished, isFalse, reason: 'one rival is still racing');
    });

    test('a finished race stops the clock', () {
      final sim = build();
      runUntil(sim, () => sim.finished);
      final elapsed = sim.elapsed;
      sim.advance(1.0);
      expect(sim.elapsed, elapsed);
    });
  });

  group('finishing order', () {
    test('is by finish time, not by how far a racer coasted', () {
      final sim = build(rivals: 3);
      // Rival 1 crossed first but is stationary; rival 2 crossed later and has
      // rolled much further. Distance would put 2 ahead — wrongly.
      sim.runs[1]
        ..finishTime = const Duration(seconds: 40)
        ..progress = 3.01;
      sim.runs[2]
        ..finishTime = const Duration(seconds: 45)
        ..progress = 3.30;
      sim.advance(1 / 60);
      final finished = sim.order.where((r) => r.finishTime != null).toList();
      expect(finished.map((r) => r.id), [sim.runs[1].id, sim.runs[2].id]);
      expect(
        sim.order.indexOf(sim.runs[1]),
        lessThan(sim.order.indexOf(sim.runs[2])),
      );
    });

    test('finished racers always rank ahead of those still racing', () {
      final sim = build(rivals: 3);
      sim.runs[1].finishTime = const Duration(seconds: 80);
      sim.runs[1].progress = 3.0;
      sim.player.progress = 2.9;
      sim.advance(1 / 60);
      expect(sim.order.first, sim.runs[1]);
    });
  });

  group('a multiplayer opponent', () {
    test('is not driven here', () {
      final sim = build(network: true, rivals: 1);
      final opponent = sim.runs[1];
      final startProgress = opponent.progress;
      for (var i = 0; i < 120; i++) {
        sim.advance(1 / 60);
      }
      expect(
        opponent.progress,
        startProgress,
        reason: 'the AI moved a human opponent',
      );
      expect(opponent.speed, 0);
    });

    test('finishing ends the race for a player who has not', () {
      final sim = build(network: true, rivals: 1);
      sim.applyPlayerTelemetry(progress: 1.2, speedKmh: 150);
      expect(sim.finished, isFalse);
      sim.markFinished(sim.runs[1]);
      expect(sim.finished, isTrue);
      expect(sim.player.finishTime, isNull);
      expect(sim.position, 2);
    });

    test('finishing second to the player does not change who won', () {
      final sim = build(network: true, rivals: 1);
      sim.applyPlayerTelemetry(progress: 3.0, speedKmh: 150);
      sim.markFinished(sim.runs[1]);
      expect(sim.position, 1);
    });

    test('is only recorded once', () {
      final sim = build(network: true, rivals: 1);
      sim.advance(2);
      sim.markFinished(sim.runs[1]);
      final first = sim.runs[1].finishTime;
      sim.advance(2);
      sim.markFinished(sim.runs[1]);
      expect(sim.runs[1].finishTime, first);
    });
  });

  group('the controller', () {
    RaceController solo() =>
        RaceController(player: PlayerState(), multiplayer: null);

    test('ends the race when the bots finish, and says the player did not', () {
      final c = solo()..startRacing();
      var t = Duration.zero;
      var guard = 0;
      while (c.phase == RacePhase.racing && guard++ < 60 * 400) {
        t += const Duration(milliseconds: 16);
        c.tick(t);
      }
      expect(c.phase, RacePhase.results, reason: 'the race never ended');
      final r = c.result!;
      expect(r.didFinish, isFalse);
      expect(r.position, 3);
      expect(r.totalRacers, 3);
      expect(r.trophies, 0, reason: 'last place pays no trophy');
    });

    test('a race that ended around the player sets no record', () {
      final player = PlayerState();
      final c = RaceController(player: player, multiplayer: null)
        ..startRacing();
      var t = Duration.zero;
      var guard = 0;
      while (c.phase == RacePhase.racing && guard++ < 60 * 400) {
        t += const Duration(milliseconds: 16);
        c.tick(t);
      }
      expect(player.bestTime(c.sim.track.id), isNull);
      expect(player.racesFinished, 1);
    });

    test('a player who finishes still gets the normal result', () {
      final c = solo()..startRacing();
      c.tick(const Duration(milliseconds: 16));
      c.reportTelemetry(
        const RaceTelemetry(
          progress: 3.0,
          lateral: 0,
          speedKmh: 150,
          driftCharge: 0,
          drifting: false,
          wrongWay: false,
        ),
      );
      expect(c.phase, RacePhase.results);
      expect(c.result!.didFinish, isTrue);
      expect(c.result!.position, 1);
    });
  });

  group('recording a race the player did not finish', () {
    RaceReward record(PlayerState p, {required bool completed, int laps = 3}) =>
        p.recordResult(
          trackId: 'dash-valley',
          time: const Duration(seconds: 70),
          position: 3,
          laps: laps,
          completed: completed,
        );

    test('sets no record, though a finished one would have', () {
      final done = PlayerState();
      expect(record(done, completed: true).newRecord, isTrue);
      final dnf = PlayerState();
      expect(record(dnf, completed: false).newRecord, isFalse);
      expect(dnf.bestTime('dash-valley'), isNull);
    });

    test('pays XP only for the laps actually driven', () {
      final full = record(PlayerState(), completed: true, laps: 3);
      final partial = record(PlayerState(), completed: false, laps: 1);
      expect(
        full.xp - partial.xp,
        2 * PlayerState.xpPerLap + PlayerState.xpNewRecord,
      );
    });

    test('still counts as a race run', () {
      final p = PlayerState();
      record(p, completed: false, laps: 0);
      expect(p.racesFinished, 1);
      expect(p.bestPosition('dash-valley'), 3);
    });
  });

  group('what counts as a podium', () {
    RaceResult at(int position, int total) => RaceResult(
      position: position,
      totalRacers: total,
      time: const Duration(seconds: 70),
      bestLap: const Duration(seconds: 25),
      trophies: 0,
      xp: 0,
      level: 1,
      levelledUp: false,
      newRecord: false,
      trackName: 'Dash Valley',
    );

    test('beating at least one other racer is, coming last is not', () {
      expect(at(1, 3).podium, isTrue);
      expect(at(2, 3).podium, isTrue);
      expect(at(3, 3).podium, isFalse, reason: 'last of three is not a podium');
      expect(at(1, 2).podium, isTrue);
      expect(at(2, 2).podium, isFalse);
    });
  });

  group('the results screen', () {
    Future<void> pump(WidgetTester tester, {required bool didFinish}) async {
      tester.view.physicalSize = const Size(1688, 780);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      Scene3D.availableOverride = false;
      await tester.pumpWidget(
        ProviderScope(
          child: WidgetsApp(
            color: const Color(0xFF000000),
            home: ResultsScreen(
              result: RaceResult(
                position: 3,
                totalRacers: 3,
                time: const Duration(minutes: 1, seconds: 10),
                bestLap: const Duration(seconds: 25),
                trophies: 0,
                xp: 30,
                level: 1,
                levelledUp: false,
                newRecord: false,
                trackName: 'Dash Valley',
                didFinish: didFinish,
              ),
              onReplay: () {},
              onHome: () {},
            ),
            pageRouteBuilder: <T>(s, b) => PageRouteBuilder<T>(
              settings: s,
              pageBuilder: (c, _, _) => b(c),
            ),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    testWidgets('shows DNF instead of a time when the player did not finish', (
      tester,
    ) async {
      await pump(tester, didFinish: false);
      expect(find.text('DNF'), findsWidgets);
      expect(find.text('1:10.00'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the time when they did', (tester) async {
      await pump(tester, didFinish: true);
      expect(find.text('DNF'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
