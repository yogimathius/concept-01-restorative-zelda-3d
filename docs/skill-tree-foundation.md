# Connected Waykeeper tree — Phase B

Canonical direction: [RPG revision](rpg-systems-restoration-revision.md).

Current extension: the original 13-node Phase B tree now has **16 nodes**. Living
Conduit uses Weave mastery to strengthen Flow near connected water; Living Echo
combines Mend and Weave to pass partial care between linked sites; Living Network
lets a Bloomed shelter extend through a Weave connection to its spring. See
[the living route implementation](weave-living-route.md) and
[the first Bloom route](bloom-first-route.md). The delivery record below
describes the original Phase B milestone and its verification at that time.

## Delivered scope

One connected, touch-pannable watershed with **13 purchasable nodes**. Waykeeper
fundamentals, Mend, Warden and a Mend/Anchor hybrid share connections. Weaver and
Living Arts are visibly future branches; their techniques remain story-led future
work after the quality benchmark. Existing Warden/Weaver art is retained, and both
heroes can invest in either implemented tradition.

**Each Waykeeper level after level 1 grants two Skill Points.** The point budget is
reconstructed from earned character progression. Mastery stays separate and gates
eligibility. Parent nodes, mastery, learned techniques and point costs must all be
satisfied. No automatic purchases. Skill mastery still comes from the existing
unique meaningful-event ledger; empty casts, resolved sites and reloads cannot farm it.

| Branch | Nodes | Actual effects |
| --- | --- | --- |
| Waykeeper | Steady Vessel, Deep Reserve | +8 Stability / +10 Flow capacity; existing depletion stays |
| Waykeeper | Spring Attunement, Current Rider, Restoration Return | Extra spring regeneration; 25% farther Glide when launched near restored water; +8 completion Flow |
| Mend | Living Pulse, Resonance, Gentle Current | Partial completion waves, stronger waves, 25% cheaper Mend near restored springs |
| Warden | Groundwave, Undertow, Shared Ground, Root Memory | Existing multi-target clearing, stabilizing Force, shared grounding and Anchor healing |
| Hybrid | Gentle Foundation | Requires Living Pulse + Shared Ground, Mend mastery 6 + Anchor mastery 2 and 2 points. Mending Anchored systems costs 25% less and protects Stability during useful channeling |

Most nodes cost one point. The hybrid costs two. At current level 5 the player has
8 earned points, so the whole tree cannot be learned at once. More branches and
later techniques expand this foundation in future phases.

Ferryman's Staff supplies effective Undertow while equipped without adding a
purchased node or spending points. Learning Undertow makes it independent of that
staff. Other existing gear behaviour and visible replacements remain intact;
new trade-off items are Phase E.

## Touch interface

SKILLS opens TREE: drag the ceramic waterways horizontally/vertically, tap any node
to inspect it, then use the separate LEARN button to purchase. Learned, available
and locked nodes have distinct states. Details show effect, cost, mastery and
missing prerequisites. Long requirements scroll within their own panel.
TECHNIQUES keeps the compact loadout; selecting/swiping techniques remains separate
from buying capabilities. Gameplay pauses and held touch input is cancelled while
the screen is open. Panning cannot spend points or cast an ability.

## Save continuity

Schema **5** preserves purchased nodes and inherited legacy choices. Existing six
behavioural upgrades migrate into equivalent learned nodes, including prerequisite
paths, without consuming the newly available point budget. Earned mastery and
technique loadouts remain. Older saves do not automatically buy unchosen upgrades.
New purchases are reconstructed against real level budgets, prerequisites and
mastery; repeated loading cannot refund spending or grant extra points.

Tree/resource configuration loads before resource sanitization, preserving Flow
above the former 100 cap. Resources still follow active-play time and never refill
offline. The launcher resumes both regions for schemas 2–5; schemas 1–4 migrate.

## Architecture

- `scripts/skills/waykeeper_tree.gd`: node definitions, connections, mastery, costs,
  layout, tradition colours and the legacy mapping.
- `waykeeper_progression.gd`: point budget, eligibility, purchases and migration.
- `waykeeper_journey.gd`: purchase orchestration and gear-supplied effective nodes.
- `scripts/ui/skills_screen.gd`, `skill_tree_map.gd`: touch screen and waterways.
- `scripts/rpg/waykeeper_resources.gd`: chosen resource modifiers and capacities.
- Hero/verbs consume node effects; the region coordinates persistence and level sync.
- `tests/unit/test_waykeeper_tree.gd`: choices, prerequisites, safe migration,
  resource persistence, real hybrid channeling, spring/Glide effects, gear and touch pan.

Phase C is now delivered: [journey rebalance](journey-rebalance.md). Next build the complete
10–15 minute opening benchmark (Phase D), before expanding regions or implementing
Weave/Channel/Bloom (Phase E). Physical-phone performance validation is still pending.

## Verification — 2026-09-27

- Full suite: **157 passed, 0 failed**, with no script/parse errors.
- Native touch UI: purchase Living Pulse, pan the watershed, inspect locked Warden
  prerequisites, switch to technique loadout, and spend the remaining point on a
  real Flow-capacity node; **zero failures**.
- Native existing journey: all 12 sites, story teaching, saved intermediate
  conditions, visible gear, both-region travel/return and Unmoored; **zero failures**.
- Existing production save backed up and migrated to schema 5. XP, inventory,
  equipped gear, story, active region, mastery event ledger, restored/partial and
  ecological state compared unchanged. No nodes were bought for the player.
- Android APK rebuilt, alignment and signature verified. Hardware performance
  remains unverified; no phone is connected.
- Headless shutdown reports seven active WAV/playback references. A verbose
  isolated world test identified audio playback objects, not tree UI nodes;
  runtime memory/thermal validation remains part of the physical-phone benchmark.

Captures live in `builds/playtest/rpg-foundation/tree-*.png`.
