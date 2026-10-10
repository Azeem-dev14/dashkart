import 'package:flutter_test/flutter_test.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/kart_tuning.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/track_shape.dart';
import 'package:dashkart/features/race/scene/race_simulation.dart';

/// The AI field used to be a constant: `run.progress += run.pace * dt`, with
/// a comment noting that every bot held exactly the same speed as the others
/// for the whole race. That cannot be raced against — it is a progress bar
/// with a kart model on it. It also meant that where 3D was unavailable the
/// player never moved at all, because their progress only ever arrived from
/// physics telemetry, so the race could never end and the player was stuck.
///
/// These cover both: that the bots drive the circuit's real geometry, and
/// that the fallback is a playable race.
Kart _kart(Map<KartStat, int> stats) => Kart(
  id: 'dash',
  name: 'Test',
  tagline: '',
  model: 'dashkart',
  unlock: const Starter(),
  stats: {
    KartStat.speed: 5,
    KartStat.acceleration: 5,
    KartStat.handling: 5,
    KartStat.drift: 5,
    KartStat.weight: 5,
    ...stats,
  },
);

void main() {
  RaceSimulation build({
    String trackId = 'dash-valley',
    String kartId = 'dash',
    int rivals = 3,
    int seed = 42,
  }) {
    return RaceSimulation(
      track: Catalog.trackById(trackId),
      playerKart: Catalog.kartById(kartId),
      playerName: 'Player',
      rivals: List.generate(rivals, (_) => Catalog.karts.first),
      seed: seed,
    );
  }

  /// Runs [seconds] of race at a fixed step.
  void run(RaceSimulation sim, double seconds, {double dt = 1 / 60}) {
    for (var i = 0; i < seconds / dt; i++) {
      sim.advance(dt);
    }
  }

  group('the field', () {
    test('is the player plus their rivals', () {
      final sim = build();
      expect(sim.runs.length, 4);
      expect(sim.runs.first.isPlayer, isTrue);
      expect(sim.runs.skip(1).every((r) => !r.isPlayer), isTrue);
    });

    test('everyone has a name worth putting on a results board', () {
      final sim = build();
      for (final racer in sim.runs) {
        expect(racer.name, isNotEmpty);
      }
      final names = sim.runs.map((r) => r.name).toSet();
      expect(names.length, sim.runs.length, reason: 'duplicate names');
    });

    test('bots accelerate from a standstill rather than starting at pace', () {
      final sim = build();
      expect(sim.runs[1].speed, 0);
      run(sim, 0.5);
      expect(sim.runs[1].speed, greaterThan(0));
    });

    test('bots actually make progress round the lap', () {
      final sim = build();
      run(sim, 10);
      for (final bot in sim.runs.skip(1)) {
        expect(bot.progress, greaterThan(0));
      }
    });

    test('no bot ever exceeds the top speed of the kart it is driving', () {
      final sim = build();
      for (var i = 0; i < 60 * 90; i++) {
        sim.advance(1 / 60);
        for (final bot in sim.runs.skip(1)) {
          expect(
            bot.speed,
            lessThanOrEqualTo(bot.tuning.topSpeed + 1e-6),
            reason: 'catch-up made ${bot.name} faster than its kart can go',
          );
        }
      }
    });

    test('bots slow for the corners instead of holding one pace', () {
      // Frozen Peak is the tightest circuit that ships, so a bot that reads
      // the geometry has to vary its speed round it.
      final sim = build(trackId: 'frozen-peak');
      run(sim, 6); // up to speed first
      final speeds = <double>[];
      for (var i = 0; i < 60 * 40; i++) {
        sim.advance(1 / 60);
        speeds.add(sim.runs[1].speed);
      }
      final fastest = speeds.reduce((a, b) => a > b ? a : b);
      final slowest = speeds.reduce((a, b) => a < b ? a : b);
      expect(
        fastest - slowest,
        greaterThan(1.0),
        reason: 'the bot drove the whole circuit at one speed',
      );
    });

    test('a bot never corners faster than its tyres allow', () {
      final sim = build(trackId: 'frozen-peak');
      final shape = TrackShape.forTrack('frozen-peak');
      run(sim, 5);
      for (var i = 0; i < 60 * 40; i++) {
        sim.advance(1 / 60);
        final bot = sim.runs[1];
        final radius = shape.curvatureRadiusAt(bot.progress % 1.0);
        if (!radius.isFinite) continue;
        // v = sqrt(a * r), with a little slack for the one frame between
        // reading the corner and having braked for it.
        final limit = (bot.tuning.grip * radius);
        expect(bot.speed * bot.speed, lessThan(limit * 1.35));
      }
    });

    test('a harder circuit fields a faster, more competent grid', () {
      final easy = build(trackId: 'dash-valley');
      final hard = build(trackId: 'frozen-peak');
      expect(
        hard.runs[1].skill,
        greaterThan(easy.runs[1].skill),
        reason: 'difficulty does not reach the AI',
      );
    });

    test('the grid is varied, not one block of identical bots', () {
      final sim = build();
      final skills = sim.runs.skip(1).map((r) => r.skill).toSet();
      expect(skills.length, sim.runs.length - 1);
    });

    test('is deterministic for a given seed', () {
      final a = build(seed: 7);
      final b = build(seed: 7);
      run(a, 20);
      run(b, 20);
      for (var i = 0; i < a.runs.length; i++) {
        expect(a.runs[i].progress, b.runs[i].progress);
      }
    });

    test('bots take a line through the corners rather than a fixed lane', () {
      final sim = build(trackId: 'desert-rush');
      run(sim, 4);
      final lanes = <double>[];
      for (var i = 0; i < 60 * 30; i++) {
        sim.advance(1 / 60);
        lanes.add(sim.runs[1].lateralLane);
      }
      final widest = lanes.reduce((a, b) => a > b ? a : b);
      final tightest = lanes.reduce((a, b) => a < b ? a : b);
      expect(widest - tightest, greaterThan(0.5));
    });

    test('bots stay on the road', () {
      final sim = build(trackId: 'desert-rush');
      for (var i = 0; i < 60 * 60; i++) {
        sim.advance(1 / 60);
        for (final bot in sim.runs.skip(1)) {
          expect(bot.lateralLane.abs(), lessThanOrEqualTo(5.6 + 1e-6));
        }
      }
    });
  });

  group('catch-up', () {
    test('nudges a bot that is a long way behind, within bounds', () {
      final sim = build();
      run(sim, 10);
      // Put the player half a lap up the road.
      sim.applyPlayerTelemetry(progress: 0.5, speedKmh: 180);
      final behind = sim.runs[1];
      final before = behind.speed;
      run(sim, 2);
      expect(behind.speed, greaterThanOrEqualTo(before - 1e-9));
      expect(behind.speed, lessThanOrEqualTo(behind.tuning.topSpeed));
    });

    test('does not kick in for a gap too small to matter', () {
      final sim = build();
      run(sim, 20);
      final bot = sim.runs[1];
      sim.applyPlayerTelemetry(progress: bot.progress, speedKmh: 180);
      final before = bot.speed;
      sim.advance(1 / 60);
      // Level with the player, so pace is whatever the corner allows and
      // nothing more.
      expect(bot.speed, closeTo(before, 0.5));
    });
  });

  group('position', () {
    test('is 1-based, best first', () {
      final sim = build();
      sim.applyPlayerTelemetry(progress: 2.0, speedKmh: 100);
      expect(sim.position, 1);
      for (final bot in sim.runs.skip(1)) {
        bot.progress = 3.0;
      }
      sim.advance(1 / 60);
      expect(sim.position, sim.runs.length);
    });

    test('the cached order is invalidated when progress changes', () {
      final sim = build();
      // The player starts at the back of the grid.
      expect(sim.position, sim.runs.length);
      // Reading it above cached the order; new telemetry has to clear that.
      sim.applyPlayerTelemetry(progress: 2.0, speedKmh: 100);
      expect(sim.position, 1);
      for (final bot in sim.runs.skip(1)) {
        bot.progress = 3.0;
      }
      sim.advance(1 / 60);
      expect(sim.position, sim.runs.length);
    });
  });

  group('lap timing', () {
    test('a completed lap is recorded, and the best one kept', () {
      final sim = build();
      run(sim, 30);
      sim.applyPlayerTelemetry(progress: 0.99, speedKmh: 150);
      expect(sim.bestLap, isNull);

      sim.applyPlayerTelemetry(progress: 1.01, speedKmh: 150);
      final first = sim.bestLap;
      expect(first, isNotNull);

      // A second, slower lap must not replace the best.
      run(sim, 60);
      sim.applyPlayerTelemetry(progress: 2.01, speedKmh: 150);
      expect(sim.bestLap, first);
    });

    test('driving back over the line does not bank a one-frame lap', () {
      final sim = build();
      run(sim, 30);
      sim.applyPlayerTelemetry(progress: 1.01, speedKmh: 150);
      final best = sim.bestLap;
      // Reverse over the line and come back.
      sim.applyPlayerTelemetry(progress: 0.99, speedKmh: 40);
      sim.applyPlayerTelemetry(progress: 1.01, speedKmh: 40);
      expect(
        sim.bestLap,
        best,
        reason: 'crossing the line backwards then forwards banked a lap',
      );
    });
  });

  group('boost', () {
    test('refreshes rather than stacks', () {
      final sim = build();
      sim.useBoost();
      expect(sim.boosting, isTrue);
      expect(sim.boostFraction, closeTo(1.0, 1e-9));
      sim.advance(1.0);
      sim.useBoost();
      expect(sim.boostFraction, closeTo(1.0, 1e-9));
    });

    test('a mini turbo is shorter than a collected one', () {
      expect(KartTuning.miniTurboDuration, lessThan(KartTuning.boostDuration));
      final sim = build();
      sim.useBoost(duration: KartTuning.miniTurboDuration);
      expect(sim.boostFraction, lessThan(1.0));
      expect(sim.boosting, isTrue);
    });

    test('a shorter boost never cuts a longer one short', () {
      final sim = build();
      sim.useBoost();
      sim.useBoost(duration: KartTuning.miniTurboDuration);
      expect(sim.boostFraction, closeTo(1.0, 1e-9));
    });

    test('expires', () {
      final sim = build();
      sim.useBoost();
      run(sim, KartTuning.boostDuration + 0.5);
      expect(sim.boosting, isFalse);
      expect(sim.boostFraction, 0);
    });
  });

  group('the kinematic fallback', () {
    test('drives the player, so a race without 3D is still a race', () {
      final sim = build();
      expect(sim.player.progress, 0);
      for (var i = 0; i < 60 * 3; i++) {
        sim.advance(1 / 60);
        sim.advancePlayerKinematically(1 / 60, steer: 0, braking: false);
      }
      expect(sim.player.progress, greaterThan(0));
      expect(sim.speedKmh, greaterThan(0));
    });

    test('finishes the race rather than running forever', () {
      final sim = build();
      var seconds = 0.0;
      while (!sim.finished && seconds < 600) {
        sim.advance(1 / 60);
        sim.advancePlayerKinematically(1 / 60, steer: 0, braking: false);
        seconds += 1 / 60;
      }
      expect(sim.finished, isTrue, reason: 'the race never ended');
      expect(sim.player.lap, greaterThanOrEqualTo(sim.track.laps));
      // Three laps of an arcade circuit, not a marathon.
      expect(seconds, inInclusiveRange(30, 240));
    });

    test('records lap times along the way', () {
      final sim = build();
      while (!sim.finished) {
        sim.advance(1 / 60);
        sim.advancePlayerKinematically(1 / 60, steer: 0, braking: false);
      }
      expect(sim.bestLap, isNotNull);
      expect(sim.bestLap!.inMilliseconds, greaterThan(0));
      expect(sim.bestLap, lessThan(sim.elapsed));
    });

    test('braking slows the kart', () {
      final sim = build();
      for (var i = 0; i < 60 * 4; i++) {
        sim.advance(1 / 60);
        sim.advancePlayerKinematically(1 / 60, steer: 0, braking: false);
      }
      final cruising = sim.speedKmh;
      for (var i = 0; i < 30; i++) {
        sim.advance(1 / 60);
        sim.advancePlayerKinematically(1 / 60, steer: 0, braking: true);
      }
      expect(sim.speedKmh, lessThan(cruising));
    });

    test('steering moves the kart across the road, and no further', () {
      final sim = build();
      for (var i = 0; i < 60 * 20; i++) {
        sim.advance(1 / 60);
        sim.advancePlayerKinematically(1 / 60, steer: 1, braking: false);
      }
      expect(sim.player.lateralLane, greaterThan(0));
      expect(sim.player.lateralLane, lessThanOrEqualTo(5.6 + 1e-6));
    });

    test('a faster kart finishes sooner', () {
      Duration finish(int speed) {
        final sim = RaceSimulation(
          track: Catalog.tracks.first,
          playerKart: _kart({KartStat.speed: speed}),
          playerName: 'P',
          rivals: [Catalog.karts.first],
        );
        while (!sim.finished && sim.elapsed.inSeconds < 600) {
          sim.advance(1 / 60);
          sim.advancePlayerKinematically(1 / 60, steer: 0, braking: false);
        }
        return sim.elapsed;
      }

      expect(finish(10), lessThan(finish(2)));
    });

    test('a finished race stops advancing', () {
      final sim = build();
      while (!sim.finished) {
        sim.advance(1 / 60);
        sim.advancePlayerKinematically(1 / 60, steer: 0, braking: false);
      }
      final progress = sim.player.progress;
      final elapsed = sim.elapsed;
      run(sim, 5);
      sim.advancePlayerKinematically(1 / 60, steer: 0, braking: false);
      expect(sim.player.progress, progress);
      expect(sim.elapsed, elapsed);
    });
  });

  group('corner speed limits', () {
    test('a straight imposes none', () {
      final sim = build();
      final tuning = KartTuning.of(Catalog.karts.first);
      // A circle has constant curvature, so sample the flattest point of a
      // real circuit instead of asserting on a synthetic straight.
      final limits = [
        for (var i = 0; i < 100; i++) sim.cornerSpeedLimit(i / 100, tuning),
      ];
      expect(limits.reduce((a, b) => a > b ? a : b), tuning.topSpeed);
    });

    test('a tighter corner imposes a lower one', () {
      final sim = build(trackId: 'frozen-peak');
      final tuning = KartTuning.of(Catalog.karts.first);
      final shape = TrackShape.forTrack('frozen-peak');
      var tightestT = 0.0;
      var tightest = double.infinity;
      for (var i = 0; i < 500; i++) {
        final r = shape.curvatureRadiusAt(i / 500);
        if (r < tightest) {
          tightest = r;
          tightestT = i / 500;
        }
      }
      expect(
        sim.cornerSpeedLimit(tightestT, tuning),
        lessThan(tuning.topSpeed),
      );
    });

    test('a grippier kart carries more speed through the same corner', () {
      final sim = build(trackId: 'frozen-peak');
      final shape = TrackShape.forTrack('frozen-peak');
      var tightestT = 0.0;
      var tightest = double.infinity;
      for (var i = 0; i < 500; i++) {
        final r = shape.curvatureRadiusAt(i / 500);
        if (r < tightest) {
          tightest = r;
          tightestT = i / 500;
        }
      }
      final grippy = KartTuning.of(_kart({KartStat.handling: 10}));
      final loose = KartTuning.of(_kart({KartStat.handling: 2}));
      expect(
        sim.cornerSpeedLimit(tightestT, grippy),
        greaterThan(sim.cornerSpeedLimit(tightestT, loose)),
      );
    });
  });

  group('track geometry', () {
    test('every circuit has a corner somewhere', () {
      for (final entry in TrackShape.all) {
        final radii = [
          for (var i = 0; i < 200; i++) entry.value.curvatureRadiusAt(i / 200),
        ];
        expect(
          radii.where((r) => r.isFinite && r < 60),
          isNotEmpty,
          reason: '${entry.key} has nothing a player has to slow for',
        );
      }
    });
  });

  group('multiplayer', () {
    test('fields exactly the opponent, under their own name', () {
      final sim = RaceSimulation(
        track: Catalog.tracks.first,
        playerKart: Catalog.karts.first,
        playerName: 'Me',
        rivals: [Catalog.karts.first],
        rivalNames: const ['Them'],
      );
      expect(sim.runs.length, 2);
      expect(sim.runs[1].name, 'Them');
    });
  });

  group('player tuning', () {
    test('is the selected karts own numbers', () {
      final sim = build(kartId: 'dash');
      expect(
        sim.tuning.topSpeed,
        KartTuning.of(Catalog.kartById('dash')).topSpeed,
      );
    });

    test('the HUD top speed is the one the kart reaches', () {
      final sim = build();
      expect(sim.topSpeed, sim.tuning.topSpeedKmh);
      expect(sim.topSpeed, greaterThan(0));
    });
  });

  group('track laps', () {
    test('every circuit is a sane length to race', () {
      for (final track in Catalog.tracks) {
        expect(track.laps, inInclusiveRange(2, 5));
      }
    });

    test('difficulty rises with running order', () {
      final order = [for (final t in Catalog.tracks) t.difficulty.chevrons];
      // Not strictly monotonic — two easy circuits open the game — but it
      // must never go backwards.
      for (var i = 1; i < order.length; i++) {
        expect(order[i], greaterThanOrEqualTo(order[i - 1]));
      }
    });

    test('the running order has no gaps or repeats', () {
      final indices = [for (final t in Catalog.tracks) t.index]..sort();
      expect(indices, [for (var i = 1; i <= Catalog.tracks.length; i++) i]);
    });
  });

  group('next track', () {
    test('walks the running order and wraps', () {
      var track = Catalog.tracks.first;
      final seen = <String>[];
      for (var i = 0; i < Catalog.tracks.length; i++) {
        seen.add(track.id);
        track = Catalog.nextTrack(track);
      }
      expect(seen.toSet().length, Catalog.tracks.length);
      expect(track.id, Catalog.tracks.first.id);
    });
  });
}
