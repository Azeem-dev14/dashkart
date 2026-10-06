import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/features/multiplayer/multiplayer_service.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/core/scaffold/dash_brawl_screen.dart';

/// Host-or-join lobby for a live 1v1 race.
///
/// Both sides land here. [onSessionReady] fires the instant the room's
/// status flips to racing — for the host that is their own "Start Race" tap;
/// for the guest it is the host doing that, observed over the same stream.
/// Either way the caller gets an identical callback and pushes [RaceScreen]
/// the same way for both.
class MultiplayerScreen extends ConsumerStatefulWidget {
  const MultiplayerScreen({
    super.key,
    required this.onBack,
    required this.onSessionReady,
  });

  final VoidCallback onBack;
  final ValueChanged<MultiplayerSession> onSessionReady;

  @override
  ConsumerState<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

enum _Mode { choose, joinCode, lobby }

class _MultiplayerScreenState extends ConsumerState<MultiplayerScreen> {
  _Mode _mode = _Mode.choose;
  MultiplayerSession? _session;
  StreamSubscription<void>? _sub;
  String? _error;
  bool _busy = false;

  /// Set once [onSessionReady] has fired, so [dispose] leaves the session's
  /// lifetime to [RaceScreen] instead of tearing it down out from under it.
  bool _navigated = false;

  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  @override
  void dispose() {
    _sub?.cancel();
    if (!_navigated) {
      _session?.leave();
      _session?.dispose();
    }
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _host(PlayerState player) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await MultiplayerSession.host(
        name: player.name,
        kartId: player.kart.id,
        trackId: player.track.id,
      );
      _attach(session);
    } on MultiplayerException catch (e) {
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not reach the server. Check your connection.';
        _busy = false;
      });
    }
  }

  Future<void> _join(PlayerState player) async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await MultiplayerSession.join(
        code: code,
        name: player.name,
        kartId: player.kart.id,
      );
      _attach(session);
    } on MultiplayerException catch (e) {
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not reach the server. Check your connection.';
        _busy = false;
      });
    }
  }

  void _attach(MultiplayerSession session) {
    _session = session;
    _sub = session.onUpdate.listen((_) {
      if (!mounted) return;
      if (session.status == RoomStatus.racing && !_navigated) {
        _navigated = true;
        widget.onSessionReady(session);
        return;
      }
      setState(() {});
    });
    setState(() {
      _mode = _Mode.lobby;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final compact = DashBreakpoint.of(context).isCompact;
    return DashBrawlScreen(
      title: 'Multiplayer',
      onBack: widget.onBack,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: compact ? 4.0 : 12.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: switch (_mode) {
              _Mode.choose => _ChooseView(
                busy: _busy,
                error: _error,
                onHost: () => _host(player),
                onJoin: () => setState(() {
                  _mode = _Mode.joinCode;
                  _error = null;
                }),
              ),
              _Mode.joinCode => _JoinCodeView(
                controller: _codeController,
                focusNode: _codeFocus,
                busy: _busy,
                error: _error,
                onJoin: () => _join(player),
                onBack: () => setState(() {
                  _mode = _Mode.choose;
                  _error = null;
                }),
              ),
              _Mode.lobby => _LobbyView(
                session: _session!,
                myName: player.name,
                onReady: () => _session!.setReady(true),
                onStart: _session!.role == MultiplayerRole.host
                    ? _session!.startRace
                    : null,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _ChooseView extends StatelessWidget {
  const _ChooseView({
    required this.busy,
    required this.error,
    required this.onHost,
    required this.onJoin,
  });

  final bool busy;
  final String? error;
  final VoidCallback onHost;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Race a friend head-to-head. Host a room and share the code, or '
          'join one someone else started.',
          style: DashType.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DashSpace.x6),
        DashButton(
          label: 'Host a Race',
          icon: DashIcons.steeringWheel,
          variant: DashButtonVariant.turbo,
          expand: true,
          glow: true,
          loading: busy,
          onPressed: busy ? null : onHost,
        ),
        const SizedBox(height: DashSpace.x3),
        DashButton(
          label: 'Join a Race',
          icon: DashIcons.key,
          variant: DashButtonVariant.ghost,
          expand: true,
          onPressed: busy ? null : onJoin,
        ),
        if (error != null) ...[
          const SizedBox(height: DashSpace.x4),
          Text(
            error!,
            style: DashType.bodySm.copyWith(color: DashColors.racingRed),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _JoinCodeView extends StatelessWidget {
  const _JoinCodeView({
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.error,
    required this.onJoin,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final String? error;
  final VoidCallback onJoin;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Enter the room code', style: DashType.h3),
        const SizedBox(height: DashSpace.x5),
        _CodeField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: onJoin,
        ),
        const SizedBox(height: DashSpace.x5),
        DashButton(
          label: 'Join',
          icon: DashIcons.play,
          variant: DashButtonVariant.turbo,
          expand: true,
          loading: busy,
          onPressed: busy ? null : onJoin,
        ),
        const SizedBox(height: DashSpace.x3),
        DashButton(
          label: 'Back',
          variant: DashButtonVariant.ghost,
          expand: true,
          onPressed: busy ? null : onBack,
        ),
        if (error != null) ...[
          const SizedBox(height: DashSpace.x4),
          Text(
            error!,
            style: DashType.bodySm.copyWith(color: DashColors.racingRed),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// A 5-character room code entry. Raw [EditableText], not a Material
/// [TextField] — DashKart composes every control from tokens rather than
/// pulling in Material chrome; see [DashSlider] for the same choice.
class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: DashSpace.x5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DashColors.surfaceSunken,
        borderRadius: DashRadius.mdAll,
        border: Border.all(color: DashColors.stroke, width: DashStroke.thick),
      ),
      child: EditableText(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        maxLines: 1,
        style: DashType.lap.copyWith(fontSize: 28, letterSpacing: 10),
        cursorColor: DashColors.textPrimary,
        backgroundCursorColor: DashColors.surfaceSunken,
        selectionColor: DashColors.textTertiary.withValues(alpha: 0.4),
        onSubmitted: (_) => onSubmitted(),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
          LengthLimitingTextInputFormatter(5),
          TextInputFormatter.withFunction(
            (oldValue, newValue) =>
                newValue.copyWith(text: newValue.text.toUpperCase()),
          ),
        ],
      ),
    );
  }
}

class _LobbyView extends StatelessWidget {
  const _LobbyView({
    required this.session,
    required this.myName,
    required this.onReady,
    required this.onStart,
  });

  final MultiplayerSession session;
  final String myName;
  final VoidCallback onReady;

  /// Non-null only for the host — the guest has no Start button, they wait.
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    final isHost = session.role == MultiplayerRole.host;
    final opponent = session.opponent;

    return DashCard(
      variant: DashCardVariant.raised,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DashSpace.x4 : DashSpace.x5,
        vertical: compact ? DashSpace.x3 : DashSpace.x5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text('ROOM CODE', style: DashType.label),
                SizedBox(height: compact ? DashSpace.x1 : DashSpace.x2),
                DashOutlinedText(
                  session.roomCode,
                  style: DashType.lap.copyWith(
                    fontSize: compact ? 30 : 40,
                    letterSpacing: compact ? 6 : 10,
                  ),
                ),
                SizedBox(height: compact ? 2 : DashSpace.x2),
                Text(
                  'Share this code with your friend',
                  style: DashType.bodySm,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? DashSpace.x3 : DashSpace.x6),
          _RacerRow(name: myName, tag: 'YOU', ready: true, compact: compact),
          SizedBox(height: compact ? DashSpace.x2 : DashSpace.x3),
          _RacerRow(
            name: opponent.isPresent ? opponent.name : null,
            tag: isHost ? 'GUEST' : 'HOST',
            ready: opponent.isPresent && (isHost ? opponent.ready : true),
            compact: compact,
          ),
          SizedBox(height: compact ? DashSpace.x3 : DashSpace.x6),
          if (isHost)
            DashButton(
              label: 'Start Race',
              icon: DashIcons.play,
              variant: DashButtonVariant.turbo,
              expand: true,
              glow: opponent.ready,
              size: compact ? DashButtonSize.sm : DashButtonSize.md,
              onPressed: opponent.isPresent && opponent.ready ? onStart : null,
            )
          else
            DashButton(
              label: session.me.ready ? 'Waiting for host…' : 'Ready',
              icon: DashIcons.checkmark,
              variant: session.me.ready
                  ? DashButtonVariant.ghost
                  : DashButtonVariant.success,
              expand: true,
              size: compact ? DashButtonSize.sm : DashButtonSize.md,
              onPressed: session.me.ready ? null : onReady,
            ),
        ],
      ),
    );
  }
}

class _RacerRow extends StatelessWidget {
  const _RacerRow({
    required this.name,
    required this.tag,
    required this.ready,
    this.compact = false,
  });

  /// Null means the slot is still empty.
  final String? name;
  final String tag;
  final bool ready;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 40 : 52,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DashSpace.x3 : DashSpace.x4,
      ),
      decoration: BoxDecoration(
        color: DashColors.surfaceSunken,
        borderRadius: DashRadius.mdAll,
        border: Border.all(color: DashColors.stroke),
      ),
      child: Row(
        children: [
          Text(tag, style: DashType.label),
          SizedBox(width: compact ? DashSpace.x2 : DashSpace.x3),
          Expanded(
            child: Text(
              name ?? 'Waiting for a racer…',
              style: DashType.body.copyWith(
                color: name == null
                    ? DashColors.textTertiary
                    : DashColors.textPrimary,
                fontStyle: name == null ? FontStyle.italic : FontStyle.normal,
                fontSize: compact ? 13 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (name != null && ready)
            DashIcon(
              DashIcons.checkmark,
              size: DashIconSize.sm,
              color: DashColors.neonGreen,
            ),
        ],
      ),
    );
  }
}
