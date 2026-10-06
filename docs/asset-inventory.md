# DashKart — Asset Inventory

Per-component asset requirements, with status. Full license records live in
[assets.md](assets.md); the design tokens they feed are in
[design-system.md](design-system.md).

**Status key**

| | Meaning |
|---|---|
| ✅ **DOWNLOADED** | Sourced, licensed, and already in `assets/` |
| ✏️ **CREATE** | No suitable licensed asset exists — spec below, must be authored |
| ⭕ **OPTIONAL** | Sourced and available, not required for v1 |
| ❌ **NOT FOUND** | Searched, nothing with a usable license |

**Current state:** 101 MB in `assets/` — 8 karts, 8 rigged racers, 102 track
pieces, 316 environment props, 172 UI SVG, 42 icons, 64 particles, 418 SFX,
9 engine loops, 5 music tracks, 6 HDRIs, 8 PBR texture sets, 5 font files.

---

## 1. Splash screen

| Component | Asset required | Source | License | Format | Status |
|---|---|---|---|---|---|
| Background environment | `gradMenuSky` gradient + `dash-valley_2k.hdr` blurred still | Poly Haven | CC0 | HDR → PNG | ✅ DOWNLOADED |
| Kart illustration | `kart-oobi.glb` rendered 3/4 | Kenney Car Kit | CC0 | GLB | ✅ DOWNLOADED |
| Speed lines | `trace_01…07.png` | Kenney Particle Pack | CC0 | PNG | ✅ DOWNLOADED |
| Speed particles | `spark_01…07.png`, `light_01…03.png` | Kenney Particle Pack | CC0 | PNG | ✅ DOWNLOADED |
| **DashKart logo** | Wordmark lockup | — | — | SVG | ✏️ **CREATE** |
| Loading indicator | Custom painter (tyre-track progress arc) | — | — | Dart | ✏️ **CREATE** |
| Launch sting | `music-jingles` — a rising 2 s sting | Kenney | CC0 | OGG | ✅ DOWNLOADED |

---

## 2. Main menu

| Component | Asset required | Source | License | Format | Status |
|---|---|---|---|---|---|
| Animated backdrop | Live `flutter_scene` view — hero kart on a road loop | Kenney Racing Kit | CC0 | GLB | ✅ DOWNLOADED |
| Hero kart | `kart-oobi.glb` + `wheel-racing.glb` | Kenney Car Kit | CC0 | GLB | ✅ DOWNLOADED |
| Hero character | `character-female-a.glb`, `sit` clip | Kenney Mini Characters | CC0 | GLB | ✅ DOWNLOADED |
| Sky | `dash-valley_2k.hdr` | Poly Haven | CC0 | HDR | ✅ DOWNLOADED |
| RACE button | `button_rectangle_depth_gloss.svg` + `gradTurbo` | Kenney UI Pack | CC0 | SVG | ✅ DOWNLOADED |
| Secondary buttons | same family, `md` size | Kenney UI Pack | CC0 | SVG | ✅ DOWNLOADED |
| Currency pill | `icon_money.svg` + pill frame | Kenney Mobile Controls | CC0 | SVG | ✅ DOWNLOADED |
| Trophy count | `trophy.png` (tinted) | Kenney Game Icons | CC0 | PNG | ✅ DOWNLOADED |
| Racing flags | `flagCheckers.glb`, `flagGreen.glb` | Kenney Racing Kit | CC0 | GLB | ✅ DOWNLOADED |
| Clouds | Baked into the HDRI sky | Poly Haven | CC0 | HDR | ✅ DOWNLOADED |
| Decorative particles | `star_*`, `circle_*`, `light_*` | Kenney Particle Pack | CC0 | PNG | ✅ DOWNLOADED |
| Menu music | `menu-racing.ogg` | OGA · Eric Matyas | **CC-BY 3.0** | OGG | ✅ DOWNLOADED |
| **Player avatar frame** | Portrait ring + rank badge | — | — | SVG | ✏️ **CREATE** |

---

## 3. Kart selection

| Component | Asset required | Source | License | Format | Status |
|---|---|---|---|---|---|
| 8 kart models | `kart-oobi/oodi/ooli/oopi/oozi`, `race`, `race-future`, `hatchback-sports` | Kenney Car Kit | CC0 | GLB | ✅ DOWNLOADED |
| Wheel variants | `wheel-default`, `wheel-dark`, `wheel-racing` | Kenney Car Kit | CC0 | GLB | ✅ DOWNLOADED |
| Carousel card frame | `button_square_depth_border.svg` | Kenney UI Pack | CC0 | SVG | ✅ DOWNLOADED |
| Stat bars | `slide_horizontal_color*.svg` | Kenney UI Pack | CC0 | SVG | ✅ DOWNLOADED |
| Lock overlay | `icon_lock.svg` | Kenney Mobile Controls | CC0 | SVG | ✅ DOWNLOADED |
| Selection sting | `interface-sounds` confirm | Kenney | CC0 | OGG | ✅ DOWNLOADED |
| Turntable platform | `roadStraight.glb` disc + rim glow | Kenney Racing Kit | CC0 | GLB | ✅ DOWNLOADED |
| **Kart thumbnails** | 8 × 264 px pre-renders for fast carousel scroll | — | — | WebP | ✏️ **CREATE** (render from GLB) |
| **5 stat icons** | Speed, Acceleration, Handling, Drift, Weight | — | — | SVG | ✏️ **CREATE** |

### The eight karts

| # | Name | Model | Speed | Accel | Handling | Drift | Weight | Unlock |
|---|---|---|---|---|---|---|---|---|
| 1 | **Dashster** | `kart-oobi.glb` | 6 | 7 | 8 | 6 | 5 | Starter |
| 2 | **Bolt-X** | `kart-oodi.glb` | 8 | 6 | 6 | 7 | 6 | 1 200 c |
| 3 | **Nitro** | `kart-ooli.glb` | 7 | 8 | 6 | 8 | 4 | 2 000 c |
| 4 | **Comet** | `kart-oopi.glb` | 9 | 5 | 5 | 6 | 7 | 3 500 c |
| 5 | **Vortex** | `kart-oozi.glb` | 6 | 9 | 7 | 9 | 3 | 5 000 c |
| 6 | **Blaze** | `race.glb` | 8 | 7 | 7 | 7 | 6 | 8 trophies |
| 7 | **Phantom** | `race-future.glb` | 10 | 6 | 6 | 8 | 5 | 16 trophies |
| 8 | **Rocket** | `hatchback-sports.glb` | 7 | 7 | 9 | 5 | 8 | 24 trophies |

Stats are 1–10 and drive both the UI bars and the physics parameters.

---

## 4. Character selection

| Component | Asset required | Source | License | Format | Status |
|---|---|---|---|---|---|
| 8 rigged racers | `character-{female,male}-{a,b,c,d}.glb` | Kenney Mini Characters | CC0 | GLB | ✅ DOWNLOADED |
| Idle / select / drive / celebrate | Clips `idle`, `emote-yes`, `drive`, `sit` — **shipped inside each GLB** | Kenney Mini Characters | CC0 | GLB | ✅ DOWNLOADED |
| Accessories | `aid-glasses.glb`, `aid-sunglasses.glb` | Kenney Mini Characters | CC0 | GLB | ✅ DOWNLOADED |
| 2D pose art | Toon Characters HD poses | Kenney | CC0 | PNG | ✅ DOWNLOADED |
| Alternate roster | 18 × `character-a…r.glb` | Kenney Blocky Characters | CC0 | GLB | ⭕ OPTIONAL |
| **Portraits** | 8 × 256 px circular portraits | — | — | WebP | ✏️ **CREATE** (render from GLB) |

### The eight racers

| # | Name | Model | Personality | Signature kart |
|---|---|---|---|---|
| 1 | **Dash** | `character-male-a` | Eager rookie, all heart | Dashster |
| 2 | **Nova** | `character-female-a` | Calm precision driver | Bolt-X |
| 3 | **Bolt** | `character-male-b` | Loud, reckless, fast | Nitro |
| 4 | **Blaze** | `character-female-b` | Fearless daredevil | Blaze |
| 5 | **Luna** | `character-female-c` | Quiet strategist | Comet |
| 6 | **Rex** | `character-male-c` | Heavyweight bruiser | Rocket |
| 7 | **Pixel** | `character-female-d` (+ glasses) | Tinkerer, drift specialist | Vortex |
| 8 | **Turbo** | `character-male-d` (+ sunglasses) | Veteran showboat | Phantom |

> The `drive` animation clip verified inside every one of these GLBs is what makes
> in-kart posing work without authoring a single animation.

---

## 5. Track selection — six tracks

| Component | Asset required | Source | License | Format | Status |
|---|---|---|---|---|---|
| Card frames | UI Pack Adventure panels | Kenney | CC0 | SVG | ✅ DOWNLOADED |
| Difficulty chevrons | `icon_arrow.svg` | Kenney Mobile Controls | CC0 | SVG | ✅ DOWNLOADED |
| Trophy / lock | `trophy.png`, `icon_lock.svg` | Kenney | CC0 | PNG/SVG | ✅ DOWNLOADED |
| **6 preview images** | 560 × 360 track art | — | — | WebP | ✏️ **CREATE** (in-engine capture) |

| # | Track | Environment | Road kit | Sky (Poly Haven) | Terrain (ambientCG) | Props | Status |
|---|---|---|---|---|---|---|---|
| 01 | **Dash Valley** | Grass + mountains | Racing Kit `road*` | `dash-valley_2k.hdr` | Grass005 + Asphalt033 | Nature Kit trees, rocks, `grandStand*`, `flagCheckers` | ✅ |
| 02 | **Neon Circuit** | Futuristic city, night | Racing Kit `road*` | `neon-circuit_2k.hdr` | Concrete034 + Asphalt033 | City Kit buildings, `lightPost*`, `billboard*`, `overhead*` | ✅ |
| 03 | **Desert Rush** | Desert + canyon | Racing Kit `road*` | `desert-rush_2k.hdr` | Ground054 + Rock064 | Nature Kit `cactus_*`, `cliff_*`, `rock_*` | ✅ |
| 04 | **Frozen Peak** | Snow + ice | Racing Kit `road*` | `frozen-peak_2k.hdr` | Snow015 + Rock064 | Nature Kit pines, `cliff_*`, `barrier*` | ✅ |
| 05 | **Sky Harbor** | Floating islands | **Toy Car Kit** `track-road-wide-*` + `supports*` | `sky-harbor_2k.hdr` | Concrete034 | `gate*`, loop pieces, cloud billboards | ✅ |
| 06 | **Cyber Coast** | Beach + futuristic | Racing Kit `road*` | `cyber-coast_2k.hdr` | Ground054 + Road007 | City Kit, `tent*`, `bannerTower*` | ✅ |

Sky Harbor deliberately uses the Toy Car Kit's suspended track — it ships supports
and loop-the-loop pieces, which is exactly a floating-island circuit.

---

## 6. Race HUD

| Component | Asset required | Source | License | Format | Status |
|---|---|---|---|---|---|
| Position indicator | Titan One `position` style + scrim pill | Google Fonts | OFL | TTF | ✅ DOWNLOADED |
| Lap counter | Chakra Petch `lap` style | Google Fonts | OFL | TTF | ✅ DOWNLOADED |
| Speed readout | Chakra Petch `speed` italic | Google Fonts | OFL | TTF | ✅ DOWNLOADED |
| Item slot | `button_square.svg` + `_highlight` | Kenney Mobile Controls | CC0 | SVG | ✅ DOWNLOADED |
| HUD scrims | Gradient painters | — | — | Dart | ✅ (code) |
| **Minimap** | Track spline + racer dots | — | — | CustomPainter | ✏️ **CREATE** |
| **Position ordinal set** | 1ST…8TH lockups | — | — | Dart/SVG | ✏️ **CREATE** |

---

## 7. Mobile controls

| Control | Asset | Pressed state | Status |
|---|---|---|---|
| Steer left / right | `direction_left.svg`, `direction_right.svg` | `*_highlight.svg` | ✅ DOWNLOADED |
| Steering (alt) | `dpad_separate.svg` | `dpad_separate_highlight.svg` | ✅ DOWNLOADED |
| Accelerate | `button_circle_wide.svg` + `icon_pedal.svg` | `button_circle_wide_highlight.svg` | ✅ DOWNLOADED |
| Brake | `button_circle.svg` + `icon_pedal_brake.svg` | `button_circle_highlight.svg` | ✅ DOWNLOADED |
| Drift | `button_bean.svg` + `icon_burst.svg` | `button_bean_highlight.svg` | ✅ DOWNLOADED |
| Item | `button_diamond.svg` | `button_diamond_highlight.svg` | ✅ DOWNLOADED |

**Pressed states ship with the pack** — every Kenney Mobile Controls button has a
matching `_highlight` variant, so §12's requirement is met at the source rather
than by runtime tinting. Glow, scale-punch, and haptics are added in code.

---

## 8. Items

Six original items. World models and pickup exist; **all six icons must be drawn.**

| Item | Effect | World model | HUD icon | Activation FX | Sound | Status |
|---|---|---|---|---|---|---|
| **Turbo Cell** | Speed boost | `item-box.glb` | ✏️ CREATE | `flame_*`, `trace_*` ✅ | sci-fi ✅ | Partial |
| **Shock Pulse** | Slows nearby racers | `item-box.glb` | ✏️ CREATE | `magic_*`, `light_*` ✅ | sci-fi ✅ | Partial |
| **Oil Blob** | Drops a trap | `item-banana.glb` ✅ | ✏️ CREATE | `smoke_*`, `scorch_*` ✅ | impact ✅ | Partial |
| **Shield Orb** | Protection | `item-box.glb` | `icon_shield.svg` ✅ | `circle_*`, `light_*` ✅ | sci-fi ✅ | ✅ |
| **Rocket Drone** | Targets a racer | `item-cone.glb` ✅ | ✏️ CREATE | `flame_*`, `spark_*` ✅ | sci-fi ✅ | Partial |
| **Warp Dash** | Short burst forward | `item-box.glb` | ✏️ CREATE | `twirl_*`, `trace_*` ✅ | sci-fi ✅ | Partial |

---

## 9. Countdown, boost, results

| Component | Asset | Source | Status |
|---|---|---|---|
| 3 · 2 · 1 · GO! type | Titan One `countdown` 160 px | Google Fonts | ✅ DOWNLOADED |
| Countdown beeps | `digital-audio` tones | Kenney | ✅ DOWNLOADED |
| Countdown voice | `voiceover-pack` | Kenney | ✅ DOWNLOADED |
| Number glow | `light_01`, `flare_01`, `circle_04` | Kenney Particle Pack | ✅ DOWNLOADED |
| GO! boost burst | `flame_04`, `spark_05`, `trace_03` | Kenney Particle Pack | ✅ DOWNLOADED |
| Speed lines | `trace_01…07` | Kenney Particle Pack | ✅ DOWNLOADED |
| Tyre smoke | `smoke_01…10` | Kenney Particle Pack | ✅ DOWNLOADED |
| Sparks | `spark_01…07` | Kenney Particle Pack | ✅ DOWNLOADED |
| Exhaust flame | `fire_01`, `flame_01…06` | Kenney Particle Pack | ✅ DOWNLOADED |
| Dirt off-track | `dirt_01…03` | Kenney Particle Pack | ✅ DOWNLOADED |
| Motion blur / distortion | `flutter_scene` post stack | flutter_scene | ✅ (engine) |
| Camera shake | Transform noise | — | ✅ (code) |
| Podium celebration | `emote-yes` clip in racer GLB | Kenney Mini Characters | ✅ DOWNLOADED |
| Crowd cheer | `crowd-cheer.mp3` | Freesound · AlaskaRobotics | ✅ DOWNLOADED |
| Victory fanfare | `music-jingles` | Kenney | ✅ DOWNLOADED |
| **Confetti** | Particle sim | — | ✏️ **CREATE** (uses `star_*`, `circle_*` ✅) |
| **Trophy art** | Gold / silver / bronze | — | ✏️ **CREATE** |

---

## 10. Settings, garage, audio

| Component | Asset | Source | Status |
|---|---|---|---|
| Sliders | `slide_horizontal_color*.svg` | Kenney UI Pack | ✅ DOWNLOADED |
| Toggles | `check_square_color_checkmark.svg` | Kenney UI Pack | ✅ DOWNLOADED |
| Audio icons | `icon_sound{,_disabled}`, `icon_music{,_disabled}` | Kenney Mobile Controls | ✅ DOWNLOADED |
| Section icons | `icon_cog`, `icon_wrench`, `information.png` | Kenney | ✅ DOWNLOADED |
| Garage turntable | `roadStraight.glb` + rim light | Kenney Racing Kit | ✅ DOWNLOADED |
| Wheel swap | 3 wheel GLBs | Kenney Car Kit | ✅ DOWNLOADED |
| Colour swatches | Material tint on kart GLB | — | ✅ (code) |
| Engine loops | 6 CC0 loops | Freesound | ✅ DOWNLOADED |
| Track ambience | `amb-kart-outdoor.mp3` | Freesound · OverlookHotelRecords | ✅ DOWNLOADED |
| UI / impact SFX | 418 files | Kenney | ✅ DOWNLOADED |
| **Decals** | 12 racing decals | — | ✏️ **CREATE** |
| **Vibration icon** | | — | ✏️ **CREATE** |

---

## ✏️ CREATE — full list with specifications

Fifteen items. Nothing here is a placeholder gap: each is either brand identity
(which must be original) or a metaphor no CC0 set carries.

### Brand

**1. DashKart logo lockup** — ✅ **BUILT** as `DashWordmark`
(`lib/ui/components/dash_wordmark.dart`). Titan One, italicised ~8°, "DASH" in
`gradSpeed` and "KART" in `gradTurbo`, with three speed lines trailing the
leading edge. Drawn rather than exported so it animates its own per-letter
reveal on the splash. Still to export: static SVG/PNG variants (stacked,
icon-only, monochrome) for the store listing and app icon.

**2. App icon** — PNG, `assets/images/branding/`
Icon-only mark on `gradSpeed`, 1024² with iOS/Android densities. No text.

**3. Player avatar frame** — SVG, `assets/images/ui/`
Circular ring, 96 dp, 4 dp gradient stroke, notched at 4 and 8 o'clock, rank
badge anchor bottom-right.

### Icons — draw on the Kenney Mobile Controls grid

All nine below: **SVG, 64 × 64 viewBox, solid fill, no stroke, single path where
possible**, matching the existing `assets/images/ui/icons/*.svg` weight so the set
stays one family. Destination `assets/images/ui/icons/`.

| # | Icon | Metaphor | Status |
|---|---|---|---|
| 4 | `icon_speed` | Speedometer arc with needle at 2 o'clock | ✅ **DRAWN** |
| 5 | `icon_acceleration` | Three chevrons, increasing size | ✅ **DRAWN** |
| 6 | `icon_handling` | Cornering arrow tracking a curve | ✅ **DRAWN** |
| 7 | `icon_drift` | Kart at a yaw angle over two curved skid lines | ✅ **DRAWN** |
| 8 | `icon_weight` | Weight plate with a grip cut-out | ✅ **DRAWN** |
| 9 | `icon_vibration` | Handset with motion arcs each side | ✅ **DRAWN** |
| 10 | `icon_item` | Question cube, echoing `item-box.glb` | ✅ **DRAWN** |
| 11 | `icon_map` | Folded map with a dashed route and pin | ✅ **DRAWN** |
| 12 | `icon_position` | Three-tier podium, tallest centre | ✅ **DRAWN** |

All nine are in `assets/images/ui/icons/`, authored on the same 48×48 grid and
solid-white fill as the Kenney set, so the family reads as one.

### Item icons

**13. Six item icons** — SVG 64², `assets/images/ui/icons/items/`
Each a filled silhouette on a coloured rounded-square field, single accent hue:
Turbo Cell (`turboOrange.500`, capsule + flame), Shock Pulse (`skyBlue.500`,
concentric rings + bolt), Oil Blob (`darkNavy`, droplet + splat), Shield Orb
(`skyBlue.400`, reuse `icon_shield`), Rocket Drone (`racingRed.500`, rocket +
crosshair), Warp Dash (`neonGreen`, double chevron + motion arc).

### Track and kart art

**14. Six track previews + eight kart thumbnails + eight portraits**
WebP. Track 560 × 360 → `assets/images/tracks/`; kart 264 × 264 →
`assets/images/karts/`; portraits 256 × 256 circular → `assets/images/characters/`.

**Not hand-painted** — captured from the real scene. `flutter_scene` exposes
synchronous frame capture as `ui.Image`, so a debug-only capture route poses each
subject under its track lighting and writes the file. Art stays automatically in
sync with the models, and there is no risk of a preview that misrepresents the track.

**15. Trophy set + 12 decals**
Trophies: gold/silver/bronze, SVG 128², `assets/images/ui/`. Decals: flame, bolt,
stripe, star, chevron, checker, wave, circuit, claw, arrow, splash, gradient fade —
SVG, `assets/images/karts/decals/`, applied as a material overlay.

---

## ❌ NOT FOUND

| Requirement | Searched | Outcome |
|---|---|---|
| Kart-specific engine loop (CC0) | Freesound, Kenney, OpenGameArt, Pixabay | Nothing genuinely kart-like under CC0. **Resolved:** six CC0 car/generic engine loops are pitch-shifted by RPM — standard practice and more flexible than a fixed recording. Not a blocker. |
| Cartoon kart racer UI kit (complete, CC0) | Kenney, itch.io, OpenGameArt | No single pack covers a full kart-racer UI. **Resolved:** Kenney UI Pack + UI Pack Adventure + Mobile Controls compose into one, all CC0, all one author. |
| Rigged *cartoon* racer with a kart-sitting pose | Kenney, Sketchfab, itch.io | Free rigged characters with a genuine `drive` clip are rare. **Resolved:** Kenney Mini Characters ships `drive` and `sit` — verified by parsing the GLB. Better than the requirement. |

Nothing on this list blocks the build.

---

## ⭕ OPTIONAL

| Asset | Source | License | Why held back |
|---|---|---|---|
| Blocky Characters (18 racers) | [kenney.nl/assets/blocky-characters](https://kenney.nl/assets/blocky-characters) | CC0 | Second unlockable roster |
| Toy Car Kit vehicles (8) | Kenney Toy Car Kit | CC0 | Monster truck / drag racer as a bonus class |
| Racing Kit isometric sprites (578 PNG) | Kenney Racing Kit | CC0 | 2D fallback if `flutter_scene` proves unstable |
| Kenney Fonts (11) | [kenney.nl/assets/kenney-fonts](https://kenney.nl/assets/kenney-fonts) | CC0 | Backup display face |
| Casino / RPG audio | Kenney | CC0 | Reward-wheel SFX for a later meta layer |
| CC0 Upbeat/Electronic music | [OpenGameArt](https://opengameart.org/content/cc0-upbeat-electronic-music) | CC0 | Extra per-track themes |
| Poly Haven 3D models | [polyhaven.com/models](https://polyhaven.com/models) | CC0 | Photoreal props — clash with the low-poly style |
| Cursor Pack, Input Prompts | Kenney | CC0 | Gamepad support later |

---

## Licence obligations checklist

- [ ] Settings ▸ Licenses screen lists every source in [assets.md](assets.md)
- [ ] **CC-BY 3.0 attribution shipped verbatim** for "Racing Menu" (Eric Matyas) and "Arcade Racing Tune" (rezoner) — mandatory
- [ ] SIL OFL 1.1 text bundled for Titan One, Fredoka, Chakra Petch
- [ ] CC0 courtesy credits for Kenney, Poly Haven, ambientCG, and each Freesound author
- [ ] Freesound *originals* substituted for the preview-quality MP3s before store release
- [ ] Confirm no Nintendo/Sega/Activision-derived shape, name, or sound anywhere
