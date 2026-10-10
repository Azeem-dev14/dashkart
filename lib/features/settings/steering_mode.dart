/// How the player steers.
///
/// This replaces a `tiltSteering` flag that was persisted, offered as a
/// choice, and never read by anything — the game has no accelerometer input
/// at all, so picking "Tilt" changed nothing about how the kart drove. Both
/// modes here are real, and both feed the same -1..1 signal the race
/// controller already took, so nothing downstream knows which one is in use.
///
/// Lives in its own file rather than beside the settings screen so the HUD
/// can read it without a core widget depending on a feature screen.
enum SteeringMode {
  /// Two held direction buttons. Precise, instantly readable, and what the
  /// Kenney control art was drawn for.
  buttons('Buttons'),

  /// A thumb pad: press anywhere on it and slide. Gives proportional lock
  /// rather than all-or-nothing, which is what makes a long sweeping bend
  /// holdable instead of a series of corrections.
  analog('Thumb pad');

  const SteeringMode(this.label);

  final String label;
}
