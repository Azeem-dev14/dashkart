import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dashkart/core/scaffold/dash_ui_scale.dart';

/// Builds the same shape as the real app: [DashUiScale] in `WidgetsApp.builder`,
/// which is what puts it above the Navigator.
Widget _app({required Widget home}) => WidgetsApp(
  color: const Color(0xFF000000),
  builder: (context, child) => DashUiScale(child: child!),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (c, _, _) => builder(c),
  ),
  home: home,
);

/// Reports the logical size its subtree is laid out against.
class _SizeProbe extends StatelessWidget {
  const _SizeProbe(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Text(
      '$label ${size.width.round()}x${size.height.round()}',
      textDirection: TextDirection.ltr,
    );
  }
}

Future<void> _pump(WidgetTester tester, Size size, Widget home) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(home: home));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a phone-shaped screen is left exactly as designed', (
    tester,
  ) async {
    await _pump(tester, const Size(844, 390), const _SizeProbe('home'));
    expect(find.text('home 844x390'), findsOneWidget);
  });

  testWidgets('a tablet lays out on a smaller canvas, magnified to fill', (
    tester,
  ) async {
    await _pump(tester, const Size(1366, 1024), const _SizeProbe('home'));
    // 1024 / 390 clamps to the 1.5 ceiling, so the canvas is 1/1.5 of the
    // real screen and every fixed size in the app is drawn 1.5x bigger.
    expect(DashUiScale.scaleFor(const Size(1366, 1024)), DashUiScale.maxScale);
    expect(find.text('home 911x683'), findsOneWidget);
  });

  testWidgets('a cramped phone gets a little more room, never less', (
    tester,
  ) async {
    await _pump(tester, const Size(640, 360), const _SizeProbe('home'));
    expect(find.text('home 693x390'), findsOneWidget);
  });

  // The regression this file exists for: the scale originally sat below
  // WidgetsApp's Navigator, so the home route scaled and every screen you
  // actually navigate to — kart select, settings, the race — did not.
  testWidgets('a pushed route is scaled too, not just the home route', (
    tester,
  ) async {
    late BuildContext homeContext;
    await _pump(
      tester,
      const Size(1366, 1024),
      Builder(
        builder: (context) {
          homeContext = context;
          return const _SizeProbe('home');
        },
      ),
    );

    Navigator.of(homeContext).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, _) => const _SizeProbe('pushed'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('pushed 911x683'), findsOneWidget);
  });

  testWidgets('the 3D view opts back out, at the device\'s real size', (
    tester,
  ) async {
    await _pump(
      tester,
      const Size(1366, 1024),
      DashUiScale.unscaled(child: const _SizeProbe('scene')),
    );
    expect(find.text('scene 1366x1024'), findsOneWidget);
  });
}
