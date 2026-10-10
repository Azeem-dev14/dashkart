import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
