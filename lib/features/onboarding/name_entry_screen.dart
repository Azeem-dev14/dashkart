import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';

/// First-launch-only screen: asks for a name, then never shows again on this
/// device — gated by [PlayerState.needsOnboarding].
class NameEntryScreen extends ConsumerStatefulWidget {
  const NameEntryScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends ConsumerState<NameEntryScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _focus.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _continue() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    _dismissKeyboard();
    ref.read(playerProvider).completeOnboarding(name);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    final margins = DashSafeMargins.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismissKeyboard,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const BrawlLobbyBackdrop(),

          // Centered slanted card modal matching Brawl Stars style in golden-yellow
          Center(
            child: _SlantedNameCard(
              controller: _controller,
              focusNode: _focus,
              onSubmitted: _dismissKeyboard,
              compact: compact,
            ),
          ),

          // Top-right hero action button: visible at all times, never obscured by keyboard
          Positioned(
            right: margins.right,
            top: margins.top,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                final canContinue = value.text.trim().isNotEmpty;
                return DashRaceButton(
                  label: 'CONTINUE',
                  compact: compact,
                  glow: canContinue,
                  enabled: canContinue,
                  onPressed: canContinue ? _continue : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Slanted dialog card container in golden-yellow arcade style.
class _SlantedNameCard extends StatelessWidget {
  const _SlantedNameCard({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.compact,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final bool compact;

  static const _skewX = -0.09;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 420.0 : 480.0;
    final cardRadius = compact ? 12.0 : 10.0;

    return Transform(
      transform: Matrix4.skewX(_skewX),
      alignment: Alignment.center,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: DashColors.pureBlack, width: 3.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              offset: Offset(0, 6),
              blurRadius: 0,
            ),
          ],
          color: const Color(0xFFA25128), // 3D burnt-orange bevel bottom
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius - 3.5),
          child: Stack(
            children: [
              // Golden-yellow card face
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 8.0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFDE00), // bright yellow top
                        Color(0xFFF7BD00), // rich golden yellow
                        Color(0xFFEAA600), // warm amber
                        Color(0xFFDE9400), // deep amber bottom
                      ],
                      stops: [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Crisp divider line between yellow face and bottom bevel
              Positioned(
                left: 0,
                right: 0,
                bottom: 8.0,
                height: 1.5,
                child: Container(color: const Color(0x44000000)),
              ),

              // Top bright specular sheen highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3.0,
                child: Container(
                  color: const Color(0xFFFFF780).withValues(alpha: 0.95),
                ),
              ),

              // Content inside card
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 22.0 : 28.0,
                  compact ? 16.0 : 20.0,
                  compact ? 22.0 : 28.0,
                  (compact ? 16.0 : 20.0) + 8.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header text: Counter-skewed so text reads strictly upright
                    Transform(
                      transform: Matrix4.skewX(-_skewX),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BrawlInkText(
                            'WHAT SHOULD WE CALL YOU?',
                            fontSize: compact ? 19.0 : 22.0,
                            weight: BrawlInkWeight.heavy,
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'CHOOSE YOUR RACER NAME',
                            style: TextStyle(
                              fontFamily: 'LilitaOne',
                              fontSize: compact ? 11.0 : 12.0,
                              letterSpacing: 0.6,
                              color: const Color(0xFF4A2500),
                              shadows: const [
                                Shadow(
                                  color: Color(0x33FFFFFF),
                                  offset: Offset(0, 1.0),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: compact ? 14.0 : 18.0),

                    // Slanted Text Input Field (shares card's skew)
                    _SlantedInputField(
                      controller: controller,
                      focusNode: focusNode,
                      onSubmitted: onSubmitted,
                      compact: compact,
                      parentSkew: _skewX,
                    ),

                    const SizedBox(height: 8.0),

                    // Bottom helper and counter row
                    Transform(
                      transform: Matrix4.skewX(-_skewX),
                      alignment: Alignment.center,
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (context, value, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '★ VISIBLE TO OTHER RACERS',
                                style: TextStyle(
                                  fontFamily: 'LilitaOne',
                                  fontSize: compact ? 10.0 : 11.0,
                                  letterSpacing: 0.4,
                                  color: const Color(0xFF5A2E00),
                                ),
                              ),
                              Text(
                                '${value.text.length}/18',
                                style: TextStyle(
                                  fontFamily: 'LilitaOne',
                                  fontSize: compact ? 10.5 : 11.5,
                                  letterSpacing: 0.5,
                                  color: const Color(0xFF422100),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A slanted text input field with sunken dark background, cyan cursor, and upright typography.
class _SlantedInputField extends StatelessWidget {
  const _SlantedInputField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.compact,
    required this.parentSkew,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final bool compact;
  final double parentSkew;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 52.0 : 60.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF081220),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: DashColors.pureBlack, width: 2.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top inner shadow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3.0,
            child: Container(color: const Color(0x33000000)),
          ),

          // Text content: Counter-skewed so text and cursor stay upright
          Positioned.fill(
            child: Transform(
              transform: Matrix4.skewX(-parentSkew),
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14.0 : 18.0,
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (context, value, _) {
                          if (value.text.isNotEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            'ENTER NAME...',
                            style: TextStyle(
                              fontFamily: 'LilitaOne',
                              fontSize: compact ? 20.0 : 24.0,
                              letterSpacing: 0.6,
                              color: const Color(0x38FFFFFF),
                            ),
                          );
                        },
                      ),
                      EditableText(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: compact ? 20.0 : 24.0,
                          letterSpacing: 0.6,
                          color: DashColors.textPrimary,
                        ),
                        cursorColor: const Color(0xFF3DF2FF),
                        cursorWidth: 3.0,
                        backgroundCursorColor: DashColors.pureBlack,
                        selectionColor: const Color(0x553DF2FF),
                        onSubmitted: (_) {
                          focusNode.unfocus();
                          SystemChannels.textInput.invokeMethod(
                            'TextInput.hide',
                          );
                          onSubmitted();
                        },
                        inputFormatters: [LengthLimitingTextInputFormatter(18)],
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
  }
}
