import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_icon.dart';

/// How thick a [BrawlInkText]'s outline reads — bigger text wants more
/// shadow passes or the outline looks thin next to the glyph strokes.
enum BrawlInkWeight { heavy, medium, light }

/// LilitaOne text with a hand-built cartoon ink outline: several small,
/// hard-edged [Shadow]s stacked behind the fill rather than a real stroke.
///
/// This is the Main Menu / Kart Detail screens' signature text treatment —
/// was six-plus copies of the same `shadows: const [Shadow(...), ...]` list
/// scattered across those two files with the offsets very slightly
/// (accidentally) different between copies. One widget, three weights,
/// instead.
///
/// Not the same technique as [DashOutlinedText] (a real stroke via
/// `TextPainter`) — that remains the right choice for the rest of the app's
/// UI; this one is specifically the Brawl-style screens' look.
class BrawlInkText extends StatelessWidget {
  const BrawlInkText(
    this.text, {
    super.key,
    required this.fontSize,
    this.weight = BrawlInkWeight.medium,
    this.color = DashColors.textPrimary,
    this.outlineColor = DashColors.pureBlack,
    this.fontStyle,
    this.letterSpacing = 0.5,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final double fontSize;
  final BrawlInkWeight weight;
  final Color color;
  final Color outlineColor;
  final FontStyle? fontStyle;
  final double letterSpacing;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  List<Shadow> get _shadows => switch (weight) {
    BrawlInkWeight.heavy => [
      Shadow(color: outlineColor, offset: const Offset(2.0, 2.0)),
      Shadow(color: outlineColor, offset: const Offset(-1.5, 1.5)),
      Shadow(color: outlineColor, offset: const Offset(1.5, -1.5)),
      Shadow(color: outlineColor, offset: const Offset(-1.5, -1.5)),
      Shadow(color: outlineColor, offset: const Offset(0, 3.0)),
    ],
    BrawlInkWeight.medium => [
      Shadow(color: outlineColor, offset: const Offset(1.5, 1.5)),
      Shadow(color: outlineColor, offset: const Offset(-1.5, 1.5)),
      Shadow(
        color: outlineColor,
        offset: const Offset(0, 2.5),
        blurRadius: 1.0,
      ),
    ],
    BrawlInkWeight.light => [
      Shadow(color: outlineColor, offset: const Offset(1.0, 1.0)),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'LilitaOne',
        fontSize: fontSize,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        color: color,
        shadows: _shadows,
      ),
    );
  }
}

/// Brawl Stars-style header text pairing a white label with a cyan count
/// (e.g. "KARTS 1/3" or "BRAWLERS 4/41"), rendered with a solid ink outline
/// and 3D downward drop-shadow block.
class BrawlCountTitle extends StatelessWidget {
  const BrawlCountTitle({
    super.key,
    required this.title,
    required this.count,
    this.fontSize,
    this.titleColor = DashColors.textPrimary,
    this.countColor = const Color(0xFF54C7FF),
    this.outlineColor = DashColors.pureBlack,
    this.letterSpacing = 0.5,
  });

  final String title;
  final String count;
  final double? fontSize;
  final Color titleColor;
  final Color countColor;
  final Color outlineColor;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    final size = fontSize ?? (compact ? 20.0 : 24.0);
    final strokeWidth = size * 0.16;
    final depth = (size * 0.12).clamp(2.5, 4.0);

    final strokeStyle = TextStyle(
      fontFamily: 'LilitaOne',
      fontSize: size,
      letterSpacing: letterSpacing,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = outlineColor,
    );

    final fullText = '${title.toUpperCase()} $count';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 3D downward block extrusion
        for (final dy in [depth, depth * 0.66, depth * 0.33])
          Transform.translate(
            offset: Offset(0, dy),
            child: ExcludeSemantics(child: Text(fullText, style: strokeStyle)),
          ),
        // Primary outline stroke
        ExcludeSemantics(child: Text(fullText, style: strokeStyle)),
        // Fill text on top
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'LilitaOne',
              fontSize: size,
              letterSpacing: letterSpacing,
            ),
            children: [
              TextSpan(
                text: '${title.toUpperCase()} ',
                style: TextStyle(color: titleColor),
              ),
              TextSpan(
                text: count,
                style: TextStyle(color: countColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Brawl Stars-style header text for single titles (e.g. "SETTINGS", "SHOP",
/// "MULTIPLAYER"), rendered with a solid ink outline and 3D downward drop-shadow block.
class BrawlTitleText extends StatelessWidget {
  const BrawlTitleText(
    this.title, {
    super.key,
    this.fontSize,
    this.color = DashColors.textPrimary,
    this.outlineColor = DashColors.pureBlack,
    this.letterSpacing = 0.5,
  });

  final String title;
  final double? fontSize;
  final Color color;
  final Color outlineColor;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    final size = fontSize ?? (compact ? 20.0 : 24.0);
    final strokeWidth = size * 0.16;
    final depth = (size * 0.12).clamp(2.5, 4.0);

    final strokeStyle = TextStyle(
      fontFamily: 'LilitaOne',
      fontSize: size,
      letterSpacing: letterSpacing,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = outlineColor,
    );

    final upper = title.toUpperCase();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        for (final dy in [depth, depth * 0.66, depth * 0.33])
          Transform.translate(
            offset: Offset(0, dy),
            child: ExcludeSemantics(child: Text(upper, style: strokeStyle)),
          ),
        ExcludeSemantics(child: Text(upper, style: strokeStyle)),
        Text(
          upper,
          style: TextStyle(
            fontFamily: 'LilitaOne',
            fontSize: size,
            letterSpacing: letterSpacing,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Multi-span LilitaOne text with a solid ink outline and 3D downward drop shadow.
class BrawlOutlinedRichText extends StatelessWidget {
  const BrawlOutlinedRichText({
    super.key,
    required this.spans,
    required this.fontSize,
    this.textAlign = TextAlign.center,
    this.outlineColor = DashColors.pureBlack,
    this.strokeWidth,
    this.shadowDepth,
    this.letterSpacing = 0.5,
  });

  final List<InlineSpan> spans;
  final double fontSize;
  final TextAlign textAlign;
  final Color outlineColor;
  final double? strokeWidth;
  final double? shadowDepth;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final sWidth = strokeWidth ?? (fontSize * 0.16).clamp(2.4, 4.5);
    final depth = shadowDepth ?? (fontSize * 0.14).clamp(2.0, 3.8);

    final strokeStyle = TextStyle(
      fontFamily: 'LilitaOne',
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = outlineColor,
    );

    final buffer = StringBuffer();
    void extractText(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text != null) buffer.write(span.text);
        span.children?.forEach(extractText);
      }
    }

    spans.forEach(extractText);
    final fullText = buffer.toString();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        for (final dy in [depth, depth * 0.66, depth * 0.33])
          Transform.translate(
            offset: Offset(0, dy),
            child: ExcludeSemantics(
              child: Text(fullText, textAlign: textAlign, style: strokeStyle),
            ),
          ),
        ExcludeSemantics(
          child: Text(fullText, textAlign: textAlign, style: strokeStyle),
        ),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'LilitaOne',
              fontSize: fontSize,
              letterSpacing: letterSpacing,
            ),
            children: spans,
          ),
          textAlign: textAlign,
        ),
      ],
    );
  }
}

/// Circular green checkmark badge displayed in the top-right of an equipped
/// Brawl-style card.
class BrawlEquippedTickBadge extends StatelessWidget {
  const BrawlEquippedTickBadge({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 32.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DashColors.pureBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: DashColors.pureBlack,
            offset: Offset(0, 2.5),
            blurRadius: 0,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5CF32E), Color(0xFF22AA08)],
        ),
      ),
      child: Center(
        child: DashIcon(
          DashIcons.checkmark,
          size: compact ? DashIconSize.sm : DashIconSize.md,
          color: DashColors.textPrimary,
        ),
      ),
    );
  }
}

/// Yellow cartoon arcade button used on unequipped Brawl-style selection cards
/// (e.g. "SELECT" or "LOCKED").
class BrawlCardYellowButton extends StatelessWidget {
  const BrawlCardYellowButton({
    super.key,
    required this.label,
    required this.compact,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: compact ? 38.0 : 44.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 8.0 : 6.0),
        border: Border.all(color: DashColors.pureBlack, width: 2.6),
        boxShadow: const [
          BoxShadow(
            color: DashColors.pureBlack,
            offset: Offset(0, 3.5),
            blurRadius: 0,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFDD00), Color(0xFFFFAE00)],
        ),
      ),
      child: Center(
        child: Transform(
          transform: Matrix4.skewX(0.09),
          alignment: Alignment.center,
          child: BrawlOutlinedRichText(
            fontSize: compact ? 17.0 : 20.0,
            letterSpacing: 0.5,
            spans: [
              TextSpan(
                text: label,
                style: const TextStyle(color: DashColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
