import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashkart/core/scaffold/dash_ui_scale.dart';
import 'package:dashkart/features/multiplayer/multiplayer_screen.dart';
import 'package:dashkart/features/multiplayer/multiplayer_service.dart';
import 'package:dashkart/features/race/scene/scene3d.dart';

/// The multiplayer flow was missing from the layout suite entirely, and had
/// quietly stayed in the old flat style — a pale description straight on the
/// backdrop and a navy ghost button — while every other screen moved on.
/// These lay out every state of it at every size the game supports.
const _sizes = <String, Size>{
  'compact-android 640x360': Size(640, 360),
  'iPhone SE 667x375': Size(667, 375),
  'phone 844x390': Size(844, 390),
  'large phone 932x430': Size(932, 430),
  'iPad 1024x768': Size(1024, 768),
};

void noop() {}

Widget _app(Widget home) => ProviderScope(
  child: WidgetsApp(
    color: const Color(0xFF000000),
    builder: (context, child) => DashUiScale(child: child!),
    home: home,
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
  ),
);

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    Scene3D.availableOverride = false;
  });

  for (final entry in _sizes.entries) {
    Future<void> size(WidgetTester tester) async {
      tester.view.physicalSize = entry.value * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('choose @ ${entry.key}', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        _app(MultiplayerScreen(onBack: noop, onSessionReady: (_) {})),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('HOST A RACE'), findsOneWidget);
      expect(find.text('JOIN A RACE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('join code @ ${entry.key}', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        _app(MultiplayerScreen(onBack: noop, onSessionReady: (_) {})),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('JOIN A RACE'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('ENTER THE ROOM CODE'), findsWidgets);
      expect(find.text('BACK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final (label, isHost, meReady, opponent) in [
      ('host, alone', true, true, const RacerTelemetry()),
      (
        'host, guest ready',
        true,
        true,
        const RacerTelemetry(name: 'Nitro', ready: true),
      ),
      (
        'guest, not ready',
        false,
        false,
        const RacerTelemetry(name: 'A very long player name indeed'),
      ),
      (
        'guest, ready',
        false,
        true,
        const RacerTelemetry(name: 'Host', ready: true),
      ),
    ]) {
      testWidgets('lobby ($label) @ ${entry.key}', (tester) async {
        await size(tester);
        await tester.pumpWidget(
          _app(
            MultiplayerLobby(
              roomCode: 'K7Q2X',
              isHost: isHost,
              myName: 'Azeem',
              meReady: meReady,
              opponent: opponent,
              onReady: noop,
              onStart: noop,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('K7Q2X'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('only a ready guest lets the host start', (tester) async {
    tester.view.physicalSize = const Size(1688, 780);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    var started = false;

    Future<void> pump(RacerTelemetry opponent) async {
      await tester.pumpWidget(
        _app(
          MultiplayerLobby(
            roomCode: 'K7Q2X',
            isHost: true,
            myName: 'Azeem',
            meReady: true,
            opponent: opponent,
            onReady: noop,
            onStart: () => started = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
    }

    await pump(const RacerTelemetry());
    await tester.tap(find.text('WAITING FOR GUEST…'));
    expect(started, isFalse);

    await pump(const RacerTelemetry(name: 'Nitro'));
    await tester.tap(find.text('WAITING FOR GUEST…'));
    expect(started, isFalse, reason: 'joined but not ready');

    await pump(const RacerTelemetry(name: 'Nitro', ready: true));
    await tester.tap(find.text('START RACE'));
    expect(started, isTrue);
  });
}
