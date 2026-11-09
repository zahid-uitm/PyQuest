# res://scripts/ui/BottomDialogBar.gd
extends CanvasLayer

signal dialog_finished

@onready var overlay_root: Control = $OverlayRoot
@onready var dim_backdrop: ColorRect = $OverlayRoot/DimBackdrop
@onready var left_stage: Control = $OverlayRoot/LeftPortraitStage
@onready var left_portrait: TextureRect = $OverlayRoot/LeftPortraitStage/LeftPortrait
@onready var left_name_plate: PanelContainer = $OverlayRoot/LeftPortraitStage/LeftNamePlate
@onready var left_name_label: Label = $OverlayRoot/LeftPortraitStage/LeftNamePlate/LeftNameLabel

@onready var right_stage: Control = $OverlayRoot/RightPortraitStage
@onready var right_portrait: TextureRect = $OverlayRoot/RightPortraitStage/RightPortrait
@onready var right_name_plate: PanelContainer = $OverlayRoot/RightPortraitStage/RightNamePlate
@onready var right_name_label: Label = $OverlayRoot/RightPortraitStage/RightNamePlate/RightNameLabel

@onready var dialog_box: PanelContainer = $OverlayRoot/DialogBoxPanel
@onready var speaker_title_label: Label = $OverlayRoot/DialogBoxPanel/Margin/VBox/HeaderRow/SpeakerTitleLabel
@onready var mood_badge_label: Label = $OverlayRoot/DialogBoxPanel/Margin/VBox/HeaderRow/MoodBadgeLabel
@onready var skip_btn: Button = $OverlayRoot/DialogBoxPanel/Margin/VBox/HeaderRow/SkipButton
@onready var text_label: RichTextLabel = $OverlayRoot/DialogBoxPanel/Margin/VBox/DialogTextLabel
@onready var next_btn: Button = $OverlayRoot/DialogBoxPanel/Margin/VBox/FooterRow/NextButton
@onready var step_counter_label: Label = $OverlayRoot/DialogBoxPanel/Margin/VBox/FooterRow/StepCounterLabel

const ALEX_PORTRAITS: Dictionary = {
	"calm": "res://assets/sprites/portraits/portrait_alex_calm.png",
	"talk": "res://assets/sprites/portraits/portrait_alex_talk.png",
	"thinking": "res://assets/sprites/portraits/portrait_alex_special.png",
	"special": "res://assets/sprites/portraits/portrait_alex_special.png",
	"determined": "res://assets/sprites/portraits/portrait_alex_aggression.png",
	"aggression": "res://assets/sprites/portraits/portrait_alex_aggression.png",
	"smile": "res://assets/sprites/portraits/portrait_alex_smile.png",
	"sadness": "res://assets/sprites/portraits/portrait_alex_sadness.png",
	"hurt": "res://assets/sprites/portraits/portrait_alex_sadness.png"
}

const ADA_PORTRAIT: String = "res://assets/sprites/portraits/portrait_princess_ada.png"

const BOSS_INFO: Dictionary = {
	1: {
		"name": "NullByte • Dark Syntax Knight",
		"short_name": "NullByte",
		"portrait": "res://assets/sprites/portraits/portrait_nullbyte.png",
		"color": Color("#F43F5E")
	},
	2: {
		"name": "Chronos-If • Infinite Loop Warden",
		"short_name": "Chronos-If",
		"portrait": "res://assets/sprites/portraits/portrait_chronos.png",
		"color": Color("#38BDF8")
	},
	3: {
		"name": "Lambda-Prime • Modular Relic Sovereign",
		"short_name": "Lambda-Prime",
		"portrait": "res://assets/sprites/portraits/portrait_lambda.png",
		"color": Color("#C084FC")
	},
	4: {
		"name": "Vektor-Zero • Catacomb Sequence Lich",
		"short_name": "Vektor-Zero",
		"portrait": "res://assets/sprites/portraits/portrait_vektor.png",
		"color": Color("#F59E0B")
	},
	5: {
		"name": "Ignis-Py • The Guardian of Pythonia",
		"short_name": "Ignis-Py",
		"portrait": "res://assets/sprites/portraits/portrait_ignis.png",
		"color": Color("#FB7185")
	},
	6: {
		"name": "Lord SegFault • The Null Sovereign",
		"short_name": "Lord SegFault",
		"portrait": "res://assets/sprites/portraits/portrait_segfault.png",
		"color": Color("#A855F7")
	}
}

# -------------------------------------------------------------------------
# 1. WORLD ENTRY DIALOG SEQUENCES (Varied each time Alex enters a World)
# -------------------------------------------------------------------------
const WORLD_INTRO_VARIATIONS: Dictionary = {
	1: [
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "calm", "mood_tag": "CALM", "text": "So this is Variable Valley... The air itself hums with raw data streams and glowing runes."},
			{"side": "left", "name": "Adventurer Alex", "mood": "thinking", "mood_tag": "THINKING", "text": "Master PyWizard mentioned that everything in Pythonia begins with storing values in [color=#FCD34D]variables[/color]—integers, floats, strings, and booleans."},
			{"side": "left", "name": "Adventurer Alex", "mood": "determined", "mood_tag": "DETERMINED", "text": "Three Elemental Shrines guard the northern gate. Let's awaken them and draw out NullByte!"}
		],
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "smile", "mood_tag": "SMILE", "text": "Back in Variable Valley! The emerald trees and runic streams never get old."},
			{"side": "left", "name": "Adventurer Alex", "mood": "talk", "mood_tag": "TALK", "text": "Let's make sure my variable assignments and data types are razor-sharp before heading to the Northern Sanctum."}
		]
	],
	2: [
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "calm", "mood_tag": "CALM", "text": "The Chamber of Conditions... Look at those abyssal chasms and laser-locked suspension bridges."},
			{"side": "left", "name": "Adventurer Alex", "mood": "thinking", "mood_tag": "SPECIAL", "text": "A simple variable won't be enough here. I'll need [color=#38BDF8]if / elif / else[/color] branches to unlock the bridge terminals and [color=#38BDF8]for / while[/color] loops to cross safely."},
			{"side": "left", "name": "Adventurer Alex", "mood": "determined", "mood_tag": "AGGRESSION", "text": "Chronos-If thinks he can trap me in an Infinite Loop. Let's prove him wrong!"}
		],
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "thinking", "mood_tag": "SPECIAL", "text": "Those floor rune traps pulse in a strict conditional cycle... Safe when [code]armed == False[/code], deadly when [code]True[/code]."},
			{"side": "left", "name": "Adventurer Alex", "mood": "talk", "mood_tag": "TALK", "text": "Time to check the bridge terminals and awaken the three Control Shrines!"}
		]
	],
	3: [
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "calm", "mood_tag": "CALM", "text": "Whoa... The Relic Vault is massive. Those floating arcane obelisks are channeling pure modular magic."},
			{"side": "left", "name": "Adventurer Alex", "mood": "thinking", "mood_tag": "SPECIAL", "text": "Instead of writing the same spell over and over, the ancients used [color=#C084FC]def[/color] functions, parameters, and [color=#C084FC]return[/color] conduits."},
			{"side": "left", "name": "Adventurer Alex", "mood": "smile", "mood_tag": "SMILE", "text": "Let's invoke the West and East Function Altars and unseal Lambda-Prime's sanctum!"}
		],
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "talk", "mood_tag": "TALK", "text": "The Return Conduit pads are humming with energy. One press of [R] and I can warp straight across the Vault wings!"},
			{"side": "left", "name": "Adventurer Alex", "mood": "determined", "mood_tag": "DETERMINED", "text": "Keep an eye on the Scope Resonance rings—stay in local scope and let's clear these shrines!"}
		]
	],
	4: [
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "calm", "mood_tag": "CALM", "text": "The Catacombs... Every sandstone tile and golden sarcophagus here is numbered starting from [color=#F59E0B]Index [0][/color]."},
			{"side": "left", "name": "Adventurer Alex", "mood": "thinking", "mood_tag": "SPECIAL", "text": "If I step out of bounds, those [code]IndexError[/code] floor spikes will trigger immediately. I'll need [code].append()[/code], [code]len()[/code], and list slicing to navigate this crypt."},
			{"side": "left", "name": "Adventurer Alex", "mood": "determined", "mood_tag": "AGGRESSION", "text": "Let's gather the crypt relics into my inventory list and confront Vektor-Zero!"}
		],
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "talk", "mood_tag": "TALK", "text": "Zero-based indexing from the front, negative indexing [code][-1][/code] from the back... The Catacombs test every sequence trick in the book."},
			{"side": "left", "name": "Adventurer Alex", "mood": "smile", "mood_tag": "SMILE", "text": "No lich is hiding behind a locked portcullis on my watch!"}
		]
	],
	5: [
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "determined", "mood_tag": "AGGRESSION", "text": "The Obsidian Spire... Rivers of molten lava below, and Ignis-Py's throne waiting at the northern summit."},
			{"side": "left", "name": "Adventurer Alex", "mood": "thinking", "mood_tag": "SPECIAL", "text": "Four Elemental Seals block the causeway—Lists, Functions, Control Flow, and Variables. And look, the Mentors from all four realms have gathered in the side sanctuaries!"},
			{"side": "left", "name": "Adventurer Alex", "mood": "smile", "mood_tag": "SMILE", "text": "Everything I've learned across Pythonia leads to this climb. Let's shatter those four seals and face the Guardian!"}
		],
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "talk", "mood_tag": "TALK", "text": "The heat from the magma vents is intense! I'll time my steps when the vents are dormant and ascend the causeway."},
			{"side": "left", "name": "Adventurer Alex", "mood": "determined", "mood_tag": "AGGRESSION", "text": "Hang tight, Pythonia—I'm taking down Ignis-Py today!"}
		]
	],
	6: [
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "determined", "mood_tag": "AGGRESSION", "text": "We're inside the Royal Citadel Sanctum! Look up ahead—Princess Ada is trapped inside that glowing Glitch Prism beside the throne!"},
			{"side": "left", "name": "Adventurer Alex", "mood": "thinking", "mood_tag": "SPECIAL", "text": "All 5 Awakened Boss Generals—NullByte, Chronos-If, Lambda-Prime, Vektor-Zero, and Ignis-Py—have taken positions around the Sanctum alcoves to help me breach SegFault's barrier!"},
			{"side": "left", "name": "Adventurer Alex", "mood": "smile", "mood_tag": "SMILE", "text": "I'll dodge SegFault's live Glitch Beams on the central floor, override all 4 Prism Terminals with the Generals to activate their Field Auras, and then take down Lord SegFault together!"}
		],
		[
			{"side": "left", "name": "Adventurer Alex", "mood": "talk", "mood_tag": "TALK", "text": "Every General's Prism Terminal I override weakens SegFault's arena hazards and charges up our 5-General Siege Assist Bar for the final showdown!"},
			{"side": "left", "name": "Adventurer Alex", "mood": "determined", "mood_tag": "AGGRESSION", "text": "Hold on, Princess Ada—we're breaking you out of that prism!"}
		]
	]
}

# -------------------------------------------------------------------------
# 2. PRE-BOSS BATTLE DIALOG VARIATIONS (Awakened / Taunting / Showdown)
# -------------------------------------------------------------------------
const BOSS_INTRO_VARIATIONS: Dictionary = {
	1: [
		# Variant A: Awakened from slumber
		[
			{"side": "right", "mood": "aggression", "mood_tag": "AWAKENED", "text": "*GRRRK—CLANG!* Who dares disturb my century of hibernation inside the Variable Sanctum?!"},
			{"side": "left", "mood": "talk", "mood_tag": "TALK", "text": "So you're NullByte! Your corrupted variables have been scrambling the valley's harvest records."},
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Insolent fledgling! Half-asleep or not, my uninitialized [code]None[/code] blade will erase your data types from memory!"},
			{"side": "left", "mood": "determined", "mood_tag": "AGGRESSION", "text": "Not a chance! My integers, strings, and booleans are properly declared. En garde!"}
		],
		# Variant B: Taunting Alex
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Hahaha! Look what wandered into my arena—a rookie adventurer who probably still puts quotes around integers!"},
			{"side": "left", "mood": "smile", "mood_tag": "SMILE", "text": "Keep laughing, NullByte. I know the difference between [code]100[/code] and [code]'100'[/code] with my eyes closed."},
			{"side": "right", "mood": "aggression", "mood_tag": "FURY", "text": "Bold words! Let's see how fast you throw a [code]TypeError[/code] under real combat pressure!"}
		],
		# Variant C: Showdown
		[
			{"side": "left", "mood": "determined", "mood_tag": "DETERMINED", "text": "Stand down, NullByte! The three Elemental Shrines of Variable Valley are awakened!"},
			{"side": "right", "mood": "aggression", "mood_tag": "CHALLENGE", "text": "My obsidian armor holds 500 HP of pure corrupted syntax! Show me if your Python declarations can even scratch it!"}
		]
	],
	2: [
		# Variant A: Awakened from temporal stasis
		[
			{"side": "right", "mood": "aggression", "mood_tag": "AWAKENED", "text": "*TICK... TOCK...* My eternal stasis loop has been interrupted! Who broke the [code]while asleep == True[/code] seal?!"},
			{"side": "left", "mood": "smile", "mood_tag": "SMILE", "text": "That would be me, Chronos-If! It's time someone put a [code]break[/code] statement in your loop."},
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Foolish mortal! I will bind you in a nested loop that runs until the end of time!"},
			{"side": "left", "mood": "determined", "mood_tag": "AGGRESSION", "text": "With clean [code]if / elif / else[/code] logic, I'll cut right through your temporal armor!"}
		],
		# Variant B: Taunting Alex
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Another coder steps onto my chasm bridge! Tell me, little hero—do you even remember to put a colon at the end of your [code]if[/code] statements?"},
			{"side": "left", "mood": "talk", "mood_tag": "TALK", "text": "Every colon in place and every block indented by four spaces. You're looking at a master of control flow."},
			{"side": "right", "mood": "aggression", "mood_tag": "CHALLENGE", "text": "Then survive my branching trials, or fall into the chasm of infinite recursion!"}
		],
		# Variant C: Showdown
		[
			{"side": "left", "mood": "thinking", "mood_tag": "SPECIAL", "text": "His clockwork shield shifts between [code]if[/code] branches and [code]for range()[/code] counters... I just need to read the pattern."},
			{"side": "right", "mood": "aggression", "mood_tag": "FURY", "text": "Analyze all you want, Alex! Time itself obeys my conditions!"}
		]
	],
	3: [
		# Variant A: Awakened from meditation
		[
			{"side": "right", "mood": "aggression", "mood_tag": "AWAKENED", "text": "Who invokes my sanctum without passing the sacred arguments?! I was deep in modular meditation!"},
			{"side": "left", "mood": "talk", "mood_tag": "TALK", "text": "Sorry to interrupt your slumber, Lambda-Prime, but I need the Relic Vault's seal unlocked!"},
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "You dare call [code]challenge_sovereign()[/code]?! Without a valid [code]return[/code] value, your spells will evaluate to [code]None[/code]!"},
			{"side": "left", "mood": "determined", "mood_tag": "AGGRESSION", "text": "Good thing my functions always return full arcane power!"}
		],
		# Variant B: Taunting Alex
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "How amusing! A mortal who probably confuses [code]print()[/code] with [code]return[/code] dares to stand before the Modular Sovereign!"},
			{"side": "left", "mood": "smile", "mood_tag": "SMILE", "text": "I know that [code]print()[/code] only displays text while [code]return[/code] sends the real power back to the caller."},
			{"side": "right", "mood": "aggression", "mood_tag": "CHALLENGE", "text": "Hmph! Let us test your parameters and local scope in live combat!"}
		],
		# Variant C: Showdown
		[
			{"side": "left", "mood": "determined", "mood_tag": "DETERMINED", "text": "Both Vault wings are unsealed, Lambda-Prime! Face me!"},
			{"side": "right", "mood": "aggression", "mood_tag": "FURY", "text": "Behold the elegance of reusable destruction! Witness my modular wrath!"}
		]
	],
	4: [
		# Variant A: Awakened from sarcophagus
		[
			{"side": "right", "mood": "aggression", "mood_tag": "AWAKENED", "text": "*KSHHH—AAAARGH!* Three thousand years I slumbered at [code]crypt[0][/code]... Who dares pop me from my royal sarcophagus?!"},
			{"side": "left", "mood": "talk", "mood_tag": "TALK", "text": "Wake up, Vektor-Zero! Your Catacomb sequences are blocking the path to the Guardian's Lair!"},
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Wretched intruder! I shall slice your shield into fragments and banish you with an [code]IndexError[/code]!"},
			{"side": "left", "mood": "determined", "mood_tag": "AGGRESSION", "text": "From index [code][0][/code] to [code][-1][/code], I've got your entire phylactery array mapped out!"}
		],
		# Variant B: Taunting Alex
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Kekeke! Most adventurers who enter my tomb think the first element of a list is at index 1! Shall I prepare your epitaph now?"},
			{"side": "left", "mood": "smile", "mood_tag": "SMILE", "text": "Zero-based indexing is Day One knowledge, Vektor-Zero. Your ancient traps won't fool me!"},
			{"side": "right", "mood": "aggression", "mood_tag": "FURY", "text": "Insolent whelp! Let us see how you handle live list mutations and slices!"}
		],
		# Variant C: Showdown
		[
			{"side": "left", "mood": "thinking", "mood_tag": "SPECIAL", "text": "His phylactery power is stored inside an ordered Python list. If I target the exact indices, his barrier will crumble."},
			{"side": "right", "mood": "aggression", "mood_tag": "CHALLENGE", "text": "Come, seeker of sequences! Face the Undying Array of Vektor-Zero!"}
		]
	],
	5: [
		# Variant A: Awakened from volcanic slumber
		[
			{"side": "right", "mood": "aggression", "mood_tag": "AWAKENED", "text": "*ROOOOAAAR!* The Obsidian Spire trembles! For eons I slumbered beneath the magma core... and a mere mortal awakens me?!"},
			{"side": "left", "mood": "determined", "mood_tag": "AGGRESSION", "text": "Ignis-Py! I've awakened the shrines of all four realms and shattered your four Elemental Spire Seals!"},
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Impressive, young coder... But in my lair, I corrupt live Python code itself! Can you debug my flames while surviving 600 HP of draconic fury?!"},
			{"side": "left", "mood": "smile", "mood_tag": "SMILE", "text": "Variables, loops, functions, lists, and live bug-hunting—bring it all on, Ignis-Py!"}
		],
		# Variant B: Taunting Alex
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "So you defeated NullByte, Chronos-If, Lambda-Prime, and Vektor-Zero... Do not think their isolated trials compare to my Grand Synthesis!"},
			{"side": "left", "mood": "talk", "mood_tag": "TALK", "text": "I'm not fighting alone—the mentors of every realm passed their wisdom on to me."},
			{"side": "right", "mood": "aggression", "mood_tag": "FURY", "text": "Then draw your grimoire, Adventurer Alex! Prove you are worthy of the Crown of Pythonia!"}
		],
		# Variant C: Showdown
		[
			{"side": "left", "mood": "determined", "mood_tag": "DETERMINED", "text": "This is it—the final battle for Pythonia! 600 HP across three raid stages."},
			{"side": "right", "mood": "aggression", "mood_tag": "CHALLENGE", "text": "Show me the pinnacle of your Python mastery, Alex! Let the Final Raid begin!"}
		]
	],
	6: [
		[
			{"side": "right", "mood": "aggression", "mood_tag": "MENACING", "text": "So... the mortal from UiTM Tapah breaches my Obsidian Citadel. Did you really think you could undo my corruption, Alex?!"},
			{"side": "left", "mood": "determined", "mood_tag": "AGGRESSION", "text": "Release Princess Ada, Lord SegFault! The Five Generals are purified, and their keystones are in my hands!"},
			{"side": "right", "mood": "aggression", "mood_tag": "WRATH", "text": "Those five fools were mere pawns. I will overwrite reality itself and crash your mortal soul into nonexistence!"},
			{"side": "left", "mood": "determined", "mood_tag": "RESOLVE", "text": "Not while I can compile Python! En garde!"}
		]
	]
}

# -------------------------------------------------------------------------
# 3. POST-BOSS VICTORY & DEFEAT DIALOG VARIATIONS
# -------------------------------------------------------------------------
const BOSS_VICTORY_VARIATIONS: Dictionary = {
	1: [
		[
			{"side": "right", "mood": "sadness", "mood_tag": "SHATTERED", "text": "Impossible...! My corrupted armor... overwritten by clean, strongly-typed variables?!"},
			{"side": "left", "mood": "smile", "mood_tag": "SMILE", "text": "Your syntax glitches are history, NullByte! Variable Valley is free, and the road to Chapter 2 is open!"}
		],
		[
			{"side": "right", "mood": "sadness", "mood_tag": "DEFEATED", "text": "Ghhk... Not a single [code]NameError[/code] or [code]TypeError[/code]... You truly understand Python data types, adventurer."},
			{"side": "left", "mood": "talk", "mood_tag": "TALK", "text": "That's the power of clean fundamentals. Rest easy now, NullByte!"}
		]
	],
	2: [
		[
			{"side": "right", "mood": "sadness", "mood_tag": "BROKEN", "text": "My... my Infinite Loop! You injected a clean termination condition and shattered my chronometer!"},
			{"side": "left", "mood": "smile", "mood_tag": "SMILE", "text": "Every loop needs a way out, Chronos-If! Thanks for the control-flow workout!"}
		],
		[
			{"side": "right", "mood": "sadness", "mood_tag": "DEFEATED", "text": "Flawless branching... Your [code]if / elif / else[/code] logic anticipated every single one of my temporal strikes."},
			{"side": "left", "mood": "determined", "mood_tag": "VICTORY", "text": "Onward to the Relic Vault!"}
		]
	],
	3: [
		[
			{"side": "right", "mood": "sadness", "mood_tag": "UNSEALED", "text": "Magnificent... Your functions accepted every parameter and returned pure arcane force!"},
			{"side": "left", "mood": "smile", "mood_tag": "SMILE", "text": "Modular code always wins in the long run, Lambda-Prime!"}
		],
		[
			{"side": "right", "mood": "sadness", "mood_tag": "DEFEATED", "text": "My Sovereign barrier has been deconstructed... Take the Vault's blessing, Master of Functions."},
			{"side": "left", "mood": "talk", "mood_tag": "TALK", "text": "Thank you, Lambda-Prime. Next stop: The Catacombs!"}
		]
	],
	4: [
		[
			{"side": "right", "mood": "sadness", "mood_tag": "DEPLETED", "text": "Curse you, coder! You popped every phylactery from my list until [code]len(armor) == 0[/code]!"},
			{"side": "left", "mood": "smile", "mood_tag": "SMILE", "text": "From index [code][0][/code] to the final slice, your sequence is cleared, Vektor-Zero!"}
		],
		[
			{"side": "right", "mood": "sadness", "mood_tag": "DEFEATED", "text": "Even my negative-index illusions couldn't trigger an [code]IndexError[/code] against you... Go, ascend the Obsidian Spire!"},
			{"side": "left", "mood": "determined", "mood_tag": "VICTORY", "text": "Ignis-Py is the only one left. Let's finish this quest!"}
		]
	],
	5: [
		[
			{"side": "right", "mood": "sadness", "mood_tag": "VANQUISHED", "text": "*ROOOAAAR...* Incredible! You debugged my corrupted flames and wove Variables, Loops, Functions, and Lists into one supreme spell!"},
			{"side": "left", "mood": "smile", "mood_tag": "GRANDMASTER", "text": "We did it! The Obsidian Shield is broken and the Crown of Pythonia is unsealed!"},
			{"side": "right", "mood": "calm", "mood_tag": "HONORED", "text": "Stand proud, Adventurer Alex. You have proven yourself a true Python Grandmaster!"}
		],
		[
			{"side": "right", "mood": "calm", "mood_tag": "HONORED", "text": "For centuries I waited for a coder who could synthesize all four pillars under fire... Today, Pythonia has found its champion."},
			{"side": "left", "mood": "smile", "mood_tag": "SMILE", "text": "What an adventure! Every bug patched and every trial conquered!"}
		]
	],
	6: [
		[
			{"side": "right", "mood": "sadness", "mood_tag": "PURGED", "text": "N-No...! My null-pointer tendrils... severed! The compiler core is restoring...! CURSE YOU, ALEEEEX...!"},
			{"side": "left", "mood": "smile", "mood_tag": "TRIUMPH", "text": "Process Purged: Error Code 0. The stasis prism is shattered! Pythonia is saved, Princess Ada!"}
		]
	]
}

const BOSS_DEFEAT_VARIATIONS: Dictionary = {
	1: [
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": " Bwahaha! Your shield hit [code]0[/code] HP! Come back when you learn how to assign a variable without a [code]SyntaxError[/code]!"},
			{"side": "left", "mood": "sadness", "mood_tag": "HURT", "text": "Ugh... My shield gave out. Let me review the variable rules and rematch him!"}
		]
	],
	2: [
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Trapped in my loop! Without proper [code]if / else[/code] conditions, you will repeat this defeat forever!"},
			{"side": "left", "mood": "sadness", "mood_tag": "HURT", "text": "I misread the loop condition... Let's recalibrate my logic and try again!"}
		]
	],
	3: [
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Your spell returned [code]None[/code], young mage! Study your [code]def[/code] declarations and parameters before challenging me again!"},
			{"side": "left", "mood": "sadness", "mood_tag": "HURT", "text": "I'll fix my function return values and break your barrier next round!"}
		]
	],
	4: [
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Kekeke! [code]IndexError: list index out of range[/code]! Back to the crypts with you, mortal!"},
			{"side": "left", "mood": "sadness", "mood_tag": "HURT", "text": "Off by one index... I won't fall for that sequence trap twice!"}
		]
	],
	5: [
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "My volcanic bugs overwhelmed your shield, Alex! Only a coder who masters every Python fundamental can survive my lair!"},
			{"side": "left", "mood": "sadness", "mood_tag": "HURT", "text": "So close... Let me trace those buggy lines carefully and jump back into the raid!"}
		]
	],
	6: [
		[
			{"side": "right", "mood": "aggression", "mood_tag": "TAUNT", "text": "Segmentation Fault (Core Dumped)! Your code was too frail to withstand the supreme compiler of the void!"},
			{"side": "left", "mood": "sadness", "mood_tag": "HURT", "text": "Ugh... His glitch attacks are vicious. I need to focus my syntax and break through!"}
		]
	]
}

var _lines: Array = []
var _current_idx: int = 0
var _is_typing: bool = false
var _type_tween: Tween = null
var _active: bool = false

func _ready() -> void:
	layer = 115
	overlay_root.visible = false
	skip_btn.pressed.connect(_on_skip_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	dialog_box.gui_input.connect(_on_box_gui_input)
	dim_backdrop.gui_input.connect(_on_box_gui_input)

func is_dialog_active() -> bool:
	return _active

# Flow 1: World Entry Dialog
func play_world_intro(world_num: int) -> void:
	var variants: Array = WORLD_INTRO_VARIATIONS.get(world_num, WORLD_INTRO_VARIATIONS[1])
	var chosen: Array = variants[randi() % variants.size()].duplicate(true)
	for entry in chosen:
		entry["left_name"] = "Adventurer Alex"
		entry["left_portrait"] = ALEX_PORTRAITS.get(entry.get("mood", "calm"), ALEX_PORTRAITS["calm"])
		entry["show_right"] = false
	play_sequence(chosen)

# Flow 2: Pre-Boss Fight Dialog
func play_boss_intro(world_num: int) -> void:
	var b_info: Dictionary = BOSS_INFO.get(world_num, BOSS_INFO[1])
	var variants: Array = BOSS_INTRO_VARIATIONS.get(world_num, BOSS_INTRO_VARIATIONS[1])
	var chosen: Array = variants[randi() % variants.size()].duplicate(true)
	var formatted: Array = []
	for raw in chosen:
		var side: String = raw.get("side", "left")
		var alex_mood: String = raw.get("mood", "determined") if side == "left" else "calm"
		formatted.append({
			"side": side,
			"name": "Adventurer Alex" if side == "left" else b_info["name"],
			"left_name": "Adventurer Alex",
			"right_name": b_info["short_name"],
			"left_portrait": ALEX_PORTRAITS.get(alex_mood, ALEX_PORTRAITS["calm"]),
			"right_portrait": b_info["portrait"],
			"show_right": true,
			"mood_tag": raw.get("mood_tag", "TALK"),
			"theme_color": Color("#38BDF8") if side == "left" else b_info["color"],
			"text": raw.get("text", "")
		})
	play_sequence(formatted)

# Flow 3: Post-Boss Victory or Defeat Dialog
func play_boss_outro(world_num: int, is_victory: bool) -> void:
	var b_info: Dictionary = BOSS_INFO.get(world_num, BOSS_INFO[1])
	var source_dict: Dictionary = BOSS_VICTORY_VARIATIONS if is_victory else BOSS_DEFEAT_VARIATIONS
	var variants: Array = source_dict.get(world_num, source_dict[1])
	var chosen: Array = variants[randi() % variants.size()].duplicate(true)
	var formatted: Array = []
	for raw in chosen:
		var side: String = raw.get("side", "left")
		var default_alex_mood: String = "smile" if is_victory else "sadness"
		var alex_mood: String = raw.get("mood", default_alex_mood) if side == "left" else default_alex_mood
		formatted.append({
			"side": side,
			"name": "Adventurer Alex" if side == "left" else b_info["name"],
			"left_name": "Adventurer Alex",
			"right_name": b_info["short_name"],
			"left_portrait": ALEX_PORTRAITS.get(alex_mood, ALEX_PORTRAITS["calm"]),
			"right_portrait": b_info["portrait"],
			"show_right": true,
			"mood_tag": raw.get("mood_tag", "TALK"),
			"theme_color": Color("#34D399") if side == "left" else b_info["color"],
			"text": raw.get("text", "")
		})
	play_sequence(formatted)

func play_sequence(lines: Array) -> void:
	if lines.is_empty():
		dialog_finished.emit()
		return
	_lines = lines
	_current_idx = 0
	_active = true
	overlay_root.visible = true

	# Pop-in animation at bottom of screen
	dialog_box.modulate.a = 0.0
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(dialog_box, "modulate:a", 1.0, 0.2)

	_show_line(_current_idx)

func _show_line(idx: int) -> void:
	if idx >= _lines.size():
		_finish_sequence()
		return

	var line: Dictionary = _lines[idx]
	var side: String = line.get("side", "left")
	var show_right: bool = bool(line.get("show_right", false))

	left_stage.visible = true
	right_stage.visible = show_right

	var l_path: String = line.get("left_portrait", "")
	if l_path.is_empty():
		if line.get("left_name", "") == "Princess Ada" or line.get("name", "") == "Princess Ada":
			l_path = ADA_PORTRAIT
		else:
			l_path = ALEX_PORTRAITS.get(line.get("mood", "calm"), ALEX_PORTRAITS["calm"])
	if not ResourceLoader.exists(l_path):
		l_path = "res://assets/sprites/portraits/portrait_alex.png"
	if ResourceLoader.exists(l_path):
		left_portrait.texture = load(l_path)

	left_name_label.text = line.get("left_name", "Adventurer Alex")

	if show_right:
		var r_path: String = line.get("right_portrait", "")
		if r_path.is_empty():
			if line.get("right_name", "") == "Princess Ada":
				r_path = ADA_PORTRAIT
			else:
				r_path = "res://assets/sprites/portraits/portrait_nullbyte.png"
		if not ResourceLoader.exists(r_path):
			r_path = "res://assets/sprites/portraits/portrait_pywizard.png"
		if ResourceLoader.exists(r_path):
			right_portrait.texture = load(r_path)
		right_name_label.text = line.get("right_name", "Boss")

	# Highlight active speaker bust & dim passive bust
	var l_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if side == "left":
		l_tw.tween_property(left_portrait, "scale", Vector2(1.05, 1.05), 0.2)
		l_tw.parallel().tween_property(left_portrait, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)
		if show_right:
			l_tw.parallel().tween_property(right_portrait, "scale", Vector2(0.92, 0.92), 0.2)
			l_tw.parallel().tween_property(right_portrait, "modulate", Color(0.42, 0.42, 0.48, 0.88), 0.18)
	else:
		l_tw.tween_property(left_portrait, "scale", Vector2(0.92, 0.92), 0.2)
		l_tw.parallel().tween_property(left_portrait, "modulate", Color(0.42, 0.42, 0.48, 0.88), 0.18)
		if show_right:
			l_tw.parallel().tween_property(right_portrait, "scale", Vector2(1.05, 1.05), 0.2)
			l_tw.parallel().tween_property(right_portrait, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)

	var spk_name: String = line.get("name", "Adventurer Alex")
	var theme_col: Color = line.get("theme_color", Color("#38BDF8") if side == "left" else Color("#FB7185"))
	speaker_title_label.text = "💬 " + spk_name
	speaker_title_label.add_theme_color_override("font_color", theme_col)

	var m_tag: String = line.get("mood_tag", "TALK")
	mood_badge_label.text = "[ %s ]" % m_tag
	mood_badge_label.add_theme_color_override("font_color", Color("#FCD34D"))

	step_counter_label.text = "%d / %d" % [idx + 1, _lines.size()]
	next_btn.text = "Next ▸" if (idx + 1 < _lines.size()) else "Finish ✓"

	text_label.text = line.get("text", "")
	text_label.visible_ratio = 0.0
	_is_typing = true

	AudioManager.play_npc_chat()

	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	var char_count: int = max(12, text_label.get_total_character_count())
	var dur: float = clampf(float(char_count) * 0.018, 0.35, 1.6)
	_type_tween = create_tween()
	_type_tween.tween_property(text_label, "visible_ratio", 1.0, dur)
	_type_tween.tween_callback(func(): _is_typing = false)

func _on_next_pressed() -> void:
	if not _active:
		return
	if _is_typing:
		if _type_tween and _type_tween.is_valid():
			_type_tween.kill()
		text_label.visible_ratio = 1.0
		_is_typing = false
		return

	_current_idx += 1
	if _current_idx < _lines.size():
		_show_line(_current_idx)
	else:
		_finish_sequence()

func _on_skip_pressed() -> void:
	if not _active:
		return
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_is_typing = false
	_finish_sequence()

func _on_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_next_pressed()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_next_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_skip_pressed()
			get_viewport().set_input_as_handled()

func _finish_sequence() -> void:
	_active = false
	overlay_root.visible = false
	dialog_finished.emit()
