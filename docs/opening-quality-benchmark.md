# Opening quality benchmark — playable candidate

Canonical [Phase D](rpg-systems-restoration-revision.md) target: a coherent
10–15 minute opening, tested on a representative midrange Android phone.
**The playable presentation pass is implemented. The quality milestone remains
open until real-player pacing, touch feel and physical-phone performance pass.**
Do not begin a full third region or promote Weave ahead of that gate.

## Route to play

1. Arrive at Broken Ford and speak to Mara beside the river marker. She remembers
   the returning Waykeeper and explains who depends on the silent channels.
2. Explore the caretaker's pavilion, dry communal basin and eastward path.
3. Hold Mend near the Homecoming grove. The first place remains mechanically easy.
4. Watch connection, reforming roots, a rising broad crossing, returning water,
   vegetation and the settled living grove. Movement remains available throughout.
5. The first restoration gives the existing 40 XP, level 2, two Skill Points and
   Bloomkeeper's wand. A separate optional reward card opens Gear or Skills.
6. Equip the wand, choose a tree node and cross to Iona. None is auto-selected.
7. Learn Force from Iona, give the stonebound spring room, switch to Mend and
   complete recovery. Unfinished work, clearing and rewards still persist.
8. Return west: the public basin holds water, cups are set out, birds return and
   Mara walks to tend the gathering. TALK recognizes how the upstream spring
   helped people downstream. The remembered return opens the rest of the journey.
9. Continue to Iona's Anchor lesson and both existing chapters at the player's pace.

This route has no forced reading timer, cutscene lock, precise placement, extra
permanent action buttons or repeatable reward farm. Automated route duration is
not evidence of a human 10–15 minute playtime. Measure actual play before tuning.

## Presentation delivered

- Five civilian models replace primitive NPC bodies. The existing credited CC0
  human foundation is adapted to 43-bone rigs, tailored working clothes, aprons,
  porcelain/bronze fittings, defined faces and distinct palettes/hair/props.
  Mara/Neri have a separate jaw treatment. Models are approximately 15.8–16.0k
  triangles; idle, walking and greeting clips are exported as normal animations.
- Conversation portraits show the actual animated NPC under dedicated lighting;
  they render only while talking. The dialog retains touch navigation, two
  actionable choices, a close control and pagination for longer text.
- An authored ceramic living-water grove replaces the opening prototype tree.
  Its restored form grows upward, alongside staged riverglass arcs and moving
  water ribbons. The bridge rises physically while its safe collision is already
  available. Cosmetic presentation never delays saves, gear or progression.
- Ceramic pavilion, gauging pillars, channels, vessels and basin give the opening
  a shared river-order setting. Static dressing is grouped into MultiMeshes.
- World kit outlines were removed to reduce broken black contours and noise.
  Hero/equipment materials and authored appearances are preserved.
- Original 24-second sparse reed-bell motif, water and bird loops are generated
  offline. Habitat layers fade with restoration/healthy water. This establishes
  audio direction; it does not claim final recorded music or sound production.
- A brief, gentle camera widening frames major recovery without taking controls.
- First reward guidance is optional, separated from objectives and kept near the
  grove. A compact explicit 100% confirmation stays visible during recovery;
  Unmoored guidance remains visible beside NPCs. During major restoration the
  world has room to show its physical change.

## Save continuity

Save schema remains 5. `opening_reward_seen` and `opening_return_seen` extend the
existing validated story flags. No resource, XP, mastery, purchased node, inventory,
consumable, region state or earned reveal is reset. Completed older places derive
the new basin/garden/NPC state without playing completion VFX or introductory
rewards again. The return conversation remains available to older visitors.

The developer preview uses **its own save**,
`user://opening-benchmark-preview.json`; the normal production journey remains
`user://restoration-journey.json`. Normal game launch still resumes that journey.

## Implementation map

- `scripts/presentation/opening_journey.gd`: opening beats, reward choice,
  delayed presentation feedback and Mara's return location.
- `opening_waterway.gd`, `river_craft.gd`: authored reusable craft vocabulary,
  batched dressing and derived living settlement state.
- `restoration_presentation.gd`: bounded staged cosmetic response/recovery.
- `waterway_soundscape.gd`: adaptive habitat/music layers.
- `scripts/ui/conversation_portrait.gd`, `dialogue_screen.gd`: lit native portraits
  and phone-sized conversation layout.
- `scripts/story/story_npc.gd`: human models and routine/greeting animation.
- `art/characters/build_inhabitants.py`, `build_homecoming_grove.py`: reproducible
  Blender source. See `art/source/makehuman` for human asset credit/license.
- `art/audio/build_soundscape.py`: original deterministic audio source.
- `tests/unit/test_opening_benchmark.gd`: partial progress, immediate safe
  completion, player-selected growth, persistence, consequences, legacy continuity
  and civilian geometry/animation contracts.
- `dev/review_opening_benchmark.gd`: actual screen-touch walkthrough, snapshots
  and desktop frame samples. Isolated fixture never writes the production save.
- `dev/play_opening_benchmark.gd`: separate persistent opening playtest.

## Verification

- Full automated regression: **167 passed, 0 failed**, including an Android
  export check for both runtime region map files.
- Five new opening tests cover retained healing, immediate gameplay completion,
  paid growth, inhabited return, legacy saves and civilian assets.
- Final portrait/reward checks: five opening and eight story tests passed without
  script errors. A focused verbose dialogue run confirmed the portrait is cleaned
  up at shutdown. The headless runner retains its pre-existing dummy-renderer
  null-material messages in kit fixtures and audio-reference shutdown warnings;
  native walkthroughs had no script errors.
- The final full regression rerun passed all 166 tests. A native caption check
  confirmed the 100% label remains visible and the panel shrinks below 50 logical
  pixels. The focused Unmoored test also passed after the opening HUD changes.
- Native screen-touch route passed Mara, walking, first Mend, chosen tree node,
  visible equipment, Iona/Force, the spring and social return, then JSON reload.
  Screenshots are `builds/playtest/opening-benchmark/*.png`.
- The final desktop sample on Apple M2 Max at 1280×720 measured approximately
  13.6 ms median and 19.0 ms p95, with 76.6 MB of Godot static allocations. These
  are walkthrough frame deltas including menus/captures, not GPU timing or total
  process/GPU memory, and do not establish phone performance.
- The Android debug APK includes the new models, grove, audio and presentation
  scripts. Signature and ZIP alignment verified; package size is about 31.7 MiB.
- Production save was backed up before opening the separate preview and remained
  exactly equal afterward. Normal saved progress was not used as a test fixture.
- No physical Android device was attached when checked.

## Planned player device

- The player specified a Samsung Galaxy S24 for the first physical-phone
  playtest. ADB found no connected device on 2026-09-27.
- Record the exact device variant and Android version when connected, then
  measure the opening on that hardware. No S24 performance results exist yet.
- The representative midrange Android performance gate remains open.

## Android emulator check — 2026-09-27

- At the player's request, launched `godot_lab_phone`: Android 16/API 36,
  arm64, 1080×2400, landscape gameplay with the existing aspect presentation.
- Actual APK launch exposed missing ASCII region maps. Godot's resource export
  did not include runtime-loaded text files; `include_filter="levels/*.txt"`
  now includes both chapter maps. Rebuilt and installed with `adb install -r`.
- Verified Android touch-stick movement, Mara's paginated conversation and
  animated portrait, held Mend with retained partial progress, recovered grove
  and crossing, Level 2/reward card, purchasing Living Pulse, and equipping the
  Bloomkeeper's wand. Restarted the app and verified restored geometry, Level 2
  and the equipped wand; saved JSON retains the purchased node and 40 XP.
- Updated APK signature and ZIP alignment pass. Runtime log has no script errors
  or Android crashes after the packaging fix; emulator shader-cache recompilation
  warnings remain. Screenshots, JSON evidence and log are in
  `builds/playtest/opening-benchmark/emulator/`.
- Emulator is left running at the recovered crossing. Desktop saves were not
  modified. This checks Android functionality; the rest of the opening route,
  uncoached pacing and physical-device performance gates remain open.

## Remaining benchmark gates

The subsequent journal enhancement has **172 passing tests**, a native journal
touch check and a repeated full opening route with zero failures. Android emulator
inspection preserves the prior save and verifies the journal/discovered-site pin.
See [feature research and next choices](feature-research-next.md). This is an
opening clarity enhancement, not completion of the physical-phone/pacing gate.

- Have a player complete the sequence without coaching; record pacing and places
  where targeting, technique switching or reward choice remains unclear.
- Review human character faces, silhouettes, environment and restoration motion
  at actual phone size. Wider regions still contain prototype scenery.
- Test on a real midrange Android phone: frame time, memory, heat/battery, loading,
  touch latency, water/transparency/vegetation/shadow and restoration effect cost.
- Tune the sequence from those results. Desktop samples or a signed APK do not
  satisfy the mobile gate. The milestone is still a candidate until then.
