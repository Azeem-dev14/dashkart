import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';

/// Progression used to be two unrelated systems wearing one coat: the results
/// screen showed an XP figure derived from an eight-racer field, while the
/// save advanced a level by a flat amount that had nothing to do with it, and
/// a brand-new player started on fourteen trophies and level seven of mock
/// data they had not earned.
///
/// These hold the economy to being one system, reachable, and honest about
/// what it pays.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  PlayerState fresh() => PlayerState();

  group('a fresh save', () {
    test('starts at zero, not on seeded mock progress', () {
      final player = fresh();
      expect(player.trophies, 0);
      expect(player.xp, 0);
      expect(player.level, 1);
      expect(player.levelProgress, 0);
      expect(player.racesFinished, 0);
    });

    test('has the starter content and nothing else', () {
      final player = fresh();
      final karts = Catalog.karts.where(player.isKartUnlocked);
      final tracks = Catalog.tracks.where(player.isTrackUnlocked);
      expect(karts.map((k) => k.id), ['dash']);
      expect(tracks.map((t) => t.id), ['dash-valley']);
    });

    test('needs onboarding until it is completed', () {
      final player = fresh();
      expect(player.needsOnboarding, isTrue);
      player.completeOnboarding('Azeem');
      expect(player.needsOnboarding, isFalse);
      expect(player.name, 'Azeem');
    });
  });

  group('rewards', () {
    RaceReward finish(PlayerState player, int position) => player.recordResult(
      trackId: 'dash-valley',
      time: const Duration(seconds: 70),
      position: position,
      laps: 3,
    );

    test('the top two places pay, and last place does not', () {
      expect(finish(fresh(), 1).trophies, 3);
      expect(finish(fresh(), 2).trophies, 2);
      expect(finish(fresh(), 3).trophies, 0);
      expect(finish(fresh(), 4).trophies, 0);
    });

    test('XP always pays something, so a race is never wasted', () {
      for (var position = 1; position <= 4; position++) {
        expect(finish(fresh(), position).xp, greaterThan(0));
      }
    });

    test('a better finish is worth more', () {
      var previous = 1 << 30;
      for (var position = 1; position <= 4; position++) {
        final xp = finish(fresh(), position).xp;
        expect(xp, lessThan(previous));
        previous = xp;
      }
    });

    test('what the screen is told is exactly what was banked', () {
      final player = fresh();
      final reward = finish(player, 1);
      expect(player.trophies, reward.trophies);
      expect(player.xp, reward.xp);
      expect(player.level, reward.level);
    });

    test('a first finish sets the record; a slower one does not beat it', () {
      final player = fresh();
      final first = player.recordResult(
        trackId: 'dash-valley',
        time: const Duration(seconds: 70),
        position: 1,
        laps: 3,
      );
      expect(first.newRecord, isTrue);
      expect(player.bestTime('dash-valley'), const Duration(seconds: 70));

      final slower = player.recordResult(
        trackId: 'dash-valley',
        time: const Duration(seconds: 80),
        position: 1,
        laps: 3,
      );
      expect(slower.newRecord, isFalse);
      expect(player.bestTime('dash-valley'), const Duration(seconds: 70));
    });

    test('best position only ever improves', () {
      final player = fresh();
      finish(player, 3);
      expect(player.bestPosition('dash-valley'), 3);
      finish(player, 1);
      expect(player.bestPosition('dash-valley'), 1);
      finish(player, 4);
      expect(player.bestPosition('dash-valley'), 1);
    });

    test('a trophy for the circuit means having actually won it', () {
      final player = fresh();
      finish(player, 2);
      expect(player.hasTrophy('dash-valley'), isFalse);
      finish(player, 1);
      expect(player.hasTrophy('dash-valley'), isTrue);
    });

    test('a multiplayer race is not the single-player ladder', () {
      final player = fresh();
      final reward = player.recordResult(
        trackId: 'dash-valley',
        time: const Duration(seconds: 60),
        position: 1,
        laps: 3,
        ranked: false,
      );
      expect(reward.trophies, 0);
      expect(reward.xp, 0);
      expect(player.trophies, 0);
      // It still counts as a race run, and still sets a personal best.
      expect(player.racesFinished, 1);
      expect(player.bestTime('dash-valley'), const Duration(seconds: 60));
    });

    test('crossing a threshold is reported so it can be announced', () {
      final player = fresh();
      // Desert Rush wants 6; two wins at 3 each gets there.
      expect(finish(player, 1).unlocked, isEmpty);
      final second = finish(player, 1);
      expect(second.unlocked, contains('Desert Rush'));
      expect(player.isTrackUnlocked(Catalog.trackById('desert-rush')), isTrue);
    });

    test('a threshold is only announced on the race that crosses it', () {
      final player = fresh();
      finish(player, 1);
      expect(finish(player, 1).unlocked, contains('Desert Rush'));
      // Later races cross their own thresholds, but never re-announce one
      // already passed.
      for (var race = 0; race < 10; race++) {
        expect(finish(player, 1).unlocked, isNot(contains('Desert Rush')));
      }
    });

    test('every threshold in the game is announced exactly once', () {
      final player = fresh();
      final seen = <String>[];
      for (var race = 0; race < 40; race++) {
        seen.addAll(finish(player, 1).unlocked);
      }
      expect(seen.toSet().length, seen.length, reason: 'announced twice');
      // Everything gated behind trophies gets its moment.
      final gated = [
        for (final track in Catalog.tracks)
          if (track.unlock is TrophyCount) track.name,
      ];
      expect(seen..sort(), containsAll(gated));
    });
  });

  group('levels', () {
    test('are derived from XP, so the two cannot disagree', () {
      final player = fresh();
      var level = player.level;
      for (var race = 0; race < 40; race++) {
        final reward = player.recordResult(
          trackId: 'dash-valley',
          time: Duration(seconds: 70 - race),
          position: 1,
          laps: 3,
        );
        expect(reward.level, player.level);
        expect(reward.levelledUp, player.level > level);
        level = player.level;
      }
      expect(player.level, greaterThan(1));
    });

    test('progress stays a real fraction at every amount of XP', () {
      final player = fresh();
      for (var race = 0; race < 60; race++) {
        player.recordResult(
          trackId: 'dash-valley',
          time: const Duration(seconds: 70),
          position: 2,
          laps: 3,
        );
        expect(player.levelProgress, inInclusiveRange(0.0, 1.0));
      }
    });

    test('later levels take longer than earlier ones', () {
      expect(
        PlayerState.xpForLevel(10),
        greaterThan(PlayerState.xpForLevel(1)),
      );
    });
  });

  group('the unlock ladder', () {
    test('is reachable, and paced over a sane number of races', () {
      final player = fresh();
      final target = Catalog.tracks
          .map((t) => t.unlock)
          .whereType<TrophyCount>()
          .map((u) => u.trophies)
          .reduce((a, b) => a > b ? a : b);

      var races = 0;
      while (player.trophies < target && races < 200) {
        player.recordResult(
          trackId: 'dash-valley',
          time: const Duration(seconds: 70),
          position: 1,
          laps: 3,
        );
        races++;
      }
      expect(player.trophies, greaterThanOrEqualTo(target));
      // Winning everything should clear the game in a session or two, not
      // across a hundred races — and not in three, either.
      expect(races, inInclusiveRange(5, 40));
      for (final kart in Catalog.karts) {
        expect(player.isKartUnlocked(kart), isTrue, reason: kart.id);
      }
      for (final track in Catalog.tracks) {
        expect(player.isTrackUnlocked(track), isTrue, reason: track.id);
      }
    });

    test('states how far off a locked item is', () {
      final player = fresh();
      final desert = Catalog.trackById('desert-rush');
      expect(player.trophiesRemaining(desert.unlock), 6);
      player.recordResult(
        trackId: 'dash-valley',
        time: const Duration(seconds: 70),
        position: 1,
        laps: 3,
      );
      expect(player.trophiesRemaining(desert.unlock), 3);
      expect(player.trophiesRemaining(const Starter()), 0);
    });

    test('every unlock threshold is distinct and ordered with difficulty', () {
      final trackGates = [
        for (final track in Catalog.tracks)
          if (track.unlock case TrophyCount(:final trophies)) trophies,
      ];
      expect(trackGates, equals([...trackGates]..sort()));
      expect(trackGates.toSet().length, trackGates.length);
    });
  });

  group('selection', () {
    test('a locked track cannot be selected', () {
      final player = fresh();
      final lockedTrack = Catalog.tracks.firstWhere(
        (t) => !player.isTrackUnlocked(t),
      );
      player.selectTrack(lockedTrack);
      expect(player.track.id, isNot(lockedTrack.id));
    });

    test('an unlocked one can', () {
      final player = fresh();
      // Desert Rush wants 6 trophies: two wins.
      for (var i = 0; i < 2; i++) {
        player.recordResult(
          trackId: 'dash-valley',
          time: const Duration(seconds: 70),
          position: 1,
          laps: 3,
        );
      }
      player.selectTrack(Catalog.trackById('desert-rush'));
      expect(player.track.id, 'desert-rush');
    });

    test('a save naming content that no longer exists still loads', () async {
      SharedPreferences.setMockInitialValues({
        'dashkart_player_kart_id': 'a-kart-from-a-future-build',
        'dashkart_player_track_id': 'nowhere',
        'dashkart_player_trophies': 5,
      });
      final player = PlayerState();
      await player.load();
      // Falls back rather than throwing out of `firstWhere`, which is what it
      // used to do — on launch, before anything could catch it.
      expect(player.kart.id, Catalog.karts.first.id);
      expect(player.track.id, Catalog.tracks.first.id);
      expect(player.trophies, 5);
    });

    test('a save holding content it can no longer afford falls back', () async {
      SharedPreferences.setMockInitialValues({
        'dashkart_player_track_id': 'frozen-peak',
        'dashkart_player_trophies': 0,
      });
      final player = PlayerState();
      await player.load();
      expect(player.track.id, 'dash-valley');
    });

    test('a reset is written through, not just held in memory', () async {
      final player = fresh();
      player.completeOnboarding('Azeem');
      player.recordResult(
        trackId: 'dash-valley',
        time: const Duration(seconds: 60),
        position: 1,
        laps: 3,
      );
      await player.save();
      player.resetProgress();
      await player.save();

      final loaded = PlayerState();
      await loaded.load();
      expect(loaded.trophies, 0);
      expect(loaded.bestTime('dash-valley'), isNull);
      expect(loaded.name, 'Azeem');
      expect(loaded.needsOnboarding, isFalse);
    });

    test('resetGame erases name, sets needsOnboarding true, and persists', () async {
      final player = fresh();
      player.completeOnboarding('Speedy');
      player.recordResult(
        trackId: 'dash-valley',
        time: const Duration(seconds: 55),
        position: 1,
        laps: 3,
      );
      await player.save();
      expect(player.needsOnboarding, isFalse);
      expect(player.name, 'Speedy');

      player.resetGame();
      await player.save();

      expect(player.needsOnboarding, isTrue);
      expect(player.name, 'Dash');
      expect(player.trophies, 0);
      expect(player.bestTime('dash-valley'), isNull);

      final reloaded = PlayerState();
      await reloaded.load();
      expect(reloaded.needsOnboarding, isTrue);
      expect(reloaded.name, 'Dash');
      expect(reloaded.trophies, 0);
      expect(reloaded.bestTime('dash-valley'), isNull);
    });
  });
}
