# Weave: first playable connection

Status: **implemented first slice**, 2026-09-27. This is a bounded Reedglass interaction, not the complete future Weave network.

The second authored link, Daro's spring to the willow refuge, is documented in [weave-living-route.md](weave-living-route.md).

After Neri's garden (M1) and the reed nursery (M2) are restored, Neri offers the Link lesson. Two ceramic relays sit east of her, in the garden court. Their damaged feed is visible before linking. Select Weave on the existing technique medallion, stand near either relay, hold, drag toward the other broad screen halo, and release. The relay pair magnetizes within 105 screen pixels. Linking costs 16 Flow; empty gestures and insufficient Flow leave the world unchanged. A short upward medallion swipe still cycles techniques. The same medallion remains usable after travel to Ford, where it gives a useful hint instead of trying to find nonexistent relays.

The link is a physical, persistent change: luminous water appears between the ceramic halves, both garden and nursery ecological records mark `linked`, and Neri moves her work to the new channel. The garden's status and Neri's conversation respond. The link awards 20 Waykeeper XP and three Weave mastery exactly once, with no reward on repeated attempts or reload. Linked water also counts as healthy water for Flow recovery. The optional `Living Conduit` Weaver node, reached through `Spring Attunement` and three Weave mastery, adds four Flow per second near connected water. Purchased nodes stay player choices.

The existing bell and Lio letter route does not require Weave. This protects the playable two-chapter story and older saves while adding a visible deeper restoration. The link is stored in the existing per-site ecology save dictionary; missing `linked` fields migrate to false. There is no new save version.

## Verification

- Full `bash dev/test.sh`: **193 passed, 0 failed**. New coverage exercises Neri's lesson, the actual touch drag, target preview, Flow refusal, one-time XP and mastery, ecological reload, the Weaver node's resource effect, and safely switching away from Weave after returning to Ford.
- `dev/review_weave_relay.gd`: six native route checks passed with Master audio muted. Captures under `builds/playtest/weave-first-link/` show the severed feed, target preview, animated connected water, Neri's independent move, reload and the Weaver tree.
- The main Android debug APK exported and launched on the emulator. Its existing Ford save remained at one restoration and 40 XP. An isolated Reedglass save then exercised an actual Android swipe from the Weave medallion to the garden inlet: both ecology records became linked, three Weave mastery was recorded, and 20 quest XP appeared. The emulator's original save was restored byte for byte after the test. Captured startup and gesture logs contain no Godot script error or Android runtime crash.

## Next Weave work

- Build on the second authored spring/refuge connection; it establishes a different social and renewable-care consequence but still is not a freely configurable network.
- Give the player a return visit after Neri changes her routine, including another character noticing the new water distribution.
- Add a true Weave Echo node only when more than one useful link target exists; do not sell a node that has no playable effect.
- Tune drag reach and screen halo on a physical midrange Android phone. The emulator verifies the touch route, but cannot certify thumb comfort, battery behavior or 30 FPS hardware performance.
