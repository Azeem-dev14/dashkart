import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/core/audio/audio_manager.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/features/race/scene/kart_viewer.dart';
import 'package:dashkart/core/widgets/components.dart';

/// The hub.
///
/// A party-game lobby, not a list of menu entries: the player's kart is the
/// hero of the screen, feature tiles run down a rail on the left, wallet and
/// settings sit top-right, and one oversized PLAY button owns the bottom-right
/// corner. Landscape-only, which is what lets the rails and the stage coexist.
class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({
    super.key,
    required this.onRace,
    required this.onKarts,
    required this.onTracks,
    required this.onSettings,
    required this.onShop,
  });

  final VoidCallback onRace;
  final VoidCallback onKarts;

  final VoidCallback onTracks;
  final VoidCallback onSettings;
  final VoidCallback onShop;

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  /// Drives the ambient backdrop only. Kept separate from entrance animation so
  /// it can keep running without re-triggering the stagger.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void initState() {
    super.initState();
    AudioManager.instance.playMenuMusic();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bp = DashBreakpoint.of(context);
    final player = ref.watch(playerProvider);
    final compact = bp.isCompact;

    // Snug arcade edge margins matching Brawl Stars landscape UI: ~42dp
    // clearance for a notch/Dynamic Island on whichever side it appears, a
    // tight ~10-14dp margin from the curved glass on clear sides.
    final margins = DashSafeMargins.of(
      context,
      sideCompact: 10.0,
      sideRegular: 14.0,
    );
    final leftMargin = margins.left;
    final rightMargin = margins.right;
    final topMargin = margins.top;
    final bottomMargin = margins.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Brawl Stars lobby background: vibrant cyan-to-blue radial gradient
        const BrawlLobbyBackdrop(),
        Padding(
          padding: EdgeInsets.only(
            left: leftMargin,
            right: rightMargin,
            top: topMargin,
            bottom: bottomMargin,
          ),
          child: Stack(
            children: [
              // --- centre: the kart on its stage ------------------------
              Positioned.fill(
                child: Padding(
                  // Clear of both rails so the kart is never overlapped.
                  padding: EdgeInsets.symmetric(horizontal: compact ? 72 : 100),
                  child: _KartStage(kart: player.kart, compact: compact),
                ),
              ),

              // --- top-left: Brawl Stars profile badge ------------------
              Positioned(
                left: 0,
                top: 0,
                child: DashEnter(
                  index: 0,
                  offset: -24,
                  child: DashBrawlProfileBadge(
                    name: player.name.toUpperCase(),
                    compact: compact,
                  ),
                ),
              ),

              // --- top-right: Brawl Stars replica menu / settings button -
              Positioned(
                right: 0,
                top: 0,
                child: DashEnter(
                  index: 1,
                  offset: 24,
                  child: DashBrawlSettingsButton(
                    compact: compact,
                    onPressed: widget.onSettings,
                  ),
                ),
              ),

              // --- left rail: Brawl Stars replica feature buttons -------
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DashEnter(
                        index: 2,
                        offset: -24,
                        child: DashBrawlRailButton(
                          label: 'Karts',
                          type: BrawlRailButtonType.karts,
                          onPressed: widget.onKarts,
                          compact: compact,
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      DashEnter(
                        index: 3,
                        offset: -24,
                        child: DashBrawlRailButton(
                          label: 'Tracks',
                          type: BrawlRailButtonType.tracks,
                          onPressed: widget.onTracks,
                          compact: compact,
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      DashEnter(
                        index: 4,
                        offset: -24,
                        child: DashBrawlRailButton(
                          label: 'Shop',
                          type: BrawlRailButtonType.shop,
                          onPressed: widget.onShop,
                          compact: compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- bottom-right: the one hero action --------------------
              Positioned(
                right: 0,
                bottom: 0,
                child: DashEnter(
                  index: 7,
                  offset: 32,
                  child: _PlayButton(
                    onPressed: widget.onRace,
                    compact: compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The one hero action, styled after the iconic Brawl Stars action button.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed, required this.compact});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DashRaceButton(
      label: 'PLAY',
      onPressed: onPressed,
      compact: compact,
      glow: true,
    );
  }
}

/// The centre of the screen: the player's kart, lit on a round stage.
/// The live 3D model when Flutter GPU is up, a painted silhouette in its
/// livery colour otherwise.
class _KartStage extends StatelessWidget {
  const _KartStage({required this.kart, required this.compact});

  final Kart kart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DashGroundShadow(widthFraction: 0.70),
        KartViewer(
          modelPath: kart.modelPath,
          tint: kart.livery,
          spin: true,
          // A slow, unhurried turn: the menu is somewhere to rest, and the
          // kart is the backdrop rather than the thing being inspected.
          spinPeriod: const Duration(seconds: 20),
          cameraTargetY: 0.725,
          cameraEyeY: 0.88,
        ),
      ],
    );
  }
}
