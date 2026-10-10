import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/features/loading/loading_screen.dart';
import 'package:dashkart/features/race/scene/race_scene.dart';

/// The loading screen exists to warm the 3D models, so that entering a race
/// or opening the kart viewer is a cache hit rather than a parse and a GPU
/// upload while the player waits. These guard that promise: content added to
/// the catalogue later is covered automatically, and a path that no longer
/// resolves fails here instead of silently costing a stall mid-game.
void main() {
  final paths = LoadingScreen.assetPaths();

  test('every kart model is preloaded', () {
    for (final kart in Catalog.karts) {
      expect(paths, contains(kart.modelPath), reason: 'kart ${kart.id}');
    }
  });

  test('the road and every circuit prop is preloaded', () {
    expect(paths, contains(RaceScene.roadModelPath));
    for (final track in Catalog.tracks) {
      for (final prop in RaceScene.propsForTrack(track.id)) {
        expect(
          paths,
          contains('assets/models/environment/$prop.glb'),
          reason: '${track.id} prop $prop',
        );
      }
    }
  });

  test('every preloaded path is a real asset', () {
    for (final path in paths) {
      expect(File(path).existsSync(), isTrue, reason: 'missing asset: $path');
    }
  });

  test('nothing is preloaded twice', () {
    expect(paths.toSet().length, paths.length);
  });
}
