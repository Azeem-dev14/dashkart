import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dashkart/core/feedback/haptics.dart';
import 'package:dashkart/core/widgets/dash_controls.dart';

/// Steering is the one input the whole race hangs on. These pin down how a
/// thumb is read: one finger drives it, it can slide between the two halves,
/// and letting go always recentres — an unsteady wheel was the complaint.
void main() {
  setUp(() => Haptics.enabled = false);

  Future<List<double>> pumpSteering(WidgetTester tester) async {
    final signals = <double>[];
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (_, _) => Align(
          alignment: Alignment.topLeft,
          child: DashSteering(onSteer: signals.add, size: 80),
        ),
      ),
    );
    return signals;
  }

  // Cluster is 2 * 80 + 8 = 168 wide; the midpoint is x = 84.
  const left = Offset(30, 40);
  const right = Offset(140, 40);

  testWidgets('pressing the left half steers left, the right half right', (
    tester,
  ) async {
    final signals = await pumpSteering(tester);
    var g = await tester.startGesture(left);
    expect(signals.last, -1);
    await g.up();
    expect(signals.last, 0);

    g = await tester.startGesture(right);
    expect(signals.last, 1);
    await g.up();
    expect(signals.last, 0);
  });

  testWidgets('one thumb sliding across hands over from left to right', (
    tester,
  ) async {
    final signals = await pumpSteering(tester);
    final g = await tester.startGesture(left);
    expect(signals.last, -1);
    await g.moveTo(right);
    expect(signals.last, 1, reason: 'the slide never reached the right half');
    await g.moveTo(left);
    expect(signals.last, -1);
    await g.up();
    expect(signals.last, 0);
  });

  testWidgets('a held thumb never reports both directions at once', (
    tester,
  ) async {
    final signals = await pumpSteering(tester);
    final g = await tester.startGesture(left);
    await g.moveTo(right);
    await g.moveTo(const Offset(84, 40));
    await g.up();
    expect(signals.every((s) => s == -1 || s == 0 || s == 1), isTrue);
    expect(signals.last, 0);
  });

  testWidgets('a second finger does not fight the first', (tester) async {
    final signals = await pumpSteering(tester);
    final first = await tester.startGesture(left, pointer: 1);
    expect(signals.last, -1);
    final second = await tester.startGesture(right, pointer: 2);
    expect(signals.last, -1, reason: 'the second finger took over');
    await second.up();
    expect(signals.last, -1, reason: 'lifting the second finger recentred');
    await first.up();
    expect(signals.last, 0);
  });

  testWidgets('a cancelled touch recentres rather than sticking', (
    tester,
  ) async {
    final signals = await pumpSteering(tester);
    final g = await tester.startGesture(right);
    expect(signals.last, 1);
    await g.cancel();
    expect(signals.last, 0);
  });

  group('thumb pad', () {
    Future<List<double>> pumpPad(WidgetTester tester) async {
      final signals = <double>[];
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (_, _) => Align(
            alignment: Alignment.topLeft,
            child: DashSteeringPad(onSteer: signals.add),
          ),
        ),
      );
      return signals;
    }

    testWidgets('gives lock in proportion to how far it is slid', (
      tester,
    ) async {
      final signals = await pumpPad(tester);
      final g = await tester.startGesture(const Offset(80, 40));
      await g.moveBy(const Offset(DashSteeringPad.travel / 2, 0));
      expect(signals.last, closeTo(0.5, 0.01));
      await g.moveBy(const Offset(DashSteeringPad.travel * 3, 0));
      expect(signals.last, 1, reason: 'lock must be clamped at full');
      await g.moveTo(const Offset(80 - DashSteeringPad.travel * 2, 40));
      expect(signals.last, -1);
      await g.up();
      expect(signals.last, 0);
    });

    testWidgets('is anchored where the thumb lands, not at the centre', (
      tester,
    ) async {
      final signals = await pumpPad(tester);
      final g = await tester.startGesture(const Offset(150, 40));
      await g.moveBy(const Offset(1, 0));
      expect(signals.last.abs(), lessThan(0.05));
      await g.up();
    });
  });
}
