# Current spatial-design milestone

User approved a river-valley opening prototype on 2026-09-27. V2a now adds distributed trail destinations, the playable upper ford weir, and downstream water/boat/NPC consequences. See [requirements, outcomes and next steps](open-world-direction.md). This is the current continuation priority; deeper RPG phases remain planned. The main journey and saves stay intact.

The [proposed story and universe plan](story-universe-plan.md) maps the current two chapters into a deeper character/world arc and explores possible links to our universe. The [user-authored story-agent brief](story-agent-brief.md) directs the next narrative pass to challenge that plan, especially Lio and the value of an Earth connection. Neither document implements a third chapter or decides cosmology.

# Broken Waterway — product follow-ups

## Canonical revision — RPG systems and restoration

Adopted 2026-09-27: [full canonical specification](rpg-systems-restoration-revision.md).
Status: [phase ledger](rpg-foundation.md). **A delivered: Stability/Flow, schema 4,
150-test milestone and both-chapter native touch route.**
**B delivered:** 13-node connected tree, two points/level, mastery gates, touch UI,
hybrid and schema 5 migration. See [tree implementation](skill-tree-foundation.md).
**C delivered:** differentiated Reedglass main sites, local learning and optional
garden irrigation. See [journey rebalance](journey-rebalance.md).
**D candidate implemented:** human NPCs/portraits, staged first recovery, opening
craft, chosen first growth and an inhabited return. See [opening benchmark](opening-quality-benchmark.md).
Actual phone/pacing gates remain open. **E in progress:** meaningful gear, two
Reedglass Weave links, [Channel's first carried-current circuit](channel-first-route.md)
and [Bloom's first living route](bloom-first-route.md) are playable; the wider
network, deeper Channel and wider Bloom are still ahead. See
[first Weave link](weave-first-link.md). Complete the benchmark
before a full third region.
**Opening guidance enhancement:** MAP → JOURNAL remembers discovered sites,
partial recovery and technique conditions; optional pins survive region travel.
The [living care world pass](living-care-world.md) adds distinct conditions and
staged care to all 12 authored patches, non-combat willow life, a Care journal
and map layer, and story-site priority for Mend. That milestone passed
202 tests. Uncoached phone targeting and wider world ecology remain open.
The [Reedglass correspondence route](marsh-correspondence.md) now gives Lio's
letter, Neri's reply and Oren's courier work visible persistent consequences.
Its uncoached story comprehension and phone-sized presentation remain open.
See [feature research and next choices](feature-research-next.md) for implementation,
source-backed ideas and the ordered community/gear/Weave follow-ups.
The following milestones record earlier delivered work.

## Earlier shift — Waykeeper ability progression

Adopted 2026-09-26. **Force/Anchor slice implemented.** Full direction and acceptance
criteria: [Waykeeper progression direction](waykeeper-progression-direction.md).
Agent entry point: [AGENTS.md](../AGENTS.md).

Replace the single-verb progression assumption with learned restoration techniques,
individual mastery, behavioural skill upgrades, equipment builds and revisitable
partial ecological recovery. Preserve approachable restoration, visible healing,
touch controls, existing story/content and player saves.

### Delivered milestone — Force and Anchor in Broken Ford

- [x] Extensible ability/target/state framework; future Weave, Channel and Bloom support.
- [x] Story/world acquisition of Force and Anchor; Mend and Glide at the start.
- [x] At least three of the six sites mechanically differentiated through abilities.
- [x] A site encountered before the necessary technique and completed on return.
- [x] Persistent individual mastery and upgrades that alter behaviour.
- [x] At least two pieces of behavioural skill gear; retain visible replacements.
- [x] Compact touch skill switching/loadouts without displaying six permanent buttons.
- [x] Persist unlocks, mastery, loadout and ecological state; migrate existing saves
      while preserving all earned progress and completed sites.
- [x] Extend required automated coverage and preserve the regression suite.
- [x] Inspect/play the full Ford route, acquisition pacing and unavailable-skill
      feedback; verify both fresh progression and legacy completed-save continuity.

Implementation map and playable route: [waykeeper-slice.md](waykeeper-slice.md).
Five Ford sites now use technique conditions; three optional marsh sites reuse them.
The original two chapters, visible equipment, supplies and consumables are retained.
All **141 automated regression tests passed**. Final story checks: **8 passed** after the optional marsh interactions were added.
The native touch walkthrough restored all **12 places**, learned both traditions,
reloaded intermediate conditions, equipped behavioural gear, completed the marsh
chapter and returned successfully. Android APK aligned, signed and verified.
Physical-phone playtesting remains outstanding.

Longer term: Weave/Channel/Bloom gameplay, combinations and alternate solutions,
Warden/Weaver specialization philosophies, narrative traditions, and environmental
language that gradually replaces explicit instruction. Examples in the direction
are design possibilities; this milestone does not require the entire eventual tree.


## Art identity — tracked, deferred

Requested 2026-09-26. Build an unmistakable visual identity for this game:

- A distinctive, readable hero silhouette and visible outfit language.
- Recognizable regional architecture and authored landmark shapes.
- A signature restoration animation that identifies the game without its title.
- Bring world models, characters, and detailed touch artwork to a coherent finish.

Acceptance: review screenshots and a restoration clip at actual phone size;
recognize the same visual language across the hero, terrain, NPCs, equipment,
and UI. Asset provenance alone does not establish a distinctive style.

Status: **partially implemented; wider identity remains a follow-up**.
The 2026-09-26 [hero/equipment craft pass](hero-art-direction.md) replaces both
hero models and all 15 gear pieces with layered river-order armour, tailoring and
crafted fittings. Native front/back, walk/Mend, catalogue and wardrobe views were
reviewed. A 2026-09-27 refinement adds fitted armour, taller proportions, baked
surface shading, woven mantle borders and richer crafted gear fittings. Further
face/body refinement adds defined facial anatomy, continuous joint skinning,
shaped hands/boots and more natural idle, walking and offering poses.
The user-approved human foundation replacement adapts a credited CC0 MakeHuman
anatomy mesh, refits adult proportions and equipment, and introduces a 43-bone rig
with finger/wrist/ankle articulation and baked foot placement. See the art guide
for source provenance and the revised 24,000-triangle body ceiling.
Regional architecture, detailed NPC models, UI cohesion and the signature
restoration animation still need a shared finish and phone-size identity review.

## Implemented milestone — a populated, connected adventure

Status: **implemented 2026-09-26**. Playable Ford/Marsh chapters, real touch
conversations, visible gear discoveries, brewing, and multi-region persistence.
Verified with the regression suite and a native touch-driven round trip.
Android APK exports; physical phone playtesting remains outstanding.

- Broken Ford chapter framing and a real exit into Reedglass Marsh.
- A second playable region with approachable restoration, optional discoveries,
  character conversations, quest guidance, and a complete chapter payoff.
- Visible equippable loot obtained from restoring places and helping inhabitants.
- Consumables that support healing/travel; touch use, counts, saved consumption.
- Persistent NPC/quest state, multi-region restoration, inventory and outfits.
- Preserve existing saves and the gentle, touch-first default mission.

Story direction: a returning waykeeper discovers why the waterway went silent.
Restore the routes that carry messages and reunite its inhabitants. Dialogue
must respond to completed work, including restoring a place before accepting
its quest. Quest rewards and supplies cannot be farmed by repeated conversation.
