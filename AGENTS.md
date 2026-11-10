# Broken Waterway / Broken Ford — agent guidance

## Read first

- [Restorative economy direction](docs/restorative-economy-direction.md): first playable care patches, Ford exchange, scrip, crafting ranks, commissions and the larger world expansion ledger. Preserve unique restoration and mastery, current saves and the touch-first flow while expanding it.
- [First playable Weave link](docs/weave-first-link.md): Neri teaches Link after garden and nursery restoration; a touch drag reconnects their ceramic feed and persists.
- [Daro's living Weave route](docs/weave-living-route.md): a second independent spring/refuge link grows mint, changes Daro's routine, creates a journal request and repeatable care benefit. Living Echo adds a chosen Mend/Weave care interaction. These are authored links, not the completed network discipline.
- [Bryn's carried current](docs/channel-first-route.md): the first playable Channel route connects the restored bell to lantern beds and the exchange lamp. Carry, deliver, journal, reward, NPC response and save state are authored; Reservoir and wider Charge gameplay remain planned.
- [Neri's new season](docs/bloom-first-route.md): Bloom grows a linked garden seed bed and a willow shelter, with an authored quest and a chosen Living Network cross-skill node. Wider growth and traversal remain planned.
- [Living care world pass](docs/living-care-world.md): reed, glass, silt and habitat care conditions now respond in visible stages; the Care journal and map surface renewable work, and Mend prioritizes viable story restoration. Preserve existing material mapping, save ledger and original restored sites.
- [Reedglass correspondence](docs/marsh-correspondence.md): Lio's recovered letter and Neri's reply have visible places, Oren and Neri change routines, and a one-time touch quest persists. The reply asks what Lio saw; it does not establish the truth of his decision.

- [Current river-valley / open-world direction and outcome ledger](docs/open-world-direction.md): user adopted 2026-09-27. V2a builds on the bounded perspective opening: distributed sites, a playable upper weir and derived water/NPC consequences before a full new region. Use its separate save and Android package; preserve the main two-chapter journey. Follow the requirement IDs and ordered next milestones.
- [Proposed story and universe plan](docs/story-universe-plan.md): narrative architecture, character arcs, Stillfall/Lio continuity, visible social consequences and optional ways this world could relate to ours. This is a plan, not shipped content or an approved literal Earth connection. Preserve established two-chapter events and the distinction between the local Ford weir and Lio's reservoir sluice.
- [User-authored story-agent brief](docs/story-agent-brief.md): next narrative pass must critique inherited assumptions, develop Lio and Earth alternatives, rank five risks in a Narrative Director's Critique, and write a new proposal under `docs/`. The brief forbids gameplay code edits during that pass. It does not make any proposed lore canon.

- [Canonical RPG systems revision](docs/rpg-systems-restoration-revision.md):
  user-adopted 2026-09-27; supersedes the earlier progression direction.
- [Phase status and resource implementation](docs/rpg-foundation.md).
- [Earlier progression direction](docs/waykeeper-progression-direction.md): historical context.
- [Delivered Force/Anchor slice and technical map](docs/waykeeper-slice.md).
- [Roadmap and milestone status](docs/roadmap.md).
- [Current playable build](README.md) and [story chapters](docs/story-chapters.md).

**Phases A (resources), B (connected tree) and C (existing journey) are delivered.**
Phase D has a playable presentation candidate: read
[opening benchmark](docs/opening-quality-benchmark.md). Real-player pacing and
physical-phone validation remain required before marking D complete.
The opening also has MAP → JOURNAL: discovered-site observations, retained
progress, technique requirements and one persistent optional return pin. Read
[feature research and next choices](docs/feature-research-next.md). Keep journal
observations tied to real world state; choosing a technique must never cast it.
Read [journey rebalance and save continuity](docs/journey-rebalance.md).
Read [connected tree implementation](docs/skill-tree-foundation.md).
See the phase ledger for exact values, schema 5 and automated/native route evidence.
Execute the canonical phases A–E: resources, chosen skill trees, existing journey,
a 10–15 minute opening benchmark, then deeper techniques and gear. Do not prioritize
a third region before the benchmark. Stability and Flow are the two main resources;
level grants broad growth/points, mastery gates eligibility, and purchased nodes
represent player choice. Target stable 30 FPS on a representative midrange Android
phone, with actual hardware evidence required.

The **Force/Anchor progression slice is implemented**. The broader progression
direction remains adopted; Weave has two playable Reedglass connections, one
Weaver node and a Mend/Weave hybrid. Channel has one authored Carry route with
two permanent receivers. Bloom has two authored living outcomes and a Weave/Bloom
hybrid. A wider Weave network, deeper Channel, wider Bloom and later
specialization trees are future work. Keep delivered features separate from planned work.
Later explicit user instructions take precedence over these documents.

## Product direction

Build a touch-first restorative action-RPG about becoming a Waykeeper. Progression
expands the player's techniques, their interactions and equipment builds. Mend is
the starting verb; future sites can need physical clearing, stability, connections,
energy handling or healthy growth before full recovery. Requirements must follow
visible world rules and support remembered partial restoration and later revisits.

The delivered Broken Ford slice has learnable
**Force and Anchor**, individual mastery, behavioural upgrades, at least three
mechanically differentiated sites, one meaningful return visit, at least two gear
pieces that alter skills, compact touch loadouts, persistence and route verification.
The same components serve three optional marsh sites. Architecture supports
later Weave, Channel and Bloom; Weave's two authored links, Channel's first
carried-current circuit and Bloom's first living route are playable. See the
implementation guide for the actual current route, save schema and test evidence.

## Requirements to preserve

- User requested silent prototyping during a call. Keep the Master bus muted (`default_bus_layout.tres`) until they ask to restore sound; preserve authored audio.

- Gentle, forgiving restoration and visible world recovery. Complexity grows with
  learning; avoid intricate opening obstacles, precision positioning or combat gates.
- Entire playable flow works through touch: left stick, approximately 2–3 right
  actions, illustrated buttons, compact contextual/loadout switching and Glide.
- Gear visibly replaces the worn item on the hero and in the Gear preview.
- Character XP remains distinct from individual skill mastery. Meaningful uses
  earn mastery; repeated ability spam cannot farm progress.
- NPCs/story teach techniques as traditions. Preserve Mara, Oren, Neri, Daro,
  both playable regions, brewing and dialogue that recognizes earlier work.
- Keep existing saves and earned progress. Never reset the user's production save
  or invalidate completed restoration when introducing new requirements.
- Warden/Weaver are potential restoration disciplines/specializations; investigate
  that evolution without discarding their models or useful existing systems.
- Preserve the [hero/equipment river-order craft direction](docs/hero-art-direction.md).
  Both hero meshes and all 15 gear pieces have been uplifted; the wider world/NPC/
  restoration art identity remains in the roadmap. Provenance alone does not
  satisfy it. The user approved replacing the prototype body foundation on
  2026-09-27. Preserve the original 12 named bones as compatibility anchors;
  the richer human rig adds neck/clavicle, twist, hand/finger and foot articulation.
  Preserve idle/walk/attack names and action timing. Body ceiling is now 24,000
  triangles with generated import LODs; equipment ceiling remains 3,000 per item.

## Implementation and verification

Use data-driven ability definitions, persistent unlock/mastery state and reusable
interaction components. Separate ability execution, target requirements, ecological
state, mastery, gear modifiers, UI and save serialization. The current registry/components live in `scripts/skills/`. Adding a future ability
should not require rewriting `scripts/levels/region_scene.gd`.

Useful starting points (inspect before choosing implementation):

- `scripts/hero/verb.gd`, `scripts/hero/verbs/warden_pulse.gd`,
  `scripts/hero/verbs/weaver_catch.gd`, `scripts/core/influence.gd`,
  `scripts/core/state_gauge.gd`: existing verbs and physical/state systems.
- `scripts/world/region_creature.gd`, `scripts/levels/region_builder.gd`:
  restoration targets and world transformations.
- `scripts/core/restoration_progression.gd`, `scripts/gear/`,
  `scripts/levels/region_scene.gd`, `scripts/story/journey_session.gd`:
  character progression, visible gear and multi-region save/travel.
- `scripts/ui/touch_controls.gd`, `scripts/ui/equipment_screen.gd`,
  `scripts/story/`: touch interface and narrative acquisition opportunities.

Run `bash dev/test.sh` for gameplay implementation changes. Preserve existing
coverage and add unlocking, mastery persistence, partial ecological state,
ability prerequisites, unavailable-skill feedback, behavioural equipment,
save/load migration and a multi-ability sequence. Inspect/play the full Ford route
with actual touch input and an isolated fresh save, plus a legacy completed save.
Do not equate an APK export with physical-phone gameplay verification.

The repository may contain substantial uncommitted work from earlier iterations;
preserve it. Blender can generate/export assets through the command line without
its GUI being open. Historical README sections and parent-world combat specs are
background, not the current product direction.
