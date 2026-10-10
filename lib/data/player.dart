import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/kart_tuning.dart';
import 'package:dashkart/data/models.dart';

/// What one finished race paid out.
///
/// Returned by [PlayerState.recordResult] so the results screen reports the
/// numbers that were actually banked rather than recomputing its own — the
/// two used to disagree, with the screen showing an XP figure derived from an
/// eight-racer field while progression advanced by a flat amount unrelated to
/// how the race went.
class RaceReward {
  const RaceReward({
    required this.trophies,
    required this.xp,
    required this.newRecord,
    required this.levelledUp,
    required this.level,
    required this.unlocked,
  });

  final int trophies;
  final int xp;

  /// The lap record on this circuit was beaten.
  final bool newRecord;

  final bool levelledUp;

  /// Level after the payout.
  final int level;

  /// Content this result just put within reach, newest first — shown as the
  /// unlock callout on the results screen.
  final List<String> unlocked;

  bool get isEmpty => trophies == 0 && xp == 0;
}

/// Player progression and current selections.
///
/// Deliberately a plain [ChangeNotifier]: the state here is small, and a
/// heavier solution would cost more than it saves.
class PlayerState extends ChangeNotifier {
  PlayerState();

  /// Trophies awarded by finishing position. A solo race is three karts, so
  /// the top two places pay — a close second still moves the ladder — and
  /// last place pays nothing. It used to pay 3/2/1, which with a field of
  /// three meant *every* finisher earned a trophy, including a racer who was
  /// still on the road when the race ended around them.
  static const trophiesByPosition = <int>[3, 2];

  /// Race XP by finishing position, plus [xpPerLap] for each lap completed
  /// and [xpNewRecord] for taking the circuit's record.
  static const xpByPosition = <int>[100, 70, 45, 25];
  static const xpPerLap = 10;
  static const xpNewRecord = 50;

  /// XP needed to leave level [level]. Levels get gradually longer, so early
  /// progress is quick and later levels stay meaningful.
  static int xpForLevel(int level) => 400 + (level - 1) * 120;

  String _name = 'Dash';

  /// A fresh save starts at zero. These used to be seeded with mock values
  /// (14 trophies, level 7, 62% of the way to level 8), which handed a
  /// first-time player progress they had not earned and unlocked content
  /// before they had raced.
  int _trophies = 0;
  int _xp = 0;

  String _kartId = Catalog.karts.first.id;
  String _trackId = Catalog.tracks.first.id;

  final Map<String, Duration> _bestTimes = {};
  final Map<String, int> _bestPositions = {};
  int _racesFinished = 0;

  bool _onboarded = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    // load()/save() are async; a late completion must not touch a notifier
    // the provider has already disposed.
    if (!_disposed) super.notifyListeners();
  }

  String get name => _name;
  int get trophies => _trophies;
  int get xp => _xp;
  int get racesFinished => _racesFinished;

  /// 1-based, derived from [xp] rather than stored alongside it — the two
  /// cannot drift apart that way.
  int get level {
    var level = 1;
    var remaining = _xp;
    while (remaining >= xpForLevel(level)) {
      remaining -= xpForLevel(level);
      level++;
    }
    return level;
  }

  /// 0..1 of the way through the current level.
  double get levelProgress {
    var level = 1;
    var remaining = _xp;
    while (remaining >= xpForLevel(level)) {
      remaining -= xpForLevel(level);
      level++;
    }
    return remaining / xpForLevel(level);
  }

  /// True until [completeOnboarding] has run once, ever, on this device —
  /// what the first-launch name screen gates on.
  bool get needsOnboarding => !_onboarded;

  Kart get kart => Catalog.kartById(_kartId);
  Track get track => Catalog.trackById(_trackId);

  /// The driving numbers the selected kart actually races on.
  KartTuning get tuning => KartTuning.of(kart);

  Duration? bestTime(String trackId) => _bestTimes[trackId];

  /// Best finishing position ever achieved on [trackId], or null if never
  /// finished. Drives the medal on each track card.
  int? bestPosition(String trackId) => _bestPositions[trackId];

  bool hasTrophy(String trackId) => (_bestPositions[trackId] ?? 99) == 1;

  static const _kName = 'dashkart_player_name';
  static const _kTrophies = 'dashkart_player_trophies';
  static const _kXp = 'dashkart_player_xp';
  static const _kKartId = 'dashkart_player_kart_id';
  static const _kTrackId = 'dashkart_player_track_id';
  static const _kBestTimes = 'dashkart_player_best_times_ms_';
  static const _kBestPosition = 'dashkart_player_best_position_';
  static const _kRaces = 'dashkart_player_races';
  static const _kOnboarded = 'dashkart_player_onboarded';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString(_kName) ?? _name;
      _trophies = prefs.getInt(_kTrophies) ?? _trophies;
      _xp = prefs.getInt(_kXp) ?? _xp;
      _racesFinished = prefs.getInt(_kRaces) ?? _racesFinished;
      _onboarded = prefs.getBool(_kOnboarded) ?? _onboarded;

      // Read through the catalogue rather than trusting the stored id: a
      // build that drops or renames content would otherwise leave a save
      // pointing at something that no longer exists.
      final kartId = prefs.getString(_kKartId);
      if (kartId != null) _kartId = Catalog.kartById(kartId).id;
      final trackId = prefs.getString(_kTrackId);
      if (trackId != null) _trackId = Catalog.trackById(trackId).id;

      for (final t in Catalog.tracks) {
        final ms = prefs.getInt('$_kBestTimes${t.id}');
        if (ms != null && ms > 0) {
          _bestTimes[t.id] = Duration(milliseconds: ms);
        }
        final position = prefs.getInt('$_kBestPosition${t.id}');
        if (position != null && position > 0) {
          _bestPositions[t.id] = position;
        }
      }

      // A save can name content the player can no longer afford — the reset
      // path, or a rebalanced unlock threshold. Fall back rather than
      // starting a race in a kart the game considers locked.
      if (!isKartUnlocked(kart)) _kartId = Catalog.karts.first.id;
      if (!isTrackUnlocked(track)) _trackId = Catalog.tracks.first.id;

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
      await prefs.setInt(_kXp, _xp);
      await prefs.setInt(_kRaces, _racesFinished);
      await prefs.setString(_kKartId, _kartId);
      await prefs.setString(_kTrackId, _trackId);
      await prefs.setBool(_kOnboarded, _onboarded);

      for (final track in Catalog.tracks) {
        final time = _bestTimes[track.id];
        final position = _bestPositions[track.id];
        // Written for every circuit, not only the ones with a result, so a
        // reset actually clears what a previous save left behind — a bare
        // `setInt` per entry left stale records on disk for any track the
        // player had since cleared.
        if (time == null) {
          await prefs.remove('$_kBestTimes${track.id}');
        } else {
          await prefs.setInt('$_kBestTimes${track.id}', time.inMilliseconds);
        }
        if (position == null) {
          await prefs.remove('$_kBestPosition${track.id}');
        } else {
          await prefs.setInt('$_kBestPosition${track.id}', position);
        }
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

  /// Trophies still needed for [rule], or 0 when it is already met.
  int trophiesRemaining(UnlockRule rule) => switch (rule) {
    Starter() => 0,
    TrophyCount(:final trophies) => (trophies - _trophies).clamp(0, trophies),
  };

  void selectKart(Kart kart) {
    if (!isKartUnlocked(kart) || kart.id == _kartId) return;
    _kartId = kart.id;
    notifyListeners();
    save();
  }

  void selectTrack(Track track) {
    if (!isTrackUnlocked(track) || track.id == _trackId) return;
    _trackId = track.id;
    notifyListeners();
    save();
  }

  /// Records a finished race and returns what it paid.
  ///
  /// Best time and best position only ever improve. Multiplayer races pass
  /// [ranked] false: a 1v1 against a friend is not the single-player ladder,
  /// and letting it pay trophies would make the unlock schedule trivially
  /// farmable.
  ///
  /// [laps] is the laps the player actually completed — it pays XP — and
  /// [completed] is whether they crossed the finish line themselves. A race
  /// can end around them once every other racer has finished; that still pays
  /// for what they drove and still counts as a race, but sets no record.
  RaceReward recordResult({
    required String trackId,
    required Duration time,
    required int position,
    required int laps,
    bool ranked = true,
    bool completed = true,
  }) {
    final previousTime = _bestTimes[trackId];
    final newRecord =
        time > Duration.zero &&
        (previousTime == null || time < previousTime) &&
        // Only a race the player actually finished sets a record. One that
        // ended because everyone else had finished is a time of the race's
        // length, not of the player's lap.
        completed;
    if (newRecord) _bestTimes[trackId] = time;

    final previousPosition = _bestPositions[trackId];
    if (previousPosition == null || position < previousPosition) {
      _bestPositions[trackId] = position;
    }

    _racesFinished++;

    if (!ranked) {
      notifyListeners();
      save();
      return RaceReward(
        trophies: 0,
        xp: 0,
        newRecord: newRecord,
        levelledUp: false,
        level: level,
        unlocked: const [],
      );
    }

    final before = _trophies;
    final beforeLevel = level;

    final trophies = position >= 1 && position <= trophiesByPosition.length
        ? trophiesByPosition[position - 1]
        : 0;
    final positionXp =
        xpByPosition[(position - 1).clamp(0, xpByPosition.length - 1)];
    final xp = positionXp + laps * xpPerLap + (newRecord ? xpNewRecord : 0);

    _trophies += trophies;
    _xp += xp;

    // Anything whose threshold the payout just crossed.
    final unlocked = <String>[
      for (final kart in Catalog.karts)
        if (_crossed(kart.unlock, before)) kart.name,
      for (final track in Catalog.tracks)
        if (_crossed(track.unlock, before)) track.name,
    ];

    notifyListeners();
    save();

    return RaceReward(
      trophies: trophies,
      xp: xp,
      newRecord: newRecord,
      levelledUp: level > beforeLevel,
      level: level,
      unlocked: unlocked,
    );
  }

  /// Whether [rule] went from unmet to met as trophies rose from [before].
  bool _crossed(UnlockRule rule, int before) =>
      rule is TrophyCount &&
      before < rule.trophies &&
      _trophies >= rule.trophies;

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
    _xp = 0;
    _racesFinished = 0;
    _bestTimes.clear();
    _bestPositions.clear();
    _kartId = Catalog.karts.first.id;
    _trackId = Catalog.tracks.first.id;
    notifyListeners();
    save();
  }

  /// Wipes all game progress and the player profile, resetting [needsOnboarding]
  /// to true so that a new player is prompted for their racer name.
  void resetGame() {
    _name = 'Dash';
    _onboarded = false;
    _trophies = 0;
    _xp = 0;
    _racesFinished = 0;
    _bestTimes.clear();
    _bestPositions.clear();
    _kartId = Catalog.karts.first.id;
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
  return player;
});
