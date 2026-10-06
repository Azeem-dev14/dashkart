import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scene/scene.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/features/race/scene/race_scene.dart';
import 'package:dashkart/features/race/scene/scene3d.dart';
import 'package:dashkart/features/settings/settings_screen.dart';

/// Preloads all 3D assets, settings, and player data before entering the game.
///
/// Non-skippable: Plays through completely until all assets are loaded,
/// then immediately hands off to [onDone] to navigate to the main screen.
/// Displays an image (customizable at `assets/images/splash/loading_splash.png`).
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  /// Custom loading image asset path. Replace this asset in the future with any artwork.
  static const String loadingSplashAsset =
      'assets/images/splash/loading_splash.png';

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _preload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(LoadingScreen.loadingSplashAsset), context);
  }

  List<String> _assetPaths() {
    final paths = <String>{
      RaceScene.roadModelPath,
      RaceScene.barrierModelPath,
      for (final kart in Catalog.karts) kart.modelPath,
      for (final racer in Catalog.racers) ...[
        racer.modelPath,
        if (racer.accessory != null)
          'assets/models/characters/${racer.accessory}.glb',
      ],
      for (final track in Catalog.tracks)
        for (final prop in RaceScene.propsForTrack(track.id))
          'assets/models/environment/$prop.glb',
    };
    return paths.toList(growable: false);
  }

  Future<void> _preload() async {
    final start = DateTime.now();

    // Finish loading persisted state first
    await Future.wait([
      ref.read(playerProvider).load(),
      ref.read(gameSettingsProvider).load(),
    ]);

    final ready = await Scene3D.ensureReady();
    if (!ready) {
      if (mounted) widget.onDone();
      return;
    }

    final paths = _assetPaths();
    for (var i = 0; i < paths.length; i++) {
      try {
        await loadScene(paths[i]);
      } catch (_) {}
      if (!mounted) return;
      setState(() => _progress = (i + 1) / paths.length);
    }

    // Ensure smooth minimum display so image doesn't abruptly flash
    final elapsed = DateTime.now().difference(start);
    const minDisplay = Duration(milliseconds: 1000);
    if (elapsed < minDisplay) {
      await Future<void>.delayed(minDisplay - elapsed);
    }

    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    // Non-skippable: strictly no gesture detectors or tap handlers
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen Loading Image
          Image.asset(
            LoadingScreen.loadingSplashAsset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(color: Color(0xFF000000));
            },
          ),

          // Subtle, elegant bottom progress indicator line
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 3.0,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress.clamp(0.0, 1.0),
              child: Container(color: const Color(0xFF3DF2FF)),
            ),
          ),
        ],
      ),
    );
  }
}
