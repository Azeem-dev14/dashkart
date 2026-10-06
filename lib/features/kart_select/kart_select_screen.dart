import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/core/scaffold/dash_brawl_screen.dart';
import 'package:dashkart/features/kart_select/kart_detail_screen.dart';
import 'package:dashkart/features/race/scene/kart_viewer.dart';

/// Kart picker: a grid of every kart in the roster. Tapping an unlocked card
/// swaps in [KartDetailScreen] for it; tapping a locked one just shakes
/// rather than opening a detail view for something you can't equip yet.
///
/// The grid and the detail view are two distinct screens the player taps
/// through, but deliberately still one Navigator route — swapped via local
/// state, the same way [RaceScreen]'s phases are, not a nested
/// `Navigator.push`. [onConfirm] is wired by the caller (see `main.dart`) to
/// pop exactly this one route; a nested push would leave the grid stranded
/// underneath the detail view in the back stack once that pop only closed
/// the top one.
class KartSelectScreen extends ConsumerStatefulWidget {
  const KartSelectScreen({super.key, this.onBack, this.onConfirm});

  final VoidCallback? onBack;
  final VoidCallback? onConfirm;

  @override
  ConsumerState<KartSelectScreen> createState() => _KartSelectScreenState();
}

class _KartSelectScreenState extends ConsumerState<KartSelectScreen> {
  Kart? _viewing;
  String? _shakeKartId;
  int _shake = 0;

  void _tap(Kart kart, bool unlocked, PlayerState player) {
    if (!unlocked) {
      setState(() {
        _shakeKartId = kart.id;
        _shake++;
      });
      return;
    }
    player.selectKart(kart);
    setState(() => _viewing = kart);
  }

  @override
  Widget build(BuildContext context) {
    final viewing = _viewing;
    if (viewing != null) {
      return KartDetailScreen(
        kart: viewing,
        onBack: () => setState(() => _viewing = null),
        onConfirm: widget.onConfirm,
      );
    }

    final player = ref.watch(playerProvider);
    final unlockedCount = Catalog.karts.where(player.isKartUnlocked).length;
    final totalCount = Catalog.karts.length;

    final compact = DashBreakpoint.of(context).isCompact;

    return DashBrawlScreen(
      titleWidget: BrawlCountTitle(
        title: 'KARTS',
        count: '$unlockedCount/$totalCount',
      ),
      onBack: widget.onBack,
      heroButton: DashRaceButton(
        label: 'NEXT',
        compact: compact,
        glow: true,
        onPressed: () {
          setState(() => _viewing = player.kart);
        },
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(left: 8.0, right: compact ? 120.0 : 160.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final kart in Catalog.karts)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DashSpace.x2),
                  child: DashShakeable(
                    trigger: _shakeKartId == kart.id ? _shake : 0,
                    child: _KartGridCard(
                      kart: kart,
                      equipped: kart.id == player.kart.id,
                      unlocked: player.isKartUnlocked(kart),
                      onTap: () =>
                          _tap(kart, player.isKartUnlocked(kart), player),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartGridCard extends StatelessWidget {
  const _KartGridCard({
    required this.kart,
    required this.equipped,
    required this.unlocked,
    required this.onTap,
  });

  final Kart kart;
  final bool equipped;
  final bool unlocked;
  final VoidCallback onTap;

  static const _skewX = -0.09;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    final width = compact ? 192.0 : 216.0;
    final height = compact ? 284.0 : 316.0;

    final cardRadius = compact ? 10.0 : 8.0;
    final strokeWidth = equipped ? 4.0 : 3.5;
    final innerRadius = (cardRadius - strokeWidth).clamp(2.0, 10.0);

    return DashPressable(
      onPressed: onTap,
      semanticLabel: unlocked
          ? '${kart.name}, tap for details'
          : '${kart.name}, locked. ${kart.unlock.label}',
      builder: (context, press, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Transform(
          transform: Matrix4.skewX(_skewX),
          alignment: Alignment.center,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: equipped ? DashColors.textPrimary : DashColors.pureBlack,
                width: strokeWidth,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  offset: Offset(0, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(innerRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Purple radial gradient + comic burst rays
                  const CustomPaint(painter: _CardBurstPainter()),
                  Column(
                    children: [
                      // Top spacing so 3D kart is comfortably positioned in the upper card body
                      SizedBox(height: compact ? 12.0 : 16.0),

                      // Center 3D kart model (counter-skewed so 3D model stays upright, shifted a little below)
                      Expanded(
                        child: Transform(
                          transform: Matrix4.skewX(-_skewX),
                          alignment: Alignment.center,
                          child: Transform.translate(
                            offset: Offset(0, compact ? 12.0 : 16.0),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ground shadow under 3D kart
                                Positioned(
                                  bottom: compact ? 4.0 : 6.0,
                                  child: Container(
                                    width: compact ? 100.0 : 120.0,
                                    height: compact ? 22.0 : 26.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.elliptical(
                                          compact ? 100.0 : 120.0,
                                          compact ? 22.0 : 26.0,
                                        ),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x99000000),
                                          blurRadius: 10.0,
                                          spreadRadius: 2.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                KartViewer(
                                  key: ValueKey('card_${kart.id}'),
                                  modelPath: kart.modelPath,
                                  tint: kart.livery,
                                  spin: false,
                                  fixedAngle: -math.pi * 0.38,
                                  cameraTargetY: 0.50,
                                  cameraEyeY: 1.15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Horizontal name banner across the card (matching the sketch design)
                      Container(
                        width: double.infinity,
                        height: compact ? 34.0 : 38.0,
                        decoration: const BoxDecoration(
                          color: Color(0xCC081224),
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: DashColors.pureBlack,
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: Center(
                          child: BrawlInkText(
                            kart.name.toUpperCase(),
                            fontSize: compact ? 17.0 : 20.0,
                            weight: BrawlInkWeight.heavy,
                          ),
                        ),
                      ),

                      // Bottom spacing under banner (matching the sketch layout)
                      SizedBox(height: compact ? 44.0 : 52.0),
                    ],
                  ),

                  // 3. Top-right tick badge when equipped
                  if (equipped)
                    Positioned(
                      top: compact ? 8.0 : 10.0,
                      right: compact ? 8.0 : 10.0,
                      child: Transform(
                        transform: Matrix4.skewX(-_skewX),
                        alignment: Alignment.center,
                        child: BrawlEquippedTickBadge(compact: compact),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBurstPainter extends CustomPainter {
  const _CardBurstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.44);

    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        size.height * 0.72,
        const [
          Color(0xFF9E2CFB),
          Color(0xFF7614D9),
          Color(0xFF4C0898),
          Color(0xFF260252),
        ],
        const [0.0, 0.38, 0.75, 1.0],
      );
    canvas.drawRect(Offset.zero & size, bgPaint);

    final rayPaint = Paint()..color = const Color(0x35000000);
    const rayCount = 12;
    final maxR = math.max(size.width, size.height) * 1.3;

    for (var i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi) / rayCount - 0.25;
      const spread = (2 * math.pi / rayCount) * 0.35;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + maxR * math.cos(angle - spread * 0.5),
          center.dy + maxR * math.sin(angle - spread * 0.5),
        )
        ..lineTo(
          center.dx + maxR * math.cos(angle + spread * 0.5),
          center.dy + maxR * math.sin(angle + spread * 0.5),
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
