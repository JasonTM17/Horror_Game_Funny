class_name StoryObservationController
extends Node

var _narrative: Node

func setup(narrative: Node) -> void:
	_narrative = narrative

func get_prompt(action_id: String) -> String:
	match action_id:
		"desk_clock":
			if GameState.has_flag("phone_briefing_complete") and not _observation_finished("desk_clock"):
				return "[E] Read the stopped desk clock"
		"lobby_register":
			if GameState.has_flag("phone_briefing_complete") and _observation_finished("desk_clock") and not _observation_finished("lobby_register"):
				return "[E] Read the night register"
		"floor_notice":
			if GameState.has_flag("floor_reached") and not _observation_finished("floor_notice"):
				return "[E] Read the fourth-floor maintenance notice"
		"memory_echo":
			var echo_id := _memory_echo_id()
			if not echo_id.is_empty() and not _observation_finished(echo_id):
				return "[E] Follow the message in the changed hallway"
		"room_bed_observation":
			if GameState.has_flag("room_entered") and GameState.has_flag("room_record_heard") and not _observation_finished("room_bed_observation"):
				return "[E] Search beneath the child's bed"
		"room_wardrobe_observation":
			if GameState.has_flag("room_entered") and GameState.has_flag("room_record_heard") and not _observation_finished("room_wardrobe_observation"):
				return "[E] Inspect the inside of the wardrobe"
		"room_family_table":
			if GameState.has_flag("room_entered") and GameState.has_flag("room_record_heard") and not _observation_finished("room_family_table"):
				return "[E] Inspect the family table"
	return ""

func handle_action(action_id: String) -> bool:
	match action_id:
		"desk_clock":
			if not GameState.has_flag("phone_briefing_complete"):
				return false
			return _start_observation("desk_clock", [
				"The lobby clock is still running, but its second hand never moves.",
				"The display freezes at 00:07 whenever you look away.",
				"Someone has circled the same time in every night log.",
				"In the cracked glass, the elevator doors are standing open behind you."
			], 4.0)
		"lobby_register":
			if not GameState.has_flag("phone_briefing_complete") or not _observation_finished("desk_clock"):
				return false
			return _start_observation("lobby_register", [
				"The register lists every night worker except the shift dated tonight.",
				"A fresh signature has been added beneath the old manager's name.",
				"The ink is still wet, although the pen has no ink cartridge.",
				"The final entry says: DO NOT LET THE CHILD ANSWER THE PHONE."
			], 4.0)
		"floor_notice":
			if not GameState.has_flag("floor_reached"):
				return false
			return _start_observation("floor_notice", [
				"MAINTENANCE NOTICE: FLOOR 4 CLOSED AFTER THE 2007 INCIDENT.",
				"The notice has been signed by a manager who stopped working here years ago.",
				"A hand-written arrow points toward the spare fuse locker.",
				"Below it, a smaller note reads: THE POWER NEVER FAILED."
			], 4.0)
		"memory_echo":
			return _start_memory_echo()
		"room_bed_observation":
			if not GameState.has_flag("room_entered") or not GameState.has_flag("room_record_heard"):
				return false
			return _start_observation("room_bed_observation", [
				"Dust covers the bed, except for one clean hollow in the blankets.",
				"A child's voice under the frame whispers your name once.",
				"The red rabbit was never hidden here. It was waiting somewhere you could see it.",
				"Your own initials are carved into the underside of the frame."
			], 4.0)
		"room_wardrobe_observation":
			if not GameState.has_flag("room_entered") or not GameState.has_flag("room_record_heard"):
				return false
			return _start_observation("room_wardrobe_observation", [
				"The wardrobe is deeper than its back panel should allow.",
				"Scratches on the inside spell the same four digits as the radio clue.",
				"When the door closes, the corridor outside sounds like a bedroom.",
				"A coat in your childhood size is still warm at the shoulders."
			], 4.0)
		"room_family_table":
			if not GameState.has_flag("room_entered") or not GameState.has_flag("room_record_heard"):
				return false
			return _start_observation("room_family_table", [
				"Four plates are set, but only one has dust disturbed around it.",
				"The family photograph on the table has been turned face down.",
				"Under the frame, someone has written: WE WERE WAITING FOR YOU.",
				"The empty chair turns a few degrees when you stop reading."
			], 4.0)
	return false

func final_clue_ready() -> bool:
	return _observation_finished("room_bed_observation") and _observation_finished("room_wardrobe_observation") and _observation_finished("room_family_table")

func memory_echo_ready() -> bool:
	var echo_id := _memory_echo_id()
	return not echo_id.is_empty() and _observation_finished(echo_id)

func _start_memory_echo() -> bool:
	var echo_id := _memory_echo_id()
	if echo_id.is_empty() or _observation_finished(echo_id) or GameState.has_flag(echo_id + "_started"):
		return false
	var memory_count := _memory_count()
	var lines: Array = {
		1: [
			"The wallpaper is damp where the photograph used to hang.",
			"A child's height marks stop at 00:07.",
			"The next door opens only when you stop looking at it.",
			"Something small runs across the ceiling above the impossible corner."
		],
		2: [
			"The cassette hiss is coming from inside the wall.",
			"Your voice counts footsteps that have not happened yet.",
			"The impossible corner is waiting beyond the red room number.",
			"The counting stops only when a second pair of footsteps begins."
		],
		3: [
			"The rabbit's stitched mouth is full of fresh dust.",
			"A second set of footprints ends at the corner and turns back.",
			"The hallway has finished remembering. The radio is awake.",
			"Behind the static, a child is asking why you left the door locked."
		]
	}.get(memory_count, []) as Array
	GameState.set_flag(echo_id + "_started")
	_narrative.play(lines, echo_id, 4.0)
	return true

func _start_observation(id: String, lines: Array, seconds_per_line: float) -> bool:
	var completion_flag := id + "_complete" if id.ends_with("_observation") else id + "_observation_complete"
	if GameState.has_flag(completion_flag) or GameState.has_flag(id + "_started"):
		return false
	GameState.set_flag(id + "_started")
	_narrative.play(lines, completion_flag, seconds_per_line)
	return true

func _observation_finished(id: String) -> bool:
	if id.begins_with("memory_echo_"):
		return GameState.has_flag(id)
	var completion_flag := id + "_complete" if id.ends_with("_observation") else id + "_observation_complete"
	return GameState.has_flag(completion_flag)

func _memory_echo_id() -> String:
	var count := _memory_count()
	if count <= 0 or not GameState.has_flag("memory_%s_recalled" % ["photo", "cassette", "rabbit"][count - 1]):
		return ""
	return "memory_echo_%d" % count

func _memory_count() -> int:
	return int(GameState.has_flag("memory_photo")) + int(GameState.has_flag("memory_cassette")) + int(GameState.has_flag("memory_rabbit"))
