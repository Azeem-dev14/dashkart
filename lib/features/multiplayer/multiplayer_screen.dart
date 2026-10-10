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
              _Mode.lobby => MultiplayerLobby(
                roomCode: _session!.roomCode,
                isHost: _session!.role == MultiplayerRole.host,
                myName: player.name,
                meReady: _session!.me.ready,
                opponent: _session!.opponent,
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

/// The screen's one surface: a blue panel, so text sits on a controlled
/// ground instead of directly on the pale lobby backdrop, where the old
/// description was close to unreadable.
class _View extends StatelessWidget {
  const _View({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    return BrawlPanel(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 22,
        compact ? 14 : 20,
        compact ? 16 : 22,
        compact ? 16 : 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// A failure message, in the red every other error in the game uses.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DashSpace.x3),
      child: BrawlInkText(
        message,
        fontSize: 13,
        weight: BrawlInkWeight.medium,
        color: const Color(0xFFFF8A9A),
        textAlign: TextAlign.center,
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
    final compact = DashBreakpoint.of(context).isCompact;
    final height = compact ? 46.0 : 52.0;
    return _View(
      children: [
        BrawlInkText(
          'Race a friend head-to-head. Host a room and share the code, or '
          'join one someone else started.',
          fontSize: compact ? 13 : 14,
          weight: BrawlInkWeight.light,
          color: BrawlPanel.softText,
          textAlign: TextAlign.center,
          letterSpacing: 0.3,
        ),
        SizedBox(height: compact ? DashSpace.x4 : DashSpace.x5),
        BrawlActionButton(
          label: busy ? 'CREATING ROOM…' : 'HOST A RACE',
          height: height,
          onPressed: busy ? null : onHost,
        ),
        SizedBox(height: compact ? DashSpace.x2 : DashSpace.x3),
        BrawlActionButton(
          label: 'JOIN A RACE',
          tone: BrawlButtonTone.blue,
          height: height,
          onPressed: busy ? null : onJoin,
        ),
        if (error != null) _ErrorLine(error!),
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
    final compact = DashBreakpoint.of(context).isCompact;
    final height = compact ? 46.0 : 52.0;
    return _View(
      children: [
        Center(
          child: BrawlTitleText(
            'ENTER THE ROOM CODE',
            fontSize: compact ? 20 : 24,
          ),
        ),
        SizedBox(height: compact ? DashSpace.x3 : DashSpace.x4),
        _CodeField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: onJoin,
        ),
        SizedBox(height: compact ? DashSpace.x3 : DashSpace.x4),
        BrawlActionButton(
          label: busy ? 'JOINING…' : 'JOIN',
          height: height,
          onPressed: busy ? null : onJoin,
        ),
        SizedBox(height: compact ? DashSpace.x2 : DashSpace.x3),
        BrawlActionButton(
          label: 'BACK',
          tone: BrawlButtonTone.grey,
          height: height,
          onPressed: busy ? null : onBack,
        ),
        if (error != null) _ErrorLine(error!),
      ],
    );
  }
}

/// A 5-character room code entry. Raw [EditableText], not a Material
/// [TextField] — DashKart composes every control from tokens rather than
/// pulling in Material chrome; see [DashSlider] for the same choice.
///
/// Drawn as a sunken tray set into the panel: dark, black-bordered, with the
/// code in the same inked face as every other title.
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
        color: BrawlPanel.bevel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashColors.pureBlack, width: 3),
      ),
      child: EditableText(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        maxLines: 1,
        style: const TextStyle(
          fontFamily: 'LilitaOne',
          fontSize: 32,
          letterSpacing: 12,
          color: BrawlPanel.gold,
        ),
        cursorColor: BrawlPanel.gold,
        backgroundCursorColor: BrawlPanel.bevel,
        selectionColor: BrawlPanel.softText.withValues(alpha: 0.35),
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

/// The room before the race: the code to share, both players' slots, and the
/// one button that moves things on — Start for the host, Ready for the guest.
///
/// Takes plain values rather than a live session, so it can be laid out and
/// tested without a server behind it.
class MultiplayerLobby extends StatelessWidget {
  const MultiplayerLobby({
    super.key,
    required this.roomCode,
    required this.isHost,
    required this.myName,
    required this.meReady,
    required this.opponent,
    required this.onReady,
    required this.onStart,
  });

  final String roomCode;
  final bool isHost;
  final String myName;

  /// Whether this player has pressed Ready (only meaningful for the guest).
  final bool meReady;

  /// The other player's slot; empty until someone joins.
  final RacerTelemetry opponent;
  final VoidCallback onReady;

  /// Non-null only for the host — the guest has no Start button, they wait.
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    final height = compact ? 44.0 : 52.0;
    final canStart = opponent.isPresent && opponent.ready;

    return _View(
      children: [
        Center(
          child: BrawlInkText(
            'ROOM CODE',
            fontSize: compact ? 12 : 13,
            weight: BrawlInkWeight.heavy,
            color: BrawlPanel.softText,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: compact ? 2 : DashSpace.x1),
        Center(
          child: BrawlInkText(
            roomCode,
            fontSize: compact ? 34 : 44,
            weight: BrawlInkWeight.heavy,
            color: BrawlPanel.gold,
            letterSpacing: compact ? 8 : 12,
          ),
        ),
        Center(
          child: BrawlInkText(
            'Share this code with your friend',
            fontSize: compact ? 11 : 12,
            weight: BrawlInkWeight.light,
            color: BrawlPanel.softText,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: compact ? DashSpace.x3 : DashSpace.x4),
        _RacerRow(name: myName, tag: 'YOU', ready: true, compact: compact),
        SizedBox(height: compact ? DashSpace.x2 : DashSpace.x3),
        _RacerRow(
          name: opponent.isPresent ? opponent.name : null,
          tag: isHost ? 'GUEST' : 'HOST',
          ready: opponent.isPresent && (isHost ? opponent.ready : true),
          compact: compact,
        ),
        SizedBox(height: compact ? DashSpace.x3 : DashSpace.x4),
        if (isHost)
          BrawlActionButton(
            label: canStart ? 'START RACE' : 'WAITING FOR GUEST…',
            tone: canStart ? BrawlButtonTone.green : BrawlButtonTone.grey,
            height: height,
            onPressed: canStart ? onStart : null,
          )
        else
          BrawlActionButton(
            label: meReady ? 'WAITING FOR HOST…' : 'READY',
            tone: meReady ? BrawlButtonTone.grey : BrawlButtonTone.green,
            height: height,
            onPressed: meReady ? null : onReady,
          ),
      ],
    );
  }
}

/// One player's slot in the lobby: a sunken tray with their role, their name,
/// and a green tick once they are ready.
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
    final empty = name == null;
    return Container(
      height: compact ? 42 : 52,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
      decoration: BoxDecoration(
        color: BrawlPanel.bevel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashColors.pureBlack, width: 3),
      ),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 52 : 64,
            child: BrawlInkText(
              tag,
              fontSize: compact ? 11 : 12,
              weight: BrawlInkWeight.heavy,
              color: BrawlPanel.gold,
              letterSpacing: 1,
            ),
          ),
          Expanded(
            child: BrawlInkText(
              (name ?? 'Waiting for a racer…').toUpperCase(),
              fontSize: compact ? 14 : 16,
              weight: empty ? BrawlInkWeight.light : BrawlInkWeight.heavy,
              color: empty ? BrawlPanel.softText : DashColors.textPrimary,
              fontStyle: empty ? FontStyle.italic : FontStyle.normal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!empty && ready)
            DashIcon(
              DashIcons.checkmark,
              size: DashIconSize.md,
              color: DashColors.neonGreen,
            ),
        ],
      ),
    );
  }
}
