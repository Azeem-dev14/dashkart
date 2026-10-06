# DashKart — UI Reference Study

Seven shipped kart and arcade racers, read for structure only: layout, hierarchy,
density, and HUD placement. **No artwork, icon, typeface, colour value, sound, or
UI arrangement is copied.** Each entry ends with the DashKart decision it informed.

> **Boundary.** These games are studied the way an architect studies buildings.
> Nothing Nintendo, Activision, Sega, Gameloft, or Nexon owns — character designs,
> track names, logos, item designs, mascot shapes, sound effects — appears in
> DashKart. Every asset DashKart ships is CC0, OFL, CC-BY with attribution, or
> original. See [assets.md](assets.md).

---

## 1. Mario Kart Tour — mobile-first kart racing

| Aspect | Observation |
|---|---|
| Layout | Portrait menus, landscape racing. Large hero art dominates; content is thumb-reachable at the bottom. |
| Navigation | Bottom tab bar, persistent. Menus are shallow — two taps to race. |
| Hierarchy | One unmistakable primary CTA per screen; everything else is visually secondary. |
| Colour | Saturated primaries on white/light gradients; colour marks rarity and state. |
| Typography | Heavy rounded sans throughout; numbers oversized. |
| Cards | Rounded rectangles, thick borders, glossy tops, drop shadows. |
| Animation | Everything scales and bounces. Nothing appears without overshoot. |
| Density | Deliberately low. Big targets, generous whitespace. |
| HUD | Minimal — position, lap, item. Track carries the drama. |

**DashKart decision:** adopt the *one loud CTA* rule (RACE at 76 dp, the only hero
button anywhere) and the low-density approach. **Reject** portrait menus — DashKart
locks landscape so there is no rotation stutter between menu and race.

---

## 2. Mario Kart 8 Deluxe — console polish

| Aspect | Observation |
|---|---|
| Layout | Symmetrical grids, strong centre axis, wide margins. |
| Hierarchy | Selection is unambiguous: scale, ring, glow, and elevation together. |
| Colour | Deep backgrounds so kart and character art pop. |
| Cards | Kart/character tiles at a consistent ratio with silhouettes readable at thumbnail size. |
| Animation | Slow, confident camera moves. Character reacts on selection. |
| HUD | Corners only; centre of the screen stays clear. |
| Stats | Stat bars with a ghost marker showing the previous vehicle's value while swapping. |

**DashKart decision:** the **ghost stat marker** is the single most useful idea here
and is specified into `DashStatBar`. Also adopted: dark backdrop for art contrast,
multi-signal selection state, corners-only HUD.

---

## 3. Crash Team Racing / Nitro-Fueled — drift-focused racing

| Aspect | Observation |
|---|---|
| HUD | Drift/boost charge is the most prominent HUD element after position. |
| Feedback | Boost tiers escalate visibly — colour shifts, sparks intensify. |
| Layout | Angled panels and diagonal cuts; racing-inspired geometry. |
| Colour | High-contrast, near-neon over dark. |
| Animation | Fast and punchy; short durations, hard easing. |
| Results | Dramatic podium with heavy character performance. |

**DashKart decision:** drift charge gets real HUD prominence, with escalating
colour and particle density. Adopt the angled/diagonal motif (the logo's chevron,
the 8° italic lean) as brand geometry rather than decoration.

---

## 4. Asphalt series — premium mobile racing production

| Aspect | Observation |
|---|---|
| Layout | Dense, information-rich; multiple currencies and progress meters visible. |
| Hierarchy | Risks burying the primary action under meta-progression. |
| Colour | Dark UI with neon accents; heavy gradients and glass. |
| Typography | Condensed technical sans; italic for speed. |
| HUD | Speed readout is large and central-bottom. |
| Effects | Aggressive motion blur and speed lines under boost. |

**DashKart decision:** adopt the **large bottom-centre speed readout in an italic
technical face** (Chakra Petch BoldItalic) and the dark-plus-neon direction.
**Explicitly reject** the density — Asphalt's menus are the cautionary example for
DashKart's "avoid corporate dashboard styling" rule.

---

## 5. KartRider / Drift — kart racing with deep customisation

| Aspect | Observation |
|---|---|
| Layout | Garage is the hub; customisation is the retention loop. |
| Cards | Item grids with rarity borders and clear lock states. |
| Colour | Bright, high-key, cheerful. |
| Customisation | Colour/part/decal split into tabs with live preview. |
| Density | High in garage, low elsewhere. |

**DashKart decision:** the Colour / Wheels / Decals tab split with live 3D preview
is directly the Garage structure — kept deliberately shallow for v1.

---

## 6. Beach Buggy Racing — accessible mobile arcade racing

| Aspect | Observation |
|---|---|
| Controls | Large, well-separated touch targets; tilt and touch both first-class. |
| HUD | Very few elements; item slot is prominent and centre-weighted. |
| Colour | Bright, saturated, cartoon. |
| Onboarding | Playable within seconds. |
| Density | Lowest of the set. |

**DashKart decision:** control sizing (88–96 dp driving targets, well beyond the
48 dp minimum) and the centre-weighted item slot. Touch and tilt both surface as
first-class options in Settings ▸ Controls.

---

## 7. Sonic & All-Stars Racing Transformed — variety and spectacle

| Aspect | Observation |
|---|---|
| Track select | Each track sells its own identity through distinct art and palette. |
| Layout | Track cards carry preview, difficulty, and record together. |
| Colour | Per-track palettes; UI adapts subtly to environment. |
| Animation | Transitions are themed to the track. |

**DashKart decision:** each of the six tracks gets a distinct sky (its own Poly
Haven HDRI) and terrain material set, so track identity comes from real scene
differences rather than a recoloured card. `DashTrackCard` carries preview,
difficulty, environment, and best time together.

---

## Synthesis — the DashKart interpretation

| Pattern | Where it came from | DashKart's version |
|---|---|---|
| One loud primary CTA | MK Tour, MK8 | RACE at 76 dp `hero` — the only hero button in the app |
| Dark backdrop, bright art | MK8, Asphalt | `bgBase #0B1130` under saturated brand ramps |
| Ghost stat marker | MK8 | Built into `DashStatBar` |
| Big italic speed readout | Asphalt | Chakra Petch BoldItalic 44 px, bottom-centre-left |
| Drift charge prominence | CTR | Escalating colour + particle density on the HUD |
| Oversized touch targets | Beach Buggy | 88–96 dp driving controls |
| Colour/part/decal tabs | KartRider | Garage segmented control, live 3D preview |
| Per-track identity | Sonic Racing | One Poly Haven HDRI + material set per track |
| Corners-only HUD | MK8 | Centre stays clear; two gradient scrims |
| Low menu density | MK Tour, Beach Buggy | ≤ 6 interactive elements per menu screen |
| **Rejected:** dense meta-progression | Asphalt | Currency shown, never a wall of meters |
| **Rejected:** portrait menus | MK Tour | Landscape-locked throughout |

### Where DashKart's identity comes from, not references

- **Rounded-chunky over glossy-skeuomorphic.** Kenney's flat vector UI with hard
  bevels, not gradient gloss and bevelled chrome.
- **Blue-primary with orange energy.** The reference set skews red/yellow (Mario)
  or green/purple (Sonic, CTR). DashKart Blue + Turbo Orange is deliberately
  neither, and reads distinctly at store-thumbnail size.
- **Three-family type system with a dedicated numeric face.** Most of the set uses
  one heavy face throughout. Splitting brand / UI / numeric is DashKart's own call
  and is what makes the HUD readable at speed.
- **Low-poly flat-shaded 3D.** A coherent, achievable art direction that stays
  60 fps on mid-range mobile — and a look none of the references have.

---

## Compliance check

- [x] No character design resembles a Nintendo, Sega, or Activision character
- [x] No track name, item name, or kart name reuses a protected mark
- [x] No sound is sampled from any referenced game
- [x] No UI asset is traced, screenshotted, or redrawn from any referenced game
- [x] No typeface matches a referenced game's proprietary face
- [x] The DashKart wordmark is an original lockup in an OFL typeface
- [x] Every shipped asset traces to a licence recorded in [assets.md](assets.md)
