import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/models.dart';

/// Player progression and current selections.
///
/// Deliberately a plain [ChangeNotifier]: the state here is small, and a
/// heavier solution would cost more than it saves.
class PlayerState extends ChangeNotifier {
  PlayerState();

  String _name = 'Dash';
  int _trophies = 14;
  int _level = 7;
  double _levelProgress = 0.62;

  String _kartId = Catalog.karts.first.id;
  String _racerId = Catalog.racers.first.id;
  String _trackId = Catalog.tracks.first.id;

  final Map<String, Duration> _bestTimes = {};

  bool _onboarded = false;

  String get name => _name;
  int get trophies => _trophies;
  int get level => _level;
  double get levelProgress => _levelProgress;

  /// True until [completeOnboarding] has run once, ever, on this device —
  /// what the first-launch name screen gates on.
  bool get needsOnboarding => !_onboarded;

  Kart get kart => Catalog.kartById(_kartId);
  Racer get racer => Catalog.racerById(_racerId);
  Track get track => Catalog.trackById(_trackId);

  Duration? bestTime(String trackId) => _bestTimes[trackId];

  bool hasTrophy(String trackId) => _bestTimes.containsKey(trackId);

  static const _kName = 'dashkart_player_name';
  static const _kTrophies = 'dashkart_player_trophies';
  static const _kLevel = 'dashkart_player_level';
  static const _kLevelProgress = 'dashkart_player_level_progress';
  static const _kKartId = 'dashkart_player_kart_id';
  static const _kRacerId = 'dashkart_player_racer_id';
  static const _kTrackId = 'dashkart_player_track_id';
  static const _kBestTimes = 'dashkart_player_best_times_ms_';
  static const _kOnboarded = 'dashkart_player_onboarded';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString(_kName) ?? _name;
      _trophies = prefs.getInt(_kTrophies) ?? _trophies;
      _level = prefs.getInt(_kLevel) ?? _level;
      _levelProgress = prefs.getDouble(_kLevelProgress) ?? _levelProgress;
      _kartId = prefs.getString(_kKartId) ?? _kartId;
      _racerId = prefs.getString(_kRacerId) ?? _racerId;
      _trackId = prefs.getString(_kTrackId) ?? _trackId;
      _onboarded = prefs.getBool(_kOnboarded) ?? _onboarded;

      for (final t in Catalog.tracks) {
        final ms = prefs.getInt('$_kBestTimes${t.id}');
        if (ms != null) {
          _bestTimes[t.id] = Duration(milliseconds: ms);
        }
      }
      notifyListeners();
    } catch (_) {
      // SharedPreferences might fail in constrained test environments; safe fallback.
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kName, _name);
      await prefs.setInt(_kTrophies, _trophies);
      await prefs.setInt(_kLevel, _level);
      await prefs.setDouble(_kLevelProgress, _levelProgress);
      await prefs.setString(_kKartId, _kartId);
      await prefs.setString(_kRacerId, _racerId);
      await prefs.setString(_kTrackId, _trackId);
      await prefs.setBool(_kOnboarded, _onboarded);

      for (final entry in _bestTimes.entries) {
        await prefs.setInt(
          '$_kBestTimes${entry.key}',
          entry.value.inMilliseconds,
        );
      }
    } catch (_) {}
  }

  /// Whether [rule] is satisfied by current progress.
  bool meets(UnlockRule rule) => switch (rule) {
    Starter() => true,
    TrophyCount(:final trophies) => _trophies >= trophies,
  };

  bool isKartUnlocked(Kart kart) => meets(kart.unlock);

  bool isTrackUnlocked(Track track) => meets(track.unlock);

  void selectKart(Kart kart) {
    if (!isKartUnlocked(kart)) return;
    _kartId = kart.id;
    notifyListeners();
    save();
  }

  void selectRacer(Racer racer) {
    _racerId = racer.id;
    notifyListeners();
    save();
  }

  void selectTrack(Track track) {
    if (!isTrackUnlocked(track)) return;
    _trackId = track.id;
    notifyListeners();
    save();
  }

  /// Records a finished race. Only improves a best time, never regresses it.
  void recordResult({
    required String trackId,
    required Duration time,
    required int position,
  }) {
    final previous = _bestTimes[trackId];
    if (previous == null || time < previous) _bestTimes[trackId] = time;
    if (position == 1) _trophies += 1;
    _levelProgress += 0.12;
    while (_levelProgress >= 1) {
      _levelProgress -= 1;
      _level += 1;
    }
    notifyListeners();
    save();
  }

  void rename(String value) {
    _name = value.trim().isEmpty ? _name : value.trim();
    notifyListeners();
    save();
  }

  /// Sets the player's name and clears [needsOnboarding], both in one write
  /// — called once by the first-launch name screen.
  void completeOnboarding(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) _name = trimmed;
    _onboarded = true;
    notifyListeners();
    save();
  }

  void resetProgress() {
    _trophies = 0;
    _level = 1;
    _levelProgress = 0;
    _bestTimes.clear();
    _kartId = Catalog.karts.first.id;
    _racerId = Catalog.racers.first.id;
    _trackId = Catalog.tracks.first.id;
    notifyListeners();
    save();
  }
}

/// Exposes the app's single [PlayerState] instance.
///
/// `ref.watch(playerProvider)` rebuilds the caller on every
/// [PlayerState.notifyListeners] call, the same way `PlayerScope.of(context)`
/// used to; `ref.read(playerProvider)` reads it once without subscribing.
final playerProvider = ChangeNotifierProvider<PlayerState>((ref) {
  final player = PlayerState();
  player.load();
  ref.onDispose(player.dispose);
  return player;
});
