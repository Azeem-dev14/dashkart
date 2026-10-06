import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';

/// Comic-style text: a thick ink stroke behind a solid fill.
///
/// The single biggest thing that reads as "kart racer UI" rather than
/// "generic mobile game" — countdown numbers, HUD readouts, and big titles
/// are all cut-out stickers, never flat type. The fill is a real [Text]
/// widget (so semantics and `find.text` finders behave normally); the stroke
/// behind it is painted straight from a [TextPainter] rather than a second
/// [Text], since Flutter has no native text stroke and two stacked [Text]
/// widgets with identical data would make every button label match twice
/// under `find.text`.
class DashOutlinedText extends StatelessWidget {
  const DashOutlinedText(
    this.text, {
    super.key,
    required this.style,
    this.outlineColor = DashColors.ink,
    this.strokeWidth,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle style;
  final Color outlineColor;

  /// Defaults to ~9% of the font size — thick enough to read at a glance,
  /// thin enough not to swallow narrow glyphs.
  final double? strokeWidth;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final width = strokeWidth ?? (style.fontSize ?? 24) * 0.09;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _StrokePainter(
              text: text,
              style: style.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = width
                  ..strokeJoin = StrokeJoin.round
                  ..color = outlineColor,
                shadows: const [],
              ),
              textAlign: textAlign ?? TextAlign.start,
              textDirection: Directionality.of(context),
              maxLines: maxLines,
              overflow: overflow ?? TextOverflow.clip,
            ),
          ),
        ),
        Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          style: style,
        ),
      ],
    );
  }
}

/// Paints [text] with [style] at the same box the sibling fill [Text] lays
/// out to — same string, same style modulo the stroke paint, so the two
/// layers line up glyph-for-glyph.
class _StrokePainter extends CustomPainter {
  _StrokePainter({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.textDirection,
    required this.maxLines,
    required this.overflow,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      ellipsis: overflow == TextOverflow.ellipsis ? '…' : null,
    )..layout(maxWidth: size.width);

    final dx = switch (textAlign) {
      TextAlign.center => (size.width - painter.width) / 2,
      TextAlign.right || TextAlign.end => size.width - painter.width,
      _ => 0.0,
    };
    painter.paint(canvas, Offset(dx, 0));
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old.text != text ||
      old.style != style ||
      old.textAlign != textAlign ||
      old.maxLines != maxLines ||
      old.overflow != overflow;
}
