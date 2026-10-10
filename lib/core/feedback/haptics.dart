import 'package:flutter/services.dart';

/// The one gate every haptic in the game passes through.
///
/// The vibration setting used to be persisted and then ignored: five call
/// sites across the controls, the race controller and the pressable base
/// class called `HapticFeedback` directly, so turning vibration off changed
/// nothing. Routing them all through here means a new control cannot forget
/// to honour it — there is no other way to buzz the device.
///
/// A plain static rather than a provider: haptics are fired from physics
/// callbacks and gesture handlers that have no `BuildContext` and no `ref`,
/// and the value is a single bool the settings own.
abstract final class Haptics {
  /// Set from `gameSettingsProvider` whenever the vibration setting changes,
  /// and on load.
  static bool enabled = true;

  /// A control was pressed, an item collected — the common, light tick.
  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// An impact, a boost firing — something that happened *to* the kart.
  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
