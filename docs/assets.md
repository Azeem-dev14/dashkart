# DashKart — Asset Manifest

Every third-party asset that ships in DashKart is recorded here. **Nothing enters
`assets/` without an entry in this file.** Licenses were verified individually at
the source on **2026-08-24**; license texts are mirrored in [`docs/licenses/`](licenses/).

Run [`tool/fetch_assets.sh`](../tool/fetch_assets.sh) to download and place everything.

## License summary

| License | Count | Attribution | Where credited |
|---|---|---|---|
| CC0 1.0 Universal | 30 packs / assets | Not required | Courtesy credit in Settings ▸ Licenses |
| SIL OFL 1.1 | 3 font families | Required (license text) | Settings ▸ Licenses |
| CC-BY 3.0 | 2 music tracks | **Required** | Settings ▸ Licenses — mandatory |

> **Rejected:** Freesound #443269 "Car idling, loop" (alec_havinmaa) is **CC BY-NC 4.0**.
> Non-commercial only, so it cannot ship in a store release. Excluded deliberately.

---

## 1. 3D — Karts and wheels

**Asset:** Car Kit — kart bodies and wheels
**Source:** Kenney
**URL:** https://kenney.nl/assets/car-kit
**Download:** https://kenney.nl/media/pages/assets/car-kit/1a312ec241-1775131960/kenney_car-kit.zip
**License:** CC0 1.0 Universal — "free to use in personal, educational and commercial projects"
**Attribution:** Not required (courtesy credit given)
**Files:** `kart-oobi.glb`, `kart-oodi.glb`, `kart-ooli.glb`, `kart-oopi.glb`, `kart-oozi.glb`, `race.glb`, `race-future.glb`, `hatchback-sports.glb`, `wheel-default.glb`, `wheel-dark.glb`, `wheel-racing.glb`, `debris-*.glb`, `cone.glb`
**Destination:** `assets/models/karts/`, `assets/models/environment/` (debris, cones)
**Used by:** Kart Selection, Garage, Race scene, crash effects
**Notes:** 45 models in the pack; 11 extracted. Wheels are separate meshes, which is what makes the Garage wheel-swap possible. No rig, no animation — karts are driven by transform.

---

## 2. 3D — Racers

**Asset:** Mini Characters
**Source:** Kenney
**URL:** https://kenney.nl/assets/mini-characters
**Download:** https://kenney.nl/media/pages/assets/mini-characters/bfc7e272b4-1774770718/kenney_mini-characters.zip
**License:** CC0 1.0 Universal
**Attribution:** Not required
**Files:** `character-female-a…d.glb`, `character-male-a…d.glb`, `aid-glasses.glb`, `aid-sunglasses.glb`
**Destination:** `assets/models/characters/`
**Used by:** Character Selection, Garage, Race scene, Results podium
**Notes:** Verified by parsing the GLB: **skinned, 2 skins, 32 animation clips each**, including
`drive`, `sit`, `idle`, `emote-yes`, `emote-no`, `sprint`, `pick-up`. `drive` is used in-race,
`emote-yes` on the podium. This is why this pack was chosen over the alternatives.

**Alternate (OPTIONAL, not shipped):** Blocky Characters — 18 racers, 27 clips, also with `drive`.
https://kenney.nl/assets/blocky-characters · CC0 · reserved as an unlockable second roster.

---

## 3. 3D — Track pieces

**Asset:** Racing Kit — modular circuit road
**Source:** Kenney
**URL:** https://kenney.nl/assets/racing-kit
**Download:** https://kenney.nl/media/pages/assets/racing-kit/933b8fd9fd-1677580949/kenney_racing-kit.zip
**License:** CC0 1.0 Universal (License.txt mirrored to `docs/licenses/kenney-racing-kit.txt`)
**Attribution:** Not required
**Files:** 56 `road*.glb` pieces — straights, corners (small/large/larger), ramps, bridges, splits, crossings, pit lane, `roadStart.glb`, `roadStartPositions.glb`
**Destination:** `assets/models/tracks/`
**Used by:** Tracks 01 Dash Valley, 02 Neon Circuit, 03 Desert Rush, 04 Frozen Peak, 06 Cyber Coast
**Notes:** 112 GLB in the pack. Grid-aligned modular pieces — tracks are authored as a piece list, not sculpted meshes.

**Asset:** Toy Car Kit — suspended track + pickups
**Source:** Kenney
**URL:** https://kenney.nl/assets/toy-car-kit
**Download:** https://kenney.nl/media/pages/assets/toy-car-kit/42e19cc426-1736346027/kenney_toy-car-kit.zip
**License:** CC0 1.0 Universal
**Attribution:** Not required
**Files:** `track-road-wide-*.glb`, `track-striped-wide-*.glb`, `supports*.glb`, `item-box.glb`, `item-coin-{gold,silver,bronze}.glb`, `item-banana.glb`, `item-cone.glb`, `gate.glb`, `gate-finish.glb`, `smoke.glb`
**Destination:** `assets/models/tracks/`, `assets/models/environment/`
**Used by:** Track 05 Sky Harbor (suspended track), item pickups on all tracks, finish line
**Notes:** 157 GLB in the pack. `item-box.glb` is the DashKart item box; the coin trio drives the currency pickups. Includes loop-the-loop pieces for Sky Harbor.

---

## 4. 3D — Environment props

**Asset:** Nature Kit
**Source:** Kenney · **URL:** https://kenney.nl/assets/nature-kit
**Download:** https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip
**License:** CC0 1.0 · **Attribution:** Not required
**Files:** `tree_*.glb`, `rock_*.glb`, `cliff_*.glb`, `stone_*.glb`, `cactus_*.glb`, `grass_*.glb`, `bridge_*.glb`, `log_*.glb` (149 extracted of 330)
**Destination:** `assets/models/environment/`
**Used by:** 01 Dash Valley, 03 Desert Rush, 04 Frozen Peak

**Asset:** City Kit (Suburban)
**Source:** Kenney · **URL:** https://kenney.nl/assets/city-kit-suburban
**Download:** https://kenney.nl/media/pages/assets/city-kit-suburban/2c871b7af2-1745479373/kenney_city-kit-suburban_20.zip
**License:** CC0 1.0 · **Attribution:** Not required
**Destination:** `assets/models/environment/`
**Used by:** 02 Neon Circuit, 06 Cyber Coast (background silhouettes)

**Asset:** Racing Kit — trackside dressing
**Files:** `barrier*.glb`, `pylon.glb`, `flagCheckers.glb`, `flagGreen.glb`, `flagRed.glb`, `bannerTower*.glb`, `grandStand*.glb`, `lightPost*.glb`, `tent*.glb`, `billboard*.glb`, `overhead*.glb`, `rail*.glb`, `fence*.glb`, `pits*.glb`
**Destination:** `assets/models/environment/`
**Used by:** All tracks — barriers, start gantry, crowd stands, checkered flags

---

## 5. UI frames, panels, buttons

**Asset:** UI Pack (2.0)
**Source:** Kenney · **URL:** https://kenney.nl/assets/ui-pack
**Download:** https://kenney.nl/media/pages/assets/ui-pack/f651646eab-1718203990/kenney_ui-pack.zip
**License:** CC0 1.0 · **Attribution:** Not required
**Files:** `Vector/{Blue,Yellow,Grey,Extra}/*.svg` — 100 SVG: `button_rectangle_depth_gloss`, `button_round_depth_flat`, `button_square_depth_border`, `slide_horizontal_color`, `check_square_color_checkmark`, `star`, `arrow_decorative_*`, and the rest
**Destination:** `assets/images/ui/frames/`
**Used by:** DashButton, DashCard, DashDialog, DashChip, Settings sliders and toggles
**Notes:** 430 assets in the pack; the SVG set is taken so buttons stay crisp at 3x. The `_depth_` variants carry a built-in bottom bevel — that's the chunky arcade button face, no shadow faking needed.

**Asset:** UI Pack (Adventure)
**Source:** Kenney · **URL:** https://kenney.nl/assets/ui-pack-adventure
**Download:** https://kenney.nl/media/pages/assets/ui-pack-adventure/9a877376bc-1723597274/kenney_ui-pack-adventure.zip
**License:** CC0 1.0 · **Destination:** `assets/images/ui/frames-adventure/`
**Used by:** Track Selection cards, Results screen ribbons

---

## 6. On-screen driving controls

**Asset:** Mobile Controls
**Source:** Kenney · **URL:** https://kenney.nl/assets/mobile-controls
**Download:** https://kenney.nl/media/pages/assets/mobile-controls/0d047b3be4-1754738457/mobile-controls-1.zip
**License:** CC0 1.0 · **Attribution:** Not required
**Files:** `Vector/Style A/*.svg`, `Vector/Style B/*.svg`, `Vector/Highlights A/*.svg` (72 SVG) — `button_circle`, `button_circle_wide`, `button_bean`, `button_diamond`, `button_hexagon`, `button_square`, each with a matching `_highlight` pressed state; `dpad`, `dpad_separate`, `direction_left`, `direction_right`
**Destination:** `assets/images/ui/controls/`
**Used by:** Race HUD steering, accelerate, brake, drift, item buttons
**Notes:** 900 assets across 8 styles. **Pressed states ship with the pack** — `*_highlight.svg` is the down state, so §12's "pressed states" requirement is met by the source, not by tinting.

---

## 7. Icons

**Asset:** Mobile Controls — icon family (primary icon set)
**Source:** Kenney · same pack and license as §6
**Files:** `Vector/Icons/*.svg` — 42 SVG including `icon_steering_wheel`, `icon_pedal`, `icon_pedal_brake`, `icon_shield`, `icon_fire`, `icon_burst`, `icon_play`, `icon_pause`, `icon_cog`, `icon_music`, `icon_music_disabled`, `icon_sound`, `icon_sound_disabled`, `icon_lock`, `icon_key`, `icon_money`, `icon_star`, `icon_arrow`, `icon_arrow_rotate`, `icon_arrow_curved`, `icon_target`, `icon_wrench`, `icon_checkmark`, `icon_cross`, `icon_hand`, `icon_menu`
**Destination:** `assets/images/ui/icons/`
**Used by:** Every screen
**Notes:** Chosen as the single icon family because it is the only CC0 set that already contains the *racing* metaphors — steering wheel, accelerator pedal, brake pedal. Building the set around it avoids the mixed-pack look §5 warns against.

**Asset:** Game Icons — gap fill
**Source:** Kenney · **URL:** https://kenney.nl/assets/game-icons
**Download:** https://kenney.nl/media/pages/assets/game-icons/1ebf9c14af-1677661579/kenney_game-icons.zip
**License:** CC0 1.0
**Files:** `PNG/White/2x/{trophy,home,unlocked,locked,medal1,medal2,gear,information,leaderboardsSimple}.png`
**Destination:** `assets/images/ui/icons-raster/`
**Used by:** Main Menu profile, Track Selection trophies, Results, Settings
**Notes:** Same author and design language as the primary set, so the two read as one family. Shipped white so they tint to any palette colour. Only 2 SVG exist in this pack, hence PNG at 2x.

---

## 8. Particles

**Asset:** Particle Pack
**Source:** Kenney · **URL:** https://kenney.nl/assets/particle-pack
**Download:** https://kenney.nl/media/pages/assets/particle-pack/f8fe0f8cb8-1677578741/kenney_particle-pack.zip
**License:** CC0 1.0 · **Attribution:** Not required
**Files:** 64 transparent PNG — `smoke_01…10`, `spark_01…07`, `flame_01…06`, `fire_01…02`, `dirt_01…03`, `trace_01…07`, `star_01…09`, `light_01…03`, `flare_01`, `circle_01…05`, `magic_01…05`, `twirl_01…03`, `scorch_01…03`
**Destination:** `assets/particles/`
**Used by:** Drift smoke (`smoke_*`), boost flame (`flame_*`, `fire_*`), sparks on wall contact (`spark_*`), dirt off-track (`dirt_*`), speed lines (`trace_*`), item pickup sparkle (`star_*`, `magic_*`), countdown glow (`light_*`, `flare_*`)
**Notes:** `PNG (Transparent)` variant taken, not the black-background one — additive blending needs straight alpha.

---

## 9. Sound effects

All Kenney audio packs below are **CC0 1.0**, attribution not required.

| Pack | URL | Download | Destination | Used by |
|---|---|---|---|---|
| Interface Sounds (100) | https://kenney.nl/assets/interface-sounds | `…/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip` | `assets/audio/sfx/ui/` | Button taps, navigation |
| UI Audio (50) | https://kenney.nl/assets/ui-audio | `…/ui-audio/490d233f68-1677590494/kenney_ui-audio.zip` | `assets/audio/sfx/ui/` | Menu confirm, back, error |
| Impact Sounds (130) | https://kenney.nl/assets/impact-sounds | `…/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip` | `assets/audio/sfx/impact/` | Kart collisions, barrier hits |
| Digital Audio (60) | https://kenney.nl/assets/digital-audio | `…/digital-audio/216eac4753-1677590265/kenney_digital-audio.zip` | `assets/audio/sfx/digital/` | Countdown beeps, HUD alerts |
| Sci-Fi Sounds (70) | https://kenney.nl/assets/sci-fi-sounds | `…/sci-fi-sounds/6b296f9ecf-1677589334/kenney_sci-fi-sounds.zip` | `assets/audio/sfx/scifi/` | Turbo Cell, Shock Pulse, Warp Dash, Shield Orb |
| Voiceover Pack (90) | https://kenney.nl/assets/voiceover-pack | `…/voiceover-pack/3f7f168698-1677589897/kenney_voiceover-pack.zip` | `assets/audio/voice/` | "3 · 2 · 1 · GO!" countdown, lap callouts |

Full download prefix for the table above: `https://kenney.nl/media/pages/assets/`

### Engine and ambience — Freesound

Each sound below was opened and its license read individually.

| # | Sound | Author | License | Local file |
|---|---|---|---|---|
| [369053](https://freesound.org/s/369053/) | car_idle_loop.wav | AndrewAlexander | **CC0 1.0** | `engine-idle-a.ogg` |
| [186939](https://freesound.org/s/186939/) | engine2_idle_loop.wav | ReadeOnly | **CC0 1.0** | `engine-idle-b.ogg` |
| [216563](https://freesound.org/s/216563/) | IDLE_ENGINE_001.ogg | pgi | **CC0 1.0** | `engine-idle-c.ogg` |
| [748027](https://freesound.org/s/748027/) | Sedan engine loop | Dmitry_mansurev64 | **CC0 1.0** | `engine-sedan.ogg` |
| [679693](https://freesound.org/s/679693/) | T4-19TD-2000-Engine-Loop.wav | grauxonen | **CC0 1.0** | `engine-turbo.ogg` |
| [407540](https://freesound.org/s/407540/) | Sci-Fi Engine Loop | Sojan | **CC0 1.0** | `engine-scifi.ogg` |
| [189622](https://freesound.org/s/189622/) | Go Kart Racing.flac | qubodup | **CC0 1.0** | `amb-kart-indoor.ogg` |
| [317471](https://freesound.org/s/317471/) | Go Kart Racing Outdoors | OverlookHotelRecords | **CC0 1.0** | `amb-kart-outdoor.ogg` |
| [221568](https://freesound.org/s/221568/) | cheering and clapping crowd 1 | AlaskaRobotics | **CC0 1.0** | `crowd-cheer.ogg` |

**Destination:** `assets/audio/sfx/engine/`
**Used by:** Race scene engine (pitch-shifted by RPM), track ambience, Results crowd
**Notes:** `engine-scifi.ogg` is reserved for Phantom and Bolt-X on Neon Circuit. The fetch script pulls Freesound *preview* OGGs (128 kbps); **download the originals from the sound pages before shipping** — Freesound requires a login for originals, which the script cannot do.

> **Rejected — do not use:** [443269](https://freesound.org/s/443269/) "Car idling, loop" by
> alec_havinmaa is **CC BY-NC 4.0**. Non-commercial only.

---

## 10. Music

**Asset:** Music Jingles (85 stings)
**Source:** Kenney · **URL:** https://kenney.nl/assets/music-jingles
**Download:** https://kenney.nl/media/pages/assets/music-jingles/f37e530b9e-1677590399/kenney_music-jingles.zip
**License:** CC0 1.0 · **Attribution:** Not required
**Destination:** `assets/audio/music/jingles/`
**Used by:** Unlock stings, results fanfare, level-up

| Track | Source | URL | License | Attribution | Local file | Used by |
|---|---|---|---|---|---|---|
| Winning the Race | OpenGameArt · Section31 | https://opengameart.org/content/winning-the-race | **CC0** | Not required | `race-winning-the-race.ogg` | Race BGM |
| Funked Up | OpenGameArt · Joth | https://opengameart.org/content/funked-up | **CC0** | Not required | `menu-funked-up.mp3` | Garage, Kart Select |
| Racing Menu (Looping) | OpenGameArt · Eric Matyas | https://opengameart.org/content/racing-menu-looping | **CC-BY 3.0** | **Required** | `menu-racing.ogg` | Main Menu |
| Arcade Racing Tune | OpenGameArt · rezoner | https://opengameart.org/content/arcade-racing-tune | **CC-BY 3.0** | **Required** | `race-arcade-tune.mp3` | Race BGM (alt) |

**Mandatory attribution strings** — these must appear verbatim on Settings ▸ Licenses:

```
Music: "Racing Menu" by Eric Matyas (soundimage.org), licensed CC-BY 3.0.
Music: "Arcade Racing Tune" by rezoner, licensed CC-BY 3.0.
```

Also see: [CC0 – Upbeat / Electronic Music](https://opengameart.org/content/cc0-upbeat-electronic-music), a CC0 collection kept as a reserve pool for extra track themes.

---

## 11. Fonts

All three are **SIL Open Font License 1.1**. The OFL requires the license text to
ship with the software — it is mirrored in `docs/licenses/font-*-OFL.txt` and
surfaced on Settings ▸ Licenses.

| Family | Specimen | File source | Copyright | Local file |
|---|---|---|---|---|
| **Titan One** | https://fonts.google.com/specimen/Titan+One | `google/fonts/ofl/titanone/TitanOne-Regular.ttf` | © 2011 Rodrigo Fuenzalida | `TitanOne-Regular.ttf` |
| **Fredoka** | https://fonts.google.com/specimen/Fredoka | `google/fonts/ofl/fredoka/Fredoka[wdth,wght].ttf` | © 2016 The Fredoka Project Authors | `Fredoka-VariableFont.ttf` |
| **Chakra Petch** | https://fonts.google.com/specimen/Chakra+Petch | `google/fonts/ofl/chakrapetch/ChakraPetch-{SemiBold,Bold,BoldItalic}.ttf` | © 2018 The Chakra Petch Project Authors | 3 static files |

Raw file prefix: `https://raw.githubusercontent.com/google/fonts/main/`
**Destination:** `assets/fonts/` · **Used by:** see [design-system.md](design-system.md) § Typography

**Bundled, not shipped:** `google_fonts` the pub package is deliberately *not* used —
it fetches over HTTP at runtime on first launch. Fonts are vendored so the splash
screen renders correctly offline and on first run.

---

## 12. HDRI environments

**Source:** Poly Haven · **URL:** https://polyhaven.com/hdris
**License:** CC0 1.0 — "You do not need to give credit or attribution when using them"
**Attribution:** Not required (courtesy credit given)
**Format:** `.hdr`, 2K equirectangular
**Download prefix:** `https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/2k/`
**Destination:** `assets/environments/`
**Used by:** Per-track sky dome + image-based lighting in `flutter_scene`

| Track | Poly Haven asset | Authors | Local file | Size |
|---|---|---|---|---|
| 01 Dash Valley | [kloofendal_48d_partly_cloudy_puresky](https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky) | Greg Zaal, Jarod Guest | `dash-valley_2k.hdr` | 5.2 MB |
| 02 Neon Circuit | [dikhololo_night](https://polyhaven.com/a/dikhololo_night) | Greg Zaal | `neon-circuit_2k.hdr` | 6.7 MB |
| 03 Desert Rush | [qwantani_dusk_2_puresky](https://polyhaven.com/a/qwantani_dusk_2_puresky) | Greg Zaal, Jarod Guest | `desert-rush_2k.hdr` | 4.4 MB |
| 04 Frozen Peak | [snowy_park_01](https://polyhaven.com/a/snowy_park_01) | Oliksiy Yakovlyev | `frozen-peak_2k.hdr` | 4.8 MB |
| 05 Sky Harbor | [kloppenheim_02](https://polyhaven.com/a/kloppenheim_02) | Greg Zaal | `sky-harbor_2k.hdr` | 6.6 MB |
| 06 Cyber Coast | [venice_sunset](https://polyhaven.com/a/venice_sunset) | Greg Zaal | `cyber-coast_2k.hdr` | 5.5 MB |

**Notes:** ~33 MB total at 2K. `flutter_scene` bakes these to IBL at build time and can
cross-fade between them. Drop to 1K for the low graphics tier — see
[design-system.md](design-system.md) § Graphics tiers.

---

## 13. PBR surface textures

**Source:** ambientCG · **URL:** https://ambientcg.com/
**License:** CC0 1.0 — "You can include the raw files in your project, for example a video game"
**Attribution:** Not required (courtesy credit given) · https://docs.ambientcg.com/license/
**Download pattern:** `https://ambientcg.com/get?file=<AssetID>_1K-JPG.zip`
**Destination:** `assets/textures/<subdir>/`

| Asset ID | Page | Subdir | Used by |
|---|---|---|---|
| Asphalt033 | https://ambientcg.com/view?id=Asphalt033 | `road/` | Circuit tarmac — all tracks |
| Road007 | https://ambientcg.com/view?id=Road007 | `road-marked/` | Lane markings — 01, 06 |
| Grass005 | https://ambientcg.com/view?id=Grass005 | `grass/` | 01 Dash Valley |
| Concrete034 | https://ambientcg.com/view?id=Concrete034 | `concrete/` | 02 Neon Circuit |
| Ground054 | https://ambientcg.com/view?id=Ground054 | `sand/` | 03 Desert Rush |
| Snow015 | https://ambientcg.com/view?id=Snow015 | `snow/` | 04 Frozen Peak |
| Rock064 | https://ambientcg.com/view?id=Rock064 | `rock/` | 03 canyon, 04 cliffs |
| Gravel043 | https://ambientcg.com/view?id=Gravel043 | `gravel/` | Run-off areas |

**Notes:** Each 1K-JPG archive is ~9 MB and contains Color, NormalGL, Roughness, AO,
Displacement. **Only Color / NormalGL / Roughness are extracted** — AO and Displacement
are not used by the mobile material and would waste tens of megabytes. Before shipping,
convert to KTX2 with mip chains via `flutter_scene`'s `.fstex` build step; that is where
the real size win is.

---

## Verification log

Checks performed on 2026-08-24 while building this manifest:

- Every Kenney download URL fetched and the archive opened; `License.txt` inside each pack read and confirmed CC0.
- Kenney Racing Kit `License.txt` quoted verbatim: *"License: (Creative Commons Zero, CC0) … free to use in personal, educational and commercial projects."*
- Character GLBs parsed at the binary level to confirm skins and animation clip names.
- All six Poly Haven HDRI URLs returned HTTP 200 with real content-lengths.
- All Google Fonts TTF paths returned HTTP 200; `OFL.txt` fetched for each family.
- Every Freesound sound page opened individually and its `creativecommons.org` link read.
- ambientCG download variants enumerated through the v2 API.
- Kenney "Onscreen Controls" — the pack named in early planning does **not exist**; it is now **Mobile Controls**. Corrected here.
