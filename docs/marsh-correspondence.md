# Reedglass correspondence follow-through

Status: playable two-chapter story extension, 2026-09-29. This builds on Lio's established letter without deciding whether closing the reservoir sluice was right. The Ford's local upper weir remains a separate structure.

## Player sequence

1. When the garden, nursery and bell are restored, a sealed reed letter appears beside the bell. Oren walks from the landing to inspect it. His existing conversation gives the letter and Messenger's brooch once.
2. The player brings Lio's message to Neri. His letter rests on a small ceramic writing tray in her garden. Neri asks what Lio saw at the reservoir and explains that the garden has changed while he was away.
3. A touch choice accepts Neri's reply and new seed. The packet is visible on the Waykeeper while travelling; Neri moves to her writing place. The Journal records the request and points to Oren.
4. Oren takes the packet by the bell. He moves back to the landing, and the reply remains visible there. The handoff grants 15 Waykeeper XP and four river scrip once. Neri returns to her living garden routine.

This is a short social quest with one physical handoff. It asks a question about the reservoir rather than announcing a truth about the Stillfall, Lio, or future Orchard gameplay.

## State and compatibility

`neri_reply_ready` and `neri_reply_sent` are additive story flags in the existing version-5 journey. All props and NPC destinations derive from restored sites and these flags; there is no separate quest reward ledger. Old completed saves retain their letter and can discover the reply quest. The existing two chapters, chapter reward, gear, mastery and restoration stay intact. Repeating the handoff grants nothing.

The phone-sized visual route and uncoached comprehension of the letter sequence still need review. The Godot editor was kept closed at the user's request during this pass.

## Verification

The full headless regression suite passed **203 tests**. The focused story suite passed **9 tests** after checking the new route's touch dialogue, Oren's actual walk on traversable ground, physical letter stages, one-time XP/scrip reward and JSON save/reload. Existing chapter reward and completed-save tests remain passing. This verifies logic and persistence; the world staging still needs a phone-sized visual review when the user is ready to run the game.
