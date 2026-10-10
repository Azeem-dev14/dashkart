import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/features/race/scene/scene3d.dart';

/// Renders a kart GLB on a turntable.
///
/// Used anywhere a kart is shown rather than driven — Kart Select, the Garage,
/// the splash. The model is the real Kenney `.glb` from
/// `assets/models/karts/`, loaded through `flutter_scene`.
///
/// Flutter GPU is enabled per platform (Info.plist / AndroidManifest). Without
/// it `SceneView` draws nothing, so [fallback] covers that and any load
/// failure rather than leaving a blank box.
class KartViewer extends StatefulWidget {
  const KartViewer({
    super.key,
    required this.modelPath,
    this.spin = true,
    this.tint,
    this.fallback,
    this.cameraTargetY,
    this.cameraEyeY,
    this.fixedAngle,
    this.spinPeriod = const Duration(seconds: 7),
  });

  /// e.g. `assets/models/karts/dashkart.glb`.
  final String modelPath;
  final bool spin;

  /// Base-colour tint applied to the loaded model's materials, multiplying
  /// its texture like a livery recolour. Null renders the model as-is.
  final Color? tint;
  final Widget? fallback;

  /// Vertical camera target point in scene space. Defaults to 0.5.
  final double? cameraTargetY;

  /// Camera elevation eye height. Defaults to 2.1.
  final double? cameraEyeY;

  /// Fixed horizontal camera angle in radians. When provided or when spin is false,
  /// this angle is used (e.g. pi/2 for headlights facing straight forward).
  final double? fixedAngle;

  /// Time for one full turn while [spin] is on. Longer is slower.
  final Duration spinPeriod;

  @override
  State<KartViewer> createState() => _KartViewerState();
}

class _KartViewerState extends State<KartViewer> {
  // Created only once 3D is known to work: the Scene constructor itself
  // initialises the engine's static resources.
  Scene? _scene;
  Node? _kart;
  bool _ready = false;
  bool _failed = false;

  /// Each material's imported base colour, captured the first time it is
  /// seen — the only place that colour still exists once [_tint] has
  /// overwritten it on the live material.
  final _originalColors = <PhysicallyBasedMaterial, vm.Vector4>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(KartViewer old) {
    super.didUpdateWidget(old);
    if (old.modelPath != widget.modelPath) {
      _swap();
    } else if (old.tint != widget.tint && _kart != null) {
      _tint(_kart!, widget.tint);
    }
  }

  Future<void> _load() async {
    try {
      if (!await Scene3D.ensureReady()) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      final scene = Scene();
      final node = await loadScene(widget.modelPath);
      if (!mounted) return;
      _tint(node, widget.tint);
      scene.add(node);
      _scene = scene;
      setState(() {
        _kart = node;
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _swap() async {
    try {
      final scene = _scene;
      if (scene == null) return;
      final next = await loadScene(widget.modelPath);
      if (!mounted) return;
      _tint(next, widget.tint);
      final previous = _kart;
      if (previous != null) scene.remove(previous);
      scene.add(next);
      setState(() => _kart = next);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Tints every mesh primitive under [node] with [color], multiplying the
  /// model's own texture the way a livery recolour would. `null` restores
  /// each material's original base colour — read from [_originalColors],
  /// since by the time this runs again the live material may already carry
  /// a previous tint rather than its imported value.
  void _tint(Node node, Color? color) {
    if (color == null && _originalColors.isEmpty) return;
    for (final meshNode in node.meshNodes) {
      for (final primitive in meshNode.mesh!.primitives) {
        final material = primitive.material;
        if (material is! PhysicallyBasedMaterial) continue;
        final original = _originalColors.putIfAbsent(
          material,
          () => material.baseColorFactor,
        );
        material.baseColorFactor = color == null
            ? original
            : vm.Vector4(color.r, color.g, color.b, original.a);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !_ready || _scene == null) {
      return widget.fallback ?? const SizedBox.shrink();
    }

    final spin = widget.spin && DashMotionScope.of(context);

    return SceneView(
      _scene!,
      cameraBuilder: (elapsed) {
        final angle =
            widget.fixedAngle ??
            (spin
                ? elapsed.inMilliseconds /
                      widget.spinPeriod.inMilliseconds *
                      math.pi *
                      2
                : (math.pi / 2));
        const radius = 4.4;
        return PerspectiveCamera(
          position: vm.Vector3(
            radius * math.cos(angle),
            widget.cameraEyeY ?? 2.1,
            radius * math.sin(angle),
          ),
          target: vm.Vector3(0, widget.cameraTargetY ?? 0.5, 0),
          fovRadiansY: 0.62,
        );
      },
    );
  }
}
