import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/core/scaffold/dash_brawl_screen.dart';

/// Track selection screen in the Supercell Brawl Stars arcade aesthetic.
///
/// Features horizontal left-to-right scrolling with parallelogram skewed cards,
/// dynamic biome illustrations, live equipped tick badges, unlocked/locked states,
/// and the NEXT hero action button.
class TrackSelectScreen extends ConsumerStatefulWidget {
  const TrackSelectScreen({super.key, this.onBack, this.onConfirm});

  final VoidCallback? onBack;
  final VoidCallback? onConfirm;

  @override
  ConsumerState<TrackSelectScreen> createState() => _TrackSelectScreenState();
}

class _TrackSelectScreenState extends ConsumerState<TrackSelectScreen> {
  String? _shakeTrackId;
  int _shake = 0;

  void _tap(Track track, bool unlocked, PlayerState player) {
    if (!unlocked) {
      setState(() {
        _shakeTrackId = track.id;
        _shake++;
      });
      return;
    }
    final isAlreadyEquipped = track.id == player.track.id;
    if (isAlreadyEquipped) {
      widget.onConfirm?.call();
    } else {
      player.selectTrack(track);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final totalCount = Catalog.tracks.length;
    final unlockedCount = Catalog.tracks.where(player.isTrackUnlocked).length;
    final compact = DashBreakpoint.of(context).isCompact;

    return DashBrawlScreen(
      titleWidget: BrawlCountTitle(
        title: 'TRACKS',
        count: '$unlockedCount/$totalCount',
      ),
      onBack: widget.onBack,
      heroButton: DashRaceButton(
        label: 'NEXT',
        compact: compact,
        glow: true,
        onPressed: widget.onConfirm,
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
              for (final track in Catalog.tracks)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DashSpace.x2),
                  child: DashShakeable(
                    trigger: _shakeTrackId == track.id ? _shake : 0,
                    child: _TrackGridCard(
                      track: track,
                      equipped: track.id == player.track.id,
                      unlocked: player.isTrackUnlocked(track),
                      bestTime: player.bestTime(track.id),
                      trophy: player.hasTrophy(track.id),
                      onTap: () =>
                          _tap(track, player.isTrackUnlocked(track), player),
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

class _TrackGridCard extends StatelessWidget {
  const _TrackGridCard({
    required this.track,
    required this.equipped,
    required this.unlocked,
    this.bestTime,
    this.trophy = false,
    required this.onTap,
  });

  final Track track;
  final bool equipped;
  final bool unlocked;
  final Duration? bestTime;
  final bool trophy;
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
          ? '${track.name}, ${track.environment}, ${track.difficulty.label}'
          : '${track.name}, locked. ${track.unlock.label}',
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
                  // 1. Dynamic biome landscape + speed burst + perspective road
                  CustomPaint(
                    painter: _TrackCardScenePainter(
                      trackId: track.id,
                      seed: track.index,
                      dim: !unlocked,
                    ),
                  ),

                  // 2. Top-down scrim for title contrast
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xCC000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                  ),

                  // 3. Card layout content (title, center stats/lock, bottom button)
                  Column(
                    children: [
                      // Top track title
                      Padding(
                        padding: EdgeInsets.only(
                          top: compact ? 10.0 : 14.0,
                          bottom: compact ? 2.0 : 4.0,
                          left: 10.0,
                          right: 10.0,
                        ),
                        child: Transform(
                          transform: Matrix4.skewX(-_skewX),
                          alignment: Alignment.center,
                          child: BrawlInkText(
                            track.name.toUpperCase(),
                            fontSize: compact ? 18.0 : 21.0,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Center area
                      Expanded(
                        child: Transform(
                          transform: Matrix4.skewX(-_skewX),
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Floating track info badge (when unlocked)
                              if (unlocked)
                                Positioned(
                                  bottom: compact ? 10.0 : 14.0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xD9000000),
                                      borderRadius: BorderRadius.circular(6.0),
                                      border: Border.all(
                                        color: const Color(0x55FFFFFF),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (trophy) ...[
                                          const DashRasterIcon(
                                            DashRasterIcons.trophy,
                                            size: DashIconSize.xs,
                                            color: Color(0xFFFFD700),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          bestTime != null
                                              ? DashTrackCard.formatTime(
                                                  bestTime!,
                                                )
                                              : '${track.laps} LAPS',
                                          style: const TextStyle(
                                            fontFamily: 'LilitaOne',
                                            fontSize: 12.0,
                                            color: DashColors.textPrimary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Locked overlay and lock icon with requirement
                              if (!unlocked)
                                Container(
                                  color: const Color(0xAA000000),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: compact ? 40 : 46,
                                        height: compact ? 40 : 46,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF1E212B),
                                          border: Border.all(
                                            color: const Color(0xFFFFAE00),
                                            width: 2.5,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x88000000),
                                              offset: Offset(0, 3),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: DashIcon(
                                            DashIcons.lock,
                                            size: compact
                                                ? DashIconSize.md
                                                : DashIconSize.lg,
                                            color: const Color(0xFFFFAE00),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        track.unlock.label.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'LilitaOne',
                                          fontSize: 12.0,
                                          color: Color(0xFFFFDD00),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom margin (no select button, only tick when equipped)
                      SizedBox(height: compact ? 10.0 : 14.0),
                    ],
                  ),

                  // 4. Top-right tick badge when equipped
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

class _TrackTheme {
  const _TrackTheme({
    required this.skyTop,
    required this.skyBottom,
    required this.rayColor,
    required this.skylineColor,
    required this.groundColor,
    required this.curbColor,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color rayColor;
  final Color skylineColor;
  final Color groundColor;
  final Color curbColor;
}

const _trackThemes = <String, _TrackTheme>{
  'dash-valley': _TrackTheme(
    skyTop: Color(0xFF4AC4F3),
    skyBottom: Color(0xFF1E88E5),
    rayColor: Color(0x33FFFFFF),
    skylineColor: Color(0xFF2E7D32),
    groundColor: Color(0xFF388E3C),
    curbColor: Color(0xFFFF3333),
  ),
  'desert-rush': _TrackTheme(
    skyTop: Color(0xFFFFB703),
    skyBottom: Color(0xFFFB8500),
    rayColor: Color(0x33FFE8D6),
    skylineColor: Color(0xFF9E4712),
    groundColor: Color(0xFFB0591E),
    curbColor: Color(0xFFFF3B30),
  ),
  'frozen-peak': _TrackTheme(
    skyTop: Color(0xFFA2D2FF),
    skyBottom: Color(0xFF3A86C8),
    rayColor: Color(0x3DFFFFFF),
    skylineColor: Color(0xFF4A7CB5),
    groundColor: Color(0xFF5D93CE),
    curbColor: Color(0xFFFF2A6D),
  ),
};

class _TrackCardScenePainter extends CustomPainter {
  const _TrackCardScenePainter({
    required this.trackId,
    required this.seed,
    required this.dim,
  });

  final String trackId;
  final int seed;
  final bool dim;

  @override
  void paint(Canvas canvas, Size size) {
    final theme =
        _trackThemes[trackId] ??
        const _TrackTheme(
          skyTop: Color(0xFF4AC4F3),
          skyBottom: Color(0xFF1E88E5),
          rayColor: Color(0x33FFFFFF),
          skylineColor: Color(0xFF2E7D32),
          groundColor: Color(0xFF388E3C),
          curbColor: Color(0xFFFF3333),
        );

    final horizonY = size.height * 0.52;
    final horizonCenter = Offset(size.width * 0.5, horizonY);

    // 1. Sky with gradient
    final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [theme.skyTop, theme.skyBottom],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // 2. Action rays originating from horizon center
    final rayPaint = Paint()
      ..color = theme.rayColor
      ..style = PaintingStyle.fill;

    const rayCount = 14;
    final maxRadius = math.max(size.width, size.height);
    for (var i = 0; i < rayCount; i++) {
      final angle = -math.pi + (i * math.pi / rayCount);
      final raySweep = (math.pi / rayCount) * 0.5;

      final p1 =
          horizonCenter +
          Offset(math.cos(angle) * maxRadius, math.sin(angle) * maxRadius);
      final p2 =
          horizonCenter +
          Offset(
            math.cos(angle + raySweep) * maxRadius,
            math.sin(angle + raySweep) * maxRadius,
          );

      final rayPath = Path()
        ..moveTo(horizonCenter.dx, horizonCenter.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      canvas.save();
      canvas.clipRect(skyRect);
      canvas.drawPath(rayPath, rayPaint);
      canvas.restore();
    }

    // 3. Biome Skyline / Mountains
    final rng = math.Random(seed * 977);
    final skylinePath = Path()..moveTo(0, horizonY);
    var x = 0.0;
    while (x < size.width) {
      final w = 16.0 + rng.nextDouble() * 24.0;
      final h = 10.0 + rng.nextDouble() * 28.0;
      skylinePath.lineTo(x, horizonY - h);
      skylinePath.lineTo(x + w, horizonY - h);
      x += w;
    }
    skylinePath
      ..lineTo(size.width, horizonY)
      ..close();
    canvas.drawPath(skylinePath, Paint()..color = theme.skylineColor);

    // 4. Ground
    final groundRect = Rect.fromLTWH(
      0,
      horizonY,
      size.width,
      size.height - horizonY,
    );
    canvas.drawRect(groundRect, Paint()..color = theme.groundColor);

    // 5. Perspective Race Road
    final roadTopWidth = 14.0;
    final roadBottomWidth = size.width * 0.84;
    final roadLeftTop = (size.width - roadTopWidth) * 0.5;
    final roadRightTop = roadLeftTop + roadTopWidth;
    final roadLeftBottom = (size.width - roadBottomWidth) * 0.5;
    final roadRightBottom = roadLeftBottom + roadBottomWidth;

    final roadPath = Path()
      ..moveTo(roadLeftTop, horizonY)
      ..lineTo(roadRightTop, horizonY)
      ..lineTo(roadRightBottom, size.height)
      ..lineTo(roadLeftBottom, size.height)
      ..close();

    // Road asphalt
    canvas.drawPath(roadPath, Paint()..color = const Color(0xFF222632));

    // Left and right curbs
    const curbSegments = 7;
    for (var i = 0; i < curbSegments; i++) {
      final t0 = i / curbSegments;
      final t1 = (i + 1) / curbSegments;

      final l0x = roadLeftTop + (roadLeftBottom - roadLeftTop) * t0;
      final l0y = horizonY + (size.height - horizonY) * t0;
      final l1x = roadLeftTop + (roadLeftBottom - roadLeftTop) * t1;
      final l1y = horizonY + (size.height - horizonY) * t1;

      final r0x = roadRightTop + (roadRightBottom - roadRightTop) * t0;
      final r0y = horizonY + (size.height - horizonY) * t0;
      final r1x = roadRightTop + (roadRightBottom - roadRightTop) * t1;
      final r1y = horizonY + (size.height - horizonY) * t1;

      final isAlt = i % 2 == 0;
      final curbPaint = Paint()
        ..color = isAlt ? theme.curbColor : const Color(0xFFFFFFFF);

      // Left curb
      final leftCurb = Path()
        ..moveTo(l0x, l0y)
        ..lineTo(l1x, l1y)
        ..lineTo(l1x - 3.5, l1y)
        ..lineTo(l0x - 2.5, l0y)
        ..close();
      canvas.drawPath(leftCurb, curbPaint);

      // Right curb
      final rightCurb = Path()
        ..moveTo(r0x, r0y)
        ..lineTo(r1x, r1y)
        ..lineTo(r1x + 3.5, r1y)
        ..lineTo(r0x + 2.5, r0y)
        ..close();
      canvas.drawPath(rightCurb, curbPaint);

      // Center dashed road markings
      if (isAlt) {
        final cx0 = (l0x + r0x) * 0.5;
        final cy0 = (l0y + r0y) * 0.5;
        final cx1 = (l1x + r1x) * 0.5;
        final cy1 = (l1y + r1y) * 0.5;

        canvas.drawLine(
          Offset(cx0, cy0),
          Offset(cx1, cy1),
          Paint()
            ..color = const Color(0xCCFFDD00)
            ..strokeWidth = 2.0 + t1 * 2.0
            ..strokeCap = StrokeCap.square,
        );
      }
    }

    // 6. Dimming overlay for locked state
    if (dim) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0x77000000),
      );
    }
  }

  @override
  bool shouldRepaint(_TrackCardScenePainter old) =>
      old.trackId != trackId || old.seed != seed || old.dim != dim;
}
