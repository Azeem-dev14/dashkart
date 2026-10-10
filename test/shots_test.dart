import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dashkart/core/scaffold/dash_ui_scale.dart';
import 'package:dashkart/core/widgets/dash_game_hud.dart';
import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/features/race/countdown_overlay.dart';
import 'package:dashkart/features/kart_select/kart_detail_screen.dart';
import 'package:dashkart/features/kart_select/kart_select_screen.dart';
import 'package:dashkart/features/main_menu/main_menu_screen.dart';
import 'package:dashkart/features/onboarding/name_entry_screen.dart';
import 'package:dashkart/features/race/scene/scene3d.dart';
import 'package:dashkart/features/race_mode/race_mode_screen.dart';
import 'package:dashkart/features/results/results_screen.dart';
import 'package:dashkart/features/settings/settings_screen.dart';
import 'package:dashkart/features/shop/shop_screen.dart';
import 'package:dashkart/features/track_select/track_select_screen.dart';

/// Landscape logical sizes the game has to hold up on, smallest first: a
/// compact Android, iPhone SE, a standard phone, a large phone, an iPad, and
/// a 12.9" iPad.
const _sizes = <String, Size>{
  'compact-android 640x360': Size(640, 360),
  'iPhone SE 667x375': Size(667, 375),
  'phone 844x390': Size(844, 390),
  'large phone 932x430': Size(932, 430),
  'iPad 1024x768': Size(1024, 768),
  'iPad Pro 1366x1024': Size(1366, 1024),
};

void noop() {}

void _ignoreBeat(int _) {}

final _screens = <String, Widget Function()>{
  'main menu': () => const MainMenuScreen(
    onRace: noop,
    onKarts: noop,
    onTracks: noop,
    onSettings: noop,
    onShop: noop,
  ),
  'race mode': () =>
      const RaceModeScreen(onBots: noop, onMultiplayer: noop, onBack: noop),
  'kart select': () => const KartSelectScreen(onBack: noop, onConfirm: noop),
  'kart detail': () => KartDetailScreen(
    kart: Catalog.karts.first,
    onBack: noop,
    onConfirm: noop,
  ),
  'track select': () => const TrackSelectScreen(onBack: noop, onConfirm: noop),
  'settings': () => const SettingsScreen(onBack: noop),
  'shop': () => const ShopScreen(onBack: noop),
  'name entry': () => const NameEntryScreen(onDone: noop),
  'results': () => const ResultsScreen(
    result: RaceResult(
      position: 1,
      totalRacers: 4,
      time: Duration(minutes: 1, seconds: 23, milliseconds: 456),
      bestLap: Duration(seconds: 27, milliseconds: 120),
      trophies: 3,
      xp: 160,
      level: 2,
      levelledUp: true,
      newRecord: true,
      trackName: 'Dash Valley',
      unlocked: ['Desert Rush'],
      standings: [
        RaceStanding(name: 'Dash', isPlayer: true, laps: 3),
        RaceStanding(name: 'Nitro', isPlayer: false, laps: 2.94),
        RaceStanding(name: 'Vex', isPlayer: false, laps: 2.81),
        RaceStanding(name: 'Rook', isPlayer: false, laps: 2.72),
      ],
    ),
    onNext: noop,
    nextLabel: 'DESERT RUSH',
    onReplay: noop,
    onHome: noop,
  ),
  'countdown': () => const ColoredBox(
    color: Color(0xFF123A6B),
    child: CountdownOverlay(onBeat: _ignoreBeat, onGo: noop),
  ),
  'race HUD': () => DashGameHUD(
    state: const RaceHudState(
      position: 4,
      totalRacers: 4,
      lap: 1,
      totalLaps: 3,
      speedKmh: 185,
      itemState: ItemSlotState.ready,
      trackProgress: [0.1, 0.2, 0.3, 0.4],
      trackId: 'frozen-peak',
    ),
    onSteer: (_) {},
    onBrake: (_) {},
    onDrift: (_) {},
    onUseItem: noop,
    onPause: noop,
  ),
};

const _out = String.fromEnvironment('SHOTS_DIR');

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(
      File('assets/fonts/$f')
          .readAsBytes()
          .then((b) => ByteData.view(b.buffer)),
    );
  }
  await loader.load();
}

void main() {
  // Developer tool, not a regression test: renders each screen to a PNG in
  // SHOTS_DIR for eyeballing. Skipped in a plain `flutter test` run.
  if (_out.isEmpty) return;

  setUpAll(() async {
    Scene3D.availableOverride = false;
    await _loadFont('TitanOne', ['TitanOne-Regular.ttf']);
    await _loadFont('Fredoka', ['Fredoka-VariableFont.ttf']);
    await _loadFont('LilitaOne', ['LilitaOne-Regular.ttf']);
    await _loadFont('ChakraPetch', [
      'ChakraPetch-SemiBold.ttf',
      'ChakraPetch-Bold.ttf',
    ]);
  });

  const only = String.fromEnvironment('ONLY');
  const sizeKey = String.fromEnvironment('SIZE', defaultValue: 'phone 844x390');

  for (final screen in _screens.entries) {
    if (only.isNotEmpty && !only.split(',').contains(screen.key)) continue;
    testWidgets('shot ${screen.key}', (tester) async {
      final size = _sizes[sizeKey]!;
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          child: RepaintBoundary(
            key: key,
            child: WidgetsApp(
              color: const Color(0xFF000000),
              // Mirrors the app: the scale sits in `builder`, above the Navigator.
              builder: (context, child) => DashUiScale(child: child!),
              home: screen.value(),
              pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
                settings: settings,
                pageBuilder: (context, _, _) => builder(context),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/${screen.key.replaceAll(' ', '_')}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
