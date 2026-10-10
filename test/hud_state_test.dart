import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dashkart/core/widgets/dash_game_hud.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/features/settings/steering_mode.dart';

void main() {
  test('clock formats m:ss.cc', () {
    expect(RaceHudState.clock(Duration.zero), '0:00.00');
    expect(
      RaceHudState.clock(
        const Duration(minutes: 1, seconds: 5, milliseconds: 470),
      ),
      '1:05.47',
    );
  });

  test('a drift is ready only at full charge', () {
    const almost = RaceHudState(
      position: 1,
      totalRacers: 4,
      lap: 1,
      totalLaps: 3,
      speedKmh: 0,
      driftCharge: 0.99,
    );
    const full = RaceHudState(
      position: 1,
      totalRacers: 4,
      lap: 1,
      totalLaps: 3,
      speedKmh: 0,
      driftCharge: 1,
    );
    expect(almost.driftReady, isFalse);
    expect(full.driftReady, isTrue);
  });

  for (final steering in SteeringMode.values) {
    for (final size in const [Size(640, 360), Size(844, 390)]) {
      testWidgets('HUD lays out with every transient on, ${steering.name} '
          '@ ${size.width.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            builder: (_, _) => DashGameHUD(
              steering: steering,
              state: const RaceHudState(
                position: 3,
                totalRacers: 4,
                lap: 3,
                totalLaps: 3,
                speedKmh: 187,
                boosting: true,
                boostFraction: 0.6,
                driftCharge: 1,
                drifting: true,
                wrongWay: false,
                currentLap: Duration(seconds: 27, milliseconds: 310),
                bestLap: Duration(seconds: 26, milliseconds: 90),
                flash: 'MINI TURBO',
                itemState: ItemSlotState.ready,
                trackProgress: [0.2, 0.3, 0.4, 0.5],
                trackId: 'dash-valley',
              ),
              onSteer: (_) {},
              onBrake: (_) {},
              onDrift: (_) {},
              onUseItem: () {},
              onPause: () {},
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('going backwards shows only the wrong-way warning', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> pump({required bool wrongWay}) => tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (_, _) => DashGameHUD(
          state: RaceHudState(
            position: 2,
            totalRacers: 3,
            lap: 1,
            totalLaps: 3,
            speedKmh: 80,
            wrongWay: wrongWay,
            // A callout is pending too; it must not appear over the warning.
            flash: 'MINI TURBO',
            trackProgress: const [0.1, 0.2, 0.3],
            trackId: 'dash-valley',
          ),
          onSteer: (_) {},
          onBrake: (_) {},
          onDrift: (_) {},
          onUseItem: () {},
          onPause: () {},
        ),
      ),
    );

    await pump(wrongWay: true);
    await tester.pump();
    expect(find.text('WRONG WAY'), findsWidgets);
    expect(find.text('MINI TURBO'), findsNothing);

    await pump(wrongWay: false);
    await tester.pump();
    expect(find.text('WRONG WAY'), findsNothing);
    expect(find.text('MINI TURBO'), findsWidgets);
  });
}
