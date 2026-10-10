import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashkart/core/audio/audio_manager.dart';
import 'package:dashkart/core/feedback/haptics.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/core/theme/theme.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/core/scaffold/dash_brawl_screen.dart';
import 'package:dashkart/features/settings/graphics_tier.dart';
import 'package:dashkart/features/settings/steering_mode.dart';

// Re-exported: both are read by the race scene and the HUD, so they live in
// their own files rather than behind a screen — but every caller that
// reaches them through the settings still can.
export 'package:dashkart/features/settings/graphics_tier.dart';
export 'package:dashkart/features/settings/steering_mode.dart';

/// Player-facing settings.
///
/// Every field here is read by something. Before, five of them — tilt,
/// sensitivity, vibration, camera shake and the graphics tier — persisted
/// faithfully and were never looked at again, so most of this screen was a
/// set of controls that did nothing.
class GameSettings extends ChangeNotifier {
  static const _kMusicVol = 'dashkart_settings_music_vol';
  static const _kSfxVol = 'dashkart_settings_sfx_vol';
  static const _kSteering = 'dashkart_settings_steering_mode';
  static const _kSteerSens = 'dashkart_settings_steer_sens';
  static const _kVibration = 'dashkart_settings_vibration';
  // A new key on purpose: shake used to default on, and a saved `true` would
  // otherwise keep it on for everyone who had ever opened Settings.
  static const _kCamShake = 'dashkart_settings_cam_shake_v2';
  static const _kUseMph = 'dashkart_settings_use_mph';
  static const _kGraphics = 'dashkart_settings_graphics';

  double musicVolume = 0.7;
  double sfxVolume = 0.85;
  SteeringMode steering = SteeringMode.buttons;
  double steeringSensitivity = 0.6;
  bool vibration = true;
  bool cameraShake = false;
  bool useMph = false;
  GraphicsTier graphics = GraphicsTier.medium;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      musicVolume = prefs.getDouble(_kMusicVol) ?? musicVolume;
      sfxVolume = prefs.getDouble(_kSfxVol) ?? sfxVolume;
      steeringSensitivity = prefs.getDouble(_kSteerSens) ?? steeringSensitivity;
      vibration = prefs.getBool(_kVibration) ?? vibration;
      cameraShake = prefs.getBool(_kCamShake) ?? cameraShake;
      useMph = prefs.getBool(_kUseMph) ?? useMph;
      steering =
          _enumAt(SteeringMode.values, prefs.getInt(_kSteering)) ?? steering;
      graphics =
          _enumAt(GraphicsTier.values, prefs.getInt(_kGraphics)) ?? graphics;
      notifyListeners();
    } catch (_) {}
  }

  /// A stored index is only usable if it is still in range — a build that
  /// removed an enum value would otherwise throw on load and lose every
  /// other setting with it.
  static T? _enumAt<T>(List<T> values, int? index) =>
      index != null && index >= 0 && index < values.length
      ? values[index]
      : null;

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kMusicVol, musicVolume);
      await prefs.setDouble(_kSfxVol, sfxVolume);
      await prefs.setInt(_kSteering, steering.index);
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
  // Audio volumes and the haptics gate are consumed by singletons with no
  // `ref` of their own — the audio engine and physics callbacks — so they are
  // pushed out here on load and on every change, rather than read back.
  void push() {
    AudioManager.instance.setVolumes(
      music: settings.musicVolume,
      sfx: settings.sfxVolume,
    );
    Haptics.enabled = settings.vibration;
  }

  settings.addListener(push);
  settings.load().then((_) => push());
  ref.onDispose(() => settings.removeListener(push));
  return settings;
});

// --- Theme --------------------------------------------------------------------
//
// The settings screen shares the look of the shop, the pause menu and the
// results board: ink-outlined LilitaOne text, black-bordered panels on the
// blue gradient with a hard bevel under them, and the same arcade tones for
// anything pressable. Selected states are yellow, "on" is green, destructive
// is red — the same meanings those screens already use.

const _tabGradient = [Color(0xFF34479F), Color(0xFF1B2A86)];
const _bevel = BrawlPanel.bevel;
const _softText = BrawlPanel.softText;
const _gold = BrawlPanel.gold;

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
    final compact = DashBreakpoint.of(context).isCompact;
    return DashBrawlScreen(
      title: 'Settings',
      onBack: widget.onBack,
      child: Padding(
        // Room for the bevel under the plates, which would otherwise be
        // clipped by the screen's own margin.
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: compact ? 148 : 190,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 6),
                itemCount: _sections.length,
                itemBuilder: (context, i) => _SectionTab(
                  label: _sections[i].$1,
                  icon: _sections[i].$2,
                  active: i == _section,
                  compact: compact,
                  onTap: () => setState(() => _section = i),
                ),
              ),
            ),
            SizedBox(width: compact ? DashSpace.x3 : DashSpace.x4),
            Expanded(
              child: BrawlPanel(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 18,
                  vertical: 6,
                ),
                child: AnimatedSwitcher(
                  duration: DashMotionScope.duration(context, DashMotion.fast),
                  child: KeyedSubtree(key: ValueKey(_section), child: _body()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    // Riverpod already rebuilds this State whenever GameSettings notifies
    // (that's what `ref.watch` subscribes to), so `s.update(...)` needs no
    // wrapping `setState`.
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
            options: [for (final m in SteeringMode.values) m.label],
            index: s.steering.index,
            onChanged: (i) =>
                s.update(() => s.steering = SteeringMode.values[i]),
          ),
          _SliderRow(
            label: 'Sensitivity',
            value: s.steeringSensitivity,
            onChanged: (v) => s.update(() => s.steeringSensitivity = v),
          ),
          _InfoRow(
            text: switch (s.steering) {
              SteeringMode.buttons =>
                'Two held buttons under your left thumb. Sensitivity sets '
                    'how quickly they reach full lock.',
              SteeringMode.analog =>
                'Press the pad under your left thumb and slide. How far you '
                    'slide is how much lock you get.',
            },
          ),
          const _InfoRow(
            text:
                'Hold DRIFT through a corner to slide, then release it once '
                'the meter fills for a mini turbo.',
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
          // Generated from the tier's own numbers, so the description cannot
          // promise something the renderer does not do.
          _InfoRow(text: s.graphics.detail),
          const _InfoRow(text: 'Takes effect on the next race you start.'),
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

/// A section tab on the left rail. The selected one lights up yellow, the way
/// an equipped card does elsewhere.
class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final DashIcons icon;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DashPressable(
        onPressed: onTap,
        semanticLabel: label,
        builder: (context, press, _) => Transform.translate(
          // Sinks into its own bevel while pressed.
          offset: Offset(0, press * 3),
          child: BrawlPanel(
            colors: active ? BrawlButtonTone.yellow.gradient : _tabGradient,
            radius: 12,
            borderWidth: 3,
            depth: 4 - press * 3,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 8 : 9,
            ),
            child: Row(
              children: [
                DashIcon(
                  icon,
                  size: compact ? DashIconSize.sm : DashIconSize.md,
                  color: active ? DashColors.textPrimary : _softText,
                ),
                SizedBox(width: compact ? 8 : 10),
                Expanded(
                  child: BrawlInkText(
                    label.toUpperCase(),
                    fontSize: compact ? 13 : 15,
                    weight: BrawlInkWeight.heavy,
                    color: active ? DashColors.textPrimary : _softText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A settings row: an inked label, then the control. Separated from the next
/// by a faint rule rather than a box of its own.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child, this.icon});

  final String label;
  final Widget child;
  final DashIcons? icon;

  @override
  Widget build(BuildContext context) {
    final compact = DashBreakpoint.of(context).isCompact;
    return Container(
      height: compact ? 54 : 60,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x33FFFFFF))),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            DashIcon(icon!, size: DashIconSize.md, color: _softText),
            const SizedBox(width: DashSpace.x2),
          ],
          SizedBox(
            width: compact ? 104 : 136,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: BrawlInkText(
                label.toUpperCase(),
                fontSize: 14,
                weight: BrawlInkWeight.heavy,
                maxLines: 1,
              ),
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
            child: BrawlInkText(
              '${(value * 100).round()}',
              fontSize: 17,
              weight: BrawlInkWeight.heavy,
              color: _gold,
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

  /// Space reserved at each end so the knob stays inside the track's width.
  static const _inset = 14.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        void handle(Offset local) => onChanged(
          ((local.dx - _inset) / (box.maxWidth - _inset * 2)).clamp(0.0, 1.0),
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => handle(d.localPosition),
          onHorizontalDragUpdate: (d) => handle(d.localPosition),
          child: SizedBox(
            height: 40,
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
    const inset = DashSlider._inset;
    final cy = size.height / 2;
    final track = RRect.fromLTRBR(
      inset - 6,
      cy - 8,
      size.width - inset + 6,
      cy + 8,
      const Radius.circular(8),
    );

    // Sunken groove with a black ink border.
    canvas.drawRRect(track, Paint()..color = _bevel);

    final x = inset + (size.width - inset * 2) * value;
    canvas.save();
    canvas.clipRRect(track);
    canvas.drawRect(
      Rect.fromLTRB(track.left, track.top, x, track.bottom),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: BrawlButtonTone.green.gradient,
        ).createShader(track.outerRect),
    );
    // Specular streak along the top of the fill.
    canvas.drawRect(
      Rect.fromLTRB(track.left, track.top + 2, x, track.top + 5),
      Paint()..color = const Color(0x55FFFFFF),
    );
    canvas.restore();
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = DashColors.pureBlack,
    );

    // Knob: cream face, ink ring, hard drop under it.
    canvas.drawCircle(Offset(x, cy + 2.5), 13, Paint()..color = _bevel);
    canvas.drawCircle(
      Offset(x, cy),
      13,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFD6DEFF)],
        ).createShader(Rect.fromCircle(center: Offset(x, cy), radius: 13)),
    );
    canvas.drawCircle(
      Offset(x, cy),
      13,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = DashColors.pureBlack,
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
            width: 72,
            height: 36,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              borderRadius: DashRadius.pillAll,
              border: Border.all(color: DashColors.pureBlack, width: 3),
              boxShadow: const [BoxShadow(color: _bevel, offset: Offset(0, 3))],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: value
                    ? BrawlButtonTone.green.gradient
                    : BrawlButtonTone.grey.gradient,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The state, spelled out on the side the knob is not on —
                // colour alone is a poor way to say on or off.
                Align(
                  alignment: value
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: BrawlInkText(
                      value ? 'ON' : 'OFF',
                      fontSize: 11,
                      weight: BrawlInkWeight.heavy,
                    ),
                  ),
                ),
                Align(
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DashColors.textPrimary,
                      border: Border.all(
                        color: DashColors.pureBlack,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
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
    final compact = DashBreakpoint.of(context).isCompact;
    return _Row(
      label: label,
      child: Align(
        alignment: Alignment.centerLeft,
        // A sunken tray the options sit in; the chosen one pops out of it in
        // yellow.
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _bevel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DashColors.pureBlack, width: 3),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: i == index
                          ? Border.all(color: DashColors.pureBlack, width: 2)
                          : null,
                      gradient: i == index
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: BrawlButtonTone.yellow.gradient,
                            )
                          : null,
                    ),
                    child: BrawlInkText(
                      options[i].toUpperCase(),
                      fontSize: compact ? 12 : 13,
                      weight: BrawlInkWeight.heavy,
                      color: i == index ? DashColors.textPrimary : _softText,
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
      padding: const EdgeInsets.symmetric(vertical: DashSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashRasterIcon(
            DashRasterIcons.info,
            size: DashIconSize.sm,
            color: _softText,
          ),
          const SizedBox(width: DashSpace.x3),
          Expanded(
            child: BrawlInkText(
              text,
              fontSize: 12,
              weight: BrawlInkWeight.light,
              color: _softText,
              letterSpacing: 0.3,
            ),
          ),
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
    final compact = DashBreakpoint.of(context).isCompact;

    Widget value(String text) => Align(
      alignment: Alignment.centerLeft,
      child: BrawlInkText(
        text,
        fontSize: 17,
        weight: BrawlInkWeight.heavy,
        color: _gold,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return ListView(
      children: [
        _Row(label: 'Profile', child: value(player.name.toUpperCase())),
        _Row(
          label: 'Level',
          child: value(
            '${player.level}  ·  ${(player.levelProgress * 100).round()}%',
          ),
        ),
        _Row(label: 'Trophies', child: value('${player.trophies}')),
        _Row(label: 'Races', child: value('${player.racesFinished}')),
        const SizedBox(height: DashSpace.x4),
        Align(
          alignment: Alignment.centerLeft,
          child: BrawlActionButton(
            label: 'RESET PROGRESS',
            tone: BrawlButtonTone.red,
            width: compact ? 190 : 230,
            height: compact ? 44 : 50,
            fontSize: compact ? 16 : 18,
            onPressed: onReset,
          ),
        ),
        const SizedBox(height: DashSpace.x2),
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
      padding: const EdgeInsets.symmetric(vertical: DashSpace.x2),
      itemCount: _credits.length,
      separatorBuilder: (_, _) => const SizedBox(height: DashSpace.x3),
      itemBuilder: (context, i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrawlInkText(
            _credits[i].$1.toUpperCase(),
            fontSize: 14,
            weight: BrawlInkWeight.heavy,
            color: _gold,
          ),
          const SizedBox(height: DashSpace.x1),
          BrawlInkText(
            _credits[i].$2,
            fontSize: 12,
            weight: BrawlInkWeight.light,
            color: _softText,
            letterSpacing: 0.3,
          ),
        ],
      ),
    );
  }
}
