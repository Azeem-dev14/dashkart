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
  menu('icon_menu'),
  settings('icon_cog'),
  wrench('icon_wrench'),
  checkmark('icon_checkmark'),
  close('icon_cross'),

  // Transport
  play('icon_play'),
  pause('icon_pause'),
  restart('icon_arrow_rotate'),

  // Audio
  sound('icon_sound'),
  soundOff('icon_sound_disabled'),
  music('icon_music'),
  musicOff('icon_music_disabled'),

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
  map('icon_map'),
  position('icon_position'),
  vibration('icon_vibration'),

  // Driving
  steeringWheel('icon_steering_wheel'),
  pedal('icon_pedal'),
  pedalBrake('icon_pedal_brake'),
  boost('icon_fire'),
  burst('icon_burst'),
  shield('icon_shield'),
  target('icon_target');

  const DashIcons(this._file);

  final String _file;

  String get path => 'assets/images/ui/icons/$_file.svg';

  /// Gap-fill icons that live in raster PNG form instead of SVG.
  bool get isRaster => switch (this) {
    speed || acceleration || handling || drift || weight => true,
    _ => false,
  };

  String get rasterPath => 'assets/images/ui/icons-raster/$_file.png';
}

/// The gap-fill raster icon set sourced from Kenney's Game Icons.
enum DashRasterIcons {
  trophy('trophy'),
  info('information'),
  home('home'),
  leaderboard('leaderboardsSimple'),
  locked('locked'),
  unlocked('unlocked'),
  medal1('medal1'),
  medal2('medal2');

  const DashRasterIcons(this._file);

  final String _file;

  String get path => 'assets/images/ui/icons-raster/$_file.png';
}
