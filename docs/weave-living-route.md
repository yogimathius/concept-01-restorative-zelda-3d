# Weave: Daro's living route

Status: **second playable connection**, 2026-09-27. The first garden and nursery link remains optional and independent. This is an authored expansion of the same touch interaction, not a general network of arbitrary targets.

After Daro's spring (M5) and the willow refuge (M4) are restored, he notices their ceramic feed is severed. His conversation offers a request that appears in the Waykeeper Journal and can be pinned. If Neri has taught Weave after the garden and nursery recover, the player can stand near either relay, hold the technique medallion, drag toward the broad partner halo and release. The link spends 16 Flow, awards 20 XP and three Weave mastery once, and stores `linked` on both sites. The first link is unaffected.

The new water route grows a mint bed between spring and refuge. Daro moves his work there without waiting for player dialogue. The journal changes from a Weave objective to a return visit. Reporting to Daro yields 15 XP, six river scrip and three seeds once. Thereafter, each successful care cycle at M5 yields one additional mint seed, with the existing 120 seconds of active-play cooldown. This makes restoration affect a renewable resource and a person's routine.

**Living Echo** is now a purchasable Mend/Weave node. It requires Living Pulse, Living Conduit, three Mend mastery and six Weave mastery, which the two distinct links can earn. Useful Mend on a care patch at either end of a linked pair contributes half as much care to its partner. The echo stops at 90% and cannot claim the partner's reward. The player's chosen node and partial echoed work persist. This is a narrow cross-skill interaction on connected, already-restored places; it does not yet transfer arbitrary ecological states.

The link, request, reward, care cooldown and balances use the existing version 5 save. Older saves load with unlinked sites. `RestorationInventory` records earned seed grants separately from discovery claims. On load it reconstructs the balance from valid claims, grants and brews, retaining the existing rule that ignores an arbitrary saved balance. The new quest flag is saved through the established story flag whitelist.

## Verification

- Full `bash dev/test.sh`: **195 passed, 0 failed**. Five focused Weave tests cover touch target selection, independent links, Flow/mastery/XP, Daro's request and one-time reward, later care, cooldown, Living Echo purchase and effect, and reload. The older inventory validation test still rejects forged balances.
- `dev/review_weave_living_route.gd`: eleven native route checks passed with Master audio muted, an in-memory journey and no production save writes. Captures in `builds/playtest/weave-living-route/` show Daro's independent movement, the route after reload and the new tree node. The mint bed and tree layout were refined after visual review, and the route passed again.
- The updated main Android APK was installed on the emulator. An isolated Reedglass save exercised an actual medallion swipe after the camera settled: both M4 and M5 recorded `linked`, 20 XP was added and Weave remained equipped. Captures and the resulting isolated save are in `builds/playtest/weave-living-route/`. The first swipe, made while the camera was still travelling from spawn, cycled techniques; waiting for the view to settle resolved it. The emulator's original save was restored byte for byte after each attempt. No script/crash errors appeared in the captured Android log.

## Next

- Test both links and the return conversation on a physical midrange phone for thumb comfort, clarity and frame time. The emulator alone cannot verify hardware performance.
- Extend Echo beyond care only when a second target can receive meaningful transferred restoration under readable world rules. Do not award mastery for empty casts or repeated links.
- Improve how the player learns about multiple links in the world, while keeping 2–3 right-side actions and forgiving targets.
