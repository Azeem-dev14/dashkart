import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/core/scaffold/dash_brawl_screen.dart';
import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/kart_tuning.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';

/// The shop: every kart and circuit in the game, what each one does,
/// and how to get it. Nothing here is bought — DashKart has no currency;
/// content unlocks by trophies (see `UnlockRule`) — so this is where a player
/// sees what they have, what is still locked, how far off it is, and equips
/// it.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);

    return DashBrawlScreen(
      title: 'Shop',
      onBack: onBack,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: DashSpace.x4),
        children: [
          _Header(trophies: player.trophies),
          const _SectionTitle('KARTS'),
          for (final kart in Catalog.karts)
            _ShopRow(
              title: kart.name,
              // The real driving numbers, not just the flavour line: with
              // four karts that genuinely differ, the top speed and what
              // each one is best at are what the choice is actually about.
              subtitle:
                  '${kart.tagline}\n'
                  '${KartTuning.of(kart).topSpeedKmh.round()} km/h top'
                  ' · ${_statLine(kart)}',
              chipLabel: player.isKartUnlocked(kart)
                  ? 'Unlocked'
                  : kart.unlock.label,
              chipTone: player.isKartUnlocked(kart)
                  ? DashChipTone.success
                  : DashChipTone.locked,
              locked: !player.isKartUnlocked(kart),
              lockedHint: _remaining(player, kart.unlock),
              equipped: player.kart.id == kart.id,
              onEquip: () => player.selectKart(kart),
            ),
          const _SectionTitle('CIRCUITS'),
          for (final track in Catalog.tracks)
            _ShopRow(
              title: '${track.number} · ${track.name}',
              subtitle:
                  '${track.environment} · ${track.difficulty.label} · '
                  '${track.laps} laps',
              chipLabel: player.isTrackUnlocked(track)
                  ? 'Unlocked'
                  : track.unlock.label,
              chipTone: player.isTrackUnlocked(track)
                  ? DashChipTone.success
                  : DashChipTone.locked,
              locked: !player.isTrackUnlocked(track),
              lockedHint: _remaining(player, track.unlock),
              equipped: player.track.id == track.id,
              equipLabel: 'SELECT',
              onEquip: () => player.selectTrack(track),
            ),
        ],
      ),
    );
  }

  /// "3 more trophies" for a locked item, or null when [rule] is met. The
  /// arithmetic lives on [PlayerState], which is also what the unlock checks
  /// use, so the two can never disagree about how far off something is.
  static String? _remaining(PlayerState player, UnlockRule rule) {
    final missing = player.trophiesRemaining(rule);
    if (missing <= 0) return null;
    return '$missing more ${missing == 1 ? 'trophy' : 'trophies'}';
  }

  /// The two axes a kart is most distinguished by, as a short line.
  static String _statLine(Kart kart) {
    final sorted = [...KartStat.values]
      ..sort((a, b) => kart.stat(b).compareTo(kart.stat(a)));
    return sorted.take(2).map((s) => '${s.label} ${kart.stat(s)}').join(' · ');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.trophies});

  final int trophies;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DashSpace.x1),
      child: Row(
        children: [
          Expanded(
            child: BrawlInkText(
              'WIN RACES TO EARN TROPHIES AND UNLOCK MORE',
              fontSize: 13,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: DashSpace.x3),
          // Trophy count on a black plate, like the profile badge's.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: DashColors.pureBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD83A), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(DashRasterIcons.trophy.path, width: 22, height: 22),
                const SizedBox(width: 6),
                BrawlInkText(
                  '$trophies',
                  fontSize: 20,
                  weight: BrawlInkWeight.heavy,
                  color: const Color(0xFFFFD83A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DashSpace.x4, bottom: DashSpace.x2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: BrawlTitleText(text, fontSize: 24),
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.title,
    required this.subtitle,
    required this.chipLabel,
    required this.chipTone,
    required this.equipped,
    required this.onEquip,
    this.locked = false,
    this.lockedHint,
    this.equipLabel = 'EQUIP',
  });

  final String title;
  final String subtitle;
  final String chipLabel;
  final DashChipTone chipTone;
  final bool equipped;
  final bool locked;
  final String? lockedHint;
  final String equipLabel;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    final status = locked
        ? (lockedHint ?? chipLabel).toUpperCase()
        : (equipped ? 'IN USE' : 'UNLOCKED');
    final statusColor = locked
        ? const Color(0xFFFF8A9A)
        : (equipped ? const Color(0xFFFFD83A) : const Color(0xFF6BF26B));
    return Padding(
      padding: const EdgeInsets.only(bottom: DashSpace.x3),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 14, compact ? 8 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: equipped ? const Color(0xFFFFD83A) : DashColors.pureBlack,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0A1040),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF34479F), Color(0xFF1B2A86)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrawlInkText(
                    title.toUpperCase(),
                    fontSize: 18,
                    weight: BrawlInkWeight.heavy,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  BrawlInkText(
                    subtitle,
                    fontSize: 12,
                    weight: BrawlInkWeight.light,
                    color: const Color(0xFFCBD6FF),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  BrawlInkText(
                    status,
                    fontSize: 12,
                    weight: BrawlInkWeight.medium,
                    color: statusColor,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DashSpace.x3),
            BrawlActionButton(
              label: locked ? 'LOCKED' : (equipped ? 'EQUIPPED' : equipLabel),
              tone: BrawlButtonTone.green,
              width: compact ? 112 : 140,
              height: 44,
              fontSize: 16,
              onPressed: locked || equipped ? null : onEquip,
            ),
          ],
        ),
      ),
    );
  }
}
