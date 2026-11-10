# Waykeeper feature research and next build choices

2026-09-27. The player asked to continue building, enhancing and researching.
This supplements the canonical RPG revision; the opening benchmark remains a
candidate until real-player pacing and physical hardware testing are convincing.

## Delivered now — remembered places

MAP → JOURNAL opens a touch journal of observed restoration sites. The opening
grove/current marsh garden is known; other places appear only after discovery,
partial recovery or restoration. All observations come from the actual ecology,
partial progress and saved region snapshots. There is no second quest ledger.

- Read retained recovery percentages, remaining conditions and the next technique.
- Read how the place affects the world, and its guaranteed gear/supply discovery.
- Pin one unresolved place, then use an optional direction/distance hint and map
  ring. The bearing is a straight-line orientation aid, not a navigable route.
- Select a learned technique explicitly from a local journal entry; the journal
  closes without casting, using Flow or spending skill points.
- Scroll the place list and long notes with touch. Scrolling never chooses a row.
- Remember other-region destinations, with a region name instead of a false local
  arrow. Completed sites stop showing navigation; optional irrigation remains.
- Persist the chosen pin in an additive `journal` field of schema 5. Existing
  saves retain progress and begin without a forced destination.

Implementation: `scripts/story/waykeeper_journal.gd`, `scripts/ui/journal_screen.gd`,
`scripts/ui/journal_compass.gd`, existing map and region save adapters. Navigation
refreshes at 10 Hz and creates no particles, meshes or new permanent action buttons.
The journal does not implement new abilities, regions or rewards.

Verification: **172 regression tests passed, zero failures or script errors**.
Five journal tests cover discovery/partial conditions, malformed pins, completion,
optional irrigation, real two-region JSON round trips, legacy saves and touch
scroll/pin/technique selection. Native journal inspection passed; the full existing
opening touch route also passed with zero failures. Android APK journal entry,
discovered spring and pin were inspected in the emulator. Before-update comparison
preserved world snapshots, XP, equipment/inventory, skills and story exactly.
The chosen spring pin survived the final APK update/restart and displayed its
nearby Force requirement; final Android log has no script errors or crashes.
Desktop production saves were not used as fixtures. Captures live in
`builds/playtest/journal/`; physical hardware gates remain open.

## Sources and what they inform

- [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
  recommends large, spaced touch targets, simple controls and avoiding repeated
  inputs. Our application: generous rows, separate PIN/READY actions and gesture
  cancellation while scrolling; preserve three gameplay actions.
- [Stationary interface targets](https://gameaccessibilityguidelines.com/make-interactive-elements-that-require-accuracy-eg-cursor-touch-controlled-menu-options-stationary/)
  explains why moving targets make selection harder. Our application: stationary
  action buttons and no rotating radial menu required for journal actions.
- [Wildmender's official FAQ](https://www.wildmender.com/faq) documents selecting
  and pinning a current quest for guidance, and a journal for item/plant knowledge.
  Our inference: explicit player-chosen tracking suits restorative exploration;
  here it records physical conditions and retained work rather than a task treadmill.
- [Wildmender's developer store description](https://store.steampowered.com/app/1599330/Wildmender/)
  describes springs, plant growth and animal settlement. Our inference: restoration
  can pay off through visible habitat relationships, which fits our existing basin,
  birds and Neri irrigation. Do not import its survival hunger/thirst loop.
- [Terra Nil's developer page](https://freelives.net/games/terra-nil/)
  presents restoring an ecosystem rather than conventional expansion. Our inference:
  habitat-level payoffs are useful references; our action RPG should retain human
  stories, learned techniques and forgiving exploration rather than become a builder.
- [Android power efficiency guidance](https://developer.android.com/games/optimize/power)
  describes the relationship between sustained workload, heat and battery use.
  Our application: measure sustained sessions, profile effects/water/shadows, and
  develop quality options from measured bottlenecks. An emulator cannot establish
  S24 or representative midrange thermal/battery performance.

These are mechanism references, not evidence that the game is original or that a
particular implementation will be enjoyable. Our river-order art and Waykeeper
world language remain the authored identity.

## Next feature candidates in order

| Priority | Candidate | Concrete player payoff | Acceptance before delivery |
| --- | --- | --- | --- |
| 1 | Opening clarity and presentation | Shorter prompts, readable portraits, clearer spatial restoration stages and rewards | Uncoached route, phone-sized review, no extra action buttons |
| 2 | Inhabitant consequences | Restored routes move people, gatherings and resources; journal records observed changes | Real NPC/world behaviour, saved state, no repeated reward farming |
| 3 | Gear build comparison | Compare gained/lost technique behaviour and resource trade-offs before equipping | Accurate whole-loadout preview, visible replacement, legacy gear retained |
| 4 | Two meaningful build relics | A grounding outfit versus a flowing-water outfit; ability effects outrank raw percentages | Real resource/technique effects, understandable drawbacks, meaningful acquisition |
| 5 | Story-led Weave | Lio/Neri reveal why an intact waterway remains disconnected; generous two-target linking | Opening gate satisfied; preview, magnetized selection, cancel/refund, unique mastery and saved site conditions |
| 6 | Channel then living arts | Energy transfer and thriving ecosystems create new return opportunities | Reuse stable state/resource rules; no new permanent resource bars or region rush |

## Design experiments, still unimplemented

- Quietwater equipment: quicker Flow recovery beside restored water, weaker Charge
  retention. Only add the Charge drawback once Channel actually works.
- Keeper's Weight: larger Stability capacity with modest movement reduction.
  Capacity changes must preserve depletion across equip/load; swapping cannot heal.
- Community commissions: authored restoration requests that bring a person or
  resource to a repaired place, with unique rewards; no procedural daily chores.
- Habitat observations: returning reeds, insects, birds and a changed soundscape
  recorded after the player sees them; avoid a giant collectible checklist.
- Optional tap-to-channel accessibility: consider after targeting tests; cancellation,
  movement, menus and focus loss must be clear and safe.
- Story dilemmas: one healthy flow may conflict with another community's need.
  Discuss needs before altering a system; avoid surprise punishment or timed failure.

Do not add these together in one pass. No loot rarity treadmill, combat grinding,
mandatory ecology micromanagement or third-region expansion is proposed here.
