import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_brawl_ink_text.dart';

/// Colour families for [BrawlActionButton]; the same palette the menu's
/// cards and PLAY button use, so every confirm/cancel looks like one game.
enum BrawlButtonTone {
  green([Color(0xFF6BF26B), Color(0xFF1DB32B)], Color(0xFF0B6B16)),
  yellow([Color(0xFFFFE04A), Color(0xFFF59E00)], Color(0xFF8F5200)),
  red([Color(0xFFFF6A82), Color(0xFFE0143A)], Color(0xFF820A20)),
  blue([Color(0xFF5CC8FF), Color(0xFF1479E0)], Color(0xFF0A3F8A)),
  grey([Color(0xFF8E97B8), Color(0xFF5A6285)], Color(0xFF2E3454));

  const BrawlButtonTone(this.gradient, this.bevel);

  final List<Color> gradient;
  final Color bevel;
}

/// The chunky action button: gradient face, black outline, a hard coloured
/// bevel underneath that the face sinks into when pressed, ink-outlined
/// label. A null [onPressed] greys it out and stops it responding.
class BrawlActionButton extends StatefulWidget {
  const BrawlActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = BrawlButtonTone.green,
    this.height = 50,
    this.fontSize = 19,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final BrawlButtonTone tone;
  final double height;
  final double fontSize;

  /// Null stretches to the available width.
  final double? width;

  @override
  State<BrawlActionButton> createState() => _BrawlActionButtonState();
}

class _BrawlActionButtonState extends State<BrawlActionButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final tone = enabled ? widget.tone : BrawlButtonTone.grey;
    final pressed = _down && enabled;
    final depth = pressed ? 1.0 : 4.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.label,
        child: Padding(
          padding: EdgeInsets.only(top: 4 - depth, bottom: 4),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: DashColors.pureBlack, width: 2.6),
              boxShadow: [
                BoxShadow(
                  color: tone.bevel,
                  offset: Offset(0, depth),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0x66000000),
                  offset: Offset(0, depth + 2),
                  blurRadius: 0,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: tone.gradient,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: widget.height * 0.45,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      color: Color(0x35FFFFFF),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: BrawlInkText(
                    widget.label,
                    fontSize: widget.fontSize,
                    weight: BrawlInkWeight.heavy,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
