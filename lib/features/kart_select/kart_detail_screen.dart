import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/features/race/scene/kart_viewer.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';

/// One kart's full detail view: 3D turntable, stats, lore, and the
/// SELECT/NEXT confirm action. Reached by tapping a card on
/// [KartSelectScreen]'s grid — this screen always shows exactly the one
/// [kart] it was opened for, so it carries none of that screen's roster
/// browsing state.
class KartDetailScreen extends ConsumerWidget {
  const KartDetailScreen({
    super.key,
    required this.kart,
    this.onBack,
    this.onConfirm,
  });

  final Kart kart;
  final VoidCallback? onBack;
  final VoidCallback? onConfirm;

  static String _kartClass(Kart kart) => 'ALL-ROUNDER';

  static String _kartTagline(Kart kart, bool unlocked) {
    if (!unlocked) return 'LOCKED • ${kart.unlock.label.toUpperCase()}';
    return 'STARTING KART';
  }

  // Dash is the only kart in the roster (see Catalog.karts), so this is a
  // constant rather than a per-kart switch.
  static String _kartDescription(Kart kart) =>
      'Flutter\'s legendary mascot, kitted out for the grid. Balanced '
      'acceleration and top handling make Dash reliable on every track!';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final compact = DashBreakpoint.of(context).isCompact;
    final isEquipped = kart.id == player.kart.id;
    final isUnlocked = player.isKartUnlocked(kart);

    final margins = DashSafeMargins.of(context);
    final leftMargin = margins.left;
    final rightMargin = margins.right;
    final topMargin = margins.top;
    final bottomMargin = margins.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: BrawlLobbyBackdrop()),

        // Centre stage: 3D kart turntable + ground shadow.
        Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 0.45),
                    radius: 0.70,
                    colors: [
                      (kart.livery ?? DashColors.cyan).withValues(alpha: 0.28),
                      const Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
            const DashGroundShadow(widthFraction: 0.52),
            KartViewer(
              key: ValueKey(kart.id),
              modelPath: kart.modelPath,
              tint: kart.livery,
              spin: true,
              cameraTargetY: 0.725,
              cameraEyeY: 0.88,
            ),
          ],
        ),

        // Left column: name plaque, tagline, description aligned to bottom left.
        Positioned(
          left: leftMargin,
          bottom: bottomMargin,
          width: compact ? 218.0 : 252.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrawlNamePlaque(
                name: kart.name.toUpperCase(),
                subtitle: _kartClass(kart),
                compact: compact,
              ),
              const SizedBox(height: 3.0),
              _BrawlCyanTagline(
                tagline: _kartTagline(kart, isUnlocked),
                compact: compact,
              ),
              const SizedBox(height: 6.0),
              Text(
                _kartDescription(kart),
                style: TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: compact ? 11.0 : 12.5,
                  height: 1.25,
                  color: DashColors.textPrimary,
                  shadows: const [
                    Shadow(
                      color: DashColors.pureBlack,
                      offset: Offset(1.2, 1.2),
                      blurRadius: 0,
                    ),
                    Shadow(
                      color: DashColors.pureBlack,
                      offset: Offset(-1.2, 1.2),
                      blurRadius: 0,
                    ),
                    Shadow(
                      color: DashColors.pureBlack,
                      offset: Offset(0, 2.0),
                      blurRadius: 1.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom-right action button — same spot and same default size as
        // PLAY on the main menu, so every hero action in the app feels like
        // one template rather than a different placement per screen.
        Positioned(
          right: rightMargin,
          bottom: bottomMargin,
          child: DashRaceButton(
            label: isEquipped ? 'NEXT' : (isUnlocked ? 'SELECT' : 'LOCKED'),
            compact: compact,
            glow: isUnlocked,
            enabled: isUnlocked,
            onPressed: () {
              if (!isUnlocked) return;
              if (!isEquipped) {
                player.selectKart(kart);
              } else {
                onConfirm?.call();
              }
            },
          ),
        ),

        // Right column: power level header + stat bars.
        Positioned(
          right: rightMargin,
          top: topMargin + (compact ? 44.0 : 50.0),
          bottom: bottomMargin,
          width: compact ? 180.0 : 212.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BrawlPowerHeader(compact: compact),
              const SizedBox(height: 8.0),
              _BrawlStatsContainer(kart: kart, compact: compact),
            ],
          ),
        ),

        // Top bar: back on the left, kart name centred with 3D block, home on the right.
        Positioned(
          top: topMargin,
          left: leftMargin,
          right: rightMargin,
          child: DashBrawlTopBar(
            title: kart.name.toUpperCase(),
            onBack: onBack,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

/// Slanted white name plaque matching Shelly's name banner in Brawl Stars.
class _BrawlNamePlaque extends StatelessWidget {
  const _BrawlNamePlaque({
    required this.name,
    required this.subtitle,
    required this.compact,
  });

  final String name;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.skewX(-0.10),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12.0 : 16.0,
          vertical: compact ? 4.0 : 6.0,
        ),
        decoration: BoxDecoration(
          color: DashColors.textPrimary,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: DashColors.pureBlack, width: 2.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              offset: Offset(0, 3.5),
              blurRadius: 4.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: compact ? 22.0 : 26.0,
                letterSpacing: 0.5,
                color: DashColors.textPrimary,
                shadows: const [
                  Shadow(
                    color: DashColors.pureBlack,
                    offset: Offset(2.0, 2.0),
                    blurRadius: 0,
                  ),
                  Shadow(
                    color: DashColors.pureBlack,
                    offset: Offset(-1.5, 1.5),
                    blurRadius: 0,
                  ),
                  Shadow(
                    color: DashColors.pureBlack,
                    offset: Offset(1.5, -1.5),
                    blurRadius: 0,
                  ),
                  Shadow(
                    color: DashColors.pureBlack,
                    offset: Offset(-1.5, -1.5),
                    blurRadius: 0,
                  ),
                  Shadow(
                    color: DashColors.pureBlack,
                    offset: Offset(0, 3.0),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: compact ? 11.0 : 12.5,
                letterSpacing: 0.3,
                color: const Color(0xFF1E2330),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slanted electric cyan tagline underneath the name banner.
class _BrawlCyanTagline extends StatelessWidget {
  const _BrawlCyanTagline({required this.tagline, required this.compact});

  final String tagline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.skewX(-0.10),
      alignment: Alignment.centerLeft,
      child: Text(
        tagline,
        style: TextStyle(
          fontFamily: 'LilitaOne',
          fontStyle: FontStyle.italic,
          fontSize: compact ? 11.5 : 13.0,
          letterSpacing: 0.4,
          color: const Color(0xFF3DF2FF),
          shadows: const [
            Shadow(
              color: DashColors.pureBlack,
              offset: Offset(1.5, 1.5),
              blurRadius: 0,
            ),
            Shadow(
              color: DashColors.pureBlack,
              offset: Offset(-1.5, 1.5),
              blurRadius: 0,
            ),
            Shadow(
              color: DashColors.pureBlack,
              offset: Offset(0, 2.0),
              blurRadius: 1.0,
            ),
          ],
        ),
      ),
    );
  }
}

/// Power level header banner replica above the stats container.
class _BrawlPowerHeader extends StatelessWidget {
  const _BrawlPowerHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.0 : 12.0,
        vertical: compact ? 3.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: DashColors.pureBlack,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'POWER LEVEL',
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: compact ? 11.0 : 13.0,
                letterSpacing: 0.5,
                color: DashColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6.0),
            Text(
              '1',
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: compact ? 13.0 : 15.0,
                color: const Color(0xFF3DF2FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brawl Stars styled stat bars container (Speed, Accel, Handling, Drift).
class _BrawlStatsContainer extends StatelessWidget {
  const _BrawlStatsContainer({required this.kart, required this.compact});

  final Kart kart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final speed = kart.stats[KartStat.speed] ?? 5;
    final accel = kart.stats[KartStat.acceleration] ?? 5;
    final handling = kart.stats[KartStat.handling] ?? 5;
    final drift = kart.stats[KartStat.drift] ?? 5;

    final speedSeg = (speed / 2.0).round().clamp(1, 5);
    final accelSeg = (accel / 2.0).round().clamp(1, 5);
    final handlingSeg = (handling / 2.0).round().clamp(1, 5);
    final driftSeg = (drift / 2.0).round().clamp(1, 5);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.0 : 12.0,
        vertical: compact ? 8.0 : 12.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC091833),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: DashColors.pureBlack, width: 2.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            offset: Offset(0, 4),
            blurRadius: 6.0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrawlStatRow(
            label: 'SPEED',
            icon: DashIcons.speed,
            filledSegments: speedSeg,
            badgeColor: const Color(0xFFFF2E56),
            barGradient: const [Color(0xFFFF3366), Color(0xFFD61838)],
            emptyColor: const Color(0xFF4A0A14),
            compact: compact,
          ),
          SizedBox(height: compact ? 6.0 : 8.0),
          _BrawlStatRow(
            label: 'ACCELERATION',
            icon: DashIcons.acceleration,
            filledSegments: accelSeg,
            badgeColor: const Color(0xFF00E65A),
            barGradient: const [Color(0xFF00E65A), Color(0xFF00A83A)],
            emptyColor: const Color(0xFF083815),
            compact: compact,
          ),
          SizedBox(height: compact ? 6.0 : 8.0),
          _BrawlStatRow(
            label: 'HANDLING',
            icon: DashIcons.handling,
            filledSegments: handlingSeg,
            badgeColor: const Color(0xFF0099FF),
            barGradient: const [Color(0xFF00A2FF), Color(0xFF0067DB)],
            emptyColor: const Color(0xFF081C40),
            compact: compact,
          ),
          SizedBox(height: compact ? 6.0 : 8.0),
          _BrawlStatRow(
            label: 'DRIFT',
            icon: DashIcons.drift,
            filledSegments: driftSeg,
            badgeColor: const Color(0xFFFFB800),
            barGradient: const [Color(0xFFFFD000), Color(0xFFD68800)],
            emptyColor: const Color(0xFF422804),
            compact: compact,
          ),
        ],
      ),
    );
  }
}

/// Single stat row: slanted badge on left, title + 5-segment bar on right.
class _BrawlStatRow extends StatelessWidget {
  const _BrawlStatRow({
    required this.label,
    required this.icon,
    required this.filledSegments,
    required this.badgeColor,
    required this.barGradient,
    required this.emptyColor,
    required this.compact,
  });

  final String label;
  final DashIcons icon;
  final int filledSegments;
  final Color badgeColor;
  final List<Color> barGradient;
  final Color emptyColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badgeSize = compact ? 26.0 : 30.0;
    final barHeight = compact ? 13.0 : 15.0;

    return Row(
      children: [
        Transform(
          transform: Matrix4.skewX(-0.10),
          alignment: Alignment.center,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: DashColors.pureBlack, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  offset: Offset(0, 2),
                  blurRadius: 2.0,
                ),
              ],
            ),
            child: Center(
              child: DashIcon(
                icon,
                size: badgeSize * 0.62,
                color: DashColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: compact ? 10.5 : 12.0,
                  letterSpacing: 0.4,
                  color: DashColors.textPrimary,
                  shadows: const [
                    Shadow(
                      color: DashColors.pureBlack,
                      offset: Offset(1.0, 1.0),
                      blurRadius: 0,
                    ),
                    Shadow(
                      color: DashColors.pureBlack,
                      offset: Offset(0, 1.5),
                      blurRadius: 0.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2.0),
              Transform(
                transform: Matrix4.skewX(-0.10),
                alignment: Alignment.center,
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: DashColors.pureBlack,
                    borderRadius: BorderRadius.circular(2.5),
                    border: Border.all(color: DashColors.pureBlack, width: 1.8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < 5; i++) ...[
                          if (i > 0)
                            Container(width: 1.5, color: DashColors.pureBlack),
                          Expanded(
                            child: i < filledSegments
                                ? Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: barGradient,
                                      ),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          height: barHeight * 0.4,
                                          child: Container(
                                            color: const Color(0x38FFFFFF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(color: emptyColor),
                          ),
                        ],
                      ],
                    ),
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
