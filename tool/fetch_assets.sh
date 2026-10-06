#!/usr/bin/env bash
#
# DashKart asset fetcher.
#
# Downloads every third-party asset listed in docs/assets.md into .assetcache/
# (gitignored), then extracts only the curated subset the game actually ships
# into assets/. Re-running is safe: cached archives are reused.
#
#   ./tool/fetch_assets.sh            # fetch + extract everything
#   ./tool/fetch_assets.sh models     # one group only
#
# Groups: models characters ui icons particles audio music fonts hdri textures
#
# Every asset here has a license verified at the source. See docs/assets.md.
# Licenses land in docs/licenses/.

set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
CACHE="$ROOT/.assetcache"
mkdir -p "$CACHE" docs/licenses

c_ok=$'\033[32m'; c_dim=$'\033[2m'; c_warn=$'\033[33m'; c_head=$'\033[1;36m'; c_off=$'\033[0m'
say()  { printf '%s\n' "$*"; }
step() { printf '\n%s==>%s %s\n' "$c_head" "$c_off" "$*"; }
ok()   { printf '  %s✓%s %s\n' "$c_ok" "$c_off" "$*"; }
skip() { printf '  %s·%s %s\n' "$c_dim" "$c_off" "$*"; }
warn() { printf '  %s!%s %s\n' "$c_warn" "$c_off" "$*"; }

# fetch <url> <cached-filename>
fetch() {
  local url="$1" out="$CACHE/$2"
  if [[ -s "$out" ]]; then skip "cached  $2"; return; fi
  curl -fsSL -A "Mozilla/5.0 (DashKart asset fetcher)" --retry 3 --max-time 300 -o "$out.part" "$url"
  mv "$out.part" "$out"
  ok "fetched $2 ($(du -h "$out" | cut -f1))"
}

# unpack <zip> <dest> <glob...>   — extract matching entries, flattened
unpack() {
  local zip="$CACHE/$1" dest="$ROOT/$2"; shift 2
  mkdir -p "$dest"
  unzip -o -j -q "$zip" "$@" -d "$dest" 2>/dev/null || true
}

want() { [[ "${GROUP:-all}" == "all" || "${GROUP}" == "$1" ]]; }
GROUP="${1:-all}"

# ---------------------------------------------------------------------------
# Kenney pack URLs — verified 2026-08-24. All CC0 1.0.
# ---------------------------------------------------------------------------
K_RACING_KIT="https://kenney.nl/media/pages/assets/racing-kit/933b8fd9fd-1677580949/kenney_racing-kit.zip"
K_CAR_KIT="https://kenney.nl/media/pages/assets/car-kit/1a312ec241-1775131960/kenney_car-kit.zip"
K_TOY_CAR_KIT="https://kenney.nl/media/pages/assets/toy-car-kit/42e19cc426-1736346027/kenney_toy-car-kit.zip"
K_NATURE_KIT="https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip"
K_CITY_SUBURBAN="https://kenney.nl/media/pages/assets/city-kit-suburban/2c871b7af2-1745479373/kenney_city-kit-suburban_20.zip"
K_MINI_CHARS="https://kenney.nl/media/pages/assets/mini-characters/bfc7e272b4-1774770718/kenney_mini-characters.zip"
K_BLOCKY_CHARS="https://kenney.nl/media/pages/assets/blocky-characters/8369c0cf30-1749547469/kenney_blocky-characters_20.zip"
K_TOON_CHARS="https://kenney.nl/media/pages/assets/toon-characters/4e8a6e4e53-1774770819/kenney_toon-characters.zip"
K_UI_PACK="https://kenney.nl/media/pages/assets/ui-pack/f651646eab-1718203990/kenney_ui-pack.zip"
K_UI_ADVENTURE="https://kenney.nl/media/pages/assets/ui-pack-adventure/9a877376bc-1723597274/kenney_ui-pack-adventure.zip"
K_MOBILE_CONTROLS="https://kenney.nl/media/pages/assets/mobile-controls/0d047b3be4-1754738457/mobile-controls-1.zip"
K_GAME_ICONS="https://kenney.nl/media/pages/assets/game-icons/1ebf9c14af-1677661579/kenney_game-icons.zip"
K_PARTICLE_PACK="https://kenney.nl/media/pages/assets/particle-pack/f8fe0f8cb8-1677578741/kenney_particle-pack.zip"
K_INTERFACE_SFX="https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip"
K_IMPACT_SFX="https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip"
K_UI_AUDIO="https://kenney.nl/media/pages/assets/ui-audio/490d233f68-1677590494/kenney_ui-audio.zip"
K_DIGITAL_AUDIO="https://kenney.nl/media/pages/assets/digital-audio/216eac4753-1677590265/kenney_digital-audio.zip"
K_MUSIC_JINGLES="https://kenney.nl/media/pages/assets/music-jingles/f37e530b9e-1677590399/kenney_music-jingles.zip"
K_SCIFI_SFX="https://kenney.nl/media/pages/assets/sci-fi-sounds/6b296f9ecf-1677589334/kenney_sci-fi-sounds.zip"
K_VOICEOVER="https://kenney.nl/media/pages/assets/voiceover-pack/3f7f168698-1677589897/kenney_voiceover-pack.zip"

# ===========================================================================
# 3D — karts, track kits, environment props
# ===========================================================================
if want models; then
step "3D models — karts, tracks, environment  (Kenney, CC0)"
  fetch "$K_CAR_KIT"       car-kit.zip
  fetch "$K_TOY_CAR_KIT"   toy-car-kit.zip
  fetch "$K_RACING_KIT"    racing-kit.zip
  fetch "$K_NATURE_KIT"    nature-kit.zip
  fetch "$K_CITY_SUBURBAN" city-kit-suburban.zip

  # --- The eight DashKart karts + swappable wheels (Car Kit) ---
  unpack car-kit.zip assets/models/karts \
    "Models/GLB format/kart-oobi.glb" "Models/GLB format/kart-oodi.glb" \
    "Models/GLB format/kart-ooli.glb" "Models/GLB format/kart-oopi.glb" \
    "Models/GLB format/kart-oozi.glb" "Models/GLB format/race.glb" \
    "Models/GLB format/race-future.glb" "Models/GLB format/hatchback-sports.glb" \
    "Models/GLB format/wheel-default.glb" "Models/GLB format/wheel-dark.glb" \
    "Models/GLB format/wheel-racing.glb"
  # Collision debris for crash effects
  unpack car-kit.zip assets/models/environment \
    "Models/GLB format/debris-*.glb" "Models/GLB format/cone.glb" "Models/GLB format/cone-flat.glb"
  ok "karts + wheels ($(ls assets/models/karts/*.glb 2>/dev/null | wc -l | tr -d ' ') models)"

  # --- Pickups and gates (Toy Car Kit) ---
  unpack toy-car-kit.zip assets/models/environment \
    "Models/GLB format/item-box.glb" "Models/GLB format/item-coin-gold.glb" \
    "Models/GLB format/item-coin-silver.glb" "Models/GLB format/item-coin-bronze.glb" \
    "Models/GLB format/item-banana.glb" "Models/GLB format/item-cone.glb" \
    "Models/GLB format/gate.glb" "Models/GLB format/gate-finish.glb" \
    "Models/GLB format/smoke.glb"
  # --- Stylised suspended track (Sky Harbor) ---
  unpack toy-car-kit.zip assets/models/tracks \
    "Models/GLB format/track-road-wide-*.glb" "Models/GLB format/track-striped-wide-*.glb" \
    "Models/GLB format/supports*.glb"
  ok "pickups, gates, suspended track ($(ls assets/models/tracks/*.glb 2>/dev/null | wc -l | tr -d ' ') pieces)"

  # --- Modular circuit road (Racing Kit) ---
  unpack racing-kit.zip assets/models/tracks \
    "Models/GLTF format/road*.glb"
  # --- Trackside dressing ---
  unpack racing-kit.zip assets/models/environment \
    "Models/GLTF format/barrier*.glb" "Models/GLTF format/pylon.glb" \
    "Models/GLTF format/flag*.glb" "Models/GLTF format/bannerTower*.glb" \
    "Models/GLTF format/grandStand*.glb" "Models/GLTF format/lightPost*.glb" \
    "Models/GLTF format/light*.glb" "Models/GLTF format/tent*.glb" \
    "Models/GLTF format/tree*.glb" "Models/GLTF format/billboard*.glb" \
    "Models/GLTF format/overhead*.glb" "Models/GLTF format/rail*.glb" \
    "Models/GLTF format/fence*.glb" "Models/GLTF format/ramp.glb" \
    "Models/GLTF format/pits*.glb" "Models/GLTF format/grass.glb"
  ok "circuit road + trackside props"

  # --- Nature (Dash Valley, Frozen Peak, Desert Rush) ---
  unpack nature-kit.zip assets/models/environment \
    "Models/GLTF format/tree_*.glb" "Models/GLTF format/rock_*.glb" \
    "Models/GLTF format/cliff_*.glb" "Models/GLTF format/stone_*.glb" \
    "Models/GLTF format/cactus_*.glb" "Models/GLTF format/grass_*.glb" \
    "Models/GLTF format/bridge_*.glb" "Models/GLTF format/log_*.glb"
  # --- City (Neon Circuit, Cyber Coast) ---
  unpack city-kit-suburban.zip assets/models/environment \
    "Models/GLB format/building-*.glb" "Models/GLB format/*.glb"
  ok "nature + city props ($(ls assets/models/environment/*.glb 2>/dev/null | wc -l | tr -d ' ') models)"

  unzip -p "$CACHE/racing-kit.zip" "*[Ll]icense.txt" > docs/licenses/kenney-racing-kit.txt 2>/dev/null || true
  unzip -p "$CACHE/car-kit.zip"    "*[Ll]icense.txt" > docs/licenses/kenney-car-kit.txt 2>/dev/null || true
fi

# ===========================================================================
# 3D — racers (rigged, with a `drive` clip)
# ===========================================================================
if want characters; then
step "3D racers — rigged characters  (Kenney, CC0)"
  fetch "$K_MINI_CHARS"   mini-characters.zip
  fetch "$K_BLOCKY_CHARS" blocky-characters.zip
  fetch "$K_TOON_CHARS"   toon-characters.zip

  # Primary roster: 8 of the 12 Mini Characters (32 clips incl. `drive`, `emote-yes`)
  unpack mini-characters.zip assets/models/characters \
    "*GLB*/character-female-a.glb" "*GLB*/character-female-b.glb" \
    "*GLB*/character-female-c.glb" "*GLB*/character-female-d.glb" \
    "*GLB*/character-male-a.glb"   "*GLB*/character-male-b.glb" \
    "*GLB*/character-male-c.glb"   "*GLB*/character-male-d.glb"
  # Accessories used to differentiate racer silhouettes
  unpack mini-characters.zip assets/models/characters \
    "*GLB*/aid-glasses.glb" "*GLB*/aid-sunglasses.glb"
  ok "racer roster ($(ls assets/models/characters/*.glb 2>/dev/null | wc -l | tr -d ' ') models, 32 clips each)"

  # 2D portrait art for menus (Toon Characters is a 2D pack)
  unpack toon-characters.zip assets/images/characters \
    "*/PNG/Poses HD/*idle*.png" "*/PNG/Poses HD/*cheer*.png" "*/PNG/Poses HD/*jump*.png"
  ok "2D portrait poses"

  unzip -p "$CACHE/mini-characters.zip" "*[Ll]icense.txt" > docs/licenses/kenney-mini-characters.txt 2>/dev/null || true
fi

# Post-process 3D models: embed external colormaps directly into GLB bufferViews
if want models || want characters; then
  step "Embedding textures into GLB models"
  fvm dart run tool/embed_textures.dart || dart run tool/embed_textures.dart
  ok "all GLB textures embedded"
fi

# ===========================================================================
# UI frames, panels, buttons
# ===========================================================================
if want ui; then
step "UI frames and panels  (Kenney, CC0)"
  fetch "$K_UI_PACK"         ui-pack.zip
  fetch "$K_UI_ADVENTURE"    ui-pack-adventure.zip
  fetch "$K_MOBILE_CONTROLS" mobile-controls.zip

  # Vector UI so it stays crisp at every density
  unpack ui-pack.zip assets/images/ui/frames "Vector/Blue/*.svg" "Vector/Yellow/*.svg" "Vector/Grey/*.svg" "Vector/Extra/*.svg"
  unpack ui-pack-adventure.zip assets/images/ui/frames-adventure "Vector/*.svg" "*/Vector/*.svg"
  ok "UI frames ($(ls assets/images/ui/frames/*.svg 2>/dev/null | wc -l | tr -d ' ') SVG)"

  # On-screen driving controls, with built-in pressed ("highlight") states
  unpack mobile-controls.zip assets/images/ui/controls \
    "Vector/Style A/*.svg" "Vector/Style B/*.svg" "Vector/Highlights A/*.svg"
  ok "control buttons + pressed states ($(ls assets/images/ui/controls/*.svg 2>/dev/null | wc -l | tr -d ' ') SVG)"

  unzip -p "$CACHE/ui-pack.zip" "*[Ll]icense.txt" > docs/licenses/kenney-ui-pack.txt 2>/dev/null || true
fi

# ===========================================================================
# Icons — one consistent family
# ===========================================================================
if want icons; then
step "Icon set  (Kenney, CC0)"
  fetch "$K_MOBILE_CONTROLS" mobile-controls.zip
  fetch "$K_GAME_ICONS"      game-icons.zip

  # Primary: Kenney Mobile Controls icon family (racing-specific — steering
  # wheel, pedals, brake, shield, fire) as SVG.
  unpack mobile-controls.zip assets/images/ui/icons "Vector/Icons/*.svg"
  # Gap-fill from Kenney Game Icons — same author, same design language.
  unpack game-icons.zip assets/images/ui/icons-raster \
    "PNG/White/2x/trophy.png" "PNG/White/2x/home.png" "PNG/White/2x/unlocked.png" \
    "PNG/White/2x/locked.png" "PNG/White/2x/medal1.png" "PNG/White/2x/medal2.png" \
    "PNG/White/2x/gear.png" "PNG/White/2x/information.png" "PNG/White/2x/leaderboardsSimple.png"
  ok "icons ($(ls assets/images/ui/icons/*.svg 2>/dev/null | wc -l | tr -d ' ') SVG + $(ls assets/images/ui/icons-raster/*.png 2>/dev/null | wc -l | tr -d ' ') PNG)"
  warn "9 icons still need drawing — see docs/asset-inventory.md § CREATE"
fi

# ===========================================================================
# Particles — boost, drift smoke, sparks, speed lines
# ===========================================================================
if want particles; then
step "Particles  (Kenney, CC0)"
  fetch "$K_PARTICLE_PACK" particle-pack.zip
  unpack particle-pack.zip assets/particles \
    "PNG (Transparent)/smoke_*.png"  "PNG (Transparent)/spark_*.png" \
    "PNG (Transparent)/flame_*.png"  "PNG (Transparent)/fire_*.png" \
    "PNG (Transparent)/dirt_*.png"   "PNG (Transparent)/trace_*.png" \
    "PNG (Transparent)/star_*.png"   "PNG (Transparent)/light_*.png" \
    "PNG (Transparent)/flare_*.png"  "PNG (Transparent)/circle_*.png" \
    "PNG (Transparent)/magic_*.png"  "PNG (Transparent)/twirl_*.png" \
    "PNG (Transparent)/scorch_*.png"
  ok "particles ($(ls assets/particles/*.png 2>/dev/null | wc -l | tr -d ' ') textures)"
  unzip -p "$CACHE/particle-pack.zip" "*[Ll]icense.txt" > docs/licenses/kenney-particle-pack.txt 2>/dev/null || true
fi

# ===========================================================================
# Sound effects
# ===========================================================================
if want audio; then
step "Sound effects  (Kenney CC0 + Freesound CC0)"
  fetch "$K_INTERFACE_SFX" interface-sounds.zip
  fetch "$K_IMPACT_SFX"    impact-sounds.zip
  fetch "$K_UI_AUDIO"      ui-audio.zip
  fetch "$K_DIGITAL_AUDIO" digital-audio.zip
  fetch "$K_SCIFI_SFX"     sci-fi-sounds.zip
  fetch "$K_VOICEOVER"     voiceover-pack.zip

  unpack interface-sounds.zip assets/audio/sfx/ui   "Audio/*.ogg" "*.ogg"
  unpack ui-audio.zip         assets/audio/sfx/ui   "Audio/*.ogg" "*.ogg"
  unpack impact-sounds.zip    assets/audio/sfx/impact "Audio/*.ogg" "*.ogg"
  unpack digital-audio.zip    assets/audio/sfx/digital "Audio/*.ogg" "*.ogg"
  unpack sci-fi-sounds.zip    assets/audio/sfx/scifi "Audio/*.ogg" "*.ogg"
  unpack voiceover-pack.zip   assets/audio/voice    "Audio/*.ogg" "*.ogg"
  ok "Kenney SFX ($(find assets/audio/sfx -name '*.ogg' 2>/dev/null | wc -l | tr -d ' ') files)"

  # Engine loops — Freesound, each verified CC0 1.0 individually.
  step "Engine loops  (Freesound, CC0 — verified per sound)"
  # Freesound serves previews from a CDN path that embeds an upload id, so the
  # sound page is scraped for it. Originals need a login, which this cannot do.
  fs() { # fs <id> <name>
    local id="$1" name="$2" url
    if [[ -s "assets/audio/sfx/engine/$name" ]]; then skip "cached  $name"; return; fi
    mkdir -p assets/audio/sfx/engine
    url=$(curl -fsSL -A "Mozilla/5.0 (DashKart)" --max-time 60 "https://freesound.org/s/$id/" \
          | grep -oE 'https://cdn\.freesound\.org/previews/[^"'"'"' ]+-hq\.mp3' | head -1)
    if [[ -n "$url" ]] && curl -fsSL -A "Mozilla/5.0 (DashKart)" --max-time 120 \
         -o "assets/audio/sfx/engine/${name%.ogg}.mp3" "$url"; then
      ok "${name%.ogg}.mp3"
    else
      warn "$name — download by hand: https://freesound.org/s/$id/"
    fi
  }
  fs 369053 engine-idle-a.ogg      # car_idle_loop.wav       — AndrewAlexander     CC0
  fs 186939 engine-idle-b.ogg      # engine2_idle_loop.wav   — ReadeOnly           CC0
  fs 216563 engine-idle-c.ogg      # IDLE_ENGINE_001.ogg     — pgi                 CC0
  fs 748027 engine-sedan.ogg       # Sedan engine loop       — Dmitry_mansurev64   CC0
  fs 679693 engine-turbo.ogg       # T4-19TD-2000-Engine     — grauxonen           CC0
  fs 407540 engine-scifi.ogg       # Sci-Fi Engine Loop      — Sojan               CC0
  fs 189622 amb-kart-indoor.ogg    # Go Kart Racing.flac     — qubodup             CC0
  fs 317471 amb-kart-outdoor.ogg   # Go Kart Racing Outdoors — OverlookHotelRecords CC0
  fs 221568 crowd-cheer.ogg        # cheering crowd          — AlaskaRobotics      CC0
  warn "Freesound previews are 128kbps OGG. For shipping quality, log in and download the originals."
fi

# ===========================================================================
# Music
# ===========================================================================
if want music; then
step "Music  (Kenney CC0 + OpenGameArt)"
  fetch "$K_MUSIC_JINGLES" music-jingles.zip
  unpack music-jingles.zip assets/audio/music/jingles "Audio/*.ogg" "*.ogg"
  ok "jingles ($(ls assets/audio/music/jingles/*.ogg 2>/dev/null | wc -l | tr -d ' ') stings)"

  oga() { # oga <url> <name> <license note>
    local url="$1" name="$2"
    if [[ -s "assets/audio/music/$name" ]]; then skip "cached  $name"; return; fi
    mkdir -p assets/audio/music
    curl -fsSL -A "Mozilla/5.0 (DashKart)" --max-time 180 -o "assets/audio/music/$name" "$url" \
      && ok "$name  ($3)" || warn "$name failed — fetch by hand"
  }
  oga "https://opengameart.org/sites/default/files/S31-Winning%20the%20Race.ogg" \
      race-winning-the-race.ogg "CC0 · Section31"
  oga "https://opengameart.org/sites/default/files/Funked%20Up.mp3" \
      menu-funked-up.mp3 "CC0 · Joth"
  oga "https://opengameart.org/sites/default/files/racing_menu.ogg" \
      menu-racing.ogg "CC-BY 3.0 · Eric Matyas — ATTRIBUTION REQUIRED"
  oga "https://opengameart.org/sites/default/files/random-race.mp3" \
      race-arcade-tune.mp3 "CC-BY 3.0 · rezoner — ATTRIBUTION REQUIRED"
  warn "The two CC-BY tracks must be credited on the Settings ▸ Licenses screen."
fi

# ===========================================================================
# Fonts
# ===========================================================================
if want fonts; then
step "Fonts  (Google Fonts, SIL OFL 1.1)"
  gf() { # gf <repo-path> <local-name>
    local path="$1" name="$2"
    if [[ -s "assets/fonts/$name" ]]; then skip "cached  $name"; return; fi
    curl -fsSL --max-time 120 -o "assets/fonts/$name" \
      "https://raw.githubusercontent.com/google/fonts/main/$path" && ok "$name"
  }
  gf "ofl/fredoka/Fredoka%5Bwdth,wght%5D.ttf"      "Fredoka-VariableFont.ttf"
  gf "ofl/titanone/TitanOne-Regular.ttf"           "TitanOne-Regular.ttf"
  gf "ofl/chakrapetch/ChakraPetch-SemiBold.ttf"    "ChakraPetch-SemiBold.ttf"
  gf "ofl/chakrapetch/ChakraPetch-Bold.ttf"        "ChakraPetch-Bold.ttf"
  gf "ofl/chakrapetch/ChakraPetch-BoldItalic.ttf"  "ChakraPetch-BoldItalic.ttf"
  for f in fredoka titanone chakrapetch; do
    curl -fsSL --max-time 60 -o "docs/licenses/font-$f-OFL.txt" \
      "https://raw.githubusercontent.com/google/fonts/main/ofl/$f/OFL.txt" 2>/dev/null || true
  done
  ok "OFL license texts saved to docs/licenses/"
fi

# ===========================================================================
# HDRI environments — sky + image-based lighting per track
# ===========================================================================
if want hdri; then
step "HDRI skies  (Poly Haven, CC0)"
  ph() { # ph <slug> <local-name>
    local slug="$1" name="$2"
    if [[ -s "assets/environments/$name" ]]; then skip "cached  $name"; return; fi
    curl -fsSL -A "Mozilla/5.0 (DashKart)" --max-time 300 -o "assets/environments/$name" \
      "https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/2k/${slug}_2k.hdr" && ok "$name"
  }
  ph kloofendal_48d_partly_cloudy_puresky dash-valley_2k.hdr    # 01 Dash Valley
  ph dikhololo_night                      neon-circuit_2k.hdr   # 02 Neon Circuit
  ph qwantani_dusk_2_puresky              desert-rush_2k.hdr    # 03 Desert Rush
  ph snowy_park_01                        frozen-peak_2k.hdr    # 04 Frozen Peak
  ph kloppenheim_02                       sky-harbor_2k.hdr     # 05 Sky Harbor
  ph venice_sunset                        cyber-coast_2k.hdr    # 06 Cyber Coast
fi

# ===========================================================================
# PBR surface textures
# ===========================================================================
if want textures; then
step "Surface textures  (ambientCG, CC0)"
  warn "1K-JPG archives are ~9 MB each and carry maps the game does not ship."
  warn "Only Color / NormalGL / Roughness are extracted; the rest stay in .assetcache/."
  acg() { # acg <AssetID> <dest-subdir>
    local id="$1" sub="$2"
    fetch "https://ambientcg.com/get?file=${id}_1K-JPG.zip" "acg-${id}.zip"
    mkdir -p "assets/textures/$sub"
    unzip -o -j -q "$CACHE/acg-${id}.zip" \
      "*_Color.jpg" "*_NormalGL.jpg" "*_Roughness.jpg" -d "assets/textures/$sub" 2>/dev/null || true
    ok "$id → assets/textures/$sub"
  }
  acg Asphalt033  road         # circuit tarmac  — all tracks
  acg Road007     road-marked  # lane markings   — Dash Valley, Cyber Coast
  acg Grass005    grass        # 01 Dash Valley
  acg Concrete034 concrete     # 02 Neon Circuit
  acg Ground054   sand         # 03 Desert Rush
  acg Snow015     snow         # 04 Frozen Peak
  acg Rock064     rock         # 03 / 04 canyon + cliffs
  acg Gravel043   gravel       # run-off areas
  printf 'ambientCG assets are CC0 1.0. https://docs.ambientcg.com/license/\n' > docs/licenses/ambientcg-CC0.txt
fi

step "Done"
say ""
say "  assets/  $(du -sh assets 2>/dev/null | cut -f1)     cache  $(du -sh "$CACHE" 2>/dev/null | cut -f1)  (gitignored)"
say ""
say "  Every asset above ships under CC0 except two CC-BY 3.0 music tracks,"
say "  which are credited in docs/assets.md and must appear in Settings ▸ Licenses."
say ""
