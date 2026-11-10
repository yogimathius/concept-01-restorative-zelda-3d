# Restorative world economy — implementation and expansion ledger

Status: first playable vertical slice, 2026-09-27. This document tracks the user's request for a larger, more interactive, farmable world. It does not make the Orchard or any speculative Stillfall lore canon.

## Design rule

The Waykeeper earns a living by caring for shared systems. Broken Ford's **river scrip** is issued for maintenance and commissions, rather than coins appearing from healed wildlife. Restoration sites stay restored. Repeatable **care patches** represent new strain, sediment and seasonal withering within otherwise healthy places. Empty casts and already resolved targets yield nothing. No creature needs to be killed for XP, materials or equipment.

Players should understand three scales of work: a unique restoration changes the map and story; routine care provides materials and a modest income; a commission asks them to connect those acts to someone's needs. Later quests should have stronger character and ecological consequences than a task counter.

## Playable now

- Every authored restoration in Broken Ford and Reedglass Marsh has one nearby care patch. It becomes available only after its parent site is restored, keeps partial Mend progress, and returns after 120 seconds of **active play**. Restoring the parent stays permanent. This gives 12 renewable targets across the two chapters; the separate river-valley preview inherits Ford's six.
- Mend completes care and awards two of one material (reed fiber, silt clay or riverglass), one scrip and three character XP. A visible pickup rises and travels to the hero. It grants no technique mastery or one-time discovery again. River moths appear around restored sites and respond to nearby Mend light.
- A 2026-09-28 [living care pass](living-care-world.md) gives all 12 patches authored reed, silt, glass or habitat conditions, three partial-progress visual stages and matching pickup forms. Restored willow habitats gain small reed skippers. MAP shows ready care; JOURNAL has a Care tab with actual yield and cooldown. Mend prioritizes viable unfinished story work over nearby routine care.
- Tavi and Edda inhabit the Ford exchange. Sela and Bryn inhabit the Reedglass exchange, with their own clothing palettes and distinct visible mantle stock. Contextual TALK opens touch menus. Both traders buy surplus materials and unequipped non-starter gear and offer buyback. The stewards share a repeatable care commission: tend three distinct sites in either region, return to either settlement for eight scrip and 15 XP. The first turn-in visibly revives a community reed bed, and the steward remembers it.
- Herbcraft, rivercraft and gemcutting have separate practice ranks. Recipes require character level and craft rank, materials and sometimes scrip. Current results are existing Bloom Tea / Reed Cordial, a visible Reedweave mantle, polished riverglass and a visible Riverglass lens whose Force behavior differs from ordinary charms. Previously earned gear is preserved.
- The existing version-5 JSON journey accepts the new optional economy ledger. It saves scrip, materials, craft practice, patch progress/cooldowns, commission state and turn-ins. Legacy saves start with an empty economy. Activity XP is separate from unique restoration XP; mastery is unchanged. The prototype Master bus stays muted.

Verification: `tests/unit/test_restorative_economy.gd` covers active-play cooldowns, distinct-site commissions, craft gates, gear sale/buyback, save/load, touch dialogue in both settlements, held Mend, the revived reed bed and walkable site placement in Ford, Marsh and the valley preview. The full `bash dev/test.sh` suite passed **190/190**. `dev/review_restorative_economy.gd` produced isolated native screenshots of both exchanges, care and reward pickup in `builds/playtest/restorative-economy/` with no production-save write; its five checks passed. The final separate valley Android APK exported and installed over the existing emulator package. It launched without Godot script errors or AndroidRuntime crashes in the captured startup log; its prior one-restoration / 40-XP save remained intact with the optional economy ledger. An emulator screenshot is in `builds/playtest/restorative-economy/emulator/`. This is runtime/save evidence, not physical-phone performance validation.

## Research informing the structure

Square Enix's [FFXIV Crafting and Gathering Guide](https://na.finalfantasyxiv.com/crafting_gathering_guide/) separates gathering and crafting disciplines. The useful lesson here is **specialized practice**, not copying its item count or market complexity. Our first slice splits herbcraft, rivercraft and gemcutting and makes the requirements visible at the workbench.

Godot's [Saving games guide](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) emphasizes deciding which objects and values persist. This slice adds compact economy data to the existing journey save rather than a second save authority. Cooldowns advance during play only; quitting does not instantly replenish all care work.

## Next playable milestones

1. **Settlement quality pass:** distinct hero-quality bodies and clothing for all four new inhabitants, market canopies and ceramics, benches, ambient work loops, map pins, a short explanation from Mara and Neri of why care has value. Test that a new player discovers each exchange without an arrow or tutorial wall.
2. **Living care interactions:** the first authored reed, silt, glass and habitat forms, stage feedback, pickup forms, map/Journal layer and story-target priority are playable. Next validate targeting and readability with uncoached phone users; expand site-specific world animation and wildlife behavior only where it improves understanding.
3. **Economy depth:** two more settlement vendors with contrasting stock; supply and demand tied to restored water; a small city hub only after its paths and social role are justified. Add clear sell price and buyback UI, wardrobe previews and a non-destructive inventory category view.
4. **Crafting depth:** gathering/care mastery sourced from meaningful unique interactions, recipe discovery through people/places, gem setting and consumables that change restoration choices. Require level **and** relevant practice, with optional gear that changes recipes. Avoid making story completion depend on repetitive patch loops.
5. **Quest depth:** authored requests from Mara, Iona, Oren, Neri and Daro with visible before/after states; repeatable regional maintenance contracts; several quests solved by different technique builds; return conversations and changed routines. Quests can grant XP, scrip, recipes, materials or gear, but one-time story XP remains larger than routine work.
6. **World scale:** expand care opportunities as the open valley is developed. Populate safe routes, banks and settlements with varied low-cost life; maintain 30 FPS midrange Android target. Do not just multiply identical nodes across an empty map.

## Acceptance checks for the next agent

- A touch-only player can find Edda, accept a commission, Mend three distinct care patches, collect and spend scrip, equip an acquired item, craft a consumable, save, reload and explain why the original restored grove remains healthy.
- One repeated care action is valuable but less valuable than a first restoration. Reopening the app does not instantly reset a cooldown or duplicate a commission.
- The exchange reads as inhabited, and its stock or routines eventually respond to water and character needs; it should not become a generic loot kiosk.
- A legacy completed-save player retains all existing chapter progress, unique gear, mastery and skill purchases.
- Full automated suite, a no-coaching touch playthrough, actual phone performance and thermal checks remain gates before claiming this milestone complete.

## Known limitations of this slice

The two exchanges are small settlement markets, not complete towns or cities. Wildlife is a light ecological response, not a creature ecology system. Care sites now have four authored condition types but still share a small reusable presentation kit, and the new NPCs reuse existing meshes with different palettes. Current crafting has only five recipes and no dedicated workbench UI. These are concrete next build targets, not delivered features.
