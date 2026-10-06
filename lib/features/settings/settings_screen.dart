import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashkart/core/audio/audio_manager.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/core/scaffold/dash_brawl_screen.dart';

/// Player-facing settings.
class GameSettings extends ChangeNotifier {
  static const _kMusicVol = 'dashkart_settings_music_vol';
  static const _kSfxVol = 'dashkart_settings_sfx_vol';
  static const _kTilt = 'dashkart_settings_tilt';
  static const _kSteerSens = 'dashkart_settings_steer_sens';
  static const _kVibration = 'dashkart_settings_vibration';
  static const _kCamShake = 'dashkart_settings_cam_shake';
  static const _kUseMph = 'dashkart_settings_use_mph';
  static const _kGraphics = 'dashkart_settings_graphics';

  double musicVolume = 0.7;
  double sfxVolume = 0.85;
  bool tiltSteering = false;
  double steeringSensitivity = 0.6;
  bool vibration = true;
  bool cameraShake = true;
  bool useMph = false;
  GraphicsTier graphics = GraphicsTier.medium;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      musicVolume = prefs.getDouble(_kMusicVol) ?? musicVolume;
      sfxVolume = prefs.getDouble(_kSfxVol) ?? sfxVolume;
      tiltSteering = prefs.getBool(_kTilt) ?? tiltSteering;
      steeringSensitivity = prefs.getDouble(_kSteerSens) ?? steeringSensitivity;
      vibration = prefs.getBool(_kVibration) ?? vibration;
      cameraShake = prefs.getBool(_kCamShake) ?? cameraShake;
      useMph = prefs.getBool(_kUseMph) ?? useMph;
      final gIdx = prefs.getInt(_kGraphics);
      if (gIdx != null && gIdx >= 0 && gIdx < GraphicsTier.values.length) {
        graphics = GraphicsTier.values[gIdx];
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kMusicVol, musicVolume);
      await prefs.setDouble(_kSfxVol, sfxVolume);
      await prefs.setBool(_kTilt, tiltSteering);
      await prefs.setDouble(_kSteerSens, steeringSensitivity);
      await prefs.setBool(_kVibration, vibration);
      await prefs.setBool(_kCamShake, cameraShake);
      await prefs.setBool(_kUseMph, useMph);
      await prefs.setInt(_kGraphics, graphics.index);
    } catch (_) {}
  }

  void update(void Function() change) {
    change();
    notifyListeners();
    save();
  }
}

/// The app's single [GameSettings] instance — pushes volumes into
/// [AudioManager] on load and on every change, the way `main.dart`'s
/// `_onSettingsChanged` listener used to.
final gameSettingsProvider = ChangeNotifierProvider<GameSettings>((ref) {
  final settings = GameSettings();
  void pushVolumes() => AudioManager.instance.setVolumes(
    music: settings.musicVolume,
    sfx: settings.sfxVolume,
  );
  settings.addListener(pushVolumes);
  settings.load().then((_) => pushVolumes());
  ref.onDispose(() => settings.removeListener(pushVolumes));
  ref.onDispose(settings.dispose);
  return settings;
});

/// Chosen on first launch from a startup benchmark, then user-overridable.
/// The low tier targets 60fps on a mid-range 2021 Android.
enum GraphicsTier {
  low('Low', 'Render 70%, no shadows or bloom, 120 particles'),
  medium('Medium', 'Render 85%, directional shadows, bloom, 300 particles'),
  high('High', 'Full render, all shadows, god rays and DoF, 600 particles');

  const GraphicsTier(this.label, this.detail);

  final String label;
  final String detail;
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _section = 0;

  static const _sections = [
    ('Audio', DashIcons.sound),
    ('Controls', DashIcons.steeringWheel),
    ('Gameplay', DashIcons.boost),
    ('Graphics', DashIcons.star),
    ('Account', DashIcons.key),
    ('About', DashIcons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return DashBrawlScreen(
      title: 'Settings',
      onBack: widget.onBack,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: DashBreakpoint.of(context).isCompact ? 156 : 200,
            child: ListView.builder(
              itemCount: _sections.length,
              itemBuilder: (context, i) => _SectionTab(
                label: _sections[i].$1,
                icon: _sections[i].$2,
                active: i == _section,
                onTap: () => setState(() => _section = i),
              ),
            ),
          ),
          const SizedBox(width: DashSpace.x4),
          Expanded(
            child: DashCard(
              variant: DashCardVariant.raised,
              child: AnimatedSwitcher(
                duration: DashMotionScope.duration(context, DashMotion.fast),
                child: KeyedSubtree(key: ValueKey(_section), child: _body()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    // Riverpod already rebuilds this State whenever GameSettings notifies
    // (that's what `ref.watch` subscribes to), so `s.update(...)` needs no
    // wrapping `setState` the way the old `PlayerScope`-style access did.
    final s = ref.watch(gameSettingsProvider);
    return switch (_section) {
      0 => ListView(
        children: [
          _SliderRow(
            label: 'Music',
            value: s.musicVolume,
            icon: DashIcons.music,
            onChanged: (v) => s.update(() => s.musicVolume = v),
          ),
          _SliderRow(
            label: 'Sound Effects',
            value: s.sfxVolume,
            icon: DashIcons.sound,
            onChanged: (v) => s.update(() => s.sfxVolume = v),
          ),
        ],
      ),
      1 => ListView(
        children: [
          _SegmentRow(
            label: 'Steering',
            options: const ['Touch', 'Tilt'],
            index: s.tiltSteering ? 1 : 0,
            onChanged: (i) => s.update(() => s.tiltSteering = i == 1),
          ),
          _SliderRow(
            label: 'Sensitivity',
            value: s.steeringSensitivity,
            onChanged: (v) => s.update(() => s.steeringSensitivity = v),
          ),
          const _InfoRow(
            text:
                'Control positions can be moved during a race from the '
                'pause menu.',
          ),
        ],
      ),
      2 => ListView(
        children: [
          _ToggleRow(
            label: 'Vibration',
            value: s.vibration,
            onChanged: (v) => s.update(() => s.vibration = v),
          ),
          _ToggleRow(
            label: 'Camera Shake',
            value: s.cameraShake,
            onChanged: (v) => s.update(() => s.cameraShake = v),
          ),
          _SegmentRow(
            label: 'Speed Units',
            options: const ['KM/H', 'MPH'],
            index: s.useMph ? 1 : 0,
            onChanged: (i) => s.update(() => s.useMph = i == 1),
          ),
        ],
      ),
      3 => ListView(
        children: [
          _SegmentRow(
            label: 'Quality',
            options: [for (final t in GraphicsTier.values) t.label],
            index: s.graphics.index,
            onChanged: (i) =>
                s.update(() => s.graphics = GraphicsTier.values[i]),
          ),
          _InfoRow(text: s.graphics.detail),
        ],
      ),
      4 => _AccountSection(onReset: _confirmReset),
      _ => const _AboutSection(),
    };
  }

  Future<void> _confirmReset() async {
    final player = ref.read(playerProvider);
    final ok = await DashDialog.confirm(
      context,
      title: 'Reset progress?',
      message:
          'Every unlock, trophy, and best time is erased. '
          'This cannot be undone.',
      confirmLabel: 'Reset',
    );
    if (ok) player.resetProgress();
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final DashIcons icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashPressable(
      onPressed: onTap,
      semanticLabel: label,
      builder: (context, press, _) => AnimatedContainer(
        duration: DashMotionScope.duration(context, DashMotion.fast),
        margin: const EdgeInsets.only(bottom: DashSpace.x2),
        padding: const EdgeInsets.symmetric(
          horizontal: DashSpace.x4,
          vertical: DashSpace.x3,
        ),
        decoration: BoxDecoration(
          color: active ? DashColors.surfaceRaised : DashColors.surface,
          borderRadius: DashRadius.mdAll,
          border: Border.all(
            color: DashColors.pureBlack,
            width: active ? 2.5 : 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x8A000000),
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            DashIcon(
              icon,
              size: DashIconSize.md,
              color: active ? DashColors.orange.s500 : DashColors.textTertiary,
            ),
            const SizedBox(width: DashSpace.x3),
            Flexible(
              child: Text(
                label,
                style: DashType.h3.copyWith(
                  fontSize: 16,
                  color: active
                      ? DashColors.textPrimary
                      : DashColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A settings row. Composed, never a Material ListTile.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child, this.icon});

  final String label;
  final Widget child;
  final DashIcons? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DashColors.stroke)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            DashIcon(icon!, size: DashIconSize.md),
            const SizedBox(width: DashSpace.x3),
          ],
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: DashType.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final DashIcons? icon;

  @override
  Widget build(BuildContext context) {
    return _Row(
      label: label,
      icon: icon,
      child: Row(
        children: [
          Expanded(
            child: DashSlider(value: value, onChanged: onChanged),
          ),
          const SizedBox(width: DashSpace.x3),
          SizedBox(
            width: 44,
            child: Text(
              '${(value * 100).round()}',
              style: DashType.statValue,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// A drag track built from tokens rather than a Material Slider, which would
/// bring its own theme and thumb.
class DashSlider extends StatelessWidget {
  const DashSlider({super.key, required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        void handle(Offset local) =>
            onChanged((local.dx / box.maxWidth).clamp(0.0, 1.0));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => handle(d.localPosition),
          onHorizontalDragUpdate: (d) => handle(d.localPosition),
          child: SizedBox(
            height: 32,
            child: CustomPaint(painter: _SliderPainter(value.clamp(0.0, 1.0))),
          ),
        );
      },
    );
  }
}

class _SliderPainter extends CustomPainter {
  const _SliderPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final track = RRect.fromLTRBR(
      0,
      cy - 5,
      size.width,
      cy + 5,
      const Radius.circular(5),
    );
    canvas.drawRRect(track, Paint()..color = DashColors.surfaceSunken);

    final w = size.width * value;
    canvas.save();
    canvas.clipRRect(track);
    canvas.drawRect(
      Rect.fromLTWH(0, cy - 5, w, 10),
      Paint()
        ..shader = const LinearGradient(
          colors: DashGradients.speed,
        ).createShader(Offset.zero & size),
    );
    canvas.restore();

    canvas.drawCircle(
      Offset(w, cy),
      11,
      Paint()..color = DashColors.textPrimary,
    );
    canvas.drawCircle(
      Offset(w, cy),
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = DashColors.blue.s600,
    );
  }

  @override
  bool shouldRepaint(_SliderPainter old) => old.value != value;
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Row(
      label: label,
      child: Align(
        alignment: Alignment.centerLeft,
        child: DashPressable(
          onPressed: () => onChanged(!value),
          semanticLabel: label,
          builder: (context, press, _) => AnimatedContainer(
            duration: DashMotionScope.duration(context, DashMotion.fast),
            curve: DashMotionScope.curve(context, DashMotion.fastCurve),
            width: 60,
            height: 32,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value
                  ? DashColors.neonGreen.withValues(alpha: 0.28)
                  : DashColors.surfaceSunken,
              borderRadius: DashRadius.pillAll,
              border: Border.all(
                color: value ? DashColors.neonGreen : DashColors.stroke,
              ),
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? DashColors.neonGreen : DashColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({
    required this.label,
    required this.options,
    required this.index,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Row(
      label: label,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: DashColors.surfaceSunken,
            borderRadius: DashRadius.pillAll,
          ),
          child: Wrap(
            children: [
              for (var i = 0; i < options.length; i++)
                DashPressable(
                  onPressed: () => onChanged(i),
                  semanticLabel: options[i],
                  builder: (context, press, _) => AnimatedContainer(
                    duration: DashMotionScope.duration(
                      context,
                      DashMotion.fast,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashSpace.x3,
                      vertical: DashSpace.x2,
                    ),
                    decoration: BoxDecoration(
                      gradient: i == index
                          ? const LinearGradient(colors: DashGradients.speed)
                          : null,
                      borderRadius: DashRadius.pillAll,
                    ),
                    child: Text(
                      options[i].toUpperCase(),
                      style: DashType.label.copyWith(
                        color: i == index
                            ? DashColors.textPrimary
                            : DashColors.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DashSpace.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashRasterIcon(
            DashRasterIcons.info,
            size: DashIconSize.sm,
            color: DashColors.textTertiary,
          ),
          const SizedBox(width: DashSpace.x3),
          Expanded(child: Text(text, style: DashType.bodySm)),
        ],
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    return ListView(
      children: [
        _Row(
          label: 'Profile',
          child: Text(player.name, style: DashType.h3.copyWith(fontSize: 16)),
        ),
        _Row(
          label: 'Level',
          child: Text('${player.level}', style: DashType.statValue),
        ),
        const SizedBox(height: DashSpace.x5),
        Align(
          alignment: Alignment.centerLeft,
          child: DashButton(
            label: 'Reset Progress',
            icon: DashIcons.restart,
            variant: DashButtonVariant.danger,
            size: DashButtonSize.sm,
            onPressed: onReset,
          ),
        ),
      ],
    );
  }
}

/// Licence credits.
///
/// Not optional: two music tracks are CC-BY 3.0 and their attribution is a
/// condition of use. See docs/assets.md § 10.
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  static const _credits = [
    ('DashKart', 'Version 1.0.0'),
    (
      'Music — attribution required',
      '"Racing Menu" by Eric Matyas (soundimage.org), licensed CC-BY 3.0.\n'
          '"Arcade Racing Tune" by rezoner, licensed CC-BY 3.0.',
    ),
    (
      'Art, models and sound',
      'Kenney (kenney.nl) — CC0 1.0.\n'
          'Poly Haven (polyhaven.com) — CC0 1.0.\n'
          'ambientCG (ambientcg.com) — CC0 1.0.\n'
          'Freesound contributors — CC0 1.0.',
    ),
    (
      'Typefaces',
      'Lilita One © Juan Montoreano.\n'
          'Titan One © Rodrigo Fuenzalida.\n'
          'Fredoka © The Fredoka Project Authors.\n'
          'Chakra Petch © The Chakra Petch Project Authors.\n'
          'All under the SIL Open Font License 1.1.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _credits.length,
      separatorBuilder: (_, _) => const SizedBox(height: DashSpace.x4),
      itemBuilder: (context, i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_credits[i].$1.toUpperCase(), style: DashType.label),
          const SizedBox(height: DashSpace.x1),
          Text(_credits[i].$2, style: DashType.bodySm),
        ],
      ),
    );
  }
}
