import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_icon.dart';

enum DashChipTone { neutral, success, warning, danger, locked, brand }

/// Small pill for difficulty, environment, lock state, and rarity.
class DashChip extends StatelessWidget {
  const DashChip({
    super.key,
    required this.label,
    this.tone = DashChipTone.neutral,
    this.icon,
  });

  final String label;
  final DashChipTone tone;
  final DashIcons? icon;

  (Color bg, Color fg) get _colors => switch (tone) {
    DashChipTone.neutral => (
      DashColors.surfaceSunken,
      DashColors.textSecondary,
    ),
    DashChipTone.success => (
      DashColors.neonGreen.withValues(alpha: 0.18),
      DashColors.neonGreen,
    ),
    DashChipTone.warning => (
      DashColors.yellow.s500.withValues(alpha: 0.18),
      DashColors.yellow.s400,
    ),
    DashChipTone.danger => (
      DashColors.racingRed.withValues(alpha: 0.18),
      DashColors.racingRed,
    ),
    DashChipTone.locked => (DashColors.surfaceSunken, DashColors.textTertiary),
    DashChipTone.brand => (
      DashColors.blue.s500.withValues(alpha: 0.22),
      DashColors.blue.s300,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    final glyph = icon ?? (tone == DashChipTone.locked ? DashIcons.lock : null);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: DashRadius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            DashIcon(glyph, size: DashIconSize.xs, color: fg),
            const SizedBox(width: 5),
          ],
          Text(label.toUpperCase(), style: DashType.label.copyWith(color: fg)),
        ],
      ),
    );
  }
}
