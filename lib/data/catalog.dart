import 'package:dashkart/data/models.dart';

/// The DashKart content catalogue.
abstract final class Catalog {
  // --- Karts ---------------------------------------------------------------
  static const karts = <Kart>[
    Kart(
      id: 'dash',
      name: 'Dash',
      tagline: 'Flutter\'s mascot, kitted for the grid',
      model: 'dashkart',
      unlock: Starter(),
      stats: {
        KartStat.speed: 7,
        KartStat.acceleration: 7,
        KartStat.handling: 7,
        KartStat.drift: 6,
        KartStat.weight: 5,
      },
    ),
  ];

  // --- Racers --------------------------------------------------------------
  static const racers = <Racer>[
    Racer(
      id: 'dash',
      name: 'Classic Dash',
      personality: 'Eager rookie, all heart',
      model: 'character-male-a',
      signatureKartId: 'dash',
      bonus: (KartStat.acceleration, 1),
    ),
    Racer(
      id: 'cyber-dash',
      name: 'Cyber Dash',
      personality: 'Neon-charged speed demon',
      model: 'character-male-d',
      signatureKartId: 'dash',
      bonus: (KartStat.speed, 2),
      accessory: 'aid-sunglasses',
    ),
    Racer(
      id: 'astro-dash',
      name: 'Astro Dash',
      personality: 'Cosmic drifter from orbit',
      model: 'character-female-a',
      signatureKartId: 'dash',
      bonus: (KartStat.drift, 2),
      accessory: 'aid-glasses',
    ),
  ];

  // --- Levels --------------------------------------------------------------
  // Five circuits, easy to hard, each a distinct biome.
  static const tracks = <Track>[
    Track(
      id: 'dash-valley',
      index: 1,
      name: 'Dash Valley',
      environment: 'Grassland',
      difficulty: TrackDifficulty.easy,
      laps: 3,
      unlock: Starter(),
    ),
    Track(
      id: 'neon-circuit',
      index: 2,
      name: 'Neon Circuit',
      environment: 'Night city',
      difficulty: TrackDifficulty.easy,
      laps: 3,
      unlock: Starter(),
    ),
    Track(
      id: 'desert-rush',
      index: 3,
      name: 'Desert Rush',
      environment: 'Desert canyon',
      difficulty: TrackDifficulty.medium,
      laps: 3,
      unlock: TrophyCount(3),
    ),
    Track(
      id: 'frozen-peak',
      index: 4,
      name: 'Frozen Peak',
      environment: 'Snow and ice',
      difficulty: TrackDifficulty.hard,
      laps: 3,
      unlock: TrophyCount(6),
    ),
    Track(
      id: 'cyber-coast',
      index: 5,
      name: 'Cyber Coast',
      environment: 'Coastal city',
      difficulty: TrackDifficulty.hard,
      laps: 4,
      unlock: TrophyCount(10),
    ),
  ];

  static Kart kartById(String id) => karts.firstWhere((k) => k.id == id);

  static Racer racerById(String id) => racers.firstWhere((r) => r.id == id);

  static Track trackById(String id) => tracks.firstWhere((t) => t.id == id);
}
