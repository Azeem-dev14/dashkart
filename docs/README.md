# DashKart — Asset & UI Master Plan

An original arcade kart racer for Android and iOS. This directory is the
production plan: what the game looks like, what it is built from, and where every
asset came from.

**Status:** playable end to end — see [Implementation status](#implementation-status).

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

The game is playable start to finish: splash → loading → name entry → menu →
kart → circuit → mode → countdown → race → results → next race.

### How a race works

| Piece | Where | Notes |
|---|---|---|
| Kart stats → physics | `lib/data/kart_tuning.dart` | One conversion. The five card stats set top speed, acceleration, yaw rate, grip, drift behaviour, mass and braking. The scene, the bots, the HUD readout and the circuit tests all read it. |
| Driving model | `race_scene.dart` | Velocity-driven Rapier body. Hold DRIFT through a corner at speed to slide; release on a full meter for a mini turbo. |
| AI field | `race_simulation.dart` | Bots drive the circuit's real curvature — brake for corners, take the inside line, skill set by circuit difficulty, small bounded catch-up. |
| No-3D fallback | `advancePlayerKinematically` | Where Flutter GPU is unavailable the same tuning drives the player along the spline, so the race still finishes. |
| Progression | `lib/data/player.dart` | Trophies 3/2/1 for the podium, XP per finish + laps + record, level derived from XP. Fresh saves start at zero. Multiplayer is unranked. |
| Content | `lib/data/catalog.dart` | 1 kart (Dash; `KartTuning` supports more), 3 circuits gated by trophies. |
| Settings | `settings_screen.dart` | Volumes, steering mode (buttons / thumb pad), sensitivity, vibration, camera shake, units, graphics tier — all read by something. |

### Tests

`flutter test` — kart tuning and balance, progression and persistence, AI and
the kinematic fallback, circuit geometry against every kart, audio asset
existence, HUD states, and layout at six screen sizes for every screen.

### Not done

- **Only the turbo item exists.** `RaceItem` lists six; the other five have no
  pickups or effects. The shop and HUD only ever show turbo.
- **No on-device tuning pass.** Driving constants were derived and tested in
  simulation, not feel-tested on hardware. Expect to retune `KartTuning` and the
  bot `skill` values.
- **Impact, overtake and lap sounds are the shipped samples pitch-shifted**, not
  dedicated recordings.
- **The CREATE assets** in `asset-inventory.md` (app icon, item icons, renders)
  are still outstanding.
- **Multiplayer** needs the Firebase project configured; see `multiplayer-setup.md`.

## Release build

```sh
tool/build_release_apk.sh          # one APK per CPU type
tool/build_release_apk.sh arm64    # one APK, 64-bit ARM phones only (smallest)
```

For the Play Store build an app bundle instead — Google then serves each phone
only its own CPU's code, which is smaller still:
`flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`.

**One-off Android setup** (this machine had none): install the Android SDK
through Android Studio's SDK Manager (a platform, build-tools, and the NDK
28.2.13676358), run `flutter config --android-sdk <path to it>` — and make
`android/local.properties`' `sdk.dir` match, since it currently points at
Homebrew's `platform-tools` folder — then `flutter doctor --android-licenses`.

**Signing.** Without `android/key.properties` the release APK is signed with the
debug key: it installs and runs, but cannot be published. Create an upload key
and add `storeFile`, `storePassword`, `keyAlias`, `keyPassword` there (the file
is gitignored).

**Keep `build/symbols`.** Obfuscated crash reports need it to be readable.

What keeps the build small, so it stays that way:

- `assets/models/` is not in `pubspec.yaml`'s asset list. The build hook
  compiles those `.glb` files into `flutter_scene_generated/`, which is what
  `loadScene` reads at runtime; listing the sources too shipped every model
  twice (about 3.5 MB).
- `uses-material-design` is off — nothing uses the Material icon font.
- R8 and resource shrinking are on for release (`android/app/build.gradle.kts`).
- The kart itself is the biggest file (94k vertices, 8.4 MB compiled). Reducing
  that needs the model reworked in a 3D tool, not a build flag.
- Music is the next biggest: `menu-racing.ogg` is 500 kbps for a short loop and
  re-encoding it near 96 kbps would save about 0.6 MB. Needs `ffmpeg`.

