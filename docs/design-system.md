# DashKart — Design System

The visual contract for the game. Every screen is built from these tokens and the
eleven components at the end. Nothing in the UI uses a raw Material widget, a default
`AppBar`, or an un-tokenised colour.

**Orientation: landscape-locked.** A kart racer's HUD wants width — steering left,
pedals right, minimap top-right. Menus follow the same orientation so there is never
a rotation stutter between menu and race.

---

## 1. Canvas and breakpoints

| | Logical size | Device |
|---|---|---|
| **Baseline** | **844 × 390** | iPhone 14 / 15 landscape — design here |
| Compact | ≤ 740 × 360 | Small Android, iPhone SE |
| Regular | 741 – 1000 | Baseline phones |
| Expanded | > 1000 | iPad, foldables — content caps at 1100 and centres |

Design at **2× (1688 × 780)** and export at 1×/2×/3×.

Everything sits inside `SafeArea`. Landscape notches eat the left or right edge
depending on rotation, so **no interactive element sits closer than 24 dp to a
horizontal screen edge**. The HUD's steering and pedal clusters respect
`MediaQuery.viewPadding` directly rather than a fixed inset.

---

## 2. Colour

### Brand ramps

Each brand colour is a 10-step ramp. `500` is the brand value; the UI mostly uses
`400`–`700`. Ramps exist so gradients, pressed states, and bevels stay in-family
instead of being ad-hoc `withOpacity` calls.

**DashKart Blue** — primary. Buttons, selection, brand.

| 50 | 100 | 200 | 300 | 400 | **500** | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|---|
| `#EAF1FE` | `#D0E0FD` | `#A3C2FB` | `#6E9DF8` | `#4482F6` | **`#2A6DF4`** | `#1B55D1` | `#1341A3` | `#0D2E75` | `#081C47` |

**Turbo Orange** — secondary. Boost, speed, energy, the RACE button.

| 50 | 100 | 200 | 300 | 400 | **500** | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|---|
| `#FFF2E8` | `#FFE0C7` | `#FFC291` | `#FFA35B` | `#FF8C33` | **`#FF7A18`** | `#E05F00` | `#B24A00` | `#843700` | `#562400` |

**Energy Yellow** — accent. Coins, stars, highlights, countdown.

| 50 | 100 | 200 | 300 | 400 | **500** | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|---|
| `#FFFAE6` | `#FFF2BF` | `#FFE785` | `#FFDC5C` | `#FFD53F` | **`#FFC61A`** | `#DBA400` | `#A87E00` | `#755800` | `#423200` |

### Supporting

| Token | Hex | Use |
|---|---|---|
| `neonGreen` | `#22E06B` | Unlocked, success, "GO!", positive stat delta |
| `racingRed` | `#FF3355` | Locked, danger, brake, negative stat delta |
| `skyBlue` | `#46C8FF` | Shield Orb, water, info, cool accents |
| `darkNavy` | `#0B1130` | The ground colour everything sits on |

### Surfaces — dark (default)

The game runs dark. Bright brand colours over a deep navy is what makes the
palette read as arcade rather than corporate.

| Token | Hex | Use |
|---|---|---|
| `bgBase` | `#0B1130` | Screen floor |
| `bgGradientTop` | `#16205A` | Top of the menu backdrop gradient |
| `bgGradientBottom` | `#080D22` | Bottom of the same gradient |
| `surface` | `#151D45` | Cards, panels |
| `surfaceRaised` | `#1E2A5C` | Selected card, dialog |
| `surfaceSunken` | `#0A0F28` | Stat bar troughs, input wells |
| `stroke` | `#2E3B72` | 1 dp hairlines |
| `strokeStrong` | `#4557A8` | Focus and selection rings |
| `scrim` | `#050814` @ 72 % | Behind dialogs |

### Surfaces — light

Used only where a screen genuinely reads better bright (Results, Garage under a
sunny track). Not a full user-facing theme.

| Token | Hex |
|---|---|
| `bgBaseLight` | `#F4F7FF` |
| `surfaceLight` | `#FFFFFF` |
| `surfaceRaisedLight` | `#FFFFFF` |
| `strokeLight` | `#D8E1F5` |

### Text

| Token | On dark | On light |
|---|---|---|
| `textPrimary` | `#FFFFFF` | `#0B1130` |
| `textSecondary` | `#B7C3E8` | `#48548A` |
| `textTertiary` | `#7382B8` | `#7382B8` |
| `textOnBrand` | `#FFFFFF` | — |
| `textOnAccent` | `#3B2A00` | — (dark text on Energy Yellow) |

### Signature gradients

| Name | Stops | Use |
|---|---|---|
| `gradTurbo` | `#FFC61A` → `#FF7A18` → `#E05F00` | RACE button, boost meter |
| `gradSpeed` | `#4482F6` → `#2A6DF4` → `#1341A3` | Primary buttons, headers |
| `gradVictory` | `#FFD53F` → `#FF8C33` | 1st place, trophies |
| `gradMenuSky` | `#16205A` → `#0B1130` → `#080D22` | Every menu backdrop |
| `gradShield` | `#46C8FF` → `#2A6DF4` | Shield Orb effects |

### Contrast

Every text/background pair must clear **WCAG AA 4.5:1** for body and **3:1** for
text ≥ 24 px. Verified pairs:

| Pair | Ratio |
|---|---|
| `textPrimary` on `bgBase` | 16.8 : 1 |
| `textSecondary` on `surface` | 7.4 : 1 |
| `textOnAccent` on `energyYellow.500` | 8.9 : 1 |
| White on `dashBlue.500` | 4.6 : 1 |
| White on `turboOrange.500` | 3.1 : 1 — **large text only**, never body |

Turbo Orange is a fill and glow colour, not a body-text background.

---

## 3. Typography

Three families, each with one job. All SIL OFL, vendored under `assets/fonts/`.

| Role | Family | Why |
|---|---|---|
| **Brand** | Titan One | Single-weight chunky arcade face. Wordmark, countdown, position number. Used sparingly — it has no lighter weight to fall back to. |
| **UI** | Fredoka (variable, `wght` 300–700 + `wdth`) | Rounded, playful, still legible at 12 px. Carries every heading, button, label, and body string. |
| **Numeric** | Chakra Petch (SemiBold / Bold / BoldItalic) | Techy squared face with even digit widths. Speed, lap, time, stat values. BoldItalic leans into the speed readout. |

### Scale

| Token | Family | Size / LH | Weight | Tracking | Use |
|---|---|---|---|---|---|
| `brandXL` | Titan One | 64 / 64 | 400 | +2 | DASHKART wordmark |
| `brandL` | Titan One | 44 / 46 | 400 | +1 | Screen titles, "1ST PLACE" |
| `countdown` | Titan One | 160 / 160 | 400 | 0 | 3 · 2 · 1 · GO! |
| `position` | Titan One | 52 / 52 | 400 | 0 | HUD position |
| `h1` | Fredoka | 32 / 38 | 600 | 0 | Section headers |
| `h2` | Fredoka | 24 / 30 | 600 | 0 | Card titles, kart names |
| `h3` | Fredoka | 20 / 26 | 600 | +0.2 | Sub-headers |
| `button` | Fredoka | 20 / 24 | 600 | +0.6 | Button labels (uppercase) |
| `buttonSm` | Fredoka | 16 / 20 | 600 | +0.4 | Compact buttons |
| `body` | Fredoka | 16 / 24 | 400 | 0 | Descriptions, settings |
| `bodySm` | Fredoka | 14 / 20 | 400 | 0 | Secondary copy |
| `label` | Fredoka | 12 / 16 | 500 | +0.8 | Uppercase stat labels |
| `speed` | Chakra Petch | 44 / 44 | 700 italic | -1 | HUD speed value |
| `speedUnit` | Chakra Petch | 14 / 16 | 600 | +1.5 | "KM/H" |
| `lap` | Chakra Petch | 26 / 30 | 700 | +0.5 | LAP 2/3 |
| `timer` | Chakra Petch | 22 / 26 | 600 | +0.5 | Race and lap times |
| `statValue` | Chakra Petch | 18 / 22 | 700 | 0 | Stat numbers |

**Rules**
- Titan One is never below 28 px and never used for more than four words.
- Numerals that update every frame (speed, timer) use Chakra Petch with
  `FontFeature.tabularFigures()` so digits do not jitter.
- Button labels are uppercase; body copy is never uppercase.
- Text over live 3D always carries a shadow or a scrim — see § HUD legibility.

---

## 4. Spacing, radius, elevation

### Spacing — 4 dp base

`space.1` 4 · `space.2` 8 · `space.3` 12 · `space.4` 16 · `space.5` 20 · `space.6` 24 ·
`space.8` 32 · `space.10` 40 · `space.12` 48 · `space.16` 64 · `space.20` 80

Screen gutter 24 (compact 16). Card padding 20. Gap between cards 16. Section gap 32.

### Radius

| Token | Value | Use |
|---|---|---|
| `radius.sm` | 8 | Chips, small tags |
| `radius.md` | 14 | Buttons, stat bars |
| `radius.lg` | 20 | Cards |
| `radius.xl` | 28 | Dialogs, hero panels |
| `radius.pill` | 999 | Currency pills, toggles |

Nothing in DashKart is a square-cornered rectangle.

### Elevation

Soft ambient shadow plus a coloured glow. The glow is what makes buttons feel lit
rather than pasted on.

| Token | Shadow | Glow |
|---|---|---|
| `elev.card` | `0 4 16 rgba(5,8,20,.40)` | — |
| `elev.raised` | `0 8 24 rgba(5,8,20,.50)` | — |
| `elev.button` | `0 4 0 <brand.700>` (hard bevel) + `0 6 18 rgba(5,8,20,.45)` | — |
| `elev.buttonGlow` | as above | `0 0 28 <brand.400> @ 45 %` |
| `elev.dialog` | `0 16 48 rgba(5,8,20,.65)` | — |
| `elev.hero` | `0 12 40 rgba(5,8,20,.55)` | `0 0 60 <turbo.500> @ 30 %` |

The `0 4 0` hard offset is the arcade button bevel — a solid darker edge under the
face, no blur. Pressing collapses it to `0 1 0` and moves the face down 3 dp.

### Icon sizes

12 · 16 · **20** · 24 · 32 · 40 · 56 (default 20). Stroke-equivalent weight is fixed
by the Kenney SVG set; icons are tinted, never restyled.

---

## 5. Motion

Everything is spring-based or eased-out. Nothing uses a linear curve except
continuous loops.

| Token | Duration | Curve | Use |
|---|---|---|---|
| `motion.tap` | 90 ms | `easeOutQuad` | Button press down |
| `motion.release` | 180 ms | `easeOutBack` (1.4) | Button release |
| `motion.fast` | 160 ms | `easeOutCubic` | Chips, toggles, tooltips |
| `motion.base` | 260 ms | `easeOutCubic` | Card enter, stat fill |
| `motion.slow` | 420 ms | `easeOutQuint` | Screen transitions |
| `motion.hero` | 650 ms | `easeOutBack` (1.2) | Kart swap, hero reveal |
| `motion.celebrate` | 900 ms | `elasticOut` | Results, unlock |

**Stagger:** list and grid children enter 40 ms apart, capped at 8 children.
**Reduced motion:** when `MediaQuery.disableAnimations` is set, durations collapse
to 0 and springs become cross-fades. Confetti and camera shake are suppressed.

---

## 6. HUD legibility

The HUD sits over live 3D, where the background is uncontrolled. Rules:

- Every HUD text element gets `0 2 6 rgba(0,0,0,.75)` text shadow **and** sits on a
  scrim: either a `surface @ 55 %` blurred pill or a top/bottom gradient scrim.
- Top scrim: `#000` 45 % → transparent, 88 dp tall.
- Bottom scrim: `#000` 35 % → transparent, 120 dp tall.
- Control buttons hold ≥ 3:1 contrast against both a snow track and a night track,
  which is why they use filled Kenney frames rather than outline-only glyphs.
- Minimum touch target **48 × 48 dp**; driving controls are 72–96 dp.

---

## 7. Graphics tiers

Exposed on Settings ▸ Graphics. Chosen so the low tier holds 60 fps on a mid-range
Android from ~2021.

| | Low | Medium | High |
|---|---|---|---|
| Render scale | 0.7× | 0.85× | 1.0× |
| HDRI | 1K | 2K | 2K |
| Shadows | Off | Directional only | Directional + spot |
| Bloom | Off | On | On |
| God rays / SSR / DoF | Off | Off | On |
| Particle budget | 120 | 300 | 600 |
| Prop LOD bias | +1 | 0 | 0 |
| Target | 60 fps | 60 fps | 60 fps |

Tier is auto-selected on first launch from a one-second startup benchmark, then
user-overridable.

---

## 8. Components

Eleven reusable widgets. Each lists its variants, sizes, and states.

### `DashButton`
Primary action button. Gradient face, hard bevel, optional glow, optional icon.

- **Variants:** `primary` (gradSpeed), `turbo` (gradTurbo), `success` (neonGreen),
  `danger` (racingRed), `ghost` (transparent + `stroke` border)
- **Sizes:** `sm` 40 h / 16 px label · `md` 52 h / 20 px · `lg` 64 h / 20 px ·
  `hero` 76 h / 24 px (RACE only)
- **States:** default · pressed (face +3 dp down, bevel 4→1) · disabled (40 %,
  no glow) · loading (label swaps for a spinner) · focused (2 dp `strokeStrong` ring)
- **Anatomy:** 24 dp horizontal padding, icon 20 dp with 8 dp gap, `radius.md`
- Haptic `lightImpact` on press; `selectionClick` for `ghost`.

### `DashIconButton`
Square/round icon-only button. 44 · 52 · 64 dp. Same variants and states as
`DashButton`. Used for back, pause, settings, carousel arrows.

### `DashCard`
Base container: `surface`, `radius.lg`, `elev.card`, 20 dp padding, optional 1 dp
`stroke`. Variants: `flat` · `raised` (selected) · `outlined` · `gradient`
(brand gradient face for hero cards). Selected state adds a 2 dp `strokeStrong`
ring and lifts to `elev.raised` over `motion.base`.

### `DashStatBar`
Animated stat meter for Speed / Acceleration / Handling / Drift / Weight.

- Trough `surfaceSunken`, 10 dp tall, `radius.pill`
- Fill is a brand gradient, animated 0 → value over `motion.base` with a 40 ms
  per-row stagger
- Optional ghost marker showing the previously selected kart's value, so
  comparison is readable while swapping karts
- Label `label` style left, value `statValue` right
- Delta chip (`+12` green / `−8` red) when comparing

### `DashChip`
Small pill for difficulty, environment, lock state, rarity. 28 dp tall,
`radius.pill`, 10 dp horizontal padding, `label` type. Variants: `neutral` ·
`success` · `warning` · `danger` · `locked` (with `icon_lock`).

### `DashDialog`
Modal. `surfaceRaised`, `radius.xl`, `elev.dialog`, 72 % scrim, max width 520.
Enters with scale 0.92 → 1.0 + fade over `motion.hero`. Title `h2`, body `body`,
actions right-aligned `DashButton`s. Dismiss on scrim tap unless `barrierDismissible: false`.

### `DashBottomNav`
Persistent menu navigation. 72 dp tall, floating pill `radius.pill` inset 24 dp
from the bottom, `surface` at 92 % with a 16 dp backdrop blur. 4–5 items: icon 24
+ `label`. Active item lifts 4 dp, tints `turboOrange.500`, and shows a glow dot.

### `DashKartCard`
Kart carousel item. 132 × 168 dp. Kart render on `gradMenuSky`, name `h3` beneath,
mini stat row, lock overlay when locked (blur + `icon_lock` + unlock cost).
Selected: 2 dp `turboOrange.500` ring, scale 1.06, `elev.hero` glow.

### `DashTrackCard`
Track selection item. 280 × 180 dp, `radius.lg`. Preview image with a
bottom-up gradient scrim; name `h2` and environment `DashChip` overlaid at the
bottom; difficulty as 1–3 filled chevrons top-right; best time `timer` and
trophy icon in a bottom bar. Locked state: desaturated preview + lock + requirement.

### `DashItemSlot`
HUD item holder. 72 × 72 dp, `radius.lg`, `surface @ 55 %` with blur and a 2 dp
`stroke` ring. Empty: dashed ring at 40 %. Rolling: item icons cycle every 80 ms
with a blur. Locked in: scale punch to 1.15 → 1.0 (`motion.hero`) + colour flash.
Ready: slow 1.0 ↔ 1.04 pulse and a matching glow. Cooldown: radial sweep dimming
the icon to 40 %.

### `DashGameHUD`
Composition root for the race overlay. Owns the two scrims and positions:
position (top-left), lap (top-centre), minimap (top-right), speed
(bottom-centre-left), item slot (bottom-centre), steering (bottom-left),
pedals (bottom-right). Reads control positions from settings so §12's
"reposition controls later" is a layout change, not a rewrite.

---

## 9. Rendering architecture

| Layer | Technology | Why |
|---|---|---|
| Menus, HUD, dialogs | Flutter widgets + `CustomPainter` | Where Flutter is strongest, and where the premium bar is judged |
| Race scene | **`flutter_scene` 0.22.2** | Only real glTF/PBR 3D engine for Flutter; loads the Kenney `.glb` directly |
| Physics | `flutter_scene_rapier` | Shares flutter_scene's physics contract |
| Audio | `flutter_soloud` | Low-latency, pitch-shifting for engine RPM |

**`flutter_scene` requires Flutter ≥ 3.47** — the project is on 3.47.0 via FVM, so
this is satisfied exactly. Flutter GPU must be enabled per platform:

- `ios/Runner/Info.plist` → `<key>FLTEnableFlutterGPU</key><true/>`
- `android/app/src/main/AndroidManifest.xml`, inside `<application>` →
  `<meta-data android:name="io.flutter.embedding.android.EnableFlutterGPU" android:value="true" />`

`dart run flutter_scene:init` writes `hook/build.dart`, which converts `.glb`,
HDRIs, and textures into the engine's `.fsceneb`/`.fstex` formats at build time.
That conversion is what keeps track load times low and is where KTX2 texture
compression happens.

**Risk:** `flutter_scene` is pre-1.0 and documents that minor releases can carry
breaking changes. Mitigation: the race renderer sits behind a `RaceRenderer`
interface so the engine can be pinned or swapped without touching game logic, and
the version is pinned exactly (`flutter_scene: 0.22.2`, no caret) until 1.0.

---

## 10. Asset-backed component map

Which sourced asset each component is built from. Full records in [assets.md](assets.md).

| Component | Asset | Path |
|---|---|---|
| `DashButton` face | Kenney UI Pack `button_rectangle_depth_gloss.svg` | `assets/images/ui/frames/` |
| `DashIconButton` | Kenney UI Pack `button_round_depth_flat.svg` | `assets/images/ui/frames/` |
| `DashCard` frame | Kenney UI Pack Extra panels | `assets/images/ui/frames/` |
| `DashStatBar` | Kenney UI Pack `slide_horizontal_color*.svg` | `assets/images/ui/frames/` |
| `DashChip` | Kenney UI Pack rounded panels | `assets/images/ui/frames/` |
| `DashItemSlot` | Kenney Mobile Controls `button_square.svg` | `assets/images/ui/controls/` |
| Steering control | Kenney Mobile Controls `dpad_separate` + `direction_*` | `assets/images/ui/controls/` |
| Pedals | `button_circle_wide` + `_highlight` | `assets/images/ui/controls/` |
| Drift / item buttons | `button_bean`, `button_diamond` + `_highlight` | `assets/images/ui/controls/` |
| All icons | Kenney Mobile Controls `Vector/Icons` | `assets/images/ui/icons/` |
| Trophy / home / unlock | Kenney Game Icons (white PNG, tinted) | `assets/images/ui/icons-raster/` |
| Boost / drift FX | Kenney Particle Pack `flame_*`, `smoke_*`, `spark_*` | `assets/particles/` |
| Speed lines | Kenney Particle Pack `trace_*` | `assets/particles/` |
| Karts | Kenney Car Kit `kart-*.glb` | `assets/models/karts/` |
| Racers | Kenney Mini Characters (`drive` clip) | `assets/models/characters/` |
| Track pieces | Kenney Racing Kit + Toy Car Kit | `assets/models/tracks/` |
| Item box | Kenney Toy Car Kit `item-box.glb` | `assets/models/environment/` |
| Skies | Poly Haven HDRI, one per track | `assets/environments/` |
| Road / terrain | ambientCG PBR sets | `assets/textures/` |
