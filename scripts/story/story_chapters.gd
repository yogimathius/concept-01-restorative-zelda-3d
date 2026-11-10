class_name StoryChapters
extends RefCounted
const CAST := {
	"R1":[
		{"id":"iona","name":"Iona","role":"Old bridgekeeper","at":Vector3(30,0,5.5),"color":Color("8070aa")},
		{"id":"mara","name":"Mara","role":"Ford caretaker","at":Vector3(5.5,0,4.0),"color":Color("c39361")},
		{"id":"oren","name":"Oren","role":"Marsh ferryman","at":Vector3(49.0,0,17.3),"color":Color("4c8492")},
	],
	"R2":[
		{"id":"neri","name":"Neri","role":"Marsh gardener","at":Vector3(5.5,0,3.5),"color":Color("a86d85")},
		{"id":"daro","name":"Daro","role":"Reed herbalist","at":Vector3(7.0,0,16.5),"color":Color("648558")},
		{"id":"oren","name":"Oren","role":"Marsh ferryman","at":Vector3(23.5,0,16.5),"color":Color("4c8492")},
	],
}
static func conversation(region: Node, id: String) -> Dictionary:
	var result := _conversation(region,id)
	if region.builder.valley_mode: return ValleyPlaces.conversation(region,id,result)
	if region.region_id != "R2": return result
	if id == "neri" and region.builder.entities.M1.runtime.ecology.states.cultivated:
		result.pages[0] += " The irrigation holds now. I can tend the beds again, and our first harvest is waiting beside the channels."
	if id == "neri" and region.builder.entities.M1.runtime.ecology.states.linked:
		result.pages[0] += " The nursery's water reaches my garden now. I moved the seed trays into the new current; tomorrow's planting will be different."
	if id == "neri" and region.builder.entities.M1.runtime.ecology.states.bloomed:
		result.pages[0] += " The garden has begun a new season. I can harvest its seeds without asking the old beds to carry everything."
	var skill := "force" if id == "neri" else "anchor" if id == "oren" else ""
	var prerequisite := "M1" if skill == "force" else "M2"
	if not skill.is_empty() and region.builder.entities[prerequisite].get("restored",false) and not region.waykeeper.progress.unlocked.has(skill):
		var complete: bool = region.builder.entities.M1.get("restored",false) and region.builder.entities.M2.get("restored",false) and region.builder.entities.M3.get("restored",false)
		var lesson := {"text":"Learn %s · %s" % [WaykeeperDefinitions.SKILLS[skill].name,WaykeeperDefinitions.SKILLS[skill].verb],"action":"learn_"+skill}
		if complete:
			result.options[1] = lesson
		else:
			result.options.insert(0,lesson)
			result.options = result.options.slice(0,2)
		if not complete: result.pages.insert(0,"The nursery needs room for its water. I can show you Force now that the garden is living again." if skill == "force" else "The nursery's water reaches the bell, but its foundation cannot hold the tone. I can teach you Anchor: steady it, then Mend.")
	if id == "neri" and region.builder.entities.M1.get("restored",false) and region.builder.entities.M2.get("restored",false) and not region.waykeeper.progress.unlocked.has("weave"):
		result.pages[0] += " The little ceramic feed between garden and nursery is still severed. Weave could reconnect it."
		result.options[1] = {"text":"Learn Weave · Link","action":"learn_weave"}
	elif id == "neri" and region.waykeeper.progress.unlocked.has("weave") and not region.builder.entities.M1.runtime.ecology.states.linked:
		result.pages[0] += " The two pale relays east of me are close enough to Link. Hold Weave, drag toward the other halo, then release."
	if id == "neri" and region.builder.entities.M1.runtime.ecology.states.linked and not region.waykeeper.progress.unlocked.has("bloom"):
		result.pages[0] += " The water is connected. Bloom can help the garden grow toward what it needs now."
		result.options[1] = {"text":"Learn Bloom · Awaken","action":"learn_bloom"}
	elif id == "neri" and region.waykeeper.progress.unlocked.has("bloom") and not region.story_flags.has("neri_bloom_reward"):
		if region.bloom_growth.completed("M1") and region.bloom_growth.completed("M4"):
			result.options[1] = {"text":"Share the new growth","action":"bloom_reward"}
		else:
			result.pages[0] += " The garden and Daro's willow refuge can grow further once water reaches their roots."
	if id == "daro" and region.builder.entities.M4.get("restored",false) and region.builder.entities.M5.get("restored",false):
		if region.weave_relays.spring_refuge.linked():
			result.pages[0] += " Clear water now reaches the willow roots. Mint has taken in the bed between them; I moved my work there."
			if not region.story_flags.has("daro_link_reward"):
				result.options[1] = {"text":"Share the new herb route","action":"daro_link_reward"}
		else:
			result.pages[0] += " The spring and refuge live, but their old ceramic feed is still severed. Weave could carry water between them."
			result.options[1] = {"text":"Help the willow refuge","action":"daro_link_quest"}
	if id == "daro" and region.builder.entities.M4.runtime.ecology.states.bloomed:
		result.pages[0] += " The willow canopy shelters my cups now. I work beneath it when the current grows rough."
	return result

static func _conversation(region: Node, id: String) -> Dictionary:
	var healed := func(target: String) -> bool: return region.builder.entities.get(target,{}).get("restored",false)
	var main_done: bool = healed.call("M1") and healed.call("M2") and healed.call("M3")
	match id:
		"iona":
			if not healed.call("B1"):
				return {"pages":["I kept watch over this ford when you were a child. Mend the wounded grove first; a steady path will bring you back to me."],"options":[{"text":"I'll restore the grove","action":"close"}]}
			if not region.waykeeper.progress.unlocked.has("force"):
				return {"pages":["You remembered how to Mend. But a wound cannot close around a stone. The spring east of here is alive beneath that blockage.","Our Warden tradition begins with Force: give the world room to recover. Tap near obstructing stone and send a pulse through it. Then change back to Mend."],"options":[{"text":"Learn Force · Pulse","action":"learn_force"},{"text":"I'll return when ready","action":"close"}]}
			if not healed.call("C1"):
				return {"pages":["The stonebound spring is east of us. Force gives it room; Mend brings the water back. Swipe your medallion upward to change techniques. SKILLS also lets you choose.","When water flows again, return to me. There is another tradition I can pass on."],"options":[{"text":"Give the spring room to heal","action":"close"},{"text":"Show me my techniques","action":"skills"}]}
			if not region.waykeeper.progress.unlocked.has("anchor"):
				return {"pages":["Listen to that spring. A Warden doesn't overpower the water; we find what stops it from helping itself.","The southern willows lean on broken roots. Anchor lends them ground to hold. Tap to steady them, then Mend. The stability stays; there is no hurry."],"options":[{"text":"Learn Anchor · Ground","action":"learn_anchor"},{"text":"I'll explore and return","action":"close"}]}
			return {"pages":["Force makes room. Anchor gives ground. Mend remembers life. These are traditions, not ranks that make every problem vanish.","Take my Ferryman's staff and Stonekeeper brooch if you haven't already. They let techniques work together in different ways. Your gear changes the way you restore."],"options":[{"text":"Accept Iona's equipment","action":"iona_gear"},{"text":"Open my skill loadout","action":"skills"}]}
		"mara":
			if healed.call("C1") and not region.story_flags.has("opening_return_seen"):
				return {"pages":["Listen, waykeeper. The ford is flowing again. The basin is filling. Those cups have waited dry since the Stillfall; tonight we can set a place for everyone again.","You gave the grove its crossing, then freed the spring to feed our home. Repairing stone mattered because people live downstream. Come sit with us whenever the road feels long."],"options":[{"text":"The waterway feels like home again","action":"mara_return"},{"text":"I will keep following the water","action":"close"}]}
			if healed.call("B1") and not region.waykeeper.progress.unlocked.has("force"):
				return {"pages":["You brought our crossing back. Iona is waiting just beyond the bridge. She kept the ford before I did; she can show you why the next spring won't heal around its stone.","Mend is our first kindness. The other traditions help us understand what a wounded place needs before it can recover."],"options":[{"text":"I'll speak to Iona","action":"close"},{"text":"Tell me about the Stillfall","action":"mara_history"}]}
			if not region.story_flags.has("mara_met") and healed.call("B1") and healed.call("C1") and healed.call("C3"):
				return {"pages":["That river-mark... welcome home, waykeeper. I can hear the ford flowing again. You brought back our crossings before I even had to ask.","The Stillfall silenced the whole waterway. Oren waits at the east landing; Neri in the marsh is still waiting for a letter. Your work here has opened their way home."],"options":[{"text":"Where should I go next?","action":"mara_intro"},{"text":"Why did the water fall silent?","action":"mara_history"}]}
			if not region.story_flags.has("mara_met"):
				return {"pages":["That river-mark... I'd know it anywhere. Welcome home, waykeeper. I kept your old path clear after the Stillfall storm.","The channels have gone quiet. Our letters, gardens and crossings all depend on them. Mend the grove to the east, then follow the water to its sleeping springs."],"options":[{"text":"I'll help. Where do I start?","action":"mara_intro"},{"text":"Why did the water fall silent?","action":"mara_history"}]}
			if healed.call("B1") and healed.call("C1") and healed.call("C3"):
				return {"pages":["Listen. That's water under the stones again. Oren has waited at the east landing since the storm. Tell him Mara says the marsh is finally within reach."],"options":[{"text":"I'll find Oren","action":"close"},{"text":"Tell me about the Stillfall","action":"mara_history"}]}
			return {"pages":["The withered grove is east of here. Hold Mend near it; the crossing will remember its shape. You can explore at your own pace. Oren will wait at the far landing."],"options":[{"text":"Back to the waterway","action":"close"},{"text":"Open my consumables","action":"pack"}]}
		"neri":
			if region.story_flags.has("marsh_message"):
				if region.story_flags.has("neri_reply_sent"):
					return {"pages":["Oren has my reply. I asked Lio what he saw at the reservoir. The garden is growing differently now; I can keep tending it while his answer travels."],"options":[{"text":"I'll keep tending the waterway","action":"close"},{"text":"Read Lio's message again","action":"read_message"}]}
				if region.story_flags.has("neri_reply_ready"):
					return {"pages":["My reply and a few new seeds are with you. Ask Oren by the sluice bell to carry them upstream. I have moved my work to this writing table until it is on its way."],"options":[{"text":"I'll find Oren","action":"close"},{"text":"Read Lio's message again","action":"read_message"}]}
				return {"pages":["Lio is alive. I keep saying it so it feels real. He closed the upper sluice to protect the reservoir, but his letter cannot tell me what he saw there.","Our garden has changed while he was gone. I want to ask what the upper water needs now before anyone promises to return it to the old course."],"options":[{"text":"Carry Neri's reply","action":"neri_reply_prepare"},{"text":"Read Lio's message again","action":"read_message"}]}
			if main_done:
				return {"pages":["The garden is green, the nursery is singing, and the bell finally answers. Oren heard something catch in the sluice. Please speak to him by the bell."],"options":[{"text":"I'll find Oren by the bell","action":"close"},{"text":"Tell me about Lio","action":"neri_lio"}]}
			if not region.story_flags.has("neri_met"):
				return {"pages":["Oren brought a waykeeper? Then perhaps the marsh still has a chance. I'm Neri. My brother Lio followed the water upstream before the Stillfall. No letter has come since.","Our kitchen garden, reed nursery and sluice bell carry the same living channel. Restore all three and the bell may carry his reply. The garden needs Mend. Stone chokes the northern nursery: Force opens its feed. The southeast bell needs Anchor to hold its tone, then Mend. Your partial work stays. I can teach Force after the garden; Oren can teach Anchor after the nursery."],"options":[{"text":"Let's make the marsh sing","action":"neri_quest"},{"text":"Tell me about your brother","action":"neri_lio"}]}
			return {"pages":["The garden is just east of me. The nursery is across the northern path. The bell stands in the southeast court. You don't have to rush. Force opens the nursery feed; Anchor steadies the bell. Each one brings us closer to hearing from Lio."],"options":[{"text":"I'll keep restoring","action":"close"},{"text":"Tell me about Lio","action":"neri_lio"}]}
		"daro":
			if healed.call("M5") and not region.inventory.gifts.has("daro_spring"):
				return {"pages":["Clear water! I can smell the mint through it again. You restored my spring before I even had to ask. These cups are yours; you gave the whole reed pocket a fresh start."],"options":[{"text":"Accept Daro's cups","action":"daro_reward"},{"text":"I'll come back for them","action":"close"}]}
			if healed.call("M5"):
				return {"pages":["The spring is clear and my herb cups smell like mint again. Bring me seeds or river crystals and I'll brew for your journey. Your first fresh batch is already in your pack."],"options":[{"text":"Brew a travelling cup","action":"brew"},{"text":"Back to the marsh","action":"close"}]}
			return {"pages":["I'm Daro. I turn seeds and river crystals into travelling cups. Bloom Tea lets Mend reach farther; Reed Cordial puts a little breeze in your step.","Stone chokes my spring southwest of this platform. Your Force can free the water; then Mend it and I'll share my first fresh batch. You can also brew a cup with the supplies you've found."],"options":[{"text":"Brew a travelling cup","action":"brew"},{"text":"I'll visit your spring","action":"daro_quest"}]}
		"oren":
			if region.region_id == "R1":
				if not healed.call("C3"):
					return {"pages":["I can take you into Reedglass when the east spring flows again. Iona teaches beside the first crossing. The fractured spring needs its stones moved and its foundations grounded before Mend can finish it. Follow the path south and east; each change stays saved."],"options":[{"text":"I'll wake the spring","action":"close"}]}
				return {"pages":["You opened the spillway. I thought I'd grown roots waiting here. Neri tends the first marsh garden, and she's waiting for a letter that never came.","The route is gentle now. We can leave for Reedglass whenever you're ready. Your work here will stay; you can come back with me."],"options":[{"text":"Travel to Reedglass Marsh","action":"travel_R2"},{"text":"Keep exploring Broken Ford","action":"close"}]}
			if main_done and not region.story_flags.has("marsh_message"):
				return {"pages":["There it is. The bell's old tone. A sealed reed-letter just slipped out of the sluice; Neri's brother marked it with the same three notes.","'Neri: I'm safe in Counterweight Orchard. I closed the upper sluice to protect the reservoir. The storm didn't break it. Please send a waykeeper. — Lio'", "You've brought the marsh its first answer. Take my messenger's brooch. Neri should hear this from you."],"options":[{"text":"Take the letter to Neri","action":"marsh_message"},{"text":"Leave it with Oren for now","action":"close"}]}
			if region.story_flags.has("neri_reply_ready") and not region.story_flags.has("neri_reply_sent"):
				return {"pages":["Neri's new seed is bound to a reply? I'll carry it upriver when the route is ready. She has asked Lio to explain the reservoir before anyone changes its gate."],"options":[{"text":"Give Oren the reply","action":"neri_reply_send"},{"text":"Return to Broken Ford","action":"travel_R1"}]}
			return {"pages":["The marsh remembers every crossing. Neri is by the western kitchen garden; Daro keeps the reed pocket in the southwest. I'll stay beside this bell until it sings." if not main_done else "Neri's reply is aboard my boat. The orchard is our next journey, but that route still needs preparing." if region.story_flags.has("neri_reply_sent") else "Neri has a letter again. The orchard is our next journey, but that route still needs preparing. You can explore the marsh or return to the ford."],"options":[{"text":"Return to Broken Ford","action":"travel_R1"},{"text":"Stay in Reedglass","action":"close"}]}
	return {"pages":["The waterway is waking."],"options":[{"text":"Continue","action":"close"}]}
