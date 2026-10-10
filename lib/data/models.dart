import 'dart:ui';

import 'package:dashkart/core/theme/theme.dart';

/// The five tuning axes. Each drives both the UI bar and a physics parameter,
/// so a card and the kart it describes cannot drift apart.
enum KartStat {
  speed('Speed', DashIcons.speed),
  acceleration('Acceleration', DashIcons.acceleration),
  handling('Handling', DashIcons.handling),
  drift('Drift', DashIcons.drift),
  weight('Weight', DashIcons.weight);

  const KartStat(this.label, this.icon);

  final String label;
  final DashIcons icon;
}

/// How a piece of content is earned.
sealed class UnlockRule {
  const UnlockRule();

  String get label;
}

class Starter extends UnlockRule {
  const Starter();

  @override
  String get label => 'Starter';
}

class TrophyCount extends UnlockRule {
  const TrophyCount(this.trophies);

  final int trophies;

  @override
  String get label => '$trophies trophies';
}

class Kart {
  const Kart({
    required this.id,
    required this.name,
    required this.tagline,
    required this.model,
    required this.stats,
    required this.unlock,
    this.livery,
  });

  final String id;
  final String name;
  final String tagline;

  /// Basename of the GLB under assets/models/karts/.
  final String model;
  final Map<KartStat, int> stats;
  final UnlockRule unlock;

  /// Base-colour tint applied to the kart's real material, multiplying its
  /// texture like a livery recolour. Null renders the model's own colours.
  final Color? livery;

  String get modelPath => 'assets/models/karts/$model.glb';

  int stat(KartStat s) => stats[s] ?? 0;
}

enum TrackDifficulty {
  easy('Easy', 1),
  medium('Medium', 2),
  hard('Hard', 3);

  const TrackDifficulty(this.label, this.chevrons);

  final String label;
  final int chevrons;
}

class Track {
  const Track({
    required this.id,
    required this.index,
    required this.name,
    required this.environment,
    required this.difficulty,
    required this.laps,
    required this.unlock,
  });

  final String id;

  /// In-game running order, shown as 01..05.
  final int index;
  final String name;
  final String environment;
  final TrackDifficulty difficulty;
  final int laps;
  final UnlockRule unlock;

  String get number => index.toString().padLeft(2, '0');
}

/// Whether the player is holding a turbo to fire. The turbo is the only item
/// in the game: it is picked up on the road and fired from the TURBO button,
/// so the state is just held or not.
enum ItemSlotState { empty, ready }
