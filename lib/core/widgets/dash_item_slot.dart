import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:dashkart/data/models.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_icon.dart';

enum ItemSlotState { empty, rolling, ready, cooldown }

/// The HUD item holder.
///
/// Four states with genuinely different behaviour: an empty dashed ring, a
/// roll that cycles icons while the item is decided, a slow pulse once it is
/// usable, and a radial sweep while it recharges.
class DashItemSlot extends StatefulWidget {
  const DashItemSlot({
    super.key,
    required this.state,
    this.item,
    this.cooldown = 0,
    this.onUse,
    this.size = DashTouch.itemSlot,
  });

  final ItemSlotState state;
  final RaceItem? item;

  /// 0..1 remaining, only read in [ItemSlotState.cooldown].
  final double cooldown;
  final VoidCallback? onUse;
  final double size;

  @override
  State<DashItemSlot> createState() => _DashItemSlotState();
}

class _DashItemSlotState extends State<DashItemSlot>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Drives both the roll cycle and the lock-in punch.
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
  );

  late final AnimationController _punch = AnimationController(
    vsync: this,
    duration: DashMotion.hero,
  );

  int _rollIndex = 0;

  bool _synced = false;

  @override
  void initState() {
    super.initState();
    _roll.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _rollIndex++);
        _roll.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _sync reads DashMotionScope, so it cannot run before dependencies are
    // available.
    if (_synced) return;
    _synced = true;
    _sync(null);
  }

  @override
  void didUpdateWidget(DashItemSlot old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _sync(old.state);
  }

  void _sync(ItemSlotState? previous) {
    switch (widget.state) {
      case ItemSlotState.rolling:
        _pulse.stop();
        if (!_roll.isAnimating) _roll.forward(from: 0);
      case ItemSlotState.ready:
        _roll.stop();
        // Landing on an item punches once, then settles into a slow pulse.
        if (previous == ItemSlotState.rolling) _punch.forward(from: 0);
        if (DashMotionScope.of(context)) _pulse.repeat(reverse: true);
      case ItemSlotState.empty:
      case ItemSlotState.cooldown:
        _roll.stop();
        _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _roll.dispose();
    _punch.dispose();
    super.dispose();
  }

  RaceItem get _displayed => widget.state == ItemSlotState.rolling
      ? RaceItem.values[_rollIndex % RaceItem.values.length]
      : widget.item ?? RaceItem.turboCell;

  @override
  Widget build(BuildContext context) {
    final ready = widget.state == ItemSlotState.ready;
    final has = widget.state != ItemSlotState.empty;

    return GestureDetector(
      onTap: ready ? widget.onUse : null,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: ready,
        label: ready
            ? 'Item ready: ${widget.item?.label ?? ''}'
            : 'Item slot ${widget.state.name}',
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _roll, _punch]),
          builder: (context, _) {
            final pulse = ready ? 1 + _pulse.value * 0.04 : 1.0;
            final punch = _punch.isAnimating
                ? 1 + math.sin(_punch.value * math.pi) * 0.15
                : 1.0;
            final tint = has ? _displayed.tint : DashColors.stroke;

            return Transform.scale(
              scale: pulse * punch,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // No BackdropFilter: this slot is on screen and
                    // repainting (the pulse/roll/punch animations) for the
                    // whole race — see _HudPill's doc comment in
                    // dash_game_hud.dart for why a blurred backdrop there is
                    // an Android frame-time cost, not just a style choice.
                    ClipRRect(
                      borderRadius: DashRadius.lgAll,
                      child: Container(
                        decoration: BoxDecoration(
                          color: DashColors.bgBase.withValues(alpha: 0.9),
                          borderRadius: DashRadius.lgAll,
                          border: Border.all(
                            color: has
                                ? tint.withValues(alpha: 0.9)
                                : DashColors.stroke,
                            width: 2,
                          ),
                          boxShadow: ready
                              ? [
                                  DashElevation.glow(
                                    tint,
                                    opacity: 0.25 + _pulse.value * 0.35,
                                    blur: 22,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                    if (widget.state == ItemSlotState.empty)
                      CustomPaint(
                        painter: _DashedRingPainter(
                          color: DashColors.textTertiary.withValues(alpha: 0.4),
                        ),
                      )
                    else
                      Center(
                        child: ImageFiltered(
                          enabled: widget.state == ItemSlotState.rolling,
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 1.6,
                            sigmaY: 1.6,
                          ),
                          child: Opacity(
                            opacity: widget.state == ItemSlotState.cooldown
                                ? 0.4
                                : 1,
                            child: DashIcon(
                              _displayed.icon,
                              size: widget.size * 0.5,
                              color: DashColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    if (widget.state == ItemSlotState.cooldown)
                      CustomPaint(
                        painter: _CooldownSweepPainter(
                          progress: widget.cooldown,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(9),
      const Radius.circular(12),
    );
    // Walk the outline, drawing only alternate segments.
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

class _CooldownSweepPainter extends CustomPainter {
  const _CooldownSweepPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    canvas.drawArc(
      (Offset.zero & size).deflate(3),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      true,
      Paint()..color = DashColors.bgBase.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_CooldownSweepPainter old) => old.progress != progress;
}
