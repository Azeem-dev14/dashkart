import 'package:flutter_test/flutter_test.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/kart_tuning.dart';
import 'package:dashkart/data/models.dart';

/// Kart stats used to be decoration: the race scene drove one hard-coded set
/// of constants no matter what was selected, so two karts three points apart
/// on speed drove identically and the HUD advertised a top speed the kart
/// could never reach.
///
/// These hold the conversion honest — that every axis on the card moves
/// something, in the direction the card implies, and that no kart ends up
/// outside what the circuits can accommodate.
void main() {
  Kart kartWith(Map<KartStat, int> stats) => Kart(
    id: 'test',
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

  group('each stat moves its own quantity, in the right direction', () {
    test('speed raises top speed and nothing about cornering', () {
      final slow = KartTuning.of(kartWith({KartStat.speed: 2}));
      final fast = KartTuning.of(kartWith({KartStat.speed: 9}));
      expect(fast.topSpeed, greaterThan(slow.topSpeed));
      expect(fast.turnRate, slow.turnRate);
      expect(fast.grip, slow.grip);
    });

    test('acceleration raises acceleration and nothing else', () {
      final sluggish = KartTuning.of(kartWith({KartStat.acceleration: 2}));
      final punchy = KartTuning.of(kartWith({KartStat.acceleration: 9}));
      expect(punchy.acceleration, greaterThan(sluggish.acceleration));
      expect(punchy.topSpeed, sluggish.topSpeed);
    });

    test('handling raises both yaw rate and grip', () {
      final vague = KartTuning.of(kartWith({KartStat.handling: 2}));
      final sharp = KartTuning.of(kartWith({KartStat.handling: 9}));
      expect(sharp.turnRate, greaterThan(vague.turnRate));
      expect(sharp.grip, greaterThan(vague.grip));
      expect(sharp.minimumTurnRadius, lessThan(vague.minimumTurnRadius));
    });

    test('drift buys rotation and keeps more of the tyres', () {
      final stiff = KartTuning.of(kartWith({KartStat.drift: 2}));
      final slidey = KartTuning.of(kartWith({KartStat.drift: 9}));
      expect(slidey.driftTurnBonus, greaterThan(stiff.driftTurnBonus));
      expect(slidey.driftGrip, greaterThan(stiff.driftGrip));
    });

    test('drifting always gives up grip, at every drift rating', () {
      for (var drift = 1; drift <= 10; drift++) {
        final tuning = KartTuning.of(kartWith({KartStat.drift: drift}));
        expect(
          tuning.driftGrip,
          lessThan(tuning.grip),
          reason: 'drift $drift would slide no more than it grips',
        );
        expect(tuning.driftGrip, greaterThan(0));
      }
    });

    test('weight buys mass and costs braking and high-speed steering', () {
      final light = KartTuning.of(kartWith({KartStat.weight: 2}));
      final heavy = KartTuning.of(kartWith({KartStat.weight: 9}));
      expect(heavy.mass, greaterThan(light.mass));
      expect(heavy.brakeDecel, lessThan(light.brakeDecel));
      expect(heavy.highSpeedTurnLoss, greaterThan(light.highSpeedTurnLoss));
    });
  });

  group('the catalogue', () {
    test(
      'has a starter kart with every stat within the 1-10 cards can draw',
      () {
        expect(Catalog.karts.first.unlock, isA<Starter>());
        for (final kart in Catalog.karts) {
          for (final stat in KartStat.values) {
            expect(kart.stat(stat), inInclusiveRange(1, 10));
          }
        }
      },
    );
  });

  group('derived figures', () {
    test('a boost widens the tightest corner the kart can hold', () {
      for (final kart in Catalog.karts) {
        final tuning = KartTuning.of(kart);
        expect(
          tuning.boostingTurnRadius,
          greaterThan(tuning.minimumTurnRadius),
          reason: '${kart.id} would corner no worse on boost',
        );
      }
    });

    test('the HUD readout and the physics agree on top speed', () {
      final tuning = KartTuning.of(Catalog.karts.first);
      expect(
        tuning.topSpeedKmh,
        closeTo(tuning.topSpeed * KartTuning.kmhPerWorldUnit, 1e-9),
      );
    });
  });
}
