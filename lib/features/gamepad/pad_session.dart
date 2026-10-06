import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-shot buttons on the phone. Held inputs (steer, brake, drift) are state;
/// these are events, so they travel as ever-increasing counters — a counter
/// can't be missed or double-fired the way a true/false flag can when two
/// writes land between listener callbacks.
enum PadPress { item, pause }

/// The web game's end of a phone controller, stored at `pads/{code}`.
///
/// The game creates the node and shows its code as a QR link; the phone opens
/// that link and writes its inputs into the same node. Listens with one
/// persistent stream so the race can read [steer], [brake] and [drift] every
/// frame for free.
class PadHost extends ChangeNotifier {
  PadHost._(this.code, this._ref) {
    _sub = _ref.onValue.listen(_onEvent);
  }

  final String code;
  final DatabaseReference _ref;
  late final StreamSubscription<DatabaseEvent> _sub;

  final _presses = StreamController<PadPress>.broadcast();
  Stream<PadPress> get presses => _presses.stream;

  bool _connected = false;
  double _steer = 0;
  bool _brake = false;
  bool _drift = false;

  /// True while a phone is attached. Drops back to false on its own if the
  /// phone closes the tab or loses signal (its `onDisconnect`).
  bool get connected => _connected;
  double get steer => _steer;
  bool get brake => _brake;
  bool get drift => _drift;

  int? _itemCount;
  int? _pauseCount;

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

  /// The link the QR code encodes: this same web app, in controller mode.
  ///
  /// Defaults to wherever the game itself was loaded from, so it follows the
  /// deployment with no configuration. A phone can't reach `localhost`, so
  /// when developing, either open the game via the machine's LAN address or
  /// pass `--dart-define=PAD_BASE_URL=http://192.168.x.x:8080/`.
  static Uri linkFor(String code) {
    const override = String.fromEnvironment('PAD_BASE_URL');
    final base = override.isNotEmpty ? Uri.parse(override) : Uri.base;
    return base.replace(queryParameters: {'pad': code}, fragment: '');
  }

  Uri get link => linkFor(code);

  static Future<PadHost> create() async {
    final db = FirebaseDatabase.instance;
    final rng = math.Random();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = List.generate(
        5,
        (_) => _codeChars[rng.nextInt(_codeChars.length)],
      ).join();
      final ref = db.ref('pads/$code');
      if ((await ref.get()).exists) continue;
      await ref.set({
        'createdAt': ServerValue.timestamp,
        'connected': false,
        'steer': 0,
        'brake': false,
        'drift': false,
        'item': 0,
        'pause': 0,
      });
      unawaited(ref.onDisconnect().remove());
      return PadHost._(code, ref);
    }
    throw StateError('Could not create a controller code. Try again.');
  }

  void _onEvent(DatabaseEvent event) {
    final raw = event.snapshot.value;
    if (raw is! Map) return;
    _connected = raw['connected'] as bool? ?? false;
    _steer = ((raw['steer'] as num?)?.toDouble() ?? 0).clamp(-1.0, 1.0);
    _brake = raw['brake'] as bool? ?? false;
    _drift = raw['drift'] as bool? ?? false;

    // The first snapshot only sets the baseline: presses made before this
    // listener attached are not new presses.
    final item = (raw['item'] as num?)?.toInt() ?? 0;
    final pause = (raw['pause'] as num?)?.toInt() ?? 0;
    if (_itemCount != null && item > _itemCount!) _presses.add(PadPress.item);
    if (_pauseCount != null && pause > _pauseCount!) {
      _presses.add(PadPress.pause);
    }
    _itemCount = item;
    _pauseCount = pause;

    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    _presses.close();
    _ref.remove().catchError((_) {});
    super.dispose();
  }
}

/// The phone's end: joins `pads/{code}` and writes input into it.
class PadClient {
  PadClient._(this._ref);

  final DatabaseReference _ref;

  int _item = 0;
  int _pause = 0;

  /// Throws [PadException] with a message fit to show the player.
  static Future<PadClient> join(String code) async {
    final ref = FirebaseDatabase.instance.ref('pads/$code');
    final DataSnapshot snap;
    try {
      snap = await ref.get();
    } catch (_) {
      throw PadException('Can’t reach the game. Check your connection.');
    }
    if (!snap.exists) {
      throw PadException('That game isn’t open any more. Scan the code again.');
    }
    final raw = snap.value;
    if (raw is Map && raw['connected'] == true) {
      throw PadException('Another phone is already driving this game.');
    }
    await ref.update({'connected': true});
    unawaited(ref.child('connected').onDisconnect().set(false));
    // The counters live on in the node if this phone reconnects.
    final client = PadClient._(ref);
    if (raw is Map) {
      client._item = (raw['item'] as num?)?.toInt() ?? 0;
      client._pause = (raw['pause'] as num?)?.toInt() ?? 0;
    }
    return client;
  }

  void setSteer(double v) => _write({'steer': v});
  void setBrake(bool v) => _write({'brake': v});
  void setDrift(bool v) => _write({'drift': v});
  void pressItem() => _write({'item': ++_item});
  void pressPause() => _write({'pause': ++_pause});

  /// Fire-and-forget: a dropped input write must never stall a touch.
  void _write(Map<String, Object?> data) =>
      unawaited(_ref.update(data).catchError((_) {}));

  Future<void> leave() async {
    try {
      await _ref.update({
        'connected': false,
        'steer': 0,
        'brake': false,
        'drift': false,
      });
    } catch (_) {}
  }
}

class PadException implements Exception {
  PadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The web game's controller session, set by the connect screen and read by
/// the race. Null on mobile builds and when the player skipped the phone.
final padHostProvider = StateProvider<PadHost?>((ref) => null);
