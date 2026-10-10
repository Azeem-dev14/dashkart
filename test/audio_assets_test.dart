import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dashkart/core/audio/audio_manager.dart';

/// Every sound the game can ask for has to be a file that ships. A missing
/// one is swallowed by design (audio must never crash a race), which is
/// exactly why it has to be caught here instead.
void main() {
  test('every audio asset the manager names exists on disk', () {
    for (final path in AudioManager.allAssets) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('no asset is listed twice', () {
    expect(
      AudioManager.allAssets.toSet().length,
      AudioManager.allAssets.length,
    );
  });

  test('every audio call is safe with no audio hardware', () async {
    final audio = AudioManager.instance;
    // Not initialised: each of these must return quietly.
    await audio.playUiTap();
    await audio.playImpact();
    await audio.playDriftBoost();
    await audio.playLapComplete();
    await audio.playFinalLap();
    await audio.playRaceOver();
    await audio.startEngineLoop();
    audio.updateEnginePitch(double.nan);
    audio.updateEnginePitch(0.5, boosting: true);
    audio.duckMusic(true);
    audio.setSuspended(true);
    audio.setSuspended(false);
    audio.stopEngineLoop();
    await audio.stopMusic();
  });
}
