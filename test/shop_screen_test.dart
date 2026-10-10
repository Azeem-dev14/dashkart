import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/features/shop/shop_screen.dart';

void main() {
  testWidgets('shop lists karts and circuits', (tester) async {
    tester.view.physicalSize = const Size(2400, 1100);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: WidgetsApp(
          color: const Color(0xFF000000),
          home: const ShopScreen(),
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(Catalog.karts.first.name.toUpperCase()), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(0, -2500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('CIRCUITS'), findsWidgets);
  });
}
