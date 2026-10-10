# Playable Waykeeper slice — 2026-09-26

## Implemented scope

Mend, learnable Force and learnable Anchor; separate skill mastery; six behavioural
nodes; two visible equipment modifiers; persistent partial ecological recovery;
compact touch loadout/switching; six Ford restorations and optional marsh practice.
Weave, Channel and Bloom are registered future traditions with explicit unavailable
UI. Their gameplay, full trees and Warden/Weaver specialization choices remain future
work. Gentle restoration, NPC story, consumables and both regions remain playable.

## Acquisition and feedback

New journeys start with Mend and Glide. Restore B1, cross the wide bridge and
speak to Iona at (30, 5.5) to learn Force. Clear C1 and Mend it; return to Iona for
Anchor. Encountering B2 first is supported: Mend reaches 55%, keeps that recovery,
and identifies unstable roots and where to learn the missing tradition. Anchor
stays applied without a timed window. Technique switching never loses partial work.

The right-side actions remain three: equipped technique, Glide, contextual TALK/PACK.
Hold Mend; tap Force/Anchor; swipe upward on the technique medallion to cycle learned
techniques. SKILLS pauses the world and provides selection and mastery upgrades.
Warm map dots show wounds; violet dots remember visited sites with unmet conditions.
Stone meshes move away when cleared; water wakes; unstable models sway until grounded;
visible violet braces/root supports mark Anchor. The final spillway brings the regional
river from partial recovery to full flow, opens travel and sends recovery waves.

## Authored site rules

| Place | Conditions before complete Mend | Partial Mend limit |
| --- | --- | --- |
| Ford B1 homecoming grove | None | 100% |
| Ford C1 stonebound spring | Clear stone | 45% |
| Ford B2 leaning willow refuge | Stabilize roots | 55% |
| Ford C2 silted reed spring | Clear stone | 45% |
| Ford B3 windworn sunleaf grove | Clear stone and stabilize | 55% |
| Ford C3 fractured spillway | Clear stone and stabilize | 40% |
| Marsh M1/M2/M3 story sites | None | 100% |
| Marsh M4 willow refuge | Stabilize | 55% |
| Marsh M5 Daro's spring | Clear stone | 45% |
| Marsh M6 lantern beds | Clear stone and stabilize | 50% |

Conditions can be resolved in either order, before or after partial Mend. Force
uses the existing Influence grammar, with generous targeting of nearby obstruction;
Anchor resolves lasting stability. No hostile attacks, precise alignment, timed
stagger windows or combat finales have been added.

## Mastery and builds

Each unique clearing or grounding earns 2 points for the technique used. Making
an obstructed/unstable site viable earns 1 Mend point; completing restoration earns
3. Event keys persist, so empty casts, repeated resolved targets and reloads cannot
farm mastery. Rank thresholds modestly affect the individual skill's reach/rate;
Waykeeper XP still rewards unique completed places and records overall experience.
It no longer raises every technique automatically.

| Discipline | Behavioural node | Required mastery |
| --- | --- | --- |
| Mend | Living Pulse: completion gives nearby wounded systems partial healing, respecting their limits | 3 |
| Mend | Resonance: wider wave with twice the healing | 9 |
| Force | Groundwave: clear all eligible nearby obstructions instead of just one | 2 |
| Force | Undertow: clearing also stabilizes that system | 6 |
| Anchor | Shared Ground: nearby unstable systems share grounding | 2 |
| Anchor | Root Memory: grounding also supplies partial Mend when conditions permit | 6 |

Nodes are earned capability choices activated in SKILLS; mastery points are retained,
not spent. Later branching specializations are still future work.

Iona grants **Ferryman's staff** when learning Force: the equipped staff adds stability
to its clearing pulse. **Stonekeeper brooch**, granted with Anchor, lets grounded roots
lift obstruction. Thus a build can solve the spillway with Force + Mend or Anchor +
Mend. Wearing the corresponding piece is required; unequipping removes its behaviour.
Both replace the old bone-bound mesh in the world and wardrobe. The catalogue has
15 pieces; earlier loot, equipment and brewing remain.

## Technical map

- `scripts/skills/waykeeper_definitions.gd`: ability catalogue, nodes and site profiles.
- `scripts/skills/waykeeper_progression.gd`: unlocks, active technique, mastery ledger,
  earned choices and JSON serialization.
- `scripts/skills/restoration_site.gd`: independent target conditions, partial limits,
  remembered discovery, physical state visuals and state serialization.
- `scripts/skills/waykeeper_journey.gd`: registered technique handlers, Influence-based
  execution, gear modifiers, meaningful rewards, narrative acquisition and migration.
- `scripts/ui/skills_screen.gd` and `scripts/ui/touch_controls.gd`: paused mastery/loadout
  screen and compact action input. SVG technique icons are authored in the project.
- `scripts/levels/region_scene.gd`: hosts the journey and stores its snapshots; future
  technique execution belongs to the registry/components rather than this script.

## Save continuity

Schema 3 adds `skills` at journey level and `ecology` within each region world.
Unlocks, active technique, mastery events and chosen nodes persist. Each site's
cleared/stabilized/seen/flourishing flags and partial Mend are retained independently.
Both worlds, character XP, equipped/owned items, resources, effects and narrative
flags remain part of the same atomic save. Version 1/2 migration credits competence
represented by completed Ford work; it does not reopen or revoke finished restoration.
Iona can give returning players the newly introduced equipment once, without changing
what they currently wear. Use private saves for testing; preserve production progress.

## Verification

Run `bash dev/test.sh`. `test_waykeeper_skills.gd` covers actual touch teaching,
medallion taps and swipes, paused loadouts, mastery persistence and duplicate protection,
partial discovery/return, multi-ability spillway recovery, actual behavioural gear,
capability nodes, legacy worlds and cross-region state. Existing opening progression
coverage now exercises clearing and grounding where required rather than assuming
Mend alone completes every site. Story tests still verify brewing and chapter payoff.

Native route inspection uses real screen touches at stretched viewport coordinates,
a private save, the actual bridge walk, both lessons, all Ford sites, an intermediate
restart, gear and skill choices, marsh restoration/story and the return conversation.
Android export is separate evidence; physical-phone gameplay verification remains
outstanding. Recorded evidence: 141 full regression tests passed, 8 final story checks passed,
and the native touch route finished with zero assertion failures across all 12
restorations. Android APK aligned, signed and verified; see the roadmap for status.
