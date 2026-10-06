# DashKart — Screen Layout Specifications

Layout specs for all ten screens. Coordinates are logical dp on the **844 × 390
landscape baseline**; see [design-system.md](design-system.md) § 1 for breakpoints.
Tokens (`space.4`, `radius.lg`, `motion.base`) are defined there.

Every screen is inside `SafeArea`. No `Scaffold.appBar` anywhere — headers are
composed from `DashIconButton` + a title, floating over the backdrop.

---

## 1. Splash

```
┌────────────────────────────────────────────────────────────────┐
│  gradMenuSky backdrop, blurred dash-valley HDRI still           │
│                                                                 │
│        ╱╱╱      ┌──────────────┐                               │
│      ╱╱╱   ◄────│   DASHKART   │  brandXL, Titan One 64        │
│    ╱╱╱          └──────────────┘  gradSpeed + gradTurbo        │
│  speed lines         ▁▁▁▁▁▁                                    │
│  (trace_*)          🏎  kart-oobi, 3/4 view, enters from left  │
│                                                                 │
│              ●━━━━━━━━━━━━━━━━━━●   tyre-track progress arc    │
└────────────────────────────────────────────────────────────────┘
```

| Element | Position | Size | Style |
|---|---|---|---|
| Backdrop | fill | 844 × 390 | `gradMenuSky` + HDRI still at 30 % |
| Speed lines | left third | — | `trace_*`, additive, drift right |
| Kart | centre, y 210 | 320 wide | `kart-oobi.glb`, 15° yaw |
| Logo | centre, y 140 | 420 × 96 | `brandXL` |
| Progress | centre, y 330 | 280 × 6 | `radius.pill`, `gradTurbo` fill |

**Timeline** (2 400 ms total, skippable on tap after 800 ms)

| ms | Beat |
|---|---|
| 0–400 | Backdrop fades in, gradient pans up 12 dp |
| 300–800 | Kart slides in from x −340 → 262, `easeOutBack(1.2)` |
| 600–1000 | Speed lines spawn; `spark_*` burst at the rear wheels |
| 800–1400 | Logo scales 0.7 → 1.0 with a 40 ms letter stagger, `motion.hero` |
| 1000–2200 | Progress arc fills against real asset-load progress |
| 2200–2400 | Whole stack lifts −20 dp and fades → Main Menu |

Audio: rising sting from `music-jingles` at 300 ms; engine blip at 600 ms.
**Reduced motion:** logo and kart cross-fade in place over 400 ms.

---

## 2. Main menu

```
┌────────────────────────────────────────────────────────────────┐
│ ┌──────────┐                                    ┌────────────┐ │
│ │ 👤 Dash  │  profile card                      │ 🪙 12,450  │ │
│ │ LV 7  ▓▓▓│                                    │ 🏆 14      │ │
│ └──────────┘                                    └────────────┘ │
│                                                                 │
│                      D A S H K A R T                            │
│                                                                 │
│              ┌────────────────────────┐                        │
│              │        R A C E         │  hero, gradTurbo       │
│              └────────────────────────┘                        │
│                                                                 │
│   ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐              │
│   │ KARTS  │  │ TRACKS │  │ GARAGE │  │SETTINGS│              │
│   └────────┘  └────────┘  └────────┘  └────────┘              │
│                                                                 │
│  live 3D: hero kart + racer idling on a road loop, HDRI sky    │
└────────────────────────────────────────────────────────────────┘
```

| Element | Position | Size |
|---|---|---|
| Live 3D backdrop | fill | `SceneView`, camera orbits 4°, 0.05 rad/s |
| Profile card | 24, 20 | 180 × 64, `DashCard` flat |
| Currency pills | right, 24, 20 | auto × 32, `radius.pill` |
| Wordmark | centre, y 96 | 360 × 64 |
| RACE | centre, y 190 | 300 × 76, `DashButton` hero |
| Secondary row | centre, y 296 | 4 × 148 × 52, gap `space.4` |

- Karts / racer are the player's current selection, so the menu reflects the garage.
- Idle > 6 s: kart does a slow 360° turntable.
- Enter: buttons stagger up 24 dp, 40 ms apart, `motion.base`.
- Compact: secondary row becomes 2 × 2; wordmark drops to 280 wide.

---

## 3. Kart selection

```
┌────────────────────────────────────────────────────────────────┐
│ ◄ back            S E L E C T   K A R T          🪙 12,450     │
│ ┌───────────────────────┐ ┌──────────────────────────────────┐ │
│ │                       │ │  DASHSTER                        │ │
│ │      3D kart on a     │ │  Balanced all-rounder            │ │
│ │      lit turntable    │ │                                  │ │
│ │      + racer seated   │ │  SPEED        ▓▓▓▓▓▓░░░░  6      │ │
│ │                       │ │  ACCELERATION ▓▓▓▓▓▓▓░░░  7      │ │
│ │   ◄               ►   │ │  HANDLING     ▓▓▓▓▓▓▓▓░░  8      │ │
│ └───────────────────────┘ │  DRIFT        ▓▓▓▓▓▓░░░░  6      │ │
│                            │  WEIGHT       ▓▓▓▓▓░░░░░  5      │ │
│                            │       ┌──────────────────┐       │ │
│                            │       │     S E L E C T  │       │ │
│ ┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐  └──────────────────────────────────┘ │
│ │▓▓││  ││  ││🔒││🔒││🔒│   carousel, selected scales 1.06      │
│ └──┘└──┘└──┘└──┘└──┘└──┘                                       │
└────────────────────────────────────────────────────────────────┘
```

| Element | Position | Size |
|---|---|---|
| Header | 24, 16 | back 44², title `brandL` centred |
| Preview panel | 24, 68 | 372 × 216, `DashCard` gradient |
| Info panel | 420, 68 | 400 × 216, `DashCard` raised |
| Stat rows | inside info | 5 × (label + `DashStatBar` + value), 32 h |
| SELECT | info bottom-right | 180 × 52 |
| Carousel | 24, 300 | 796 × 76, horizontal `DashKartCard` |

- Swapping karts: outgoing kart exits left with a 6° roll, incoming enters right,
  `motion.hero`. Stat bars re-animate from the *previous* kart's value, and a ghost
  marker holds the old value so the comparison is legible mid-swap.
- Locked: preview desaturates to 30 %, panel shows the unlock requirement and an
  `UNLOCK · 2 000 🪙` button in place of SELECT.
- Drag-to-spin the turntable; release snaps back over 600 ms.

---

## 4. Character selection

Mirrors kart selection so the two feel like one flow.

```
┌────────────────────────────────────────────────────────────────┐
│ ◄ back          S E L E C T   R A C E R                        │
│ ┌───────────────────────┐ ┌──────────────────────────────────┐ │
│ │                       │ │  NOVA                            │ │
│ │   full-body racer     │ │  "Calm precision driver"         │ │
│ │   idle → emote-yes    │ │                                  │ │
│ │   on select           │ │  SIGNATURE KART   ▸ Bolt-X       │ │
│ │                       │ │  BONUS            ▸ +1 Handling  │ │
│ └───────────────────────┘ └──────────────────────────────────┘ │
│  ⬤ ⬤ ⬤ ⬤ ⬤ ⬤ ⬤ ⬤   8 circular portraits, 64 dp             │
└────────────────────────────────────────────────────────────────┘
```

- Plays `idle` on the roster; on tap plays `emote-yes` once then returns to `idle`.
- Selected portrait: 2 dp `turboOrange.500` ring, scale 1.12, glow.
- Signature-kart row is tappable and deep-links to kart selection.

---

## 5. Track selection

```
┌────────────────────────────────────────────────────────────────┐
│ ◄ back           S E L E C T   T R A C K          🏆 14        │
│                                                                 │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐           │
│  │ [preview]    │ │ [preview]    │ │ [preview] 🔒 │           │
│  │           ▸▸ │ │          ▸▸▸ │ │          ▸▸  │           │
│  │ DASH VALLEY  │ │ NEON CIRCUIT │ │ DESERT RUSH  │           │
│  │ 🌿 Grassland │ │ 🌃 City      │ │ 🏜 Desert    │           │
│  │ 🏆 1:42.08   │ │ 🏆 2:01.55   │ │ 8 trophies   │           │
│  └──────────────┘ └──────────────┘ └──────────────┘           │
│         ● ○                       horizontal page dots         │
└────────────────────────────────────────────────────────────────┘
```

| Element | Position | Size |
|---|---|---|
| Card | — | 248 × 200, `DashTrackCard`, gap `space.4` |
| Preview | card top | 248 × 120, scrim `#000` 0 → 70 % bottom-up |
| Difficulty | preview top-right | 1–3 chevrons, `energyYellow.500` |
| Name | over scrim | `h2` |
| Environment chip | under name | `DashChip` |
| Best time | card footer | `timer` + trophy icon |

- Horizontal `PageView`, 3 visible on baseline (2 compact, 4 expanded).
- Focused card scales 1.04 and lifts to `elev.raised`; neighbours sit at 0.96 / 70 % opacity.
- Locked: preview greyscale, lock centred, requirement replaces best time; tap shakes ±6 dp.
- Tap → track detail sheet (laps, record, ghost) → GO.

---

## 6. Race HUD

```
┌────────────────────────────────────────────────────────────────┐
│ ╔═══════╗          ╔═════════╗              ╔═══════════════╗ │
│ ║ 1ST   ║          ║ LAP 2/3 ║              ║   minimap     ║ │
│ ╚═══════╝          ╚═════════╝              ║  ● ○ ○ ○      ║ │
│                                              ╚═══════════════╝ │
│                                                                 │
│                      live 3D race                               │
│                                                                 │
│   ╭─────╮                    ╔═══════╗              ╭───╮ ╭───╮│
│   │  ◄  │                    ║ ITEM  ║      182     │ ⏸ │ │ ▲ ││
│   ╰─────╯ ╭─────╮            ╚═══════╝     KM/H     ╰───╯ ╰───╯│
│           │  ►  │                                    ╭───╮╭───╮│
│           ╰─────╯                                    │ ▼ ││ ⟳ ││
│                                                      ╰───╯╰───╯│
└────────────────────────────────────────────────────────────────┘
```

| Element | Anchor | Size | Asset |
|---|---|---|---|
| Position | top-left 24, 16 | 96 × 56 | `position` type on blurred pill |
| Lap | top-centre, 16 | 128 × 44 | `lap` type on pill |
| Minimap | top-right 24, 16 | 132 × 96 | `CustomPainter` (CREATE) |
| Steer left | bottom-left 24, −24 | 88² | `direction_left.svg` |
| Steer right | +96 from left | 88² | `direction_right.svg` |
| Accelerate | bottom-right −24 | 96² | `button_circle_wide` + `icon_pedal` |
| Brake | left of accelerate | 76² | `button_circle` + `icon_pedal_brake` |
| Drift | above accelerate | 76² | `button_bean` + `icon_burst` |
| Item slot | bottom-centre | 72² | `DashItemSlot` |
| Speed | right of item, baseline-aligned | auto | `speed` italic + `speedUnit` |
| Pause | top-right, under minimap | 44² | `icon_pause.svg` |

- Top scrim 88 dp, bottom scrim 120 dp — see design-system § 6.
- Boost active: speed readout shifts to `turboOrange.500`, `trace_*` speed lines sweep
  the edges, FOV widens 4°, camera shakes ±2 dp at 18 Hz.
- Position change: number does a scale punch 1.0 → 1.25 → 1.0 and flashes green (gain)
  or red (loss).
- Final lap: lap pill flashes `energyYellow.500` twice; music pitches up 4 %.
- All control anchors read from settings, so repositioning is a stored offset.

---

## 7. Race countdown

Overlays the live race, controls disabled.

| ms | Beat |
|---|---|
| 0 | Camera pulls from behind the grid to chase position over 800 ms |
| 400 | **3** — scale 2.2 → 1.0 `easeOutBack`, `light_01` glow, low beep |
| 1400 | **2** — same, +2 semitones |
| 2400 | **1** — same, +4 semitones |
| 3400 | **GO!** — scale 0.6 → 1.4 → 1.0 `elasticOut`, `flame_04` + `spark_05` burst from every kart, camera shake ±6 dp / 350 ms, white flash 12 %, controls enable |

Numbers: `countdown` type, 160 px, `gradTurbo` fill, 4 dp `darkNavy` outline,
`0 0 40 turboOrange.400` glow. GO! is `neonGreen`.
Each number leaves a radial `circle_04` shockwave scaling 1 → 2.5 while fading.

---

## 8. Results

```
┌────────────────────────────────────────────────────────────────┐
│  confetti (star_*, circle_*) falling across the full screen     │
│                                                                 │
│              🏆   1 S T   P L A C E                             │
│                                                                 │
│   ┌─────────────┐  ┌────────────────────────────────────────┐  │
│   │             │  │ RACE TIME        1:42.08               │  │
│   │  racer      │  │ BEST LAP         0:33.41  ★ NEW        │  │
│   │  emote-yes  │  │ COINS EARNED     +340 🪙               │  │
│   │  on podium  │  │ XP               +125  ▓▓▓▓▓▓░░ LV 7   │  │
│   └─────────────┘  └────────────────────────────────────────┘  │
│                                                                 │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐                  │
│   │NEXT RACE │   │  REPLAY  │   │   HOME   │                  │
│   └──────────┘   └──────────┘   └──────────┘                  │
└────────────────────────────────────────────────────────────────┘
```

**Timeline**

| ms | Beat |
|---|---|
| 0–300 | Race fades to a blurred still; scrim to 70 % |
| 200–700 | Podium rises from below, `motion.hero` |
| 400 | Racer plays `emote-yes`; crowd cheer |
| 600–1100 | "1ST PLACE" scales in `elasticOut`, `gradVictory`; trophy spins in |
| 800 | Confetti burst — 120 particles, 3 s, gravity 380 dp/s² |
| 1000–2000 | Stat rows stagger in 90 ms apart; numbers count up |
| 1600 | NEW RECORD chip punches in if beaten |
| 2000–2400 | XP bar fills; level-up ring pulses if crossed |
| 2400 | Buttons stagger up |

Placement colour: 1st `gradVictory`, 2nd `#C8D4E8`, 3rd `#CD7F32`, 4th+ `textSecondary`
(no confetti, muted fanfare).

---

## 9. Garage

```
┌────────────────────────────────────────────────────────────────┐
│ ◄ back              G A R A G E                  🪙 12,450     │
│ ┌─────────────────────────────┐ ┌────────────────────────────┐ │
│ │                             │ │ ▸ COLOUR  ▸ WHEELS ▸ DECAL │ │
│ │    kart + racer on a         │ │                            │ │
│ │    lit turntable             │ │  ⬤ ⬤ ⬤ ⬤ ⬤ ⬤ ⬤ ⬤        │ │
│ │    drag to rotate            │ │  ⬤ ⬤ ⬤ ⬤ ⬤ ⬤ ⬤ ⬤        │ │
│ │                             │ │                            │ │
│ │                             │ │  SPEED    ▓▓▓▓▓▓░░░░  6    │ │
│ └─────────────────────────────┘ │  HANDLING ▓▓▓▓▓▓▓▓░░  8    │ │
│                                  └────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

- Segmented control switches Colour / Wheels / Decals; the panel cross-fades over `motion.fast`.
- **Colour:** 16 swatches, 44 dp circles. Applied live as a material base-colour tint on the kart GLB.
- **Wheels:** 3 options from `wheel-{default,dark,racing}.glb`; swapping punches the wheel scale 1.0 → 1.15 → 1.0.
- **Decals:** 12 originals (see asset-inventory § CREATE 15), applied as a material overlay.
- Changes persist immediately; no save button.

---

## 10. Settings

Two-column landscape: section list left (220 dp), content right.

| Section | Controls |
|---|---|
| **Audio** | Music volume (slider 0–100), Sound effects (slider) |
| **Controls** | Touch / Tilt (segmented), Steering sensitivity (slider), Reposition controls (opens an overlay editor) |
| **Gameplay** | Vibration (toggle), Camera shake (toggle), Speed units KM/H · MPH (segmented) |
| **Graphics** | Low / Medium / High (segmented) + a live note of what each changes |
| **Account** | Profile name, Reset progress (destructive, `DashDialog` confirm) |
| **About** | Version, Privacy, **Licenses** |

- Rows are 56 dp, `space.4` padding, 1 dp `stroke` divider — composed, never `ListTile`.
- Sliders use `slide_horizontal_color*.svg`; toggles use `check_square_color_checkmark.svg`.
- Destructive actions are `racingRed` and always confirm.
- **Licenses is not optional** — it carries the two mandatory CC-BY 3.0 credits and the
  three OFL texts. See [assets.md](assets.md) § 10.

---

## Navigation

```
Splash ─► Main Menu ─┬─► RACE ─► Track Select ─► Kart Select ─► Character Select
                     │                                                │
                     │                                                ▼
                     │                           Countdown ─► Race ─► Results
                     │                                          │        │
                     │                                          ▼        ├─► Next Race
                     │                                       Pause       ├─► Replay
                     │                                     ├ Resume      └─► Home
                     │                                     ├ Restart
                     │                                     └ Quit ──────────┐
                     ├─► Karts ─────────────────────────────────────────────┤
                     ├─► Tracks ────────────────────────────────────────────┤
                     ├─► Garage ────────────────────────────────────────────┤
                     └─► Settings ──────────────────────────────────────────┘
                                                                            │
                                                             back to Main Menu
```

Menu-to-menu: shared-axis horizontal slide + fade, `motion.slow`.
Menu-to-race: the menu lifts and fades while the race scene is already warming, so
the transition covers scene load rather than following it.
Race-to-results: no navigation — the results layer composites over the frozen race.
