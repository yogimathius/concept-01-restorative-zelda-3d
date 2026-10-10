# Living care world pass

Status: playable world and UI pass, 2026-09-28. This develops the restorative economy's **living care interactions** milestone across the existing Broken Ford and Reedglass Marsh chapters. It adds no new save keys and does not change the original restoration or care reward values.

## What the player can see and do

- Each of the 12 restored places exposes a nearby renewable condition tied to its character: bent reeds, clouded riverglass, settled silt or a tangled willow habitat. The separate valley preview inherits the Ford sites.
- Partial Mend progress persists and now changes each patch's form through **strained → responding → nearly tended**. The world label shows the saved percentage. Finishing care returns the appropriate reed fiber, riverglass or silt clay as a distinct pickup form, plus the existing one scrip and three character XP. The original place stays restored and the patch returns after 120 seconds of active play.
- Restored willow habitats gain small, non-combat reed skippers. They wander and hop more actively near Mend. River moths continue to respond at other restored places. Wildlife is decorative world response and neither steals Mend targeting nor creates a loot farming loop.
- Mend favors an unfinished story restoration that can currently advance over a closer care patch. When the story site's present condition blocks Mend, the care patch remains usable; with no care in reach, the blocked site still explains which technique it needs.
- MAP marks ready care near restored sites with small green dots. JOURNAL has separate PLACES and CARE tabs. Care observations show condition, partial progress, active-play cooldown and the actual yield. A player can pin care or choose READY MEND without spending Flow or casting. Journal and map read the existing economy ledger; they do not create a second reward state.

## Continuity and limitations

The profile table in `scripts/world/care_profiles.gd` preserves the previous material mapping. The version-5 journey schema is unchanged. Old saves without an economy ledger still begin with empty care progress and all restored main sites intact. Named, location-specific presentation is authored at the 12 current sites; future regions need their own care profiles and a broader wildlife ecology. This pass does not turn the small exchanges into cities or claim phone performance validation.

## Verification

`tests/unit/test_living_care.gd` covers the material mapping, staged visuals, partial save/reload, single payout, original-site continuity, real Mend priority/fallback, habitat life and the touch Journal's READY action. `dev/review_living_care.gd` runs an in-memory native review at 800×360 and saves condition, map and Journal screenshots under `builds/playtest/living-care/`; it passed three route checks with Master audio muted. The care geometry and Journal layout were adjusted after inspecting these captures.

The full `bash dev/test.sh` suite passed **202 tests**. `dev/review_living_care_android.py` installed the main APK on the emulator, held the Mend medallion to finish a reed patch, confirmed saved material, scrip, cooldown, original restoration and care pin, then opened MAP → JOURNAL → CARE by touch. It restored the original emulator save byte for byte (SHA-256 `761f8639d88d059cfffefe5d835100632d1a9d2ecc51bb5faffa342b8bfd83ce`). Captures are in `builds/playtest/living-care/`. This is emulator evidence; physical midrange phone frame-time, temperature and touch-latency checks remain required.
