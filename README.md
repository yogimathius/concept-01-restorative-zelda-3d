# The Broken Waterway

*concept-01 — a Godot 3D build, one of several disposable prototypes exploring the same core question across different engines and art pipelines.*

The question this concept tests: does "heal a corrupted place" feel good as a real-time verb, and is a custom Blender-authored, toon-shaded 3D look worth its extra pipeline cost over the CC0 tile packs used in this prototype's 2D siblings? It is not a commercial release — it's a testbed for a mechanic and an art pipeline, and is treated as disposable if either doesn't hold up.

## Status

- **Two playable story chapters** — Broken Ford and Reedglass Marsh — with a full touch control scheme tuned for Android.
- **203 automated tests, all passing** (verified via `dev/test.sh`).
- A **perspective river-valley open-world prototype** is under active design iteration on its own save, alongside the two-chapter journey.
- An isolated **Android market-test build** is ready for uncoached playtests without touching the main install (`dev/build_market_test.sh`).

## Running it

```sh
godot --path .
```

Point `godot` at wherever your Godot 4 editor binary lives. Desktop previews use the same touch control flow as mobile — the mouse emulates a finger.

```sh
bash dev/test.sh
```

runs the full headless test suite (set the `GODOT` env var if your binary isn't in `PATH`).

## What's playable

- **Mend, Force, Anchor** — three restoration techniques taught progressively through the story. Mend heals corruption; Force clears obstructions; Anchor steadies unstable structures. **Weave**, **Channel**, and **Bloom** add world-reconnection, charge-carrying, and growth mechanics in the second chapter.
- A connected 16-node skill tree, a Stability/Flow resource system, restoration-earned gear (15 pieces) with visible equip changes, and brewable consumables.
- Persistent JSON save across both chapters, carried through 5 save-format revisions without resetting progress.

Full system-by-system detail — resource costs, quest structure, save migration specifics — lives in [AGENTS.md](AGENTS.md) and the rest of [docs/](docs/); [docs/roadmap.md](docs/roadmap.md) tracks open follow-ups.

## The actual experiment: a from-scratch 3D pipeline

Nothing here was reused from the 2D sibling concept except the touch-input addon:

- Hero characters modeled and rigged in Blender over a live MCP connection, exported to glTF with animations embedded; later rebuilt on an adapted CC0 MakeHuman base mesh with a 43-bone rig.
- A custom real-time toon shader (inverted-hull outline pass + hard-banded diffuse ramp), reimplementing by hand the look of an offline Blender Freestyle style-spike that has no runtime equivalent.

### Real bugs hit along the way

1. **Vulkan couldn't present frames on the dev Android emulator** (`VkResult error 5`, reproducible on both software and hardware-GPU-backed Vulkan) — the 2D sibling project uses the GLES3 Compatibility renderer, not Vulkan Mobile; switching renderers fixed it immediately.
2. **A stale crash-report dialog silently blocked emulator boot** — leftover crash data from unrelated testing on this machine; clearing `~/.android/cli/analytics/crash_reports` fixed it.
3. **A 5×5 tile grid was invisible for three unrelated reasons stacked together**: the ground mesh buried it, the fix caused z-fighting, and the eventual fix for that exposed every object in the scene sharing one literal `ShaderMaterial` resource with a hardcoded albedo color.
4. **Blender-exported assets carried a baked-in world offset** from how they'd been laid out for visibility in the shared authoring scene; fixed by recentering each to local origin before export.
5. **Touch buttons landed in the wrong screen position** because the project had no explicit window-size/stretch config, so pixel coordinates copied from the 2D build resolved against the wrong resolution.

## Verified, not claimed

A scripted headless playtest exercises movement, animation-state switching, and the corrupted → restored transformation through the real `Area3D` interaction path. A real Android emulator build has been driven with actual injected touch events (`adb shell input swipe`/`tap`), not just visually inspected.

**Not yet evaluated, same as every other concept in this lab: whether the core loop is actually fun.** This build proves the pipeline (Blender → Godot 3D → Android) and the toon art direction work end-to-end. A real playtest is the next step, not more building.
