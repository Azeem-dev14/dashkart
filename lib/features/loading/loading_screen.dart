import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scene/scene.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/features/race/scene/race_scene.dart';
import 'package:dashkart/features/race/scene/turbo_icon.dart';
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

  /// Every 3D model the game can ask for once the menu is up.
  ///
  /// Derived from the catalogue rather than hand-listed, so adding a kart
  /// or circuit is picked up here automatically and cannot be
  /// forgotten — `loading_screen_test.dart` asserts exactly that, and that
  /// every path resolves to a real asset.
  ///
  /// `loadScene` caches the realized template per path and this screen never
  /// releases its claim, so these stay resident for the process's lifetime:
  /// the race, the kart viewer and the podium all get a cache hit instead of
  /// parsing and uploading a model while the player waits.
  static List<String> assetPaths() {
    final paths = <String>{
      RaceScene.roadModelPath,
      for (final kart in Catalog.karts) kart.modelPath,
      for (final track in Catalog.tracks)
        for (final prop in RaceScene.propsForTrack(track.id))
          'assets/models/environment/$prop.glb',
    };
    return paths.toList(growable: false);
  }

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

    // Loaded together rather than one after another: these are independent
    // reads, and the registry already de-duplicates concurrent loads of the
    // same path, so the wait is the slowest asset instead of their sum.
    final paths = LoadingScreen.assetPaths();
    final failures = <String>[];
    var done = 0;
    await Future.wait(
      paths.map((path) async {
        try {
          await loadScene(path);
        } catch (error) {
          failures.add('$path ($error)');
        }
        if (!mounted) return;
        setState(() => _progress = ++done / paths.length);
      }),
    );

    // The turbo pickup's face is drawn from the control's own SVGs and
    // uploaded as a texture; built here, the first race does not stall on it.
    try {
      await TurboIcon.load();
    } catch (error) {
      failures.add('turbo pickup icon ($error)');
    }

    // Never swallow a failed preload. The game still runs without it, which
    // is exactly why it has to be loud: the cost reappears later as a stall
    // mid-race, with nothing to point at.
    assert(() {
      if (failures.isNotEmpty) {
        debugPrint(
          'LoadingScreen: ${failures.length} of ${paths.length} assets failed '
          'to preload and will be loaded again on demand:\n  '
          '${failures.join('\n  ')}',
        );
      }
      return true;
    }());

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
