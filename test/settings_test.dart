import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashkart/core/widgets/dash_dialog.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/features/settings/settings_screen.dart';

void main() {
  test('camera shake is off by default', () {
    SharedPreferences.setMockInitialValues({});
    expect(GameSettings().cameraShake, isFalse);
  });

  test('an old saved "shake on" does not keep it on', () async {
    // Shake used to default on, so anyone who had opened Settings has this
    // stored. It must not carry over now that the default is off.
    SharedPreferences.setMockInitialValues({
      'dashkart_settings_cam_shake': true,
    });
    final settings = GameSettings();
    await settings.load();
    expect(settings.cameraShake, isFalse);
  });

  test('turning it on is remembered', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = GameSettings();
    settings.update(() => settings.cameraShake = true);
    await settings.save();
    final loaded = GameSettings();
    await loaded.load();
    expect(loaded.cameraShake, isTrue);
  });

  test('steering and graphics survive a round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = GameSettings();
    settings.steering = SteeringMode.analog;
    settings.graphics = GraphicsTier.high;
    settings.steeringSensitivity = 0.3;
    await settings.save();
    final loaded = GameSettings();
    await loaded.load();
    expect(loaded.steering, SteeringMode.analog);
    expect(loaded.graphics, GraphicsTier.high);
    expect(loaded.steeringSensitivity, closeTo(0.3, 1e-9));
  });

  test('an out-of-range stored enum falls back instead of throwing', () async {
    SharedPreferences.setMockInitialValues({
      'dashkart_settings_graphics': 99,
      'dashkart_settings_steering_mode': -1,
      'dashkart_settings_music_vol': 0.2,
    });
    final settings = GameSettings();
    await settings.load();
    expect(settings.graphics, GraphicsTier.medium);
    expect(settings.steering, SteeringMode.buttons);
    // …and one bad value must not cost the others.
    expect(settings.musicVolume, closeTo(0.2, 1e-9));
  });

  testWidgets('Settings account section displays RESET GAME and resets onboarding',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'dashkart_player_name': 'Tester',
      'dashkart_player_trophies': 10,
      'dashkart_player_onboarded': true,
    });
    final player = PlayerState();
    await player.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerProvider.overrideWith((ref) => player),
        ],
        child: WidgetsApp(
          color: const Color(0xFF000000),
          home: const SettingsScreen(),
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the ACCOUNT tab
    await tester.tap(find.text('ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('RESET PROGRESS'), findsOneWidget);
    expect(find.text('RESET GAME'), findsOneWidget);

    // Tap RESET GAME
    await tester.tap(find.text('RESET GAME'));
    await tester.pumpAndSettle();

    // Confirm dialog should be shown
    expect(find.text('Reset game?'), findsOneWidget);

    // Confirm the reset by tapping the confirm button inside the dialog
    final confirmBtn = find.descendant(
      of: find.byType(DashDialog),
      matching: find.text('RESET GAME'),
    );
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(player.needsOnboarding, isTrue);
    expect(player.name, 'Dash');
    expect(player.trophies, 0);
  });
}
