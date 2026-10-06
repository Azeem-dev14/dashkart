import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/core/scaffold/dash_brawl_screen.dart';

/// The item shop. Not built out yet — the "Shop" rail button on the main
/// menu needs a destination, so this holds that place with the same frame
/// every other screen uses.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DashBrawlScreen(
      title: 'Shop',
      onBack: onBack,
      child: Center(
        child: DashCard(
          variant: DashCardVariant.raised,
          child: Padding(
            padding: const EdgeInsets.all(DashSpace.x8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DashIcon(DashIcons.star, size: DashIconSize.xxl),
                const SizedBox(height: DashSpace.x4),
                BrawlInkText('COMING SOON', fontSize: 22),
                const SizedBox(height: DashSpace.x2),
                Text(
                  'New karts and gear will show up here.',
                  style: DashType.bodySm.copyWith(
                    color: DashColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
