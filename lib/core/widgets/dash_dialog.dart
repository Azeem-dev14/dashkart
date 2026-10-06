import 'package:flutter/widgets.dart';

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/dash_button.dart';

/// A DashKart modal. Never a Material [Dialog].
class DashDialog extends StatelessWidget {
  const DashDialog({
    super.key,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  final String title;
  final String message;
  final List<Widget> actions;

  /// Shows [dialog] over a scrim, scaling in from 92%.
  static Future<T?> show<T>(
    BuildContext context, {
    required DashDialog dialog,
    bool dismissible = true,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        opaque: false,
        barrierDismissible: dismissible,
        barrierColor: DashColors.scrim,
        transitionDuration: DashMotionScope.duration(context, DashMotion.hero),
        pageBuilder: (_, _, _) => dialog,
        transitionsBuilder: (context, anim, _, child) {
          final t = CurvedAnimation(
            parent: anim,
            curve: DashMotionScope.curve(context, DashMotion.heroCurve),
          );
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(t),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Convenience for a destructive confirm, e.g. Reset Progress.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) async {
    final result = await show<bool>(
      context,
      dialog: DashDialog(
        title: title,
        message: message,
        actions: [
          _DialogAction(label: cancelLabel, value: false),
          _DialogAction(
            label: confirmLabel,
            value: true,
            variant: DashButtonVariant.danger,
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DashSpace.x6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(DashSpace.x6),
            decoration: BoxDecoration(
              color: DashColors.surfaceRaised,
              borderRadius: DashRadius.xlAll,
              border: Border.all(color: DashColors.pureBlack, width: 2.8),
              boxShadow: DashElevation.dialog,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DashType.h2),
                const SizedBox(height: DashSpace.x3),
                Text(message, style: DashType.body),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: DashSpace.x6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final a in actions) ...[
                        a,
                        if (a != actions.last)
                          const SizedBox(width: DashSpace.x3),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.value,
    this.variant = DashButtonVariant.ghost,
  });

  final String label;
  final bool value;
  final DashButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return DashButton(
      label: label,
      variant: variant,
      size: DashButtonSize.sm,
      onPressed: () => Navigator.of(context).pop(value),
    );
  }
}
