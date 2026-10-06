import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';

/// Whether 3D rendering is usable in this process.
///
/// `flutter_scene` draws through Flutter GPU, which needs Impeller. That is the
/// default on iOS and Android, but it is *not* available in widget tests, and
/// it can be off on an unusual embedder. Rather than letting every viewer
/// discover that separately by throwing, the check runs once here and every 3D
/// widget falls back to its 2D stand-in when it fails.
abstract final class Scene3D {
  static bool? _available;

  /// Forces the answer. Tests set this to false so they exercise the 2D
  /// fallback deterministically instead of depending on the renderer.
  @visibleForTesting
  static set availableOverride(bool? value) => _available = value;

  static bool get isKnownUnavailable => _available == false;

  /// Initialises the engine's static resources, once.
  ///
  /// Returns false when 3D is unavailable, so callers render their fallback.
  static Future<bool> ensureReady() async {
    if (_available != null) return _available!;
    try {
      await Scene.initializeStaticResources();
      _available = true;
    } catch (_) {
      // No Impeller, no Flutter GPU, or the shader bundle failed to load.
      // Every 3D surface degrades to its 2D stand-in.
      _available = false;
    }
    return _available!;
  }
}
