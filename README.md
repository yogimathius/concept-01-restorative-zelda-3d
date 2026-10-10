# Current development focus: perspective river valley

The perspective river valley is the active spatial-design direction. Launch it
with `Godot --path . --resolution 1280x720 -s dev/play_river_valley.gd`.
Its trails now curve through bends and blend into the terrain and each other at
junctions. The normal launcher still opens the established two-chapter journey;
the valley keeps its separate save while its presentation and routes are refined.
See [the valley direction and outcome ledger](docs/open-world-direction.md).

# Market test preparation

The main two-chapter journey has an isolated Android playtest preset. It builds
`builds/android/broken-waterway-market-test-debug.apk` under a separate package,
so installing it does not replace the owner's main journey. Run
`dev/verify_market_test.sh` after export. The [playtest plan and release ledger](docs/market-test-prep.md)
cover uncoached sessions, real-phone measurements and remaining store work.
The launcher and Godot editor can be run headlessly; the prototype Master bus
remains muted.

# River valley prototype

The opt-in valley now connects its perspective opening to an inhabited watershed: elevated trails, dispersed restoration sites, a playable upper weir and Oren's downstream landing. Audio is muted for prototyping. See [requirements, outcome ledger and launch instructions](docs/open-world-direction.md). It uses a separate save and Android package. Existing two-chapter gameplay remains available through the normal launcher.

# The Broken Waterway — two playable chapters

## Waykeeper progression — playable Force and Anchor slice

Mend begins the journey. Iona teaches Force after the first grove, then Anchor
after the stonebound spring flows. Skills have their own mastery, behaviour-changing
upgrades and a touch loadout. Some places accept partial healing until physical
conditions are resolved; gear can create alternative approaches.

Agents: read [AGENTS.md](AGENTS.md), the full
[canonical RPG systems revision](docs/rpg-systems-restoration-revision.md)
and [phase status](docs/rpg-foundation.md) and the
[implementation guide](docs/waykeeper-slice.md). Weave Link has two authored
Reedglass connections, Channel has its first carried-current route, and Bloom
has two linked living outcomes. A broader Weave network, deeper Channel, wider
Bloom and later specialization branches remain
future work. Distinctive art is still tracked
in the [roadmap](docs/roadmap.md).

## RPG resources — Phase A delivered

Stability and Flow now appear in both chapters. Useful Mend costs 8 Flow/second;
Force costs 12 and Anchor 14 per useful cast. Glide is free. Flow naturally
returns, faster beside restored springs. Unmoored recovery returns to the safe
marker and keeps restoration and rewards. Version 5 saves migrate earlier progress.
The connected Skill Point tree is now playable: 16 nodes, two points per level,
mastery prerequisites, touch panning/purchasing and a Mend/Anchor hybrid. Existing
learned upgrades migrate safely. See [tree implementation](docs/skill-tree-foundation.md).

Verification: **203 automated tests passed**, native touch route completed all
12 sites and both chapters; Android package rebuilt. Real-phone performance is
still unverified. See [implementation status](docs/rpg-foundation.md).

## Existing journey — Phase C delivered

Reedglass keeps the garden approachable with Mend, then uses Force to reopen the
nursery feed and Anchor to steady the bell. Missing techniques can be learned
locally from Neri and Oren. Partial work stays. Anchor can improve the restored
garden's irrigation; Neri returns to tending it and its water renews Flow.
Completed saves keep their completed sites. See [journey details](docs/journey-rebalance.md).

Weave now reconnects Neri's garden to the nursery and, separately, Daro's spring
to the willow refuge. The second route grows a mint bed, moves Daro's work,
creates a journal request and adds seeds to later spring care. Both links use the
same forgiving touch drag and persist. Chosen Living Echo can carry partial care
between connected sites. See [living route details](docs/weave-living-route.md).

Bryn now teaches Channel after the bell and lantern beds recover. One touch tap
carries Charge from the bell; later taps can light the living beds and Sela's
exchange lamp. These permanent changes create a journal request, mastery, XP,
river scrip, materials and new NPC behavior. See [Channel's first route](docs/channel-first-route.md).

Neri now teaches Bloom after garden water is restored and linked. It grows a
renewable seed bed and a willow shelter; the chosen Living Network tree node
shares that shelter with the linked spring. Both growths, Neri's return request
and NPC responses persist. See [Bloom's first route](docs/bloom-first-route.md).

The marsh bell now reveals Lio's sealed letter in the world. Neri can prepare
a reply about the changed garden and ask what he saw at the reservoir; Oren
prepares to carry it upstream. Their routines, the letter props, Journal request and a
one-time reward persist. See [Reedglass correspondence](docs/marsh-correspondence.md).

Restored places now offer visible reed, silt, glass and willow-habitat care that
changes form as Mend progresses. The Care journal and map show partial work,
cooldowns and yields, while Mend favors unfinished story restoration. A small
reed skipper inhabits restored willow shelter. See [living care world pass](docs/living-care-world.md).

## Opening quality — Phase D candidate

Mara and the other inhabitants now have articulated human models and lit dialogue
portraits. The opening gains a ceramic pavilion, living-water grove, staged
restoration, original adaptive soundscape and a first gear/skill choice. Restoring
the spring fills the village basin; Mara returns to it and recognizes the change.
See [benchmark route and remaining phone/pacing gates](docs/opening-quality-benchmark.md).

For a fresh opening playtest with a separate save:

```sh
/Users/mathiusjohnson/Downloads/Godot.app/Contents/MacOS/Godot --path . -s dev/play_opening_benchmark.gd
```

## Current playable build

The journey starts through `scenes/story/journey_start.tscn`, resuming the last
visited region. Broken Ford and Reedglass Marsh are playable. The older pipeline
notes below describe the prototype's origin.

- Five connected areas with continuous camera follow, contextual objectives,
  and a live map of gates, bridges, local restoration, and your last anchor.
- The opening keeps six stationary groves and springs. The first grove teaches
  simple Mend; Force moves obstructing stone and Anchor steadies roots. Approach
  within about four tiles to Mend or five to use a technique. No precise facing,
  creature positioning, stagger windows or timing challenges are required.
- Progress is retained when you let go. A live meter shows healing and a
  100% confirmation; the healthy object visibly replaces its corrupted form.
- Healing spreads across each area, restores its vegetation and clears pools.
  Groves automatically rebuild crossings; springs directly open the passages.
  The first bridge is three tiles wide, with real floor and cleared fall volumes.
- Nothing pursues, attacks or fires projectiles. Pools are safe; stepping off
  an unhealed crossing returns you to safety without losing hearts.
- Each newly healed place earns 40 restoration XP. The first place unlocks
  Level 2; all six bring you to Level 4. Waykeeper level records overall journey experience. Mend mastery improves
  its own reach/speed; using Force or Anchor meaningfully grows those disciplines. The HUD shows your level and progress toward the next.
- Restoration loot visibly rises from its place and travels into your bag.
  Broken Ford grants six gear pieces; Reedglass adds three regional pieces and
  a unique NPC quest brooch. Iona grants two behavioural pieces: a staff that
  lets Force steady springs, and a brooch whose Anchor roots lift stone. Three
  starter pieces bring the catalogue to 15.
  Tap GEAR to turn the character preview and equip; the worn mesh and its bonus
  replace the old piece, which remains in your inventory. Cards have touch pages.
- Mara frames the first chapter; Iona passes on the Warden traditions. Oren connects the ford and marsh through an
  explicit conversation choice. In Reedglass, Neri's missing-brother story ties
  together a kitchen garden, reed nursery and sluice bell. Work done before
  accepting a quest counts. Daro offers an optional spring quest and brewing.
  Six new places sit in four connected courts; all routes are broad walking paths.
  The three main story sites teach gentle Mend; optional willow, spring and
  lantern restorations use the new techniques.
- Bloom Tea gives +1.5 Mend reach for 30 active-play seconds. Reed Cordial gives
  +20% walking speed for 30 seconds. Cups drop with restoration supplies, appear
  in PACK, and cannot stack with themselves. Daro brews tea for three seeds or
  cordial for two river crystals. Counts, spending and remaining effects save.
- Levels, inventory, outfits, both region worlds, NPC/story flags, rebuilt crossings
  skill unlocks/mastery/upgrades/loadout, solved ecological conditions,
  and unfinished healing autosave
  to `user://restoration-journey.json`. A place earns XP only once across sessions.
- Both heroes now use layered river-order armour/robes, contoured faces,
  sculpted hair/hoods, taller proportions, baked surface shading, tailored cloth
  and crafted metal fittings. All 15 gear
  pieces have distinct authored shapes: lantern/crescent/reed staffs, embroidered
  mantles with woven borders, cut stones and ornate brooches. The live wardrobe shows the same rigged models.
  The latest foundation uses an adapted CC0 MakeHuman anatomy mesh and a 43-bone
  rig, with adult proportions, articulated fingers/wrists/feet and baked foot placement.
  [Art direction, sources and mobile budgets](docs/hero-art-direction.md).
- Rebuilt organic terrain, stepped stone paths, animated river, planted
  landing, brighter restoration contrast, corrected toon lighting, and a
  quieter HUD, plus distinct travelling mantles on both hero models. Touch uses
  a permanent left stick and illustrated Mend and Glide buttons on the right.

**Touch controls:** drag the left stick to move. The large right medallion uses
your equipped technique: hold Mend, or tap Force/Anchor. Swipe upward on it to
cycle learned techniques; tapping SKILLS also selects a loadout and learns earned
mastery upgrades. Swiping never casts Force or Anchor. The feather medallion is
Glide. The third right action becomes TALK beside an NPC and PACK elsewhere.
Map, Gear, Skills and conversations pause the world and release held controls.
Desktop previews use the same touch flow, with the mouse emulating a finger.

**Ford journey:** meet Mara, follow the path east and Mend the first grove.
Cross its broad bridge and speak to Iona. Learn Force and clear the stones at the
spring to the east, then Mend it. Return to Iona to learn Anchor, or explore the
southern gardens first: unfinished restoration is retained and marked on the map.
Ground leaning roots before completing their Mend. The fractured eastern spillway
needs clearing and stability, then Mend; the restored regional waterway opens the
way to Oren. His touch conversation travels into Reedglass Marsh.

**Marsh journey:** talk to Neri; Mend her kitchen garden, the northern nursery and
the southeast bell. Speak to Oren and return Lio's letter to Neri. Use Anchor at
the optional willow refuge, Force at Daro's stonebound spring, and both traditions
at the lantern beds, or use behavioural gear/upgrades for an alternative solution.
Daro still rewards his restored spring and brews consumables. Counterweight Orchard
remains the next story hook and is not yet playable.

**Existing saves:** versions 1 and 2 migrate to version 3. Completed places remain
healthy, with XP, outfits, supplies, quest state and both regions retained. Previously
completed Ford work credits appropriate technique knowledge and mastery. Meet Iona
to collect her gear; the optional marsh sites offer places to apply those techniques
if your Ford is already complete. No production save is reset for testing.

**Run:** `/Users/mathiusjohnson/Downloads/Godot.app/Contents/MacOS/Godot --path .`
**Tests:** `bash dev/test.sh`. Gameplay integration lives in
`tests/unit/test_restoration_journey.gd` verifies the gentle opening: retained
healing, healthy forms, learned-technique recovery of all six restorations, passage opening, the broad bridge
and real multi-touch input. Earlier mechanics remain available with
`RegionBuilder.restoration_only = false` for their existing regression tests.
`tests/unit/test_restoration_progression.gd` verifies rewards, duplicate
protection, ability upgrades, and save/reload of complete and partial healing.
`tests/unit/test_restoration_gear.gd` verifies actual Mend discoveries, touch
equipping, replaced bone-bound meshes, stat changes, save migration and duplicate
loot protection. Existing saves receive the gear earned from their healed places.
`tests/unit/test_story_chapters.gd` covers real NPC touch conversations, restoration
before quest acceptance, chapter completion, consumable use/expiry, brewing and
multi-region persistence. `tests/unit/test_waykeeper_skills.gd` covers real touch lessons, switching,
mastery, behavioural nodes/gear, partial requirements and save migration.
Versions 1/2 migrate to version 3; both worlds and the current region save together. The legacy battle mode remains a test-only
option; current playable chapters focus on restoration and exploration.

Follow-ups and art identity requirements: `docs/roadmap.md`.
Playable story and content rules: `docs/story-chapters.md`.

---

# concept-01: restorative Zelda-like (Godot 3D build)

A third take on the same question as the 2D concepts ("does 'heal a
corrupted room' feel good as a real-time verb?"), this time testing
whether a **custom Blender art pipeline** feeding **live 3D rendering
in Godot** can produce a more distinctive look than reusing CC0 tile
packs — the direction chosen after a throwaway Blender style-spike
(bold Freestyle outlines, hard-edged toon shading, dramatic lighting)
read as more exciting than the flat Kenney-tile look used elsewhere in
this repo.

Spec: `docs/superpowers/specs/2026-09-20-concept-01-3d-art-pipeline-design.md`
Plan: `docs/superpowers/plans/2026-09-20-concept-01-3d-art-pipeline.md`

## Historical state: step 1 feel lab (2026-09-26)

The HP/sword prototype described below has been replaced by the
transformation-combat core
(spec: `../../docs/superpowers/specs/2026-09-26-concept-01-systems-design.md`,
plan: `../../docs/superpowers/plans/2026-09-26-concept-01-step1-core-feel.md`).
Main scene is `scenes/test/feel_lab.tscn`: the Warden, three training dummies,
a Weight pad (stone), a Charge pad (cyan), and a hazard (purple).

- Keyboard: WASD move, Space/J pulse, Shift dash, F1 swap Warden/Weaver, F3 state readout.
- Touch: joystick, big orange button = pulse, small blue = dash.
- Tests: `dev/test.sh` (headless, all systems).

The question this build answers: **does the Pulse feel good?** (the Warden's Force verb: an emitted
ring of restorative energy that knocks corruption back; Charger shots are
"sparks")

## What this actually is (original 3D pipeline build, historical)

A from-scratch Godot 3D project (not a fork of `../concept-01-restorative-zelda/`,
whose 2D template and proven mobile pipeline stay untouched):

- One rigged, animated hero character (idle / 4-direction walk / attack),
  modeled and rigged entirely in Blender via a live `blender` MCP
  connection, exported to glTF with all three animations embedded.
- A 5x5 corrupted-tile room (dark, jagged purple shard props) that
  swaps to a 5x5 restored-tile room (saturated green) when the player
  walks up to a heal pedestal and presses interact — the actual core
  loop, verified working both in a scripted headless playtest and live
  on a real Android emulator.
- A custom real-time toon shader: an inverted-hull outline pass plus a
  hard-banded diffuse ramp, built as a Godot `ShaderMaterial` — the
  Blender spike's outline look came from Freestyle, an offline-render
  feature with no runtime equivalent, so this had to be reimplemented
  as an actual shader, not just reused.
- Touch controls ported from the 2D build's proven virtual-joystick
  addon + `TouchScreenButton`s.
- A working `dev/deploy.sh` (export, boot emulator if needed, install,
  launch) mirroring the 2D build's script shape.

## Real bugs hit and fixed while standing this up

1. **Vulkan Forward Mobile renderer couldn't present frames on this
   emulator** — `ERROR: Couldn't present to Vulkan queue (VkResult
   error 5)`, reproducible under both software (SwiftShader) and real
   hardware-GPU-backed Vulkan. Root cause: the 2D build's project
   settings use `gl_compatibility` (GLES3), not the 3D project's
   default `mobile` (Vulkan) — switching this project to
   `gl_compatibility` fixed it immediately. Godot's Compatibility
   renderer supports 3D scenes fine at this fidelity.
2. **Stale emulator crashpad consent dialog blocked/confused boot** —
   an old queued crash report from unrelated (Unity) testing on this
   machine caused a consent-dialog code path to fire on every launch.
   Clearing `~/.android/cli/analytics/crash_reports` and the emulator's
   crash db resolved it.
3. **5x5 corrupted-tile grid invisible** — three compounding bugs, not
   one: (a) the `Ground` box's top surface sat 0.1 units above the
   tiles, fully burying them inside opaque geometry; (b) after fixing
   that, tiles became exactly coplanar with the ground, causing
   z-fighting; (c) after nudging tiles above the ground, they were
   *still* invisible because every object in the scene — ground, hero,
   tiles, props — shared one literal `ShaderMaterial` resource with a
   hardcoded gray `base_color`, so anything successfully toon-shaded
   became visually identical to the ground. Fixed by having
   `ToonUtil.apply_toon()` duplicate the material per-surface and carry
   over each object's own original albedo color.
4. **A tile grid positioned at world x=-15 instead of x=-5..-1** — every
   Blender-exported environment asset (`corrupted_tile`,
   `restored_tile`, `heal_prop`, `dead_tree`, `live_tree`, `enemy`) had
   been authored at a distinct, deliberately-offset world position in
   the shared Blender scene (to keep them visually separated during
   the session) and never recentered to local origin before export —
   so each glTF carried that offset baked in, compounding with the
   in-Godot grid-placement math. Fixed by recentering each object group
   to origin in Blender and re-exporting.
5. **Touch buttons landing in the wrong screen position** — the project
   had no `window/size`/stretch settings at all, so raw pixel
   coordinates copied from the 2D build's `640x360` canvas landed
   somewhere else entirely on this project's default resolution.
   Fixed by matching the 2D build's `window/size` + `canvas_items`
   stretch config exactly.
6. **`Cannot infer the type of variable` GDScript parse errors** — `:=`
   type inference failed on `get_active_material()`'s return in this
   Godot version; needed explicit `: Material` annotations.

## Verified, not claimed

- Scripted headless playtest (simulated input, no display): confirmed
  movement, walk/idle/attack animation switching, and the
  corrupted→restored tile swap firing through the real `Area3D`
  interaction path (25→0 / 0→25 tile counts).
- Real Android emulator (`godot_lab_phone` AVD): signed debug APK
  built, installed, launched, and controlled via actual injected touch
  events (`adb shell input swipe`/`tap`) — not just visually inspected.
  Before/after screenshots confirm the joystick moves the player, and
  a real interact-button tap triggers the room's corrupted-to-restored
  transformation live on-device.

## What's not yet evaluated

Same as every other concept in this repo: whether the core loop is
actually *fun* is still an open question. This build proves the
pipeline (Blender → Godot 3D → Android) and the toon art direction
work end-to-end; a real playtest is the next step, not more building.
