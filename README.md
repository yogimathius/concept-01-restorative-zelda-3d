# concept-01: restorative Zelda-like (Godot 3D build)

A third take on the same question as the 2D concepts ("does 'heal a
corrupted room' feel good as a real-time verb?"), this time testing
whether a **custom Blender art pipeline** feeding **live 3D rendering
in Godot** can produce a more distinctive look than reusing CC0 tile
packs — the direction chosen after a throwaway Blender style-spike
(bold Freestyle outlines, hard-edged toon shading, dramatic lighting)
read as more exciting than the flat Kenney-tile look used elsewhere in
this repo.

Spec: `docs/superpowers/specs/2026-09-20-concept-01-3d-art-pipeline-design.md`
Plan: `docs/superpowers/plans/2026-09-20-concept-01-3d-art-pipeline.md`

## Current state: step 1 feel lab (2026-09-26)

The HP/sword prototype described below has been replaced by the
transformation-combat core
(spec: `../../docs/superpowers/specs/2026-09-26-concept-01-systems-design.md`,
plan: `../../docs/superpowers/plans/2026-09-26-concept-01-step1-core-feel.md`).
Main scene is `scenes/test/feel_lab.tscn`: the Warden, three training dummies,
a Weight pad (stone), a Charge pad (cyan), and a hazard (purple).

- Keyboard: WASD move, Space/J pulse, Shift dash, F3 state readout.
- Touch: joystick, big orange button = pulse, small blue = dash.
- Tests: `dev/test.sh` (headless, all systems).

The question this build answers: **does the Pulse feel good?** (the Warden's Force verb: an emitted
ring of restorative energy that knocks corruption back; Charger shots are
"sparks")

## What this actually is (original 3D pipeline build, historical)

A from-scratch Godot 3D project (not a fork of `../concept-01-restorative-zelda/`,
whose 2D template and proven mobile pipeline stay untouched):

- One rigged, animated hero character (idle / 4-direction walk / attack),
  modeled and rigged entirely in Blender via a live `blender` MCP
  connection, exported to glTF with all three animations embedded.
- A 5x5 corrupted-tile room (dark, jagged purple shard props) that
  swaps to a 5x5 restored-tile room (saturated green) when the player
  walks up to a heal pedestal and presses interact — the actual core
  loop, verified working both in a scripted headless playtest and live
  on a real Android emulator.
- A custom real-time toon shader: an inverted-hull outline pass plus a
  hard-banded diffuse ramp, built as a Godot `ShaderMaterial` — the
  Blender spike's outline look came from Freestyle, an offline-render
  feature with no runtime equivalent, so this had to be reimplemented
  as an actual shader, not just reused.
- Touch controls ported from the 2D build's proven virtual-joystick
  addon + `TouchScreenButton`s.
- A working `dev/deploy.sh` (export, boot emulator if needed, install,
  launch) mirroring the 2D build's script shape.

## Real bugs hit and fixed while standing this up

1. **Vulkan Forward Mobile renderer couldn't present frames on this
   emulator** — `ERROR: Couldn't present to Vulkan queue (VkResult
   error 5)`, reproducible under both software (SwiftShader) and real
   hardware-GPU-backed Vulkan. Root cause: the 2D build's project
   settings use `gl_compatibility` (GLES3), not the 3D project's
   default `mobile` (Vulkan) — switching this project to
   `gl_compatibility` fixed it immediately. Godot's Compatibility
   renderer supports 3D scenes fine at this fidelity.
2. **Stale emulator crashpad consent dialog blocked/confused boot** —
   an old queued crash report from unrelated (Unity) testing on this
   machine caused a consent-dialog code path to fire on every launch.
   Clearing `~/.android/cli/analytics/crash_reports` and the emulator's
   crash db resolved it.
3. **5x5 corrupted-tile grid invisible** — three compounding bugs, not
   one: (a) the `Ground` box's top surface sat 0.1 units above the
   tiles, fully burying them inside opaque geometry; (b) after fixing
   that, tiles became exactly coplanar with the ground, causing
   z-fighting; (c) after nudging tiles above the ground, they were
   *still* invisible because every object in the scene — ground, hero,
   tiles, props — shared one literal `ShaderMaterial` resource with a
   hardcoded gray `base_color`, so anything successfully toon-shaded
   became visually identical to the ground. Fixed by having
   `ToonUtil.apply_toon()` duplicate the material per-surface and carry
   over each object's own original albedo color.
4. **A tile grid positioned at world x=-15 instead of x=-5..-1** — every
   Blender-exported environment asset (`corrupted_tile`,
   `restored_tile`, `heal_prop`, `dead_tree`, `live_tree`, `enemy`) had
   been authored at a distinct, deliberately-offset world position in
   the shared Blender scene (to keep them visually separated during
   the session) and never recentered to local origin before export —
   so each glTF carried that offset baked in, compounding with the
   in-Godot grid-placement math. Fixed by recentering each object group
   to origin in Blender and re-exporting.
5. **Touch buttons landing in the wrong screen position** — the project
   had no `window/size`/stretch settings at all, so raw pixel
   coordinates copied from the 2D build's `640x360` canvas landed
   somewhere else entirely on this project's default resolution.
   Fixed by matching the 2D build's `window/size` + `canvas_items`
   stretch config exactly.
6. **`Cannot infer the type of variable` GDScript parse errors** — `:=`
   type inference failed on `get_active_material()`'s return in this
   Godot version; needed explicit `: Material` annotations.

## Verified, not claimed

- Scripted headless playtest (simulated input, no display): confirmed
  movement, walk/idle/attack animation switching, and the
  corrupted→restored tile swap firing through the real `Area3D`
  interaction path (25→0 / 0→25 tile counts).
- Real Android emulator (`godot_lab_phone` AVD): signed debug APK
  built, installed, launched, and controlled via actual injected touch
  events (`adb shell input swipe`/`tap`) — not just visually inspected.
  Before/after screenshots confirm the joystick moves the player, and
  a real interact-button tap triggers the room's corrupted-to-restored
  transformation live on-device.

## What's not yet evaluated

Same as every other concept in this repo: whether the core loop is
actually *fun* is still an open question. This build proves the
pipeline (Blender → Godot 3D → Android) and the toon art direction
work end-to-end; a real playtest is the next step, not more building.
