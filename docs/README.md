# DashKart — Asset & UI Master Plan

An original arcade kart racer for Android and iOS. This directory is the
production plan: what the game looks like, what it is built from, and where every
asset came from.

**Status:** plan complete, assets sourced and in place, UI implemented. The 3D
race scene is not started — see [Implementation status](#implementation-status).

## The documents

| Document | What it covers |
|---|---|
| [asset-inventory.md](asset-inventory.md) | Every screen and component, with its asset and status — **DOWNLOADED / CREATE / OPTIONAL / NOT FOUND** |
| [assets.md](assets.md) | The manifest. Source, URL, license, attribution, destination, and consumer for every third-party asset |
| [design-system.md](design-system.md) | Colour ramps, typography, spacing, radius, elevation, motion, graphics tiers, and the eleven components |
| [wireframes.md](wireframes.md) | Layout specs and animation timelines for all ten screens |
| [ui-references.md](ui-references.md) | Structural study of seven shipped racers, and the original DashKart interpretation |
| [licenses/](licenses/) | Mirrored license texts |

## What is already in place

`tool/fetch_assets.sh` has run. **101 MB** in `assets/`, every item license-verified:

| | Count | Source |
|---|---|---|
| Kart models | 8 + 3 wheel sets | Kenney Car Kit · CC0 |
| Rigged racers | 8, **32 animation clips each** incl. `drive` | Kenney Mini Characters · CC0 |
| Track pieces | 102 modular | Kenney Racing Kit + Toy Car Kit · CC0 |
| Environment props | 316 | Kenney Racing / Nature / City kits · CC0 |
| UI frames | 228 SVG | Kenney UI Pack + Adventure · CC0 |
| Driving controls | 72 SVG **with pressed states** | Kenney Mobile Controls · CC0 |
| Icons | 42 SVG + 9 PNG | Kenney Mobile Controls + Game Icons · CC0 |
| Particles | 64 | Kenney Particle Pack · CC0 |
| Sound effects | 418 | Kenney audio packs · CC0 |
| Engine / ambience loops | 9 | Freesound · CC0 (verified per sound) |
| Music | 5 | Kenney + OpenGameArt · CC0 / CC-BY 3.0 |
| HDRI skies | 6, one per track | Poly Haven · CC0 |
| PBR texture sets | 8 | ambientCG · CC0 |
| Fonts | 3 families | Google Fonts · SIL OFL 1.1 |

Re-run any group: `./tool/fetch_assets.sh [models|characters|ui|icons|particles|audio|music|fonts|hdri|textures]`

## What still has to be made

Fifteen items in [asset-inventory.md § CREATE](asset-inventory.md#️-create--full-list-with-specifications),
each with a written spec. They fall into three groups:

1. **Brand identity** — logo lockup, app icon, avatar frame. Must be original.
2. **Nine icons + six item icons** — metaphors no CC0 set carries (drift, handling,
   weight, position, and the six original items). Drawn on the Kenney grid so the
   set stays one family.
3. **Track previews, kart thumbnails, portraits** — captured from the real scene
   via `flutter_scene`'s frame capture, not hand-painted, so the art cannot drift
   out of sync with the models.

## Technical decisions

| Decision | Choice | Why |
|---|---|---|
| Orientation | Landscape-locked | The HUD needs width; no rotation stutter between menu and race |
| Menu / HUD | Flutter widgets + `CustomPainter` | Where Flutter is strongest and where the quality bar is judged |
| Race scene | `flutter_scene` 0.22.2 | Only real glTF/PBR 3D engine for Flutter; loads the Kenney `.glb` directly. Needs Flutter ≥ 3.47 — the project is on **3.47.0**, satisfied exactly |
| Physics | `flutter_scene_rapier` 0.5.0 | Shares flutter_scene's physics contract |
| Audio | `flutter_soloud` | Low latency, and pitch-shifts the engine loop by RPM |
| Fonts | Vendored, not `google_fonts` | That package fetches over HTTP on first launch; the splash must render offline |
| Version pinning | `flutter_scene` pinned exactly | Pre-1.0, documents breaking changes in minor releases |

**Risk:** `flutter_scene` is pre-1.0. Mitigated by pinning the exact version and
putting the race renderer behind a `RaceRenderer` interface. Kenney Racing Kit also
ships 578 isometric sprites, kept as a 2D fallback — see
[asset-inventory.md § OPTIONAL](asset-inventory.md#-optional).

## Before shipping

Both are recorded in [asset-inventory.md § Licence obligations](asset-inventory.md#licence-obligations-checklist):

1. **Two music tracks are CC-BY 3.0 and their attribution is mandatory** — "Racing
   Menu" (Eric Matyas) and "Arcade Racing Tune" (rezoner) must appear verbatim on
   Settings ▸ Licenses. Everything else is CC0 or OFL.
2. **Freesound originals must replace the preview MP3s.** The fetch script pulls
   128 kbps previews because originals need a login it cannot perform.

One asset was found and deliberately **rejected**: Freesound #443269 "Car idling,
loop" is CC BY-NC 4.0 — non-commercial only, so it cannot ship in a store release.

## Platform setup

`flutter_scene` needs Flutter GPU enabled once per platform:

- `ios/Runner/Info.plist` → `<key>FLTEnableFlutterGPU</key><true/>`
- `android/app/src/main/AndroidManifest.xml`, inside `<application>` →
  `<meta-data android:name="io.flutter.embedding.android.EnableFlutterGPU" android:value="true" />`

Both are now set, and `dart run flutter_scene:init` has written the asset build
hook to `hook/build.dart`.

---

## Implementation status

The plan phase is complete and implementation has started. Current state:

### Built

| Layer | Files | State |
|---|---|---|
| **Design tokens** | `lib/design/` — colours, typography, metrics, motion, icon set | Complete |
| **Components** | `lib/ui/components/` — all eleven from the design system, plus `DashWordmark`, `DashPressable`, `DashEnter`, `DashControls` | Complete |
| **Domain** | `lib/data/` — models, catalogue (8 karts, 8 racers, 6 tracks), player progression | Complete |
| **Screens** | Splash, Main Menu, Track Select, Kart Select, Character Select, Garage, Settings, Race, Results, Countdown | Complete |
| **Race HUD** | `DashGameHUD` — position, lap, minimap, speed, item slot, driving controls | Complete |
| **Race loop** | `RaceSimulation` — acceleration, braking, cornering scrub, boost, rival field, lap and position tracking | Complete |
| **Race scene** | 3D via `flutter_scene` | **Not started** — a painted road stands in |

### Verified

- `flutter analyze` — clean across the whole package
- `flutter test` — **47 tests passing**:
  - catalogue integrity, progression rules, HUD ordinals, component behaviour
  - ten covering the race simulation (speed clamp, braking, cornering scrub by
    handling, boost expiry, lap and position tracking, finish conditions)
  - **22 layout tests** running every screen at compact (667×375), baseline
    (844×390), and expanded (1194×834), plus the HUD under a landscape notch.
    A `RenderFlex` overflow paints a striped bar instead of throwing, so it is
    invisible unless something looks for it — these do.
- `flutter build bundle` — every asset path resolves
- Every screen render-checked at the 844×390 landscape baseline

### Bugs the checks caught

Found by tests:

1. `PlayerState.purchase` charged twice for an already-owned kart. Now returns early when the kart is already unlocked.
2. `_LockOverlay` overflowed its 132dp card on a two-word unlock label ("24 trophies"). Now wraps.

Found by looking at the renders:

3. Kart Select's info panel overflowed — five stat rows plus a header and an action row did not fit, and the SELECT button escaped its card. Rows tightened, stats given the flexible space.
4. `CustomPaint` with no child and no size collapses to `Size.zero`; the kart previews and turntable were rendering a few pixels wide. Both now `SizedBox.expand`.
5. The lock overlay blurred the whole card including the kart name, so a locked card showed a price without saying what it bought. Now covers the art only.
6. Main-menu secondary buttons truncated their labels ("TRAC…", "GARA…"). They now size to content.
7. The driving controls were untinted Kenney grey, leaving accelerate, brake, and drift distinguishable only by glyph. Each is now tinted to its function.

Found by the layout tests — **nine overflows across five screens**, none of which
throw at runtime:

8. Kart Select and Character Select stat blocks have a hard minimum height a short landscape screen cannot afford. Both now scale down rather than clip their last rows.
9. Track Select's footer (trophy, best time, lap count) overran a 248dp card.
10. Settings' section rail and segmented controls overran a narrow panel.
11. Results' action row and place title overran at 667dp; the row now wraps and drops icons before labels.
12. Main Menu was 18px too tall at the baseline size.

### Checking layout

```sh
flutter test test/layout_test.dart
```

Every screen at three sizes. Run this before any layout change lands.

### Rendering screens

```sh
flutter test test/render/render_screens.dart --tags render
```

Writes PNGs to `build/screens/`. Real fonts are registered through `FontLoader`,
so the output matches the device. Each screen is stepped frame by frame rather
than settled — the ambient animation loops never settle.

### Not yet built

- The 3D race scene (`flutter_scene` + `flutter_scene_rapier`)
- Audio playback (`flutter_soloud`) — all 568 files are in place, nothing plays yet
- Character Select screen
- Persistence — `PlayerState` is in-memory; `shared_preferences` is a dependency but unused
- The remaining CREATE items: app icon, six item icons, track/kart/portrait renders, trophies, decals
