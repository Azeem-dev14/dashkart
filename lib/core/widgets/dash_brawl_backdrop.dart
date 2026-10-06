import 'package:flutter/widgets.dart';

/// Exact replica of the Brawl Stars vibrant electric cyan-to-blue lobby background
/// sampled directly from the authentic in-game reference.
///
/// Features:
/// * Radiant electric-cyan core (#3CF0FF) centered behind the hero character/kart
/// * Smooth multi-stop transition through vibrant azure (#04C4FF) to rich oceanic royal blue (#005FD2)
/// * Pure, clean gradient backdrop with no overlaid decals
class BrawlLobbyBackdrop extends StatelessWidget {
  const BrawlLobbyBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.15),
          radius: 1.18,
          colors: [
            Color(0xFF3CF0FF), // Radiant turquoise cyan core
            Color(0xFF20E2FF), // Vivid electric cyan
            Color(0xFF04C4FF), // Saturated bright azure
            Color(0xFF02A2FF), // Classic vibrant Brawl blue
            Color(0xFF007DF5), // Royal blue mid tone
            Color(0xFF005FD2), // Saturated oceanic blue perimeter
          ],
          stops: [0.0, 0.18, 0.38, 0.62, 0.82, 1.0],
        ),
      ),
    );
  }
}
