# Existing journey rebalance — Phase C

Canonical specification: [RPG revision](rpg-systems-restoration-revision.md).
Phases A/B remain intact. Both playable chapters and all earned progress are preserved.

## Reedglass main story

| Place | World condition | Restoration | Retained partial progress |
| --- | --- | --- | --- |
| Neri's kitchen garden (M1) | Viable but wounded | Mend | To completion |
| Northern reed nursery (M2) | Stone chokes its water feed | Force → Mend | Up to 50% before clearing |
| Southeast sluice bell (M3) | Foundation cannot hold its tone | Anchor → Mend | Up to 60% before grounding |

Players arriving with both techniques can visit in any order. The three optional
marsh sites retain their existing combinations: Anchor at the willow refuge,
Force at Daro's spring, Force/Anchor at the lantern beds. Broken Ford keeps its
five differentiated sites, Iona lessons, partial willow discovery and return,
combined spillway and behavioural gear alternatives.

## Catch-up learning

Arriving without Anchor is possible when a Force build or Ferryman's Staff solved
the Ford spillway. Older marsh saves can also lack techniques. The main story must
remain understandable and finishable for those players:

- Mend the kitchen garden, then Neri offers a Force lesson through TALK.
- Open and restore the nursery, then Oren offers Anchor beside the bell.
- Existing teaching milestones remain necessary; XP alone cannot unlock a technique.
- Local lessons use the same learn/loadout/gear APIs, costs and mastery ledger.
- Dialogue retains two actionable choices and an always-available close control.
  Lio's earned reveal and chapter-completion choices keep their priority.
- Local learning recognizes the meeting with Neri; guidance does not ask the player
  to meet her again after she has already taught them.

NPC dialogue, objectives, technique screen and site refusal explain local teachers
and actual physical conditions. The map identifies nursery/bell techniques and
marks the garden's optional irrigation return. Partial healing is retained and
consumes no Flow once the current viability limit has been reached.

## Optional garden return

After M1 is fully restored, Anchor can secure the irrigation roots. This is a
simple optional improvement, not a new gate to the chapter or Lio's letter.

- Persistent `cultivated` state, visible clear irrigation channels and harvest baskets.
- Garden becomes healthy water for Flow recovery, using the existing recovery rules.
- Neri walks back to tending the beds and acknowledges the first harvest.
- Nearby TALK remains stable: her routine pauses while the player approaches.
- One meaningful Anchor mastery award; no duplicate site XP, loot or rewards.
- Resolved irrigation cannot be recast for mastery, including after save reload.

This does not implement Bloom. The later Living Arts technique and ecosystem
systems remain Phase E, after the opening quality benchmark.

## Save continuity and presentation

Schema 5 is retained; ecological state safely extends with `cultivated`.
Completed sites load as completed and their required clearing/grounding is credited.
The optional garden improvement remains available without undoing restoration.
Older numeric partial healing is preserved even if it is above a newly introduced
cap; solving the condition allows that same progress to continue.

Clear conditions and partial restoration survive reload, travel and Unmoored.
NPC work locations derive from saved ecological state. No existing earned item,
equipped appearance, mastery ledger, skill purchase, XP or story reveal is reset.

Site instructions are short enough for the phone layout. The contextual progress
panel shifts up when its text is longer; recent completion feedback follows the
nearby restored place so it does not cover an unrelated site after the player moves.

## Technical map

- `scripts/skills/waykeeper_definitions.gd`: authored story-site conditions/reasons.
- `restoration_site.gd`: persistent optional improvement and its visible outcome.
- `waykeeper_journey.gd`: local learning milestones, teacher hints and optional Anchor.
- `scripts/story/story_chapters.gd`, `story_director.gd`: local lessons, personal
  consequences and existing Lio completion.
- `story_npc.gd`: reusable workplace routine; no precision interaction requirement.
- `scripts/hero/hero.gd`: cultivated irrigation uses healthy-water recovery.
- `scripts/ui/journey_map.gd`, `skills_screen.gd`: world/teacher information.
- `tests/unit/test_reedglass_progression.gd`: local learning, main techniques,
  completed/partial migration, optional recovery, routines and reward protection.

## Verification — 2026-09-27

- Full regression suite: **161 passed, 0 failed**; four new Reedglass tests.
- Native screen-touch journey completed both chapters and all 12 sites with zero
  failures. Fresh-marsh touch checks covered both local lessons, optional garden
  irrigation, Neri's harvest reaction and ecological save/reload.
- Final native presentation checks passed: contextual progress stays in the
  viewport, Oren's teaching hint appears, touch loadout selects Anchor, and distant
  completion feedback does not cover the garden.
- Updated Android debug APK exported; signature and ZIP alignment verified.
  No physical-phone gameplay or performance measurement was performed.
- Production save was backed up to
  `builds/playtest/rpg-foundation/production-save-before-rebalance.json` before
  restarting the updated game. Every existing saved value matched after reopen;
  schema remains 5. The updated game was left open for play.
- Native review: `dev/review_waykeeper_journey.gd` and
  `dev/review_reedglass_progression.gd`. Captures are in
  `builds/playtest/rpg-foundation/phase-c-*.png`.

## Next — Phase D

Build the 10–15 minute opening quality benchmark: Mara, exploration, first Mend,
physical restoration spectacle, progression/tree choice, Force acquisition/use,
and a return to a visibly changed inhabited space. Polish world/NPC/human art,
dialogue/audio, resources, touch feel and persistence as one sequence. Physical
midrange-Android play/performance validation is required before claiming the
benchmark achieved. A full third region and Weave remain later priorities.
