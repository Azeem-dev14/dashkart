import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/dash_colors.dart';

/// DashKart's typography tokens, powered uniformly by [Lilita One] — the chunky,
/// energetic arcade typeface used across the entire application and lobby UI.
///
/// Every brand heading, UI button, label, dialog, and numeric readout inherits
/// [fontFamily: 'LilitaOne'] to give the app a unified Brawl Stars arcade character.
abstract final class DashType {
  /// The primary font family used across the entire application.
  static const font = 'LilitaOne';
  static const _font = 'LilitaOne';

  // --- Brand -------------------------------------------------------------
  static const brandXL = TextStyle(
    fontFamily: _font,
    fontSize: 64,
    height: 1.0,
    letterSpacing: 2,
    color: DashColors.textPrimary,
  );

  static const brandL = TextStyle(
    fontFamily: _font,
    fontSize: 44,
    height: 46 / 44,
    letterSpacing: 1,
    color: DashColors.textPrimary,
  );

  static const countdown = TextStyle(
    fontFamily: _font,
    fontSize: 160,
    height: 1.0,
    color: DashColors.textPrimary,
  );

  static const position = TextStyle(
    fontFamily: _font,
    fontSize: 52,
    height: 1.0,
    color: DashColors.textPrimary,
  );

  // --- UI ----------------------------------------------------------------
  static const h1 = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    height: 38 / 32,
    color: DashColors.textPrimary,
  );

  static const h2 = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    height: 30 / 24,
    color: DashColors.textPrimary,
  );

  static const h3 = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    height: 26 / 20,
    letterSpacing: 0.2,
    color: DashColors.textPrimary,
  );

  static const button = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    height: 24 / 20,
    letterSpacing: 0.6,
    color: DashColors.textOnBrand,
  );

  static const buttonSm = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0.4,
    color: DashColors.textOnBrand,
  );

  static const body = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    height: 24 / 16,
    color: DashColors.textSecondary,
  );

  static const bodySm = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    height: 20 / 14,
    color: DashColors.textSecondary,
  );

  /// Uppercase stat and section labels.
  static const label = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.8,
    color: DashColors.textTertiary,
  );

  // --- Numeric -----------------------------------------------------------
  static const speed = TextStyle(
    fontFamily: _font,
    fontSize: 44,
    height: 1.0,
    letterSpacing: -1,
    color: DashColors.textPrimary,
  );

  static const speedUnit = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    height: 16 / 14,
    letterSpacing: 1.5,
    color: DashColors.textSecondary,
  );

  static const lap = TextStyle(
    fontFamily: _font,
    fontSize: 26,
    height: 30 / 26,
    letterSpacing: 0.5,
    color: DashColors.textPrimary,
  );

  static const timer = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    height: 26 / 22,
    letterSpacing: 0.5,
    color: DashColors.textPrimary,
  );

  static const statValue = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    height: 22 / 18,
    color: DashColors.textPrimary,
  );
}
