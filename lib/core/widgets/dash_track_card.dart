import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:dashkart/data/models.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_chip.dart';
import 'package:dashkart/core/widgets/dash_icon.dart';
import 'package:dashkart/core/widgets/dash_pressable.dart';

/// A track selection card.
///
/// Carries preview, difficulty, environment, and best time together so a player
/// can choose without drilling in — see docs/ui-references.md § 7.
class DashTrackCard extends StatelessWidget {
  const DashTrackCard({
    super.key,
    required this.track,
    required this.unlocked,
    this.bestTime,
    this.trophy = false,
    this.focused = false,
    this.onTap,
    this.index = 0,
  });

  final Track track;
  final bool unlocked;
  final Duration? bestTime;
  final bool trophy;
  final bool focused;
  final VoidCallback? onTap;
  final int index;

  static const width = 248.0;
  static const height = 200.0;

  static String formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    final cs = (d.inMilliseconds % 1000) ~/ 10;
    return '$m:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DashEnter(
      index: index,
      child: DashPressable(
        onPressed: onTap,
        semanticLabel: unlocked
            ? '${track.name}, ${track.environment}, ${track.difficulty.label}'
            : '${track.name}, locked. ${track.unlock.label}',
        builder: (context, press, _) => AnimatedScale(
          scale: focused ? 1.04 : 0.96,
          duration: DashMotionScope.duration(context, DashMotion.base),
          curve: DashMotionScope.curve(context, DashMotion.baseCurve),
          child: AnimatedOpacity(
            duration: DashMotionScope.duration(context, DashMotion.base),
            opacity: focused ? 1 : 0.7,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: DashColors.surface,
                borderRadius: DashRadius.lgAll,
                border: Border.all(
                  color: DashColors.pureBlack,
                  width: focused ? 2.8 : 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x8A000000),
                    offset: Offset(0, focused ? 4 : 3),
                    blurRadius: focused ? 8 : 6,
                  ),
                  if (focused)
                    const BoxShadow(
                      color: Color(0x44FFC700),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _TrackPreview(track: track, dim: !unlocked),
                        // Bottom-up scrim so the name stays legible over any
                        // preview art.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xB3000000), Color(0x00000000)],
                            ),
                          ),
                        ),
                        // Top specular sheen
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 2.0,
                          child: Container(
                            color: DashColors.textPrimary.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                        Positioned(
                          top: DashSpace.x2,
                          left: DashSpace.x3,
                          child: Text(
                            track.number,
                            style: DashType.label.copyWith(
                              color: DashColors.textPrimary.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: DashSpace.x2,
                          right: DashSpace.x3,
                          child: _Difficulty(track.difficulty),
                        ),
                        Positioned(
                          left: DashSpace.x3,
                          right: DashSpace.x3,
                          bottom: DashSpace.x2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                style: DashType.h2.copyWith(fontSize: 20),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: DashSpace.x1),
                              DashChip(
                                label: track.environment,
                                tone: unlocked
                                    ? DashChipTone.brand
                                    : DashChipTone.locked,
                              ),
                            ],
                          ),
                        ),
                        if (!unlocked)
                          Container(
                            color: DashColors.bgBase.withValues(alpha: 0.45),
                            alignment: Alignment.center,
                            child: const DashIcon(
                              DashIcons.lock,
                              size: DashIconSize.xl,
                              color: DashColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashSpace.x3,
                    ),
                    color: DashColors.surfaceSunken,
                    child: Row(
                      children: [
                        if (unlocked) ...[
                          DashRasterIcon(
                            DashRasterIcons.trophy,
                            size: DashIconSize.sm,
                            color: trophy
                                ? DashColors.yellow.s500
                                : DashColors.textTertiary,
                          ),
                          const SizedBox(width: DashSpace.x2),
                          Flexible(
                            child: Text(
                              bestTime == null
                                  ? '--:--.--'
                                  : formatTime(bestTime!),
                              style: DashType.timer.copyWith(
                                fontSize: 15,
                                color: bestTime == null
                                    ? DashColors.textTertiary
                                    : DashColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: DashSpace.x2),
                          Text('${track.laps} LAPS', style: DashType.label),
                        ] else
                          Flexible(
                            child: Text(
                              track.unlock.label.toUpperCase(),
                              style: DashType.label.copyWith(
                                color: DashColors.yellow.s400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
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

class _Difficulty extends StatelessWidget {
  const _Difficulty(this.difficulty);

  final TrackDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: DashIcon(
                DashIcons.back,
                size: DashIconSize.xs,
                color: i < difficulty.chevrons
                    ? DashColors.yellow.s500
                    : DashColors.textTertiary.withValues(alpha: 0.4),
              ),
            ),
          ),
      ],
    );
  }
}

/// Track preview art, generated from the track's own identity until captured
/// renders land (docs/asset-inventory.md § CREATE 14).
///
/// Each track gets a distinct horizon palette and skyline, derived from its
/// environment, so the six cards are already visually separable.
class _TrackPreview extends StatelessWidget {
  const _TrackPreview({required this.track, required this.dim});

  final Track track;
  final bool dim;

  static const _palettes = <String, List<Color>>{
    'dash-valley': [Color(0xFF6FC7F5), Color(0xFF3E9E5C), Color(0xFF1E6B3A)],
    'desert-rush': [Color(0xFFFFB661), Color(0xFFE0762C), Color(0xFF8A4118)],
    'frozen-peak': [Color(0xFFBFE4F5), Color(0xFF7FA8C9), Color(0xFF3E5B7A)],
    'sky-harbor': [Color(0xFF8ED0FF), Color(0xFFCFE9FF), Color(0xFF4B8FD1)],
  };

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[track.id] ?? DashGradients.menuSky;
    return Opacity(
      opacity: dim ? 0.35 : 1,
      child: CustomPaint(
        painter: _HorizonPainter(palette: palette, seed: track.index),
      ),
    );
  }
}

class _HorizonPainter extends CustomPainter {
  const _HorizonPainter({required this.palette, required this.seed});

  final List<Color> palette;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette,
        ).createShader(rect),
    );

    // A silhouetted skyline, deterministic per track.
    final rng = math.Random(seed * 977);
    final horizon = size.height * 0.62;
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, horizon);
    var x = 0.0;
    while (x < size.width) {
      final w = 18 + rng.nextDouble() * 30;
      final h = rng.nextDouble() * size.height * 0.26;
      path.lineTo(x, horizon - h);
      path.lineTo(x + w, horizon - h);
      x += w;
    }
    path
      ..lineTo(size.width, horizon)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0x59000000));

    // The road, receding to the horizon.
    final road = Path()
      ..moveTo(size.width * 0.5 - 8, horizon)
      ..lineTo(size.width * 0.5 + 8, horizon)
      ..lineTo(size.width * 0.96, size.height)
      ..lineTo(size.width * 0.04, size.height)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xCC2A2E3D));
  }

  @override
  bool shouldRepaint(_HorizonPainter old) =>
      old.palette != palette || old.seed != seed;
}
