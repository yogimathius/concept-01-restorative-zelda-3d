# The Broken Waterway — first market test

Status: preparation for an **uncoached Android playtest**, 2026-09-29. This tests whether the opening makes people want to continue. It is not a store launch or a claim that the larger open world is complete.

## Build under test

- Use the normal two-chapter journey. The separate river-valley prototype has its own package and save and is not the current test product.
- Export preset `Android Market Test` produces `builds/android/broken-waterway-market-test-debug.apk` with package `dev.gamelab.brokenwaterway.playtest`. Its data is separate from the existing `dev.gamelab.restorativezelda3d` install, protecting the owner's journey save. This is a sideload/debug identity, **not** the eventual Google Play package choice.
- Public-facing app label: **The Broken Waterway Playtest**. The main Android label is **The Broken Waterway**. The legacy source directory and package ID remain unchanged for save compatibility.
- The prototype Master bus stays muted at the owner's request. Tell testers audio is intentionally absent; do not score the music/sound mix in this round.
- Give each tester a clean first launch on their own device. Never clear the owner's main package. Record APK SHA-256 and Godot version in the session sheet.
- Build and validate without opening a window: `bash dev/build_market_test.sh`. Rebuild after any gameplay or export-setting change; an older APK is not evidence for newer code.

## What this round must learn

1. Can a new player explain the Waykeeper's purpose after the first restoration, without a briefing?
2. Can they use touch controls, Mend, Force and a chosen reward without coaching?
3. Do water, people and routes visibly change enough that restoration feels consequential?
4. Do they want to explore past the Ford into Reedglass Marsh? Which promise attracts them: restoring places, story/NPCs, techniques/builds, or the wider world?
5. Does the game's current scope and visual quality support a public demo, and what breaks that impression?

Do not ask testers to imagine future cities, an integrated open world, or mechanics that this build does not contain.

## Preparation evidence — 2026-09-29

- Full headless regression: **203 passed, 0 failed**. After the last objective-card adjustment, the five focused opening tests also passed.
- The isolated APK exported headlessly and passed `dev/verify_market_test.sh`: API 36, expected package and label, ZIP alignment, APK signature and no INTERNET permission. Final playtest artifact SHA-256: `11faa426df666bca2864bc05fc8a79b4a58ba2d8fd746abbd77c1b8ab28575aa`.
- It installed and launched on the already-running **headless Android emulator**. The initial objective card now sits clear of the hero, collapses to a small title after a short reading interval and reopens by touch. Captures: `builds/playtest/market-test/emulator-objective-compact.png`, `emulator-objective-collapsed.png` and `emulator-objective-tap.png`. Captured runtime had no Godot script error or Android crash; emulator graphics warnings remain. The app was stopped afterward.
- This is a startup/UI smoke check, not an uncoached route or physical-phone performance result. The launcher still uses the default Godot icon/splash, which needs a branded production pass.

## Session format

Recruit 8–12 people who have not worked on the game, including several who rarely play action RPGs. Use actual Android phones, including a representative midrange device. One facilitator observes; they do not explain mechanics. Ask permission before screen recording or collecting contact details.

**Invitation text:** “Please play this unfinished mobile game for up to 30 minutes. Start from a fresh save and play as you normally would. You can stop whenever you want. We are testing the game, not you.”

**Observer sheet, one row per player:** device/model/Android version; build hash; start/stop time; first voluntary stop; time to talk to Mara, first Mend, first visible restoration, first reward choice, Force use, spring recovery, return to changed basin, Marsh entry; help requested; intervention and reason; crashes/soft locks; misunderstood buttons or targets; exact player words that indicate what they believed happened. If a player is stuck for three minutes, ask what they are trying to do before offering one neutral hint; mark the result as assisted.

**After play, ask without leading:**

1. What do you think happened to the first place you restored? What changed for anyone living here?
2. When did you feel unsure what to do next?
3. Which action or reward would you want to try again? Which felt unnecessary?
4. What would you expect to find if you kept playing for another hour?
5. What felt distinctive? What looked or felt unfinished?
6. Would you choose to play another build when available? Ask for contact only if they volunteer.

Then show a truthful one-line concept — “A touch-first 3D RPG about restoring a living watershed, learning Waykeeper techniques, and seeing communities adapt” — and ask whether it matches the game they just played. Record mismatches verbatim. Do not quote a hypothetical price until the product scope and platform are decided.

## Readout and decision

Report **observed behavior separately from opinions**. Include completion counts, median time to first restoration and Force recovery, assisted steps, crashes, device failures, recurring confusion, and the strongest/weakest player quotes. Keep the raw notes anonymous unless participants explicitly opt in to attribution.

An opening benchmark is ready for a wider public demo only after several uncoached players can finish the Mara → grove → reward → Iona/Force → changed basin route, can explain what restoration did, and the median route time is near the intended 10–15 minutes. Any repeated blocker or save loss requires a fix and retest. A market signal is stronger when players independently ask to continue or return for the next build; questionnaire enthusiasm alone is weak evidence.

The technical gate remains **stable 30 FPS on a representative midrange Android phone**, with load time, heat, battery, touch latency, memory and restoration effect spikes recorded. Emulator and desktop results are diagnostics, not substitutes. The named S24 is a useful first real device but does not stand in for midrange hardware.

## Store preparation ledger

| Area | Current state | Next action |
| --- | --- | --- |
| Test build | Separate Android market-test preset; debug APK for direct testers | Verify exported label, SDK, permissions, signature, launch and save isolation |
| Final package identity | Main legacy package and a temporary playtest package exist | Choose permanent package ID before a Play Console listing; document update/save migration policy |
| App title | Main and playtest labels use The Broken Waterway | Check title availability and settle final branding before public marketing |
| Engine/API | Existing APK targets Android API 36 | Verify each candidate artifact; keep up with Play requirements |
| Permissions/data | No network client found in gameplay scripts; market preset disables INTERNET | Verify manifest, all embedded SDKs, actual data collection and privacy statement before a store upload |
| Licensing | MakeHuman CC0 provenance is local; virtual joystick MIT notice is local | Audit all imported art/audio/fonts/addons and include required notices in distribution |
| Assets | Current Android launcher icons are unset | Make final icon, feature graphic, screenshots and honest store copy after visual review |
| Release artifact | Debug APKs only | Configure release signing, versioning and a signed AAB when the permanent package/Play account are chosen |
| Human/device evidence | Automated route and emulator checks exist; uncoached and physical-phone gates open | Run sessions above, then fix and retest the highest-frequency issues |

Google Play currently requires new mobile apps to target API 36, uses Android App Bundles for new Play releases, and asks publishers for Data safety declarations. New personal developer accounts created after 2023-11-13 may also need a 12-person, 14-day closed test before production access. Recheck official policy when submitting: [target API](https://support.google.com/googleplay/android-developer/answer/11926878), [releases](https://support.google.com/googleplay/android-developer/answer/9859348), [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469), [personal-account testing](https://support.google.com/googleplay/android-developer/answer/14151465).

This test does not need an account, payment system, analytics SDK or live store listing. The user's Play Console account type, final package ID, business model and public-facing privacy information remain owner decisions after the evidence above is collected.
