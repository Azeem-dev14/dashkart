import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/features/gamepad/pad_session.dart';

/// What the phone shows after scanning the game's QR code: a full-screen
/// controller that mirrors the race HUD's controls and sends them to the game
/// over [PadClient].
class ControllerScreen extends StatefulWidget {
  const ControllerScreen({
    super.key,
    required this.code,
    required this.firebaseReady,
  });

  final String code;
  final bool firebaseReady;

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  PadClient? _pad;
  String? _error;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    setState(() => _error = null);
    if (!widget.firebaseReady) {
      setState(() => _error = 'Controller isn’t set up on this server yet.');
      return;
    }
    try {
      final pad = await PadClient.join(widget.code.toUpperCase());
      if (!mounted) {
        pad.leave();
        return;
      }
      setState(() => _pad = pad);
    } on PadException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  void dispose() {
    _pad?.leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = _pad;
    return ColoredBox(
      color: DashColors.bgBase,
      child: SafeArea(
        child: pad != null
            ? _Pad(pad: pad, code: widget.code)
            : _Status(message: _error, onRetry: _error == null ? null : _join),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DashSpace.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DashWordmark(fontSize: 36),
            const SizedBox(height: DashSpace.x4),
            Text(
              message ?? 'Connecting…',
              style: DashType.body,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DashSpace.x4),
              DashButton(label: 'Try again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pad extends StatelessWidget {
  const _Pad({required this.pad, required this.code});

  final PadClient pad;
  final String code;

  @override
  Widget build(BuildContext context) {
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    // The controls are laid out for two thumbs on a wide screen, and browsers
    // don't reliably honour an orientation lock, so ask instead of squeezing.
    if (portrait) {
      return const _Status(
        message: 'Rotate your phone sideways to drive.',
        onRetry: null,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(DashSpace.x4),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: DashSteering(onSteer: pad.setSteer),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Text('CONNECTED · $code', style: DashType.label),
          ),
          Align(
            alignment: Alignment.center,
            child: DashDriveButton(
              shape: 'button_circle_wide',
              icon: DashIcons.item,
              semanticLabel: 'Use item',
              size: DashTouch.accelerate,
              tint: DashColors.yellow.s300,
              glowColor: DashColors.yellow.s500,
              onChanged: (down) {
                if (down) pad.pressItem();
              },
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: pad.pressPause,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(DashSpace.x3),
                child: DashIcon(DashIcons.pause, size: DashIconSize.xl),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DashDriveButton(
                  shape: 'button_bean',
                  icon: DashIcons.drift,
                  semanticLabel: 'Drift',
                  size: DashTouch.drift,
                  tint: DashColors.orange.s300,
                  glowColor: DashColors.orange.s400,
                  onChanged: pad.setDrift,
                ),
                const SizedBox(height: DashSpace.x2),
                DashDriveButton(
                  shape: 'button_circle_wide',
                  icon: DashIcons.pedalBrake,
                  semanticLabel: 'Brake',
                  size: DashTouch.accelerate,
                  tint: const Color(0xFFFF9AA8),
                  glowColor: DashColors.racingRed,
                  onChanged: pad.setBrake,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
