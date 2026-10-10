import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dashkart/core/theme/theme.dart';

/// The turbo button's face, as a texture for the in-world pickup.
///
/// Built from the very same assets and colours the HUD's turbo button uses
/// (`button_bean.svg` tinted orange, `icon_fire.svg` in dark navy on top), so
/// the orb on the track and the button on the screen read as one object: pick
/// up the flame, press the flame.
abstract final class TurboIcon {
  static const _beanAsset = 'assets/images/ui/controls/button_bean.svg';
  static const _fireAsset = 'assets/images/ui/icons/icon_fire.svg';

  /// Pixel width of the rendered face; its aspect follows the 64x42 bean.
  static const _width = 320.0;
  static const _height = _width * 42 / 64;

  /// Built once per process. The face is a fixed image, so rasterising the
  /// two SVGs and uploading the texture is pure start-of-race stall if it is
  /// repeated — the loading screen warms this, and the race gets it back
  /// immediately.
  static Texture2D? _cached;
  static Future<Texture2D>? _pending;

  /// Rasterises the face and uploads it, reusing the result forever after.
  /// Concurrent callers share one upload rather than racing to do it twice.
  static Future<Texture2D> load() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    return _pending ??= _build().then((texture) {
      _cached = texture;
      _pending = null;
      return texture;
    });
  }

  static Future<Texture2D> _build() async {
    final bean = await vg.loadPicture(const SvgAssetLoader(_beanAsset), null);
    final fire = await vg.loadPicture(const SvgAssetLoader(_fireAsset), null);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Bean face, tinted exactly as DashControlFace does (modulate).
    canvas.saveLayer(
      null,
      Paint()
        ..colorFilter = ColorFilter.mode(
          DashColors.orange.s300,
          BlendMode.modulate,
        ),
    );
    canvas.scale(_width / bean.size.width, _height / bean.size.height);
    canvas.drawPicture(bean.picture);
    canvas.restore();

    // Flame glyph: 42% of the face width, nudged up like the control does.
    final glyph = _width * 0.42;
    canvas.save();
    canvas.translate(
      (_width - glyph) / 2,
      (_height - glyph) / 2 - _width * 0.03,
    );
    canvas.saveLayer(
      null,
      Paint()
        ..colorFilter = ColorFilter.mode(
          DashColors.darkNavy.withValues(alpha: 0.85),
          BlendMode.srcIn,
        ),
    );
    canvas.scale(glyph / fire.size.width, glyph / fire.size.height);
    canvas.drawPicture(fire.picture);
    canvas.restore();
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(_width.round(), _height.round());
    return Texture2D.fromImage(image);
  }
}
