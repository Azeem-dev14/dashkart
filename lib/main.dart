import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dashkart/core/audio/audio_manager.dart';
import 'package:dashkart/core/scaffold/dash_ui_scale.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/firebase_options.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/core/scaffold/dash_scaffold.dart';
import 'package:dashkart/features/gamepad/connect_screen.dart';
import 'package:dashkart/features/gamepad/controller_screen.dart';
import 'package:dashkart/features/kart_select/kart_select_screen.dart';
import 'package:dashkart/features/loading/loading_screen.dart';
import 'package:dashkart/features/main_menu/main_menu_screen.dart';
import 'package:dashkart/features/multiplayer/multiplayer_screen.dart';
import 'package:dashkart/features/onboarding/name_entry_screen.dart';
import 'package:dashkart/features/race_mode/race_mode_screen.dart';
import 'package:dashkart/features/race/race_screen.dart';
import 'package:dashkart/features/settings/settings_screen.dart';
import 'package:dashkart/features/shop/shop_screen.dart';
import 'package:dashkart/features/splash/splash_screen.dart';
import 'package:dashkart/features/track_select/track_select_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Multiplayer needs a real Firebase project behind it — see
  // docs/multiplayer-setup.md. Until `flutterfire configure` has replaced
  // firebase_options.dart's placeholder values, DO NOT hand them to the
  // native SDK at all: unlike a Dart-level failure, garbage config crashes
  // the process below where try/catch can reach, taking the whole app down
  // at launch instead of falling back to single-player.
  var firebaseReady = false;
  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  if (firebaseOptions.apiKey != 'REPLACE_ME') {
    try {
      await Firebase.initializeApp(options: firebaseOptions);
      firebaseReady = true;
    } catch (_) {}
  }

  // DashKart is landscape-only. The race HUD puts steering under the left
  // thumb and throttle under the right, which a portrait column cannot hold,
  // and every menu is laid out against the same wide canvas.
  //
  // This is the runtime half of the lock; the manifest and Info.plist pin it
  // at the platform level so the app never even starts in portrait.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // A phone that scanned the game's QR code lands here with `?pad=CODE`: it
  // runs the same app, but as a bare controller — no splash, audio or menus.
  final padCode = kIsWeb ? Uri.base.queryParameters['pad'] : null;
  if (padCode != null && padCode.isNotEmpty) {
    runApp(
      DashKartApp(
        firebaseReady: firebaseReady,
        home: ControllerScreen(code: padCode, firebaseReady: firebaseReady),
      ),
    );
    return;
  }

  AudioManager.instance.init();

  // Every app-wide ChangeNotifier (PlayerState, GameSettings) is created and
  // torn down by its own provider — see playerProvider / gameSettingsProvider
  // — so there is nothing left for the app root to own itself.
  runApp(ProviderScope(child: DashKartApp(firebaseReady: firebaseReady)));
}

class DashKartApp extends StatefulWidget {
  const DashKartApp({super.key, required this.firebaseReady, this.home});

  final bool firebaseReady;

  /// Replaces the normal game flow — used for the phone controller page.
  final Widget? home;

  @override
  State<DashKartApp> createState() => _DashKartAppState();
}

class _DashKartAppState extends State<DashKartApp> {
  /// Silences the game while it is in the background, from the app root
  /// rather than from any one screen — the menu has music too, and audio is
  /// an app-wide resource. Without this, backgrounding DashKart left its
  /// music and engine loop playing over whatever the player switched to.
  ///
  /// `RaceScreen` keeps its own listener for the orthogonal concern of
  /// pausing the race itself.
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => AudioManager.instance.setSuspended(true),
      onPause: () => AudioManager.instance.setSuspended(true),
      onShow: () => AudioManager.instance.setSuspended(false),
      onRestart: () => AudioManager.instance.setSuspended(false),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No MaterialApp: DashKart draws its own chrome, and Material's theming
    // would only be overridden everywhere. WidgetsApp gives routing and
    // localisation without the Material surface.
    return WidgetsApp(
      title: 'DashKart',
      debugShowCheckedModeBanner: false,
      color: DashColors.bgBase,
      textStyle: DashType.body,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
            transitionDuration: DashMotion.slow,
            transitionsBuilder: (context, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
      // Above WidgetsApp's own Navigator, so every *pushed* route — kart
      // select, the race, settings — is scaled too, not just the home route.
      builder: (context, child) => DashUiScale(
        child: DashMotionScope(
          enabled: !MediaQuery.disableAnimationsOf(context),
          child: child!,
        ),
      ),
      home: widget.home ?? _AppFlow(firebaseReady: widget.firebaseReady),
    );
  }
}

/// Splash → Loading → (first launch only) Name entry → (web only) Connect
/// phone → Main Menu.
///
/// Each stage swaps out for the next in place rather than through
/// `Navigator.push` — none of them are a place the player should ever land
/// on again by pressing Back, so they aren't part of the back stack at all.
enum _Stage { splash, loading, onboarding, connect, menu }

class _AppFlow extends ConsumerStatefulWidget {
  const _AppFlow({required this.firebaseReady});

  final bool firebaseReady;

  @override
  ConsumerState<_AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends ConsumerState<_AppFlow> {
  _Stage _stage = _Stage.splash;

  void _afterLoading() {
    final needsOnboarding = ref.read(playerProvider).needsOnboarding;
    setState(() {
      _stage = needsOnboarding ? _Stage.onboarding : _afterOnboarding;
    });
  }

  /// On the web the main screen is the "scan to connect your phone" screen —
  /// but only when there is a server to relay the phone's input through.
  _Stage get _afterOnboarding =>
      kIsWeb && widget.firebaseReady ? _Stage.connect : _Stage.menu;

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      playerProvider.select((p) => p.needsOnboarding),
      (previous, next) {
        if (next &&
            _stage != _Stage.onboarding &&
            _stage != _Stage.splash &&
            _stage != _Stage.loading) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          AudioManager.instance.stopMusic();
          setState(() {
            _stage = _Stage.splash;
          });
        }
      },
    );

    return switch (_stage) {
      _Stage.splash => SplashScreen(
        onDone: () => setState(() => _stage = _Stage.loading),
      ),
      _Stage.loading => LoadingScreen(onDone: _afterLoading),
      _Stage.onboarding => NameEntryScreen(
        onDone: () => setState(() => _stage = _afterOnboarding),
      ),
      _Stage.connect => ConnectScreen(
        onContinue: () => setState(() => _stage = _Stage.menu),
      ),
      _Stage.menu => _MenuHost(firebaseReady: widget.firebaseReady),
    };
  }
}

class _MenuHost extends StatefulWidget {
  const _MenuHost({required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<_MenuHost> createState() => _MenuHostState();
}

class _MenuHostState extends State<_MenuHost> {
  /// Brings the menu music back when a pushed screen is popped.
  ///
  /// The menu is the home route, so its `initState` runs exactly once per
  /// launch — which meant that after the first race stopped the music, the
  /// menu stayed silent for the rest of the session.
  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(DashPageRoute<void>(page: page)).then((_) {
      if (mounted) AudioManager.instance.playMenuMusic();
    });
  }

  /// RACE runs the whole pre-race flow in order — kart, then track, then who
  /// you're racing. Each step pushes on top of the last, so Back always means
  /// "one step back in the flow".
  void _startRaceFlow(BuildContext context) {
    _push(
      context,
      KartSelectScreen(
        onConfirm: () => _push(
          context,
          TrackSelectScreen(
            onBack: () => Navigator.of(context).maybePop(),
            onConfirm: () => _push(
              context,
              RaceModeScreen(
                onBack: () => Navigator.of(context).maybePop(),
                onBots: () => _push(
                  context,
                  RaceScreen(
                    onExit: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ),
                onMultiplayer: () => _startMultiplayerFlow(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pushes the host-or-join lobby, unless Firebase was never reachable at
  /// boot (see main()'s try/catch) — in which case there is no server to
  /// talk to at all, so this explains that instead of opening a lobby that
  /// can only fail. The kart and track chosen earlier in the flow are
  /// already on [PlayerState] by this point, which is what both the lobby
  /// and the race itself read.
  void _startMultiplayerFlow(BuildContext context) {
    if (!widget.firebaseReady) {
      DashDialog.show(
        context,
        dialog: const DashDialog(
          title: 'Multiplayer unavailable',
          message:
              'This build has not been connected to a multiplayer '
              'server. See docs/multiplayer-setup.md to enable it.',
        ),
      );
      return;
    }
    _push(
      context,
      MultiplayerScreen(
        onBack: () => Navigator.of(context).maybePop(),
        onSessionReady: (session) {
          Navigator.of(context).pop();
          _push(
            context,
            RaceScreen(
              onExit: () => Navigator.of(context).maybePop(),
              multiplayer: session,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainMenuScreen(
      onRace: () => _startRaceFlow(context),
      onKarts: () => _push(
        context,
        KartSelectScreen(
          onBack: () => Navigator.of(context).maybePop(),
          onConfirm: () => Navigator.of(context).maybePop(),
        ),
      ),
      onTracks: () => _push(
        context,
        TrackSelectScreen(
          onBack: () => Navigator.of(context).maybePop(),
          onConfirm: () => Navigator.of(context).maybePop(),
        ),
      ),
      onSettings: () => _push(
        context,
        SettingsScreen(onBack: () => Navigator.of(context).maybePop()),
      ),
      onShop: () => _push(
        context,
        ShopScreen(onBack: () => Navigator.of(context).maybePop()),
      ),
    );
  }
}
