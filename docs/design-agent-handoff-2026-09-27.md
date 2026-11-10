> Historical snapshot. The [canonical RPG systems revision](rpg-systems-restoration-revision.md) supersedes earlier priorities. See [phase status](rpg-foundation.md) for delivered scope.

# Broken Waterway — design handoff

Status snapshot: 2026-09-27, after the human character foundation replacement.
Project: `/Users/mathiusjohnson/Desktop/projects/game-lab/godot/concept-01-restorative-zelda-3d`.
Working title: **The Broken Waterway**; Godot application name: **Broken Ford**.

## 1. Product vision and user constraints

A touch-first 3D restorative action-RPG about becoming a Waykeeper: heal a damaged
waterway, reconnect communities, learn restoration traditions and develop an
individual equipment/skill build. The Stillfall storm disrupted the world's living
channels. Environmental recovery and its effect on people's lives carry the story.

The user wants approachable restoration, immersion, meaningful progression, visible
loot and substantially better graphics. The original technical opening and unclear
healing/controls were rejected. Preserve these requirements:

- Mobile touch is the primary input. Left movement stick, roughly two or three
  right-side actions, illustrated buttons and compact contextual/skill switching.
- Gentle, generous interactions. No precise creature positioning, intricate opening
  obstacle sequences, timing windows or combat gates.
- Visible, understandable healing with retained partial progress and confirmation.
- Progression develops techniques and their interactions. Mend remains the first
  verb; Force and Anchor are now forgiving restoration tools.
- Gear physically replaces the worn piece. The previous piece remains owned.
- NPCs/story must make the world feel inhabited and respond to completed work.
- Preserve existing worlds, saves, XP, skills, inventory, outfits and story flags.
- A distinctive visual identity is tracked. Shared asset provenance alone does not
  establish originality. The wider art identity milestone remains incomplete.

The adopted ability progression direction supersedes the earlier assumption that
holding Mend should complete every site. Complexity should grow through learning
visible ecological rules, with partial recovery and reasons to revisit.

## 2. Current playable content

Two connected regions, **12 restoration places**, NPC conversations, story payoff,
optional discoveries, equipment, brewing, leveling and saved cross-region travel.

### Broken Ford — Chapter 1: A way home

Six places: Homecoming grove, Stonebound spring, Leaning willow refuge, Silted reed
spring, Windworn sunleaf grove and Fractured spillway. Mara introduces the return;
Iona teaches traditions; Oren provides explicit travel to Reedglass Marsh after the
route flows. The first grove accepts Mend alone. Later places need clearing,
stability or both. The final spillway combines learned techniques and can be
approached differently with behavioural equipment/mastery upgrades.

### Reedglass Marsh — Chapter 2: When the marsh sings

Six places across connected courts. Neri's kitchen garden, reed nursery and sluice
bell form the main story and accept simple Mend. Three optional places reuse Force
and Anchor: willow refuge, Daro's spring and lantern beds. Daro offers brewing and
an optional restoration quest. Restoring the main sites uncovers a message from
Neri's missing brother Lio: he is alive in Counterweight Orchard and closed the upper
sluice to protect the reservoir. The chapter awards Messenger's brooch once.

**Counterweight Orchard is a narrative hook, not a playable third region.**

Restoration changes vegetation, pools, springs, crossings and regional river flow.
Stone visibly moves when cleared; unstable structures sway until grounded; Anchor
adds visible supports. Quest guidance, the map, healing meters and completion
feedback are already present. These are functional foundations with room for polish.

## 3. Controls and interaction

- Left touch stick: movement; continuous follow camera.
- Right action 1: active technique. Hold Mend; tap Force or Anchor.
- Swipe upward on the technique medallion: cycle learned techniques without casting.
- Right action 2: Glide.
- Right action 3: contextual TALK near NPCs, PACK elsewhere.
- Map, Gear and Skills are additional menu affordances. Relevant menus/conversations
  pause the world and release held input.
- Skills also selects the active technique and earned upgrades.
- Desktop mouse emulates touch; keyboard mappings remain for development.

Opening targeting is generous. Anchor persists while switching back to Mend. Sites
retain healing if the player releases input, changes technique or reloads. A site
with unmet conditions identifies the issue and remembers the player's visit.

## 4. Abilities, character level and mastery

| Ability | Current status | Gameplay |
| --- | --- | --- |
| Mend | Implemented; available initially | Restore viable systems; hold near a target. |
| Force | Implemented; learned from Iona | Clear nearby obstruction with forgiving targeting. |
| Anchor | Implemented; learned from Iona | Permanently resolve site instability for subsequent Mend. |
| Weave | Framework definition only | Future linking and sharing between systems. |
| Channel | Framework definition only | Future carrying/redirecting Charge. |
| Bloom | Framework definition only | Future healthy growth and new routes. |

A fresh player restores the first grove, crosses its rebuilt bridge, learns Force
from Iona, clears/restores the Stonebound spring, then returns to learn Anchor.
Sites can be discovered before the needed tradition. For example, the willow keeps
55% partial Mend until grounded. Ford partial limits range from 40% to 55% where
conditions are unmet. Clearing and grounding may be resolved in either order.

Character XP and individual mastery are separate:

- Each unique completed place awards 40 Waykeeper XP, once across saved sessions.
- The first place reaches Level 2; all six Ford places reach Level 4.
- Meaningful unique clear/ground actions award mastery to the technique used.
  Viability and completion award Mend mastery. Empty casts and repeated resolved
  interactions cannot farm mastery.
- Mastery ranks affect the specific skill; character XP does not raise all skills.
- Six behavioural upgrade nodes are implemented:
  - Mend: Living Pulse spreads partial healing; Resonance enlarges/strengthens it.
  - Force: Groundwave clears nearby eligible obstructions; Undertow also stabilizes.
  - Anchor: Shared Ground stabilizes nearby systems; Root Memory adds partial Mend.
- Nodes unlock at mastery thresholds. Mastery points are retained rather than spent.
  Full branching specialization trees remain future work.

Warden and Weaver are still selectable hero identities with distinct outfits/base
movement characteristics. Reframing them as restoration disciplines or eventual
specializations is adopted investigation, not a completed class redesign. Force/
Anchor learning is handled by shared Waykeeper progression.

## 5. Loot, visible equipment and consumables

**15 gear pieces**, across three slots: five tools, four cloaks/mantles and six
charms/brooches. Three starters; six Ford discoveries; three marsh discoveries; one
marsh story reward; two Iona teaching rewards. Optional marsh sites provide supplies
without adding named equipment to the catalogue.

Drops are guaranteed named rewards from restoration/story, with duplicate protection.
Loot rises from its place and travels into the bag. The touch wardrobe previews,
turns and equips the actual rigged hero. Exactly one visible item occupies each slot;
world and preview replace it, and class swapping preserves the selected outfit.

Most gear improves reach, healing rate or travel speed. Two delivered pieces change
ability behaviour:

- Ferryman's staff: Force also stabilizes the cleared system.
- Stonekeeper brooch: Anchor roots also lift obstruction.

They create alternate restoration sequences; their behaviour disappears when removed.
A broad crafting/upgrade economy, randomized rarity/affixes and equipment set systems
have not been implemented.

Seeds and river crystals support brewing. Bloom Tea grants +1.5 Mend reach for 30
active-play seconds; Reed Cordial grants +20% walking speed for 30 seconds. Each
consumable does not stack with itself. Paused menus do not consume duration. Daro
brews tea for three seeds or cordial for two crystals. Counts and active effects save.

## 6. Art and latest character work

Direction: **ancient river-order craft** — porcelain armour, patinated bronze/gold,
indigo/teal woven cloth, reed motifs, split crescents and restrained riverglass.
Warden uses layered plate, diadem and embroidered tabard; Weaver uses an open hood,
porcelain shoulder leaves, diagonal sash and scalloped robe panels. All 15 gear
pieces have crafted silhouettes, fittings, mantles or brooch designs.

After the user rejected oval faces and puppet-like bodies, facial contours were
refined and the character foundation was replaced:

- Adapted MakeHuman core anatomy/body and five-finger hand topology, under CC0.
- Source revision, SHA-256 and licence texts kept in `art/source/makehuman/`;
  `.gdignore` excludes source data from runtime imports/exports.
- Adult proportions and refitted clothes/armour/equipment.
- 43-bone rig; the original 12 names remain compatibility anchors.
- Neck, clavicle, twist, hand, finger and foot articulation with real skin weights.
- Tool binding follows the right hand; cloak/charm bind to the chest.
- Offline-baked walking ankle IK/foot roll, torso counter-motion, breathing idle,
  and an asymmetric offering gesture with the free hand opening.
- Imported baked crevice colour/shading, differentiated cloth/skin/metal finishes.
- Original locally authored faces, hair/hoods, armour, boots and gear remain.

Measured imported body geometry: Warden 17,888 triangles; Weaver 19,031. Inspected
complete outfits: 21,838 and 22,445. Body ceiling: 24,000; gear ceiling: 3,000 per
piece. Hero imports generate distance LODs. Each hero uses one skeleton; walking
needs no runtime IK controllers. Preserve animation names and the 0.333-second
ability action duration. Body and gear fitting constants must stay synchronized.

The presentation remains stylized fantasy. Photorealistic skin, facial performance,
simulated garments and a complete NPC art uplift have not been delivered. World/NPC
art and restoration spectacle are the largest remaining visual gaps.

## 7. Technical and verification state

Godot 4.7 project using GL Compatibility; Blender generates assets without requiring
its GUI to be open. Entry scene: `scenes/story/journey_start.tscn`.

- Latest full regression: **143 passed, 0 failed**, after the anatomy/rig changes.
- Four focused hero tests passed, including actual skin influences, support/swing
  foot placement, animated hand attachment and geometry limits.
- Earlier native touch walkthrough completed all 12 places, learned Force/Anchor,
  reloaded partial conditions, equipped behavioural gear, completed the marsh story
  and returned to Ford. This walkthrough predates the latest character replacement.
- Latest art review inspected native phase renders, recorded idle/walk/action frames,
  equipment catalogue and actual world/wardrobe captures for both heroes.
- Latest Android debug APK was exported, signed and verified; approximately 38 MB.
- Physical-phone controls, performance, memory, heat and battery remain unverified.
- Existing headless dummy-renderer diagnostics/shutdown warnings remain; native art
  review logs showed no script/shader errors. Passing tests are not release polish.
- Production save was preserved and checked across the latest native-game restart.

Save schema 3 persists both worlds, partial ecological recovery, skills/unlocks/
mastery/upgrades/loadout, XP, inventory/outfit, supplies/effects and story flags.
Legacy migration preserves already completed restoration. Do not reset saves to
showcase new progression.

There is substantial uncommitted and untracked local work. Preserve it; do not assume
all current features are represented in Git history. Ignored captures/APKs/Blender
masters are local artifacts and not guaranteed to exist in another checkout.

## 8. Recommended next milestone — proposed, not built

Polish **Mara + the starting grove + its restoration sequence** as the benchmark
for the rest of the game:

1. Give Mara a distinct human face/outfit and readable idle/conversation gestures.
2. Uplift the grove's landscape, architecture, planting and lighting coherently.
3. Make partial/complete recovery a memorable physical and audiovisual event.
4. Refine the introduction, teaching, reward and onward story hook.
5. Verify the sequence through touch on a real phone and profile performance.

Then extend that finish to key NPCs/regions; introduce a story-led, generous-touch
Weave quest; expand behavioural equipment and eventually the next region. Weave
is the recommended next new ability, not an implemented or newly approved feature.

Useful design decisions to resolve:

- Visual references and originality criteria for architecture/NPCs/restoration.
- The signature restoration sequence and how recovery changes inhabitants' lives.
- Emotional opening beat and the longer Stillfall/Lio narrative arc.
- Weave's mobile selection/feedback grammar and forgiving connection rules.
- Warden/Weaver as looks, disciplines or later specializations.
- Equipment build trade-offs and consumable economy without grind.
- Target phone class and measured performance budget before increasing scene density.

## 9. Local references and artifacts

Read `AGENTS.md` first, then:

- `docs/waykeeper-progression-direction.md`: adopted long-term product direction.
- `docs/waykeeper-slice.md`: delivered abilities, mastery, site rules and save map.
- `docs/story-chapters.md`: implemented narrative and interaction rules.
- `docs/hero-art-direction.md`: current art, anatomy provenance, fitting and budgets.
- `docs/roadmap.md` and `README.md`: scope, route and outstanding milestones.

Relevant implementation: `scripts/skills/`, `scripts/story/`, `scripts/gear/`,
`scripts/ui/`, `scripts/levels/region_scene.gd`, `art/characters/` and
`shaders/hero_surface.gdshader`. Future abilities belong in the registry/components,
not a growing block of hard-coded execution inside `region_scene.gd`.

Artifacts:

- `builds/android/broken-ford-debug.apk`
- `builds/playtest/hero-art/anatomy-motion.gif` and `.avi`
- `builds/playtest/hero-art/heroes-three-quarter.png`
- `builds/playtest/hero-art/wardrobe-warden.png` and `wardrobe-weaver.png`

Run the regression suite with `bash dev/test.sh`; native art review with Godot
`--path . --resolution 1280x720 -s dev/review_hero_art.gd`. Use private test saves.
