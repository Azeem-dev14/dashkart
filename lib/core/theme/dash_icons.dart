/// The DashKart icon set.
///
/// One family, deliberately: Kenney's Mobile Controls icons are the only CC0
/// set carrying the *racing* metaphors (steering wheel, accelerator, brake), so
/// the whole set is built around them rather than mixing packs. A handful of
/// gaps are filled from Kenney's Game Icons — same author, same design
/// language — and the rest are drawn to match. See docs/assets.md § 7.
enum DashIcons {
  // Navigation and chrome
  back('icon_arrow'),
  settings('icon_cog'),
  checkmark('icon_checkmark'),

  // Transport
  play('icon_play'),
  pause('icon_pause'),
  restart('icon_arrow_rotate'),

  // Audio
  sound('icon_sound'),
  music('icon_music'),

  // Progression
  lock('icon_lock'),
  key('icon_key'),
  star('icon_star'),

  // Stats — drawn to match the Kenney grid, since no CC0 set carries these
  // metaphors. See docs/asset-inventory.md § CREATE.
  speed('icon_speed'),
  acceleration('icon_acceleration'),
  handling('icon_handling'),
  drift('icon_drift'),
  weight('icon_weight'),

  // Gameplay
  item('icon_item'),

  // Driving
  steeringWheel('icon_steering_wheel'),
  pedalBrake('icon_pedal_brake'),
  boost('icon_fire'),
  target('icon_target');

  const DashIcons(this._file);

  final String _file;

  String get path => 'assets/images/ui/icons/$_file.svg';
}

/// The gap-fill raster icon set sourced from Kenney's Game Icons.
enum DashRasterIcons {
  trophy('trophy'),
  info('information'),
  unlocked('unlocked');

  const DashRasterIcons(this._file);

  final String _file;

  String get path => 'assets/images/ui/icons-raster/$_file.png';
}
