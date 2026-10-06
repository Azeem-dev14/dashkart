import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/features/gamepad/pad_session.dart';

/// The web game's front door: scan this with a phone and the phone becomes
/// the controller.
///
/// Advances on its own a moment after a phone connects. [onContinue] also
/// fires from the skip link, for playing with the mouse and keyboard menus —
/// in which case the race HUD keeps its on-screen touch controls.
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  PadHost? _host;
  String? _error;
  Timer? _advance;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => _error = null);
    try {
      // A phone that is already attached (the player came back to this
      // screen) keeps its session rather than minting a new code.
      final host = ref.read(padHostProvider) ?? await PadHost.create();
      if (!mounted) {
        if (ref.read(padHostProvider) != host) host.dispose();
        return;
      }
      ref.read(padHostProvider.notifier).state = host;
      host.addListener(_onHostChange);
      setState(() => _host = host);
      _onHostChange();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  void _onHostChange() {
    if (!mounted) return;
    setState(() {});
    if (_host?.connected == true) {
      _advance ??= Timer(const Duration(milliseconds: 1200), () {
        if (mounted) widget.onContinue();
      });
    } else {
      _advance?.cancel();
      _advance = null;
    }
  }

  @override
  void dispose() {
    _advance?.cancel();
    _host?.removeListener(_onHostChange);
    super.dispose();
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final host = _host;
    final connected = host?.connected ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        const BrawlLobbyBackdrop(),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DashSpace.x6),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: DashSpace.x8,
                runSpacing: DashSpace.x6,
                children: [
                  _QrPanel(
                    link: host?.link.toString(),
                    connected: connected,
                    error: _error,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DashWordmark(fontSize: 48),
                        const SizedBox(height: DashSpace.x5),
                        Text(
                          connected ? 'CONTROLLER READY' : 'GRAB YOUR PHONE',
                          style: DashType.h1,
                        ),
                        const SizedBox(height: DashSpace.x3),
                        Text(
                          connected
                              ? 'Your phone is the controller. Starting…'
                              : 'Scan the code with your camera. It opens a '
                                    'controller in your phone’s browser — '
                                    'no app to install.',
                          style: DashType.body,
                        ),
                        if (host != null && !connected) ...[
                          const SizedBox(height: DashSpace.x5),
                          Text('OR OPEN', style: DashType.label),
                          const SizedBox(height: DashSpace.x1),
                          GestureDetector(
                            onTap: () => _copy(host.link.toString()),
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              _copied ? 'Copied!' : host.link.toString(),
                              style: DashType.bodySm,
                            ),
                          ),
                          const SizedBox(height: DashSpace.x2),
                          Text('CODE ${host.code}', style: DashType.h3),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: DashSpace.x5),
                          DashButton(label: 'Try again', onPressed: _open),
                        ],
                        const SizedBox(height: DashSpace.x6),
                        DashButton(
                          label: 'Play without a phone',
                          variant: DashButtonVariant.ghost,
                          onPressed: widget.onContinue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({
    required this.link,
    required this.connected,
    required this.error,
  });

  final String? link;
  final bool connected;
  final String? error;

  static const _size = 240.0;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (link == null) {
      child = Center(
        child: Text(
          error ?? 'Opening a room…',
          style: DashType.body.copyWith(color: DashColors.darkNavy),
          textAlign: TextAlign.center,
        ),
      );
    } else if (connected) {
      child = const Center(
        child: DashIcon(
          DashIcons.checkmark,
          size: 96,
          color: DashColors.darkNavy,
        ),
      );
    } else {
      child = QrImageView(
        data: link!,
        size: _size,
        padding: EdgeInsets.zero,
        backgroundColor: const Color(0xFFFFFFFF),
      );
    }

    // QR scanners need a light quiet zone around dark modules regardless of
    // theme, so the panel stays white even on the dark backdrop.
    return Container(
      width: _size + DashSpace.x6 * 2,
      height: _size + DashSpace.x6 * 2,
      padding: const EdgeInsets.all(DashSpace.x6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: DashRadius.xlAll,
        boxShadow: DashElevation.dialog,
      ),
      child: child,
    );
  }
}
