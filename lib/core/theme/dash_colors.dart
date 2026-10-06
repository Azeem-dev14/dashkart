import 'package:flutter/widgets.dart';

/// DashKart colour tokens.
///
/// Saturated party-arcade hues on a deep violet/navy ground,
/// cut out with ink outlines.
///
/// Each brand colour is a ten-step ramp so gradients, bevels, and pressed
/// states stay in-family instead of being ad-hoc opacity calls on a single hex.
class DashRamp {
  const DashRamp({
    required this.s50,
    required this.s100,
    required this.s200,
    required this.s300,
    required this.s400,
    required this.s500,
    required this.s600,
    required this.s700,
    required this.s800,
    required this.s900,
  });

  final Color s50, s100, s200, s300, s400, s500, s600, s700, s800, s900;

  /// The brand value.
  Color get base => s500;
}

abstract final class DashColors {
  // --- Brand ramps ---------------------------------------------------------

  /// DashKart Blue — primary. Buttons, selection, brand.
  static const blue = DashRamp(
    s50: Color(0xFFEAF1FE),
    s100: Color(0xFFD0E0FD),
    s200: Color(0xFFA3C2FB),
    s300: Color(0xFF6E9DF8),
    s400: Color(0xFF4482F6),
    s500: Color(0xFF2A6DF4),
    s600: Color(0xFF1B55D1),
    s700: Color(0xFF1341A3),
    s800: Color(0xFF0D2E75),
    s900: Color(0xFF081C47),
  );

  /// The house colour. Everything primary is violet.
  static const purple = DashRamp(
    s50: Color(0xFFF3EAFF),
    s100: Color(0xFFE2CCFF),
    s200: Color(0xFFC9A3FF),
    s300: Color(0xFFAE78FF),
    s400: Color(0xFF9954FF),
    s500: Color(0xFF7E30E0),
    s600: Color(0xFF6821C2),
    s700: Color(0xFF5317A0),
    s800: Color(0xFF3F107D),
    s900: Color(0xFF2B0959),
  );

  /// Turbo / boost / speed.
  static const orange = DashRamp(
    s50: Color(0xFFFFF2E8),
    s100: Color(0xFFFFE0C7),
    s200: Color(0xFFFFC291),
    s300: Color(0xFFFFA35B),
    s400: Color(0xFFFF8C33),
    s500: Color(0xFFFF7A18),
    s600: Color(0xFFE05F00),
    s700: Color(0xFFB24A00),
    s800: Color(0xFF843700),
    s900: Color(0xFF562400),
  );

  /// Highlights, coins, stars, countdown.
  static const yellow = DashRamp(
    s50: Color(0xFFFFFAE6),
    s100: Color(0xFFFFF2BF),
    s200: Color(0xFFFFE785),
    s300: Color(0xFFFFDC5C),
    s400: Color(0xFFFFD53F),
    s500: Color(0xFFFFC61A),
    s600: Color(0xFFDBA400),
    s700: Color(0xFFA87E00),
    s800: Color(0xFF755800),
    s900: Color(0xFF423200),
  );

  /// Success, 1st place, affirmative actions.
  static const green = DashRamp(
    s50: Color(0xFFE8FAF0),
    s100: Color(0xFFC6F4D8),
    s200: Color(0xFF92E8B6),
    s300: Color(0xFF5CDC93),
    s400: Color(0xFF32CF77),
    s500: Color(0xFF22E06B),
    s600: Color(0xFF16B552),
    s700: Color(0xFF0F8C3E),
    s800: Color(0xFF0A632C),
    s900: Color(0xFF063B1A),
  );

  /// Danger, brake, locked, 8th place.
  static const red = DashRamp(
    s50: Color(0xFFFFEAEF),
    s100: Color(0xFFFFCCD7),
    s200: Color(0xFFFF99AF),
    s300: Color(0xFFFF6687),
    s400: Color(0xFFFF3D65),
    s500: Color(0xFFFF3355),
    s600: Color(0xFFD61839),
    s700: Color(0xFFA30D27),
    s800: Color(0xFF70081A),
    s900: Color(0xFF3D030C),
  );

  // --- Supporting -----------------------------------------------------------
  static const neonGreen = Color(0xFF22E06B);
  static const racingRed = Color(0xFFFF3355);
  static const skyBlue = Color(0xFF46C8FF);
  static const cyan = Color(0xFF26D6FE);
  static const gold = Color(0xFFFFD53F);
  static const darkNavy = Color(0xFF0B1130);

  // --- Surfaces (dark) ------------------------------------------------------
  static const bgBase = Color(0xFF0B1130);
  static const bgGradientTop = Color(0xFF16205A);
  static const bgGradientBottom = Color(0xFF080D22);

  static const surface = Color(0xFF151D45);
  static const surfaceRaised = Color(0xFF1E2A5C);
  static const surfaceSunken = Color(0xFF0A0F28);

  static const stroke = Color(0xFF2E3B72);
  static const strokeStrong = Color(0xFF4557A8);
  static const ink = Color(0xFF0A0A14);
  static const scrim = Color(0xB8050814); // 72%

  /// Flat cartoon-ink black — the outline/fill colour the Brawl-Stars-style
  /// icon painters and card chrome use everywhere (`DashBrawlRailButton`,
  /// `DashKartCard`'s selection ring, etc). Deliberately its own token
  /// rather than [ink]: that's a near-black (`0xFF0A0A14`) for the original
  /// design system, this is pure `0xFF000000`, and the two aren't
  /// interchangeable — this one was previously ~66 separate literals.
  static const pureBlack = Color(0xFF000000);

  // --- Surfaces (light) -----------------------------------------------------
  static const bgBaseLight = Color(0xFFF4F7FF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceRaisedLight = Color(0xFFFFFFFF);
  static const strokeLight = Color(0xFFD8E1F5);

  // --- Text -----------------------------------------------------------------
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB7C3E8);
  static const textTertiary = Color(0xFF7382B8);
  static const textOnBrand = Color(0xFFFFFFFF);
  static const textOnAccent = Color(0xFF3B2A00);

  // --- Brawl Stars Lobby Theme ----------------------------------------------
  static const brawlRadialInner = Color(0xFF28D9FF);
  static const brawlRadialMid1 = Color(0xFF14BEFF);
  static const brawlRadialMid2 = Color(0xFF039AF8);
  static const brawlRadialMid3 = Color(0xFF0072DF);
  static const brawlRadialOuter = Color(0xFF004DAA);
}

abstract final class DashGradients {
  /// RACE button, boost meter.
  static const turbo = [
    Color(0xFFFFC61A),
    Color(0xFFFF7A18),
    Color(0xFFE05F00),
  ];

  /// Primary buttons, headers.
  static const speed = [
    Color(0xFF9954FF),
    Color(0xFF7E30E0),
    Color(0xFF5317A0),
  ];

  /// 1st place, trophies, victory.
  static const victory = [Color(0xFFFFD53F), Color(0xFFFF8C33)];

  /// Menu backdrop fallback.
  static const menuSky = [
    Color(0xFF16205A),
    Color(0xFF0B1130),
    Color(0xFF080D22),
  ];

  /// Shield Orb effects.
  static const shield = [Color(0xFF46C8FF), Color(0xFF2A6DF4)];

  /// Brawl Stars Lobby Blue-to-Cyan Radiant Gradient.
  static const brawlLobby = [
    DashColors.brawlRadialInner,
    DashColors.brawlRadialMid1,
    DashColors.brawlRadialMid2,
    DashColors.brawlRadialMid3,
    DashColors.brawlRadialOuter,
  ];
}

/// Fallback full-screen backdrop decoration.
const dashMenuBackdrop = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: DashGradients.menuSky,
  ),
);

/// Scrim gradients and text shadows for HUD legibility over 3D scenes.
abstract final class DashScrim {
  static const topHeight = 88.0;
  static const bottomHeight = 120.0;

  static const top = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x73000000), Color(0x00000000)],
  );

  static const bottom = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0x59000000), Color(0x00000000)],
  );

  static const textShadow = [
    Shadow(color: Color(0xBF000000), offset: Offset(0, 2), blurRadius: 6),
  ];
}
