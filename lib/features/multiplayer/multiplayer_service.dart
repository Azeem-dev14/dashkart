import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_database/firebase_database.dart';

/// Whether this device created the room or joined an existing one. Symmetric
/// in every other way — the room only remembers who "hosts" because someone
/// has to own picking the track and starting the race.
enum MultiplayerRole { host, guest }

enum RoomStatus { lobby, racing }

/// One racer's lobby info and live telemetry, stored at
/// `rooms/{code}/players/{host|guest}`.
class RacerTelemetry {
  const RacerTelemetry({
    this.name = '',
    this.kartId = '',
    this.ready = false,
    this.progress = 0,
    this.lateral = 0,
    this.finished = false,
  });

  final String name;
  final String kartId;
  final bool ready;
  final double progress;
  final double lateral;
  final bool finished;

  /// An empty name means this slot has never been written — nobody there.
  bool get isPresent => name.isNotEmpty;

  factory RacerTelemetry.fromMap(Object? raw) {
    if (raw is! Map) return const RacerTelemetry();
    return RacerTelemetry(
      name: raw['name'] as String? ?? '',
      kartId: raw['kartId'] as String? ?? '',
      ready: raw['ready'] as bool? ?? false,
      progress: (raw['progress'] as num?)?.toDouble() ?? 0,
      lateral: (raw['lateral'] as num?)?.toDouble() ?? 0,
      finished: raw['finished'] as bool? ?? false,
    );
  }
}

/// A snapshot of `rooms/{code}`.
class RoomState {
  const RoomState({
    required this.trackId,
    required this.status,
    required this.host,
    required this.guest,
  });

  final String trackId;
  final RoomStatus status;
  final RacerTelemetry host;
  final RacerTelemetry guest;

  static const empty = RoomState(
    trackId: '',
    status: RoomStatus.lobby,
    host: RacerTelemetry(),
    guest: RacerTelemetry(),
  );

  factory RoomState.fromMap(Object? raw) {
    if (raw is! Map) return empty;
    final players = raw['players'];
    return RoomState(
      trackId: raw['trackId'] as String? ?? '',
      status: raw['status'] == 'racing' ? RoomStatus.racing : RoomStatus.lobby,
      host: RacerTelemetry.fromMap(players is Map ? players['host'] : null),
      guest: RacerTelemetry.fromMap(players is Map ? players['guest'] : null),
    );
  }
}

/// A user-facing failure joining or hosting — bad code, full room, network.
class MultiplayerException implements Exception {
  MultiplayerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A live 1v1 room over Firebase Realtime Database.
///
/// [updateTelemetry] pushes this device's own steering state; [opponent] and
/// [status] read the latest known state of the room, kept current by one
/// persistent listener rather than polled — so the race loop can read them
/// every frame for free instead of awaiting anything.
///
/// Requires `rooms/{code}` to be open read/write in the Realtime Database
/// rules (no auth). That is a deliberate trade for a community demo, not a
/// production posture — see docs/multiplayer-setup.md.
class MultiplayerSession {
  MultiplayerSession._({
    required this.role,
    required this.roomCode,
    required this._roomRef,
  }) {
    _sub = _roomRef.onValue.listen(_onEvent);
  }

  final MultiplayerRole role;
  final String roomCode;
  final DatabaseReference _roomRef;
  late final StreamSubscription<DatabaseEvent> _sub;

  final _updates = StreamController<void>.broadcast();

  /// Fires whenever the room changes: lobby names, ready state, status. The
  /// race loop doesn't need this — it just reads [opponent] each frame.
  Stream<void> get onUpdate => _updates.stream;

  RoomState _room = RoomState.empty;

  String get trackId => _room.trackId;
  RoomStatus get status => _room.status;
  RacerTelemetry get me =>
      role == MultiplayerRole.host ? _room.host : _room.guest;
  RacerTelemetry get opponent =>
      role == MultiplayerRole.host ? _room.guest : _room.host;

  bool _opponentSeen = false;

  /// True once an opponent who had joined disappears — they disconnected or
  /// left. The race carries on solo; nothing here ends it automatically.
  bool opponentLeft = false;

  void _onEvent(DatabaseEvent event) {
    _room = RoomState.fromMap(event.snapshot.value);
    if (opponent.isPresent) {
      _opponentSeen = true;
    } else if (_opponentSeen) {
      opponentLeft = true;
    }
    _updates.add(null);
  }

  String get _myPath =>
      role == MultiplayerRole.host ? 'players/host' : 'players/guest';

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

  static String _newCode(math.Random rng) => List.generate(
    5,
    (_) => _codeChars[rng.nextInt(_codeChars.length)],
  ).join();

  /// Creates a room and claims the host slot, retrying on the unlikely chance
  /// the generated code is already taken.
  static Future<MultiplayerSession> host({
    required String name,
    required String kartId,
    required String trackId,
  }) async {
    final db = FirebaseDatabase.instance;
    final rng = math.Random();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _newCode(rng);
      final ref = db.ref('rooms/$code');
      final existing = await ref.get();
      if (existing.exists) continue;

      await ref.set({
        'trackId': trackId,
        'status': 'lobby',
        'createdAt': ServerValue.timestamp,
        'players': {
          'host': {
            'name': name,
            'kartId': kartId,
            'ready': true,
            'progress': 0,
            'lateral': 0,
            'finished': false,
          },
        },
      });
      unawaited(ref.child('players/host').onDisconnect().remove());
      return MultiplayerSession._(
        role: MultiplayerRole.host,
        roomCode: code,
        roomRef: ref,
      );
    }
    throw MultiplayerException('Could not create a room. Try again.');
  }

  /// Joins an existing room's guest slot.
  static Future<MultiplayerSession> join({
    required String code,
    required String name,
    required String kartId,
  }) async {
    final ref = FirebaseDatabase.instance.ref('rooms/$code');
    final snap = await ref.get();
    if (!snap.exists) throw MultiplayerException('No race with that code.');
    final room = RoomState.fromMap(snap.value);
    if (room.status != RoomStatus.lobby) {
      throw MultiplayerException('That race has already started.');
    }
    if (room.guest.isPresent) throw MultiplayerException('That race is full.');

    await ref.child('players/guest').set({
      'name': name,
      'kartId': kartId,
      'ready': false,
      'progress': 0,
      'lateral': 0,
      'finished': false,
    });
    unawaited(ref.child('players/guest').onDisconnect().remove());
    return MultiplayerSession._(
      role: MultiplayerRole.guest,
      roomCode: code,
      roomRef: ref,
    );
  }

  Future<void> setReady(bool ready) =>
      _roomRef.child('$_myPath/ready').set(ready);

  /// Host only: flips the room into the race. Each device runs its own local
  /// countdown on arrival rather than synchronising one over the network —
  /// close enough for two people racing in the same room or call.
  Future<void> startRace() => _roomRef.child('status').set('racing');

  /// Pushed at a throttled rate from the race loop. Never await this there —
  /// a slow or dropped write should never stall a frame.
  Future<void> updateTelemetry({
    required double progress,
    required double lateral,
    required bool finished,
  }) {
    return _roomRef
        .child(_myPath)
        .update({
          'progress': progress,
          'lateral': lateral,
          'finished': finished,
        })
        .catchError((_) {});
  }

  /// Removes this device's own slot so the other side sees an immediate
  /// clean departure rather than waiting on [onDisconnect].
  Future<void> leave() => _roomRef.child(_myPath).remove().catchError((_) {});

  void dispose() {
    _sub.cancel();
    _updates.close();
  }
}
