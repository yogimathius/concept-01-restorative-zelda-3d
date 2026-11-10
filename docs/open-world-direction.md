# River valley / open-world direction

User adopted: 2026-09-27. Current implementation milestone: **V2a — inhabited watershed slice**, building on the verified V1 valley opening.

## Intended outcome

The Broken Waterway should feel like an inhabited watershed that a Waykeeper can explore in three dimensions. Players see distant places, choose broad routes, climb forgiving terrain, understand upstream/downstream relationships, restore systems, and return to communities changed by their work.

This updates spatial design while preserving the canonical [RPG revision](rpg-systems-restoration-revision.md). Continue improving the opening before building another full region. The existing two-chapter game remains the main journey while the valley is evaluated separately.

## Requirements / acceptance ledger

| ID | Requirement | V1 implementation / acceptance |
| --- | --- | --- |
| V01 | Perspective view, horizon and a distant hydraulic landmark | Separate valley scene, following perspective camera; upper weir and distant silhouettes. Verify actual overlook view. |
| V02 | Real elevation and broad alternate routes | Collidable terrain; low riverside approach and hill trail converge on the existing grove. Walk both through touch. |
| V03 | Touch-first navigation | Camera-relative left stick, drag clear world space to orbit, SpringArm collision. Existing three action medallions remain. Targets outside Mend reach explicitly ask the player to move closer. Camera finger must not own joystick, actions or menus. |
| V04 | Forgiving opening | No jumping requirement, timing gates or precise placement; broad hill slopes and wide restored bridge. |
| V05 | Restore the existing opening loop | Mara → grove → restoration/reward/Skill Points → Iona/Force → spring → changed home space. Preserve meaningful technique conditions. |
| V06 | Keep existing progression and saves | Distinct desktop save and Android package. Elevation-aware position reload. Existing main two-region saves must remain intact. |
| V07 | Navigation represents the real terrain | Valley map shows bounds, trails, overlook, landmark and actual targets. Journal pin arrow rotates with the view. |
| V08 | Understandable travel boundaries | This prototype stops at its watershed boundary; it must not send its save into legacy Reedglass geometry. The upper ford weir is a playable restoration in V2a; travel to legacy Marsh remains bounded. |
| V09 | Mobile remains first-class | Compatibility rendering, bounded terrain chunks, batched vegetation, restrained effects. Emulator verifies input/runtime only; S24/midrange device performance remains unverified. |
| V10 | World expansion serves restoration and inhabitants | Future routes must support discoveries, NPC needs, techniques and visible water relationships, not empty land or combat grinding. |

## Current V2a slice

- Original grove and Force spring retain their opening positions. Later stable IDs now occupy authored places: southern willow refuge (B2), landing reed spring (C2), upper hillside sunleaf grove (B3), and upper ford weir (C3).
- Oren inhabits a ceramic/bronze boathouse with an indigo canopy. His story offers a player-chosen journal pin for the weir; optional sites stay unmarked until encountered.
- Force clears the weir intake; Anchor steadies its foundation; Mend completes recovery. Partial recovery persists. Existing gear alternatives and behavioural nodes continue to use the same requirements.
- Water visibly advances down a ceramic channel to the landing. The basin and planted pots recover, the boat shifts from its cradle, and Oren walks to his waterside workplace. Reload derives these consequences from C3 restoration.
- River stone/reeds, layered tree crowns, softer soil detail and ridged distant silhouettes replace part of the initial placeholder art. Opaque vegetation and shared geometry are batched. This is an art pass, not finished production terrain.
- Spatial guidance refers to real destinations and distance. The weir is the ford's branch intake; it does not retcon Lio's later deliberate reservoir-sluice closure.

## Valley route cohesion pass

Curved, terrain-following wear replaces separate raised trail ribbons. Shared
path coverage blends at the opening fork, ford approach and watershed junctions,
then widens into the upper weir and Oren's landing. The downstream ceramic
channel curves continuously through its bends. Silt-coloured bank shoulders,
bank skirts that meet the terrain, and sparse low route-edge planting tie the
routes to their surroundings while leaving the walking corridor open.

The route coordinates, collisions and saved positions stay the same. Perspective
review stills for Mara, the overlook, first crossing, weir and landing live under
`builds/playtest/trail-polish/`. This is a cohesion pass on prototype art; user
acceptance, phone-size review and wider terrain/architecture finish remain open.

## What V1 contains

- Approximate terrain bounds: 112 × 92 world units (previous courts approximately 48 × 24). This measures navigable prototype terrain, not finished content density.
- Original opening NPC/restoration positions remain for continuity. Existing six Ford targets retain their learned-technique requirements and rewards.
- A roughly 6.5-unit overlook and roughly 10-unit upper-weir hill, with broad ramps.
- Real river gap and a wide physical bridge restored by the first grove.
- Perspective orbit camera with spring-arm collision, elevated focus, camera-relative touch steering, and restoration framing.
- Separate preview launcher and Android export preset/package.
- Reusable terrain height/walkability queries for saves and map. The chunk layout is a foundation; **runtime streaming is not implemented**.

## Outcome and verification log

**V1 implemented and verified as a playable prototype; user acceptance and physical-phone performance are pending.**

2026-09-27 outcomes:

- V01–V04: perspective, real collidable hills, two broad opening routes, visible upper-weir landmark, touch orbit/relative steering, camera collision and Glide on slopes are implemented. Native touch climbs the overlook and returns to the grove. Automated collision test verifies the arm retracts against a solid wall and extends afterward.
- V05: complete native touch opening succeeds: Mara, first Mend/reforming water, 40 XP and two points, chosen node, visible wand equip, Iona/Force, spring, changed gathering space, Mara's return dialogue, JSON reload. Unique XP, purchased node, equipment and settled restoration persist. Zero native touch failures.
- V06: full-suite legacy restoration/save coverage remains passing; hill reload, partial healing and journal pin have dedicated tests. A separate targeted test rejects consumption of a pending main-journey session. Desktop production JSON matches the preserved pre-preview backup exactly.
- V07–V08: touch valley map opens/closes; height shading, actual recovery colors, paths, destination labels, live target/NPC dots and restored river crossing are represented. Compass projects a remembered direction relative to the rotating camera. Chapter travel is bounded explicitly.
- V09: signed/aligned Android prototype exported and installed alongside the main app. Emulator startup, camera drag, Mara dialogue, movement and first Mend succeed; private save confirms B1 restored and 40 XP. Final APK update retained B1 restoration and 40 XP. No Godot script error or AndroidRuntime crash in the captured runtime. First-launch emulator GL shader-cache warnings remain; loading/physical-device frame, heat and battery budgets are not certified.
- Audio: Master mute confirmed by automated and native checks. Silent prototype exports retain audio assets.

Evidence:

- `builds/playtest/river-valley/evidence/full-suite.log`: **178 passed, 0 failed** (the six initial valley tests plus the previous 172). The later session-isolation regression and Mend reach-feedback checks are included in the final **7 passed, 0 failed** targeted valley run: `valley-suite.log`. Do not claim 179 tests were run in the full-suite invocation.
- `builds/playtest/river-valley/evidence/native-touch.log`: latest whole opening route and valley-map touch run; **0 failures**, 1,963 desktop frame samples, median 21.2 ms / p95 28.6 ms. This concurrent desktop/emulator sample is not phone performance evidence.
- `builds/playtest/river-valley/evidence/android-export.log`, signed APK, and `emulator/runtime.log`.
- Native screenshots: `arrival.png`, `overlook.png`, `connection.png`, `water-finds-path.png`, `first-reward.png`, `first-skill-choice.png`, `first-equipment.png`, `spring-restored.png`, `return.png`, `valley-map.png`.
- Emulator screenshots live under `builds/playtest/river-valley/emulator/`.

A native walkthrough initially caught reversed terrain winding; it was repaired and covered by actual standing/climbing collision checks. Existing headless shutdown warnings remain baseline diagnostics, not native script failures.

**V1 historical limits (addressed partly by V2a):** sites were clustered and the upper weir was scenery. V2a distributes later sites and makes that weir playable. Production art, streaming, connected Marsh geography, new techniques, camera/pacing acceptance and physical-phone certification remain pending.

## V2a outcomes and verification

2026-09-27: **V2a implemented as a playable inhabited watershed prototype.** V2a does not imply all V2 milestones are complete.

- Four later restoration IDs now occupy actual trail destinations. The upper ford weir accepts retained partial Mend, then requires Force/Anchor conditions before completion. Existing gear alternatives and skills remain compatible.
- Its channel advances toward Oren’s landing; restored water, planted basin, boat position, Oren’s walking routine and dialogue survive reload. Oren’s chosen clue pins the weir without awarding repeatable XP or loot.
- Full regression suite: **184 passed, 0 failed** (172 existing, 7 V1 valley, 5 watershed tests). Coverage includes V1 partial/completed saves retaining stable IDs and rewards in the new geography, plus NPC terrain following.
- Full fresh native touch route completes the opening and all six places, including chosen node/visible gear, Force/Anchor learning, retained weir progress, Oren’s clue, downstream consequences, 240 unique XP and completed-world reload. Final full-route rerun: **0 touch failures and no script/material errors**. Its 17,576 desktop frame samples (median 6.94 ms, p95 7.15 ms) are presentation diagnostics, not phone certification. Log: `evidence/native-touch.log`.
- Visual review removed coarse checkerboard soil and cone mountains, shortened the landing sign, opened its meeting area beside the canopy, and added canopy collision. A rendered portrait lifecycle/reload check is clean. NPC world and portrait instances now share immutable cached palettes, with outline-free templates created before binding materials. The final full-route render check is also clean. Story regression after the material-sharing change: **8 passed, 0 failed** (`evidence/story-suite.log`).
- Final Android APK signature and alignment verify, and installation over the V1 package succeeds. Final cold launch, touch orbit/movement and expanded map were observed; B1 and 40 XP remain saved. Captured runtime has no script error, null-material error or AndroidRuntime crash. Desktop production JSON still matches the preserved backup exactly. Master audio remains muted.
- Evidence folder: `builds/playtest/valley-watershed/`; automated logs under `evidence/`, emulator captures/runtime under `emulator/`. The final stills are `arrival-final.png`, `overlook-final.png`, `weir-final.png` and `landing-final.png`.

Headless baseline material diagnostics and exit ObjectDB leak warnings remain; these are not native interaction failures.

**Remaining acceptance:** user pacing/camera/art feedback, production vegetation/architecture, connected Marsh geography, runtime streaming if measured cost requires it, and physical S24/midrange-phone performance. The emulator confirms runtime/input/save continuity only.

## Prototype audio

User requested silent prototyping during a call on 2026-09-27. The project Master bus is muted in `default_bus_layout.tres`; keep previews and exports silent until the user requests sound again. Audio assets/events are preserved.

## Play / resume

Desktop, from the project root:

```sh
/Users/mathiusjohnson/Downloads/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x720 -s dev/play_river_valley.gd
```

Move with the left stick. Drag the clear middle portion of the world to look around. Follow the low path to the grove or the pale trail north to the overlook; both return to the same opening restoration. MAP shows terrain and trails; JOURNAL remembers restoration requirements.

- Scene: `scenes/levels/river_valley.tscn`.
- Desktop persistence: `user://river-valley-preview.json`.
- Android preset: `Android Valley Prototype`.
- APK: `builds/android/broken-waterway-valley-debug.apk`.
- Android package: `dev.gamelab.waterwayvalley` (separate from the main game).
- V1 touch opening: `dev/review_river_valley.gd`. V2 full watershed touch route: `dev/review_valley_watershed.gd`; screenshots `builds/playtest/valley-watershed/`.
- Tests: `tests/unit/test_river_valley.gd`, `tests/unit/test_valley_watershed.gd`; full suite `bash dev/test.sh`.

## Next milestones — ordered, not implemented

### V1 acceptance / interaction polish

1. User playtest: hill route, camera comfort, sense of scale, target selection, returning to Mara. Record feedback by requirement ID above.
2. Tune drag sensitivity, default view, camera distance/collision and readable touch guidance. Consider gentle optional camera recentering and a larger safe gesture area after evaluating phone ergonomics.
3. Extend native coverage to camera collision against tall terrain/architecture, simultaneous sustained movement+orbit+Mend, Glide on slopes, river recovery, both route directions and a completed legacy save.
4. Measure physical S24 and a representative midrange phone: stable 30 FPS, memory, heat, battery, touch latency, restoration cost. Emulator numbers do not satisfy this gate.

### V2 — inhabited watershed slice (V2a delivered foundation; continue authoring)

5. V2a adds bank stone/reeds, layered crowns, soil detail and ridged horizon. Continue authoring bank bends, cliff transitions, foreground vegetation, lighting and destination silhouettes. Audio remains muted during prototyping.
6. V2a distributes B2/C2/B3/C3 and Oren, with spatial guidance and stable IDs. Continue adding intentional route discoveries and distinct destination art.
7. V2a delivers a Force/Anchor/Mend upper ford weir and Oren's landing consequence. Deepen physical intake/foundation animation before introducing Weave.
8. V2a delivers visible channel/basin/life/boat/NPC changes downstream. Refine the overlook sightline and inhabited routines; add a second meaningful social consequence.
9. V2a hides unseen optional map markers; Oren's chosen story clue records the weir. Continue optional return discoveries without checklist clutter.

### V3 — connected regions / scaling

10. Design Ford → Marsh as adjoining watersheds, retaining region IDs and earned progress. Plan old-position migration only after authored geography stabilizes.
11. Add streaming, spatial activation, LOD/visibility budgets and loading checkpoints when measured scene cost requires them. No need to load the full eventual world.
12. Revisit map scale, saved positions, safe anchors and NPC schedules for connected travel. Save migration must be explicit and tested.
13. Add story-led Weave, then Channel and Bloom following the canonical phase order; gear builds and restoration consequences remain part of the same game.

## Implementation / research notes

Authored coordinates/profiles belong to `ValleyPlaces`; spatial story and derived routines to `ValleyJourney`; bank art and the downstream water presentation to `ValleyBanks`. IDs/XP/mastery/gear/save schema are retained.

The opt-in `valley_mode` hooks in RegionBuilder keep legacy grid tests and main scenes intact. New terrain belongs to `RiverValley`; perspective control belongs to `ValleyCamera`. Device movement is converted at input reading, preserving world-space simulation/test inputs. Avoid making region_scene the owner of terrain or camera logic.

Official references informing this approach: [Godot SpringArm3D](https://docs.godotengine.org/en/stable/tutorials/3d/spring_arm.html), [Godot 3D performance guidance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html). Larger land area alone does not create a satisfying open world; author traversal, meaningful destinations and ecological consequences before scaling farther.
