# RPG foundation — implementation status

Canonical direction: [RPG Systems & Restoration Progression Revision](rpg-systems-restoration-revision.md), user-adopted 2026-09-27.

## Delivered — Phase A

Stability/Flow are playable in both chapters. Adoption baseline was 143 tests;
Phase A full suite: **150 passed, 0 failed**; Phase B: **157 passed**.
Phase C: **161 passed**. The opening presentation candidate has
**172 passing tests**. Preserve the two regions, 12 sites,
Force/Anchor/mastery, visible gear, story, touch controls and human character work.

- Main RPG displays numeric Stability/Flow bars in a dark ceramic/bronze frame.
  Hearts remain only in legacy combat/feel fixtures for compatibility.
- Maximum Stability and Flow start at 100. Hazard contact removes 15 Stability;
  overload removes 20. One second of protection prevents overlap draining it.
- At zero, **Unmoored** interrupts touch actions, shows gentle recovery guidance,
  and returns to the current safe marker after 0.8 seconds of active play. World
  restoration, partial healing, ecological conditions, gear, XP and story remain.
  Recovery restores Stability, guarantees at least 50 Flow and protects for 2 seconds.
- Mend costs 8 Flow/second of useful healing, including affordable partial healing.
  Force costs 12 per useful cast; Anchor costs 14. Glide stays free. Empty casts,
  already-resolved sites and blocked Mend at its viability cap cost nothing.
  The Skills screen explains the costs. Low Flow refusal explains recovery.
- Flow regenerates at 8/second, or 4 during useful ability spending. A restored
  spring within 5 tiles adds 6/second. No standing-still requirement.
- Weight reduces Stability loss by up to 25% and Flow recovery by up to 25%.
  Charge increases Flow recovery by up to 50%. Existing movement/overload rules
  are retained. Controlled Overcurrent remains future work.
- Stability recovers at 1/second after 4 seconds without loss, or 3 near restored
  springs. First-time completion refunds 12 Flow and restores 10 Stability.
  Loading/travel replay does not give duplicate completion rewards.
- Resources, protection and recovery/spending timing persist in **save schema 4**.
  Schemas 1–3 migrate with full initial resources and all earned progress retained.
  Reloading does not regenerate offline. Corrupt resource values are sanitized.
  Version 4 resumes the last region through the opening launcher.
- Resource time follows active physics play; dialogue, Gear and Skills pause it.
- Android export excludes local build/playtest artifacts.

These are initial forgiving values, not final balance. The opening benchmark must
measure whether resources improve decisions and communicate hazards clearly.
No new persistent resource bar was added for Weight or Charge.

## Technical map

- `scripts/rpg/waykeeper_resources.gd`: resource spending, regeneration, protection,
  Unmoored, rewards, bounded save serialization; independent of region/UI.
- `scripts/hero/hero.gd`: active-play tick, restored-water proximity, environmental
  conditions/loss, interruption and existing movement/animation compatibility.
- `scripts/skills/waykeeper_definitions.gd`: data-driven technique Flow costs.
- `scripts/hero/verbs/mend.gd`: spending proportional to actual eligible healing.
- `scripts/skills/waykeeper_journey.gd`: validated useful casts and completion refunds.
- `scripts/ui/hud.gd`: numeric bars; `skills_screen.gd`: readable cost descriptions.
- `scripts/levels/region_scene.gd`: save migration and checkpoint recovery without
  rolling back the world. `scripts/story/journey_start.gd`: region resume.
- `tests/unit/test_waykeeper_resources.gd`: seven resource/integration tests.
- `dev/review_waykeeper_journey.gd`: repeatable native touch-input route using an
  isolated save, intermediate reload, gear, both chapters, return and Unmoored.

## Verification

Full regression: `bash dev/test.sh` — **150 passed, 0 failed**.
Final resource tests after the NPC/recovery visibility adjustment: **7 passed**.
Native 1280×720 walkthrough: **zero failures**, all 12 places restored using actual
screen-touch input for teaching, action medallion, loadout, gear and travel. Position
setup uses fixture teleports; the broad crossing was traversed with the touch stick.
Intermediate ecological save reload, cross-region XP/gear/mastery continuity and
Unmoored preservation passed. HUD, useful healing, Skills costs and recovery were
visually inspected. Captures: `builds/playtest/rpg-foundation/`.

The production save was backed up and reopened in the updated build. Earned XP,
inventory/equipped gear, mastery/upgrades/loadout, story flags, active region and
restored/partial/ecological world state were compared against the backup and
remained unchanged; schema/resources migrated.

Android debug APK rebuilt (about 29 MB), aligned and signature verified. No Android device was
connected. Physical-phone playtesting, touch latency, sustained FPS, thermal/battery
and memory measurements remain outstanding. Desktop route evidence is not the
mobile performance benchmark.

## Delivered — Phase B

The [connected tree foundation](skill-tree-foundation.md) now provides 13 chosen
nodes, two Skill Points per level, parent/mastery eligibility, touch panning and
purchasing, a Mend/Anchor hybrid, gear-supplied Undertow and schema 5 migration.
The six old upgrades are real tree nodes; existing learned choices migrate without
consuming the new point budget. Phase A verification above records its earlier
150-test milestone. See the tree guide for current verification.

Phase C is delivered: [journey rebalance](journey-rebalance.md), including nursery
Force, bell Anchor, local lessons, retained partial/completed saves and optional
garden irrigation with NPC/Flow consequences.

Phase D has a playable presentation candidate; real-player pacing and physical-phone
validation remain open. Phase E has begun with meaningful gear, two authored Weave
connections, [Channel's first carried-current route](channel-first-route.md),
and [Bloom's first living route](bloom-first-route.md). A wider Weave network,
deeper Channel and wider Bloom remain planned.
Do not prioritize a full third region before the benchmark is convincing.

## Phase D — presentation candidate

[Opening benchmark](opening-quality-benchmark.md) now has human inhabitants and
portraits, an authored living grove, staged recovery, opening craft/audio, optional
first reward choice and Mara's inhabited return. Preserve these alongside A/B/C.
Actual player pacing and midrange-phone validation remain open; do not report D
complete or prioritize a full third region before those gates pass.
