import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/features/race/scene/racer_viewer.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/core/scaffold/dash_brawl_screen.dart';

/// Racer selection.
///
/// Mirrors the kart screen's shape so the two read as one flow: preview left,
/// detail right, roster along the bottom. Layout from docs/wireframes.md § 4.
class CharacterSelectScreen extends ConsumerStatefulWidget {
  const CharacterSelectScreen({
    super.key,
    this.onBack,
    this.onConfirm,
    this.onOpenKart,
  });

  final VoidCallback? onBack;
  final VoidCallback? onConfirm;

  /// The signature-kart row deep-links here.
  final VoidCallback? onOpenKart;

  @override
  ConsumerState<CharacterSelectScreen> createState() =>
      _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends ConsumerState<CharacterSelectScreen> {
  int _index = 0;

  /// Bumped on selection to replay the celebrate pose, standing in for the
  /// `emote-yes` clip on the rigged GLB.
  int _emote = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ref.read(playerProvider).racer.id;
    final i = Catalog.racers.indexWhere((r) => r.id == current);
    if (i >= 0) _index = i;
  }

  Racer get _racer => Catalog.racers[_index];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final signature = Catalog.kartById(_racer.signatureKartId);

    final isPortrait = DashBreakpoint.isPortrait(context);

    final stageCard = DashCard(
      variant: DashCardVariant.gradient,
      child: RacerViewer(
        modelPath: _racer.modelPath,
        accessoryPath: _racer.accessory != null
            ? 'assets/models/characters/${_racer.accessory}.glb'
            : null,
        fallback: _RacerStage(racer: _racer, emote: _emote),
      ),
    );

    final isEquipped = _racer.id == player.racer.id;

    final detailCard = DashCard(
      variant: DashCardVariant.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrawlInkText(
            _racer.name.toUpperCase(),
            fontSize: 26,
            weight: BrawlInkWeight.heavy,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          BrawlInkText(
            '"${_racer.personality}"',
            fontSize: 13,
            weight: BrawlInkWeight.light,
            color: const Color(0xFF3DF2FF),
            fontStyle: FontStyle.italic,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DashSpace.x2),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: box.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DetailRow(
                        label: 'Signature Kart',
                        value: signature.name,
                        icon: DashIcons.steeringWheel,
                        onTap: widget.onOpenKart,
                      ),
                      _DetailRow(
                        label: 'Bonus',
                        value: _racer.bonusLabel,
                        icon: _racer.bonus.$1.icon,
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final totalRacers = Catalog.racers.length;

    return DashBrawlScreen(
      titleWidget: BrawlCountTitle(
        title: 'RACERS',
        count: '$totalRacers/$totalRacers',
      ),
      onBack: widget.onBack,
      heroButton: DashRaceButton(
        label: isEquipped ? 'NEXT' : 'SELECT',
        onPressed: () {
          player.selectRacer(_racer);
          setState(() => _emote++);
          widget.onConfirm?.call();
        },
        glow: true,
      ),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: isPortrait
                ? Column(
                    children: [
                      Expanded(flex: 5, child: stageCard),
                      const SizedBox(height: DashSpace.x3),
                      Expanded(flex: 4, child: detailCard),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: stageCard),
                      const SizedBox(width: DashSpace.x4),
                      Expanded(flex: 6, child: detailCard),
                    ],
                  ),
          ),
          const SizedBox(height: DashSpace.x3),
          Expanded(
            flex: 2,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Catalog.racers.length,
              separatorBuilder: (_, _) => const SizedBox(width: DashSpace.x3),
              itemBuilder: (context, i) => Center(
                child: DashEnter(
                  index: i,
                  child: FittedBox(
                    child: _Portrait(
                      racer: Catalog.racers[i],
                      selected: i == _index,
                      onTap: () => setState(() {
                        _index = i;
                        _emote++;
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DashSpace.x3),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.highlight = false,
  });

  final String label;
  final String value;
  final DashIcons icon;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: DashColors.stroke)),
        ),
        child: Row(
          children: [
            DashIcon(
              icon,
              size: DashIconSize.md,
              color: DashColors.textTertiary,
            ),
            const SizedBox(width: DashSpace.x3),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: DashType.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: DashSpace.x3),
            Flexible(
              child: Text(
                value,
                style: DashType.h3.copyWith(
                  fontSize: 16,
                  color: highlight
                      ? DashColors.neonGreen
                      : DashColors.textPrimary,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: DashSpace.x2),
              Transform.rotate(
                angle: 3.14159,
                child: const DashIcon(
                  DashIcons.back,
                  size: DashIconSize.sm,
                  color: DashColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  const _Portrait({
    required this.racer,
    required this.selected,
    required this.onTap,
  });

  final Racer racer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (colors, icon) = switch (racer.id) {
      'cyber-dash' => (
        [const Color(0xFF7928CA), const Color(0xFFFF0080)],
        DashIcons.burst,
      ),
      'astro-dash' => (
        [const Color(0xFF0070F3), const Color(0xFF00DFD8)],
        DashIcons.shield,
      ),
      _ => ([DashColors.blue.s500, DashColors.skyBlue], DashIcons.boost),
    };

    return DashPressable(
      onPressed: onTap,
      semanticLabel: racer.name,
      builder: (context, press, _) => AnimatedScale(
        scale: selected ? 1.12 : 1 - press * 0.05,
        duration: DashMotionScope.duration(context, DashMotion.base),
        curve: DashMotionScope.curve(context, DashMotion.baseCurve),
        child: Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(DashSpace.x1),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: DashColors.pureBlack,
              width: selected ? 3.0 : 2.2,
            ),
            boxShadow: [
              const BoxShadow(
                color: Color(0x8A000000),
                offset: Offset(0, 3),
                blurRadius: 6,
              ),
              if (selected)
                DashElevation.glow(colors.first, opacity: 0.5, blur: 16),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DashIcon(
                icon,
                size: DashIconSize.md,
                color: DashColors.textPrimary,
              ),
              const SizedBox(height: 2),
              Text(
                racer.name.split(' ').first.toUpperCase(),
                style: DashType.label.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: DashColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The racer standing on a lit stage.
///
/// 2D fallback when 3D (Flutter GPU/Impeller) is unavailable.
class _RacerStage extends StatefulWidget {
  const _RacerStage({required this.racer, required this.emote});

  final Racer racer;
  final int emote;

  @override
  State<_RacerStage> createState() => _RacerStageState();
}

class _RacerStageState extends State<_RacerStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(_RacerStage old) {
    super.didUpdateWidget(old);
    if (widget.emote != old.emote && DashMotionScope.of(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _RacerPainter(
          accent: widget.racer.id == 'cyber-dash'
              ? const Color(0xFFFF0080)
              : widget.racer.id == 'astro-dash'
              ? const Color(0xFF00DFD8)
              : DashColors.orange.s500,
          celebrate: Curves.easeOutBack.transform(
            _c.isAnimating ? _c.value : 0,
          ),
          racerId: widget.racer.id,
        ),
      ),
    );
  }
}

class _RacerPainter extends CustomPainter {
  const _RacerPainter({
    required this.accent,
    required this.celebrate,
    required this.racerId,
  });

  final Color accent;
  final double celebrate;
  final String racerId;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // Stage disc with soft glow
    final plate = Rect.fromCenter(
      center: Offset(cx, h * 0.88),
      width: w * 0.7,
      height: h * 0.12,
    );
    canvas.drawOval(
      plate,
      Paint()..color = DashColors.surfaceSunken.withValues(alpha: 0.95),
    );
    canvas.drawOval(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = accent.withValues(alpha: 0.85),
    );

    // Primary palette
    final bodyColor = switch (racerId) {
      'cyber-dash' => const Color(0xFF9B5DE5),
      'astro-dash' => const Color(0xFF0070F3),
      _ => DashColors.blue.s400,
    };

    final lift = celebrate;
    final headCenter = Offset(cx, h * (0.34 - lift * 0.04));

    // Dash body / torso
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * (0.54 - lift * 0.02)),
        width: w * 0.32,
        height: h * 0.28,
      ),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(bodyRect, Paint()..color = bodyColor);

    // Belly patch
    final bellyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * (0.55 - lift * 0.02)),
        width: w * 0.20,
        height: h * 0.20,
      ),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(
      bellyRect,
      Paint()..color = DashColors.skyBlue.withValues(alpha: 0.8),
    );

    // Wings
    final wingPaint = Paint()..color = bodyColor;
    final leftWing = Path()
      ..moveTo(cx - w * 0.16, h * (0.46 - lift * 0.02))
      ..quadraticBezierTo(
        cx - w * (0.28 + lift * 0.04),
        h * (0.50 - lift * 0.14),
        cx - w * 0.16,
        h * (0.62 - lift * 0.02),
      )
      ..close();
    canvas.drawPath(leftWing, wingPaint);

    final rightWing = Path()
      ..moveTo(cx + w * 0.16, h * (0.46 - lift * 0.02))
      ..quadraticBezierTo(
        cx + w * (0.28 + lift * 0.04),
        h * (0.50 - lift * 0.14),
        cx + w * 0.16,
        h * (0.62 - lift * 0.02),
      )
      ..close();
    canvas.drawPath(rightWing, wingPaint);

    // Dash Head
    canvas.drawCircle(headCenter, w * 0.13, Paint()..color = bodyColor);

    // Beak
    final beakPath = Path()
      ..moveTo(cx, headCenter.dy - h * 0.01)
      ..lineTo(cx - w * 0.04, headCenter.dy + h * 0.025)
      ..lineTo(cx + w * 0.04, headCenter.dy + h * 0.025)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = DashColors.orange.s500);

    // Eyes / Visor
    if (racerId == 'cyber-dash') {
      // Cyber visor
      final visorRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, headCenter.dy - h * 0.015),
          width: w * 0.18,
          height: h * 0.04,
        ),
        Radius.circular(w * 0.02),
      );
      canvas.drawRRect(visorRect, Paint()..color = const Color(0xFFFF0080));
    } else if (racerId == 'astro-dash') {
      // Astro glasses
      final glassPaint = Paint()
        ..color = const Color(0xFF00DFD8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(
        Offset(cx - w * 0.05, headCenter.dy - h * 0.015),
        w * 0.035,
        glassPaint,
      );
      canvas.drawCircle(
        Offset(cx + w * 0.05, headCenter.dy - h * 0.015),
        w * 0.035,
        glassPaint,
      );
      canvas.drawLine(
        Offset(cx - w * 0.015, headCenter.dy - h * 0.015),
        Offset(cx + w * 0.015, headCenter.dy - h * 0.015),
        glassPaint,
      );
    } else {
      // Classic big eyes
      canvas.drawCircle(
        Offset(cx - w * 0.05, headCenter.dy - h * 0.015),
        w * 0.03,
        Paint()..color = DashColors.textPrimary,
      );
      canvas.drawCircle(
        Offset(cx + w * 0.05, headCenter.dy - h * 0.015),
        w * 0.03,
        Paint()..color = DashColors.textPrimary,
      );
      canvas.drawCircle(
        Offset(cx - w * 0.045, headCenter.dy - h * 0.02),
        w * 0.012,
        Paint()..color = const Color(0xFF1A0733),
      );
      canvas.drawCircle(
        Offset(cx + w * 0.055, headCenter.dy - h * 0.02),
        w * 0.012,
        Paint()..color = const Color(0xFF1A0733),
      );
    }

    // Feet
    final feetPaint = Paint()..color = DashColors.orange.s500;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.07, h * 0.72),
        width: w * 0.08,
        height: h * 0.04,
      ),
      feetPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.07, h * 0.72),
        width: w * 0.08,
        height: h * 0.04,
      ),
      feetPaint,
    );
  }

  @override
  bool shouldRepaint(_RacerPainter old) =>
      old.celebrate != celebrate ||
      old.racerId != racerId ||
      old.accent != accent;
}
