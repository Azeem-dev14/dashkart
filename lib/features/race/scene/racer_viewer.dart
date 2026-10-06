import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/features/race/scene/scene3d.dart';

/// Renders a 3D racer character on a turntable with optional accessories.
///
/// Used in Character Select and podium views. The model is the rigged Kenney
/// `.glb` from `assets/models/characters/`, loaded through `flutter_scene`.
class RacerViewer extends StatefulWidget {
  const RacerViewer({
    super.key,
    required this.modelPath,
    this.accessoryPath,
    this.spin = true,
    this.fallback,
  });

  /// e.g. `assets/models/characters/character-male-a.glb`.
  final String modelPath;

  /// e.g. `assets/models/characters/aid-sunglasses.glb`.
  final String? accessoryPath;

  final bool spin;
  final Widget? fallback;

  @override
  State<RacerViewer> createState() => _RacerViewerState();
}

class _RacerViewerState extends State<RacerViewer> {
  Scene? _scene;
  Node? _racer;
  bool _ready = false;
  bool _failed = false;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RacerViewer old) {
    super.didUpdateWidget(old);
    if (old.modelPath != widget.modelPath ||
        old.accessoryPath != widget.accessoryPath) {
      _swap();
    }
  }

  Future<Node> _buildRacerNode() async {
    final node = await loadScene(widget.modelPath);
    if (widget.accessoryPath != null) {
      try {
        final accessory = await loadScene(widget.accessoryPath!);
        accessory.position = vm.Vector3(0, 0, 0);
        node.children.add(accessory);
      } catch (_) {}
    }
    return node;
  }

  Future<void> _load() async {
    try {
      if (!await Scene3D.ensureReady()) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      final scene = Scene();
      final node = await _buildRacerNode();
      if (!mounted) return;
      scene.add(node);
      _scene = scene;
      setState(() {
        _racer = node;
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
      final next = await _buildRacerNode();
      if (!mounted) return;
      final previous = _racer;
      if (previous != null) scene.remove(previous);
      scene.add(next);
      setState(() => _racer = next);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
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
        if (spin) _angle = elapsed.inMilliseconds / 6000 * math.pi * 2;
        // Orbit at radius 2.9, looking at torso height (~0.75) for a full-body view.
        const radius = 2.9;
        return PerspectiveCamera(
          position: vm.Vector3(
            radius * math.sin(_angle),
            1.0,
            radius * math.cos(_angle),
          ),
          target: vm.Vector3(0, 0.72, 0),
          fovRadiansY: 0.60,
        );
      },
    );
  }
}
