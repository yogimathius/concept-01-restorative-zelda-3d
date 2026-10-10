> Historical snapshot. The [canonical RPG systems revision](rpg-systems-restoration-revision.md) supersedes earlier priorities. See [phase status](rpg-foundation.md) for delivered scope.

<!-- Governing product direction; approved by the user on 2026-09-26. -->

**Status: adopted direction; Force/Anchor slice implemented.** Recorded locally on
2026-09-26 at the user's request. This document preserves the supplied progression
redesign, including the immediate implementation milestone and longer-term ideas.
The immediate slice has since been implemented. Read [waykeeper-slice.md](waykeeper-slice.md)
for delivered scope and [roadmap.md](roadmap.md) for verification; the broader
Weave/Channel/Bloom gameplay and specialization trees remain future work.

## Authority and continuity

This direction governs future gameplay/progression work in this Godot project.
It supersedes the earlier assumption that every restoration should be solved by
holding Mend, and the earlier purely numerical leveling/gear model. Historical
combat/world specs remain references for reusable systems, not authority to
reintroduce combat or technical opening encounters.

Preserve the user's gentle restoration preference: deeper interactions must be
approachable, forgiving and touch-first. Introduce one concept at a time; avoid
precise creature positioning, timing windows and boss fights. The mobile control
budget remains a left stick and roughly two or three right-side actions, using
loadouts/context/switching to accommodate more techniques. Preserve Glide.

The current build has two playable chapters, six Ford sites and six marsh sites,
NPC dialogue, visible equipment, consumables, character XP and version 3 saves.
It now includes Force/Anchor acquisition, individual mastery, behavioural nodes and
gear, partial ecological state, touch switching and optional marsh skill sites.
Existing Force/Weight/Charge/Weaver systems remain reuse candidates for later
traditions; the old battle mode is a regression fixture, not the playable direction.

Keep both regions, story flags, owned/equipped gear, supplies, XP and completed
restorations intact through migration. Do not reset a player's world or silently
revoke already completed sites to demonstrate new prerequisites. Design legacy
completion handling explicitly; use isolated saves for fresh-route verification.
Numeric Mend progress, clearing/grounding conditions and remembered partial
restoration now persist together. Broader link/energy/growth states remain future work.

The six-site examples, acquisition sequence, specializations and named example
items below describe design intent, not fixed IDs or an obligation to implement
all six disciplines immediately. Force and Anchor are the delivered concrete slice;
Weave, Channel and Bloom have framework definitions, with gameplay still ahead.
Distinctive art identity remains a separate tracked follow-up in [roadmap.md](roadmap.md).

---

# Broken Ford — Expand Restoration Into a Full Skill Progression System

The current Broken Ford prototype has become too dependent on a single interaction:

**walk to restoration site → hold Mend → site heals.**

Mend should remain important, but it must become **the first verb in a much larger Waykeeper toolkit**, not the primary solution to nearly everything.

Evolve the game into a touch-first restorative action-RPG where the player gradually becomes a capable Waykeeper by:

**discovering new abilities → learning how they interact with the world → improving them → specializing them → combining them → finding gear that modifies them → returning to places that were previously impossible to fully restore.**

Preserve the existing gentle restoration identity, visible environmental recovery, equipment system, XP/save system, touch-first controls, Broken Ford map and existing transformation mechanics wherever useful.

The user subsequently authorized building this direction. The Force/Anchor milestone below is delivered in the playable project; the remaining broader direction guides future implementation. Consult the implementation guide before assuming a proposed development or example item is already present.

---

## Core progression philosophy

The player should regularly encounter situations where Mend alone is insufficient.

Sometimes the reason is immediately understandable:

- stone growth is physically blocking a channel;
- a structure is too unstable to safely restore;
- two severed systems need reconnecting;
- dangerous Charge must be transferred somewhere;
- vegetation has been restored but still needs help regrowing;
- a creature is healthy but trapped in an unstable state.

These should not feel like arbitrary puzzle locks.

They should feel like **rules of the world**.

Avoid:

> Find red key to open red door.

Prefer:

> The aqueduct keeps collapsing whenever you Mend it because its foundation is unstable. Once the player learns Anchor, they understand why they could not finish this restoration earlier.

Some locations should therefore remain only partially restorable when first discovered.

Mark or remember these locations so obtaining a new Waykeeper skill naturally creates reasons to revisit earlier regions.

---

# Waykeeper skill vocabulary

Build an extensible ability framework rather than hard-coding all restoration into Mend.

Begin with the following disciplines.

## 1. Mend

The foundational Waykeeper ability.

Mend restores damaged living or constructed systems once their underlying conditions permit recovery.

Current functionality can remain, but Mend should no longer automatically solve every damaged site.

Suitable uses:

- restore plants;
- heal springs;
- repair damaged crossings;
- calm damaged living systems;
- restore damaged mechanisms;
- finish restoration after another ability has resolved the underlying problem.

Initial skill:

**Mend — Restore**

Hold near a viable damaged target to restore it.

Possible later skill developments:

**Resonant Mend**  
Restoration propagates slightly into related nearby objects.

**Memory**  
Mend can restore an object toward a previous stable physical state.

**Living Pulse**  
Completing a restoration sends a small recovery wave through nearby vegetation.

Mend upgrades should change behaviour as well as speed/range.

---

## 2. Force

Reintroduce and expand the existing Force mechanic as a core restoration discipline rather than a combat ability.

Force manipulates momentum and physical relationships.

Suitable uses:

- remove stone growth;
- clear debris;
- redirect moving creatures;
- move heavy objects;
- unclog waterways;
- expose buried restoration points;
- manipulate mechanisms;
- alter flowing objects.

Initial skill:

**Force — Pulse**

Emit a directional push.

Later developments:

**Draw**  
Hold Force to pull rather than push.

**Groundwave**  
Force can travel through connected solid terrain.

**Momentum**  
Force transfers or stores movement between objects.

Existing Warden Force systems should be reused where practical.

---

## 3. Anchor

Anchor stabilizes unstable entities, structures or environmental systems.

It should solve a different category of problem than Mend.

Suitable uses:

- prevent collapsing structures from shifting;
- hold creatures in a stable physical state;
- ground something being pulled by current;
- suppress unstable Weight or Charge interactions;
- stabilize terrain long enough for Mend;
- temporarily fix moving environmental elements.

Initial skill:

**Anchor — Ground**

Hold a target in its current physical relationship.

Later developments:

**Shared Ground**  
Two nearby entities can share stability.

**Deep Anchor**  
Anchored targets accumulate Weight.

**Sanctuary**  
Create a temporary zone of reduced instability.

---

## 4. Weave

Weave should become one of the game's signature abilities.

It creates relationships between entities instead of simply changing one target.

Suitable uses:

- reconnect a broken water source;
- link two plants so restoration spreads;
- transfer Charge;
- share Weight;
- connect a spring to a channel;
- link environmental mechanisms;
- cause Mend on one target to affect another;
- balance two unstable creatures.

Initial skill:

**Weave — Link**

Select two compatible entities and establish a temporary connection between them.

Later developments:

**Transfer**  
Selected states can move through the link.

**Equalize**  
Linked entities gradually balance a selected property.

**Triad**  
Maintain three linked entities.

Reuse useful concepts from the existing Weaver systems, but expand them beyond catching projectiles.

---

## 5. Channel

Channel allows the Waykeeper to deliberately carry and redirect energetic states such as Charge.

Suitable uses:

- power dormant receivers;
- drain dangerous Charge from creatures;
- carry energy between separated systems;
- manipulate storms or charged pools;
- activate ancient mechanisms;
- temporarily empower another ability.

Initial skill:

**Channel — Carry**

Absorb manageable Charge and release it into a compatible target.

Later developments:

**Overflow**  
Excess Charge searches for another valid target.

**Reservoir**  
Safely retain Charge for longer.

**Conductive Glide**  
Glide can transport Charge across gaps or water.

Reuse the existing Charge system wherever possible.

---

## 6. Bloom

Bloom manipulates living growth after something has become healthy enough to support it.

This should make restoration useful for traversal and exploration, not merely cosmetic.

Suitable uses:

- grow reeds into temporary paths;
- strengthen roots into crossings;
- grow climbing vines;
- restore canopy;
- create living platforms;
- regenerate gardens;
- change how wildlife uses an area.

Initial skill:

**Bloom — Awaken**

Accelerate growth in viable restored vegetation.

Later developments can influence the shape or behaviour of growth.

Bloom should generally require the underlying ecosystem to already be sufficiently healthy.

---

# Skill acquisition

Do not give every skill to the player immediately.

Broken Ford should teach the basic philosophy through progression.

A possible early sequence:

**Start:** Mend + Glide

**Early Broken Ford:** acquire Force

**Mid Broken Ford:** acquire Anchor

**Late Broken Ford / transition:** discover Weave or Channel

Bloom can appear slightly later once vegetation restoration is established.

Ability acquisition should ideally arise from the story, another Waykeeper, an old Waykeeper site, environmental discovery, or meaningful restoration event.

Avoid simply displaying:

> LEVEL UP — YOU UNLOCKED FORCE.

Let discovering a new ability feel significant.

---

# Skill mastery and leveling

The player should be able to **skill up individual disciplines**.

Create persistent mastery for each Waykeeper ability.

Examples:

- Mend mastery
- Force mastery
- Anchor mastery
- Weave mastery
- Channel mastery
- Bloom mastery

Using a skill in meaningful restoration situations can contribute mastery, alongside progression rewards where appropriate.

Avoid grindable spam such as repeatedly using Force against a wall to gain levels.

Mastery should advance primarily through meaningful uses, restoration accomplishments, discoveries and/or skill points.

Each discipline should contain:

- modest numerical improvements;
- meaningful capability unlocks;
- eventually one or more specialization choices.

Do not make the tree mostly:

> +5% range  
> +5% speed  
> +5% duration

Those can exist as minor bonuses.

Major nodes should change what the player can do.

---

# Skill combinations

The long-term depth should come from abilities interacting.

Design restoration situations where several approaches are possible.

Example:

A damaged aqueduct might involve:

**Force** to clear stone blockage.

**Anchor** to stabilize the cracked foundation.

**Weave** to reconnect a severed water channel.

**Mend** to repair the structure.

**Bloom** to restore root systems that permanently support it.

Do not present this as a five-step quest checklist.

The environment should visually communicate what is wrong, and the player should gradually learn the game's physical/restorative language.

Later encounters should support alternative solutions based on skill upgrades and gear.

---

# Rework Broken Ford around this system

Keep the six existing restoration sites, but make them mechanically different.

Currently they risk feeling like six variations of “hold Mend.”

Convert at least three immediately into situations requiring different interactions.

For example:

### Grove 1

Remain simple.

Teach Mend and establish the emotional reward of restoration.

### Spring 1

Stone growth obstructs its waterway.

Introduce Force and require physical clearing before Mend can fully restore the spring.

### Grove 2

The ecosystem can be Mended partially, but its central tree remains unstable.

Once Anchor is learned, the player can return and complete its restoration.

### Spring 2

Water exists upstream but no longer reaches the spring.

Eventually teach Weave by reconnecting the source and destination.

### Southern site

Allow an optional combination approach and make it a place where equipment or skill specialization can matter.

### Final Broken Ford restoration

Require the player to combine several learned disciplines naturally.

Completing it should visibly restore the regional waterway and produce a major environmental transformation.

Do not turn the finale into a traditional boss fight.

---

# Partial restoration

Add the concept of restoration states beyond binary damaged/restored.

Useful states might include:

- damaged;
- viable;
- stabilized;
- reconnected;
- restored;
- flourishing.

A player may be able to Mend something into a viable state before possessing the skill required to complete its larger ecological recovery.

This supports exploration and backtracking without arbitrary locked doors.

Saving must preserve partial restoration and relevant state.

---

# Equipment must interact with skills

The existing:

**Tool = Mend reach**

**Cloak = movement speed**

**Brooch = Mend speed**

is too numerically shallow for the final direction.

Keep those statistics where useful, but begin making equipment modify ability behaviour.

Examples:

**Stonekeeper Brooch**  
Anchored entities gradually gain Weight.

**Riverweave Mantle**  
Gliding through flowing water lets Channel briefly carry Current.

**Ferryman's Staff**  
Force reaches much farther when affecting floating objects.

**Gardener's Clasp**  
Finishing Mend automatically triggers a small Bloom around the target.

**Echo Thread**  
Mend applied to one Weaved entity partially affects its linked partner.

Equipment should create builds.

Because visible equipment is already implemented, preserve and expand that system.

Significant gear changes should visibly appear on the player's model in the world and in the Gear screen.

---

# Warden and Weaver identity

Do not discard the existing Warden and Weaver work.

However, investigate evolving them from mutually exclusive traditional classes into **Waykeeper disciplines or specializations**.

A player might lean strongly toward:

**Warden**

- Force
- Anchor
- Weight
- structure
- physical stability

or:

**Weaver**

- Weave
- Channel
- Charge
- living networks
- transfer

but eventually learn techniques from both.

Avoid traditional tank / mage / DPS design.

These should represent different philosophies of restoration.

---

# Touch-first controls

Maintain the mobile-first control philosophy.

Do not permanently cover half the screen with six ability buttons.

Design an expandable ability interface suitable for eventually supporting many learned skills.

Possible approach:

- Mend remains a prominent contextual action;
- one or two active Waykeeper abilities are equipped to quick slots;
- hold or swipe an ability button to switch equipped technique;
- abilities become contextual where this reduces unnecessary UI;
- Gear/Skills screen allows loadout configuration.

Keep movement responsive and preserve Glide.

The player should eventually be choosing a **skill loadout/build**, rather than displaying every unlocked ability simultaneously.

---

# World guidance

Reduce explicit instructions as the player becomes experienced.

Early Broken Ford can teach mechanics clearly.

Later areas should rely increasingly on:

- animation;
- state effects;
- environmental change;
- water behaviour;
- sound;
- creature reactions;
- visual language.

The player should eventually look at a damaged place and think:

> “That structure needs anchoring.”

rather than reading:

> “Use Anchor here.”

---

# XP progression

Preserve overall Waykeeper/restoration XP, but separate it conceptually from individual skill mastery.

**Waykeeper level** represents overall experience and can unlock capacity, equipment features, skill points, additional loadout slots or broader progression.

**Skill mastery** represents expertise with Mend, Force, Anchor, Weave, Channel, Bloom, etc.

Avoid making higher character level simply increase every ability automatically.

---

# Story integration

Abilities should be part of the narrative world.

Mara, Oren, Neri, Daro and future characters should recognize Waykeeper techniques and sometimes understand different aspects of them.

Restoration abilities should have history and cultural meaning.

For example:

- ferrymen may understand currents and Channel;
- gardeners may preserve Bloom traditions;
- old bridgekeepers may know Anchor;
- former Waykeepers may disagree about Warden versus Weaver practices.

This should help the progression system feel like learning a tradition rather than unlocking videogame buttons.

---

# Technical requirements

Build the skill architecture so adding future abilities does not require rewriting `region_scene.gd`.

Prefer data-driven skill definitions, persistent skill/mastery state, reusable interaction interfaces/components and clean separation between:

- abilities;
- targets;
- environmental state;
- mastery;
- equipment modifiers;
- UI;
- save data.

Maintain compatibility with existing saves where reasonably possible.

Extend the automated test suite to cover:

- skill unlocking;
- skill mastery persistence;
- ability-specific restoration requirements;
- partial restoration;
- equipment ability modifiers;
- save/load;
- unavailable-skill behaviour;
- at least one multi-ability restoration sequence.

Preserve the currently passing test suite.

---

# Immediate implementation milestone

Do not attempt to build the entire eventual skill tree in one uncontrolled pass.

For this iteration, produce a complete playable **Broken Ford ability-progression vertical slice**:

1. Keep Mend as the starting ability.
2. Implement Force as a learnable main-journey skill using existing Force code where possible.
3. Implement Anchor as a second distinct learnable skill.
4. Create the underlying framework for future Weave, Channel and Bloom.
5. Convert at least three of the existing six restoration sites so they require or substantially benefit from different abilities.
6. Allow at least one site to be discovered before the player has the necessary technique and completed later.
7. Add individual mastery/progression for the implemented abilities.
8. Add several actual skill upgrades that alter behaviour.
9. Add at least two pieces of equipment that modify skill behaviour rather than only statistics.
10. Preserve visible equipped gear.
11. Add the necessary touch UI for switching/using abilities without cluttering the screen.
12. Persist all new progression through saving/loading.
13. Extend tests accordingly.

After implementing it, play through or systematically inspect the complete Broken Ford route and tune the progression so acquiring a new ability feels like the player has genuinely learned a **new way of interacting with the world**.

---

# North star

**Broken Ford is not a game about upgrading Mend.**

It is a game about **becoming a Waykeeper**.

The player begins knowing how to heal simple wounds.

Over the course of the adventure they learn to manipulate force, stabilize unstable systems, reconnect relationships, carry energy, encourage life, and eventually combine these techniques in sophisticated ways.

Progression should expand the player's **vocabulary**, not merely their numbers.

Gear changes how that vocabulary behaves.

Mastery deepens individual techniques.

Exploration exposes situations the player may not yet understand.

Returning later with new knowledge reveals new possibilities.

Restoration remains the purpose behind all of it.

Preserve that identity while making the moment-to-moment game substantially deeper.
