# Bloom: Neri's new season

Status: **first playable Bloom route**, 2026-09-28. This is a two-place living arts slice in Reedglass, not a complete ecological growth system or a new region.

After Neri's restored garden and nursery are linked with Weave, she can teach Bloom through a touch conversation. The existing technique medallion equips **Awaken**; a tap costs 18 Flow only beside a viable, linked living place. Bloom never replaces Mend or repairs a blocked place. The player first grows a tended seed bed at Neri's kitchen garden. Care at the garden then yields one renewable seed per completed cycle under the existing active-play cooldown. After Daro's spring and willow refuge are also restored and linked, the same technique grows a willow canopy. The refuge becomes a safe shelter: Stability recovers faster while the Waykeeper stands nearby. Daro moves his work beneath it, and both he and Neri recognize the change.

Each distinct growth gives 20 Waykeeper XP and three Bloom mastery once. Neri's journal request points to the garden, the required spring/refuge Weave link, the willow refuge and the return conversation. Reporting both changes yields 20 XP, five river scrip and three seeds once. Repeat taps never spend Flow or earn another reward. The optional garden irrigation remains available after Bloom.

**Living Network** is a chosen hybrid tree node requiring Living Conduit, six Weave mastery and six Bloom mastery. Buying it extends the Bloomed refuge's Stability shelter through the existing spring/refuge Weave link. The spring gains a visible riverglass ring; the player can recover at either end. This adds a spatial build interaction rather than another permanent resource bar.

The two growth states live in M1/M4 ecology as `bloomed`; the journal request and reward use the existing story ledger; purchased Living Network uses the existing tree save. All remain in save schema 5. Older saves keep their restored and linked sites without silently gaining Bloom or a quest reward.

## Verification and next work

- `tests/unit/test_bloom_growth.gd` covers story-gated touch teaching, useful Flow cost, two distinct growths, XP/mastery, care seed and cooldown, Stability recovery, Living Network purchase and shared shelter, one-time quest reward, save/load, and a legacy completed save. Full `bash dev/test.sh`: **199 passed, 0 failed**.
- `dev/review_bloom_growth.gd` passed **14 native checks** across both Weave links, actual medallion taps, NPC movement, the chosen hybrid node and in-memory reload at 800×360 with prototype audio muted. The first canopy obscured the player; it was rebuilt with smaller leaf clusters and the full native route passed again. Captures live in `builds/playtest/bloom-first-route/`.
- The main APK was installed on the Android emulator. `dev/review_bloom_android.py` used isolated save data and actual medallion taps to grow both garden and refuge; both `bloomed` states and mastery events appeared in the resulting save. The original emulator save was restored byte for byte afterward (SHA-256 `761f8639d88d059cfffefe5d835100632d1a9d2ecc51bb5faffa342b8bfd83ce`). Midrange physical-phone visual clarity, frame time, heat and battery use remain unverified.
- Continue with genuinely new growth interactions, such as navigable reedways and living structural support. Avoid turning Bloom into a green reskin of Mend or allowing it to skip ecological prerequisites.
