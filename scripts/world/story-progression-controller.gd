class_name StoryProgressionController
extends Node

const RADIO_SCRIPT := preload("res://scripts/puzzles/radio-puzzle.gd")
const NOTE_SCRIPT := preload("res://scripts/ui/note-reader.gd")
const OBSERVATION_SCRIPT := preload("res://scripts/world/story-observation-controller.gd")

var memory_count := 0
var loop_iteration := 0
var loop_transitioning := false

var _director: Node3D
var _hallway: Node3D
var _horror: Node3D
var _narrative: Node
var _transition: HallwayTransitionLayer
var _radio_ui: CanvasLayer
var _note_ui: CanvasLayer
var _pending_memory_actor: Node
var _observations: Node

func setup(director: Node3D, hallway: Node3D, horror: Node3D, narrative: Node, transition: HallwayTransitionLayer) -> void:
	_director = director
	_hallway = hallway
	_horror = horror
	_narrative = narrative
	_transition = transition
	_observations = OBSERVATION_SCRIPT.new() as Node
	add_child(_observations)
	_observations.setup(_narrative)
	memory_count = int(GameState.has_flag("memory_photo")) + int(GameState.has_flag("memory_cassette")) + int(GameState.has_flag("memory_rabbit"))
	loop_iteration = mini(memory_count, 2)
	_narrative.beat_finished.connect(_on_narrative_finished)
	_transition.transition_finished.connect(_on_hallway_transition_finished)
	if memory_count > 0:
		_hallway.reconfigure_for_memory(memory_count)
	if memory_count >= 3:
		_disable_loop_gate()

func get_prompt(action_id: String, _actor: Node) -> String:
	var observation_prompt: String = str(_observations.call("get_prompt", action_id))
	if not observation_prompt.is_empty():
		return observation_prompt
	if action_id == "phone" and not GameState.has_flag("phone_answered"):
		return "[E] Answer the ringing phone"
	if action_id == "logbook" and GameState.has_flag("phone_briefing_complete") and GameState.has_flag("desk_clock_observation_complete") and GameState.has_flag("lobby_register_observation_complete") and not GameState.has_flag("log_signed"):
		return "[E] Sign the night log"
	if action_id == "fuse_pickup" and GameState.has_flag("floor_notice_observation_complete") and not GameState.has_item("spare_fuse"):
		return "[E] Take the spare fuse"
	if action_id == "fuse_box" and not GameState.has_flag("fuse_installed"):
		return "[E] Install the fuse" if GameState.has_item("spare_fuse") else "[E] Inspect the empty fuse box"
	if action_id == "memory_photo" and loop_iteration == 0 and not GameState.has_flag(action_id):
		return "[E] " + _memory_label(action_id)
	if action_id == "memory_cassette" and loop_iteration == 1 and not GameState.has_flag(action_id):
		return "[E] " + _memory_label(action_id)
	if action_id == "memory_rabbit" and loop_iteration == 2 and not GameState.has_flag(action_id):
		return "[E] " + _memory_label(action_id)
	if action_id == "hallway_loop" and memory_count < 3:
		return "[E] Enter the changed hallway" if memory_count > loop_iteration and _latest_memory_recalled() and _latest_echo_heard() else "Listen to what the memory reveals"
	if action_id == "radio" and memory_count >= 3 and GameState.has_flag("memory_loop_complete") and not GameState.has_flag("radio_solved"):
		return "[E] Tune the radio"
	if action_id == "room_record" and not GameState.has_flag("room_record_started") and not GameState.has_flag("room_record_heard"):
		return "[E] Play the family recording"
	if action_id == "room_drawing" and not GameState.has_flag("room_drawing_seen"):
		return "[E] Inspect the wall drawing"
	if action_id == "final_clue" and GameState.has_flag("room_record_heard") and GameState.has_flag("room_drawing_seen") and bool(_observations.call("final_clue_ready")) and not GameState.has_flag("final_clue_seen"):
		return "[E] Read the child's note"
	if action_id == "exit" and _ending_ready():
		return "[E] Run for the lobby"
	return ""

func handle_action(action_id: String, actor: Node) -> bool:
	if bool(_observations.call("handle_action", action_id)):
		return true
	match action_id:
		"phone":
			return _answer_phone()
		"logbook":
			return _sign_logbook()
		"fuse_pickup":
			return _take_fuse()
		"fuse_box":
			return _install_fuse()
		"memory_photo", "memory_cassette", "memory_rabbit":
			return _collect_memory(action_id, actor)
		"hallway_loop":
			return _enter_hallway_loop(actor)
		"radio":
			return _open_radio(actor)
		"room_record":
			return _play_room_recording()
		"room_drawing":
			return _inspect_room_drawing()
		"final_clue":
			return _open_final_clue(actor)
		"exit":
			if not _ending_ready():
				return false
			_director.finish_ending()
			return true
	return false

func on_radio_solved() -> void:
	if GameState.has_flag("radio_solved") or GameState.has_flag("radio_sequence_started"):
		return
	GameState.set_flag("radio_sequence_started")
	GameState.set_objective("The radio has found a recording in your voice.")
	AudioManager.play_tone("radio_code", 700.0, 0.2)
	_narrative.play([
		"YOUR VOICE: Zero. Zero. Zero. Seven.",
		"YOUR VOICE: I left the rabbit under the bed.",
		"YOUR VOICE: I locked the door from the outside.",
		"The radio clicks off. Room 407 unlocks."
	], "radio_solved", 4.0)

func on_note_closed() -> void:
	if GameState.has_flag("final_clue_seen"):
		return
	GameState.set_flag("final_clue_seen")
	GameState.set_objective("The lights are failing one by one. Listen before you run.")
	_narrative.play([
		"The note is written in your childhood handwriting.",
		"Behind you, the family recording starts again.",
		"The corridor stretches toward a red EXIT light.",
		"Something stands between you and the room you forgot."
	], "chase_ready", 4.0)

func _answer_phone() -> bool:
	if GameState.has_flag("phone_answered"):
		return false
	GameState.set_flag("phone_answered")
	GameState.set_objective("Listen to the manager. The line keeps cutting out.")
	AudioManager.play_tone("phone_click", 440.0, 0.12)
	_narrative.play([
		"MANAGER: You are covering the last shift, yes?",
		"MANAGER: Sign the log. Take the fourth-floor key.",
		"MANAGER: The lights failed outside Room 407.",
		"MANAGER: If someone calls from inside... do not answer twice."
	], "phone_briefing_complete", 5.0)
	return true

func _sign_logbook() -> bool:
	if not GameState.has_flag("phone_briefing_complete") or not GameState.has_flag("desk_clock_observation_complete") or not GameState.has_flag("lobby_register_observation_complete") or GameState.has_flag("log_signed"):
		return false
	GameState.set_flag("log_signed")
	GameState.add_item("floor_key")
	GameState.set_objective("Unlock the fourth-floor door. The elevator is already waiting.")
	return true

func _take_fuse() -> bool:
	if not GameState.has_flag("floor_notice_observation_complete"):
		GameState.set_subtitle("The maintenance notice points to the spare fuse locker.")
		return false
	if not GameState.add_item("spare_fuse"):
		return false
	GameState.set_objective("Find the fuse box at the end of the dark corridor.")
	return true

func _install_fuse() -> bool:
	if GameState.has_flag("fuse_installed"):
		return false
	if not GameState.has_item("spare_fuse"):
		GameState.set_subtitle("One fuse slot is empty. A spare should be stored farther down the corridor.")
		AudioManager.play_tone("empty_fuse_box", 76.0, 0.18, -22.0)
		return true
	GameState.consume_item("spare_fuse")
	GameState.set_flag("fuse_installed")
	GameState.advance_stage(GameState.Stage.FLOOR4_POWERED)
	GameState.set_objective("Wait for the emergency circuit to stabilize.")
	_horror.trigger("fuse_power")
	AudioManager.play_tone("power_restore", 110.0, 0.8, -13.0)
	_narrative.play([
		"The fuse catches. One light wakes up.",
		"A second light answers farther down the hall.",
		"A door slams where there was no door.",
		"The emergency circuit settles into a low hum."
	], "power_stable", 4.0)
	return true

func _collect_memory(action_id: String, actor: Node) -> bool:
	if GameState.has_flag(action_id) or loop_transitioning:
		return false
	var expected: String = ["memory_photo", "memory_cassette", "memory_rabbit"][loop_iteration]
	if action_id != expected:
		return false
	GameState.set_flag(action_id)
	memory_count += 1
	_pending_memory_actor = actor
	GameState.add_item(action_id.trim_prefix("memory_"))
	_horror.trigger(action_id)
	AudioManager.play_tone("memory_%s" % memory_count, 180.0 + memory_count * 55.0, 0.42, -18.0)
	var memory_lines: Array = {
		"memory_photo": ["The photograph shows you outside Room 407, holding the red rabbit.", "Behind the family, the lobby clock is frozen at 00:07."],
		"memory_cassette": ["The cassette contains your voice asking to be let out.", "A second voice whispers: the radio remembers the stopped clock."],
		"memory_rabbit": ["The rabbit's stitched name is yours.", "The corridor was not hunting the missing child. It was bringing you home."]
	}.get(action_id, []) as Array
	GameState.set_objective("Stay still. The object is returning a memory.")
	_narrative.play(memory_lines, action_id + "_recalled", 3.5)
	return true

func _enter_hallway_loop(actor: Node) -> bool:
	if memory_count <= loop_iteration or memory_count >= 3 or loop_transitioning or not _latest_memory_recalled() or not _latest_echo_heard():
		return false
	loop_iteration += 1
	GameState.set_objective("The same corridor returned, but the doors are wrong.")
	AudioManager.play_tone("hallway_turn", 52.0, 1.0, -11.0)
	_run_loop_transition(actor, loop_iteration, true)
	return true

func _open_radio(actor: Node) -> bool:
	if memory_count < 3 or not GameState.has_flag("memory_loop_complete") or GameState.has_flag("radio_solved"):
		return false
	if _radio_ui == null:
		_radio_ui = RADIO_SCRIPT.new() as CanvasLayer
		add_child(_radio_ui)
	_radio_ui.open(_director, actor)
	return true

func _play_room_recording() -> bool:
	if GameState.has_flag("room_record_started") or GameState.has_flag("room_record_heard"):
		return false
	GameState.set_flag("room_record_started")
	GameState.set_objective("Listen to the recording recovered from Room 407.")
	AudioManager.play_tone("room_record", 145.0, 1.2, -16.0)
	_narrative.play([
		"RECORDING: You promised you would come back for us.",
		"CHILD: I put the rabbit where the hallway cannot see.",
		"RECORDING: The door was locked from the outside."
	], "room_record_heard", 4.0)
	return true

func _inspect_room_drawing() -> bool:
	if not GameState.has_flag("room_record_heard") or GameState.has_flag("room_drawing_seen"):
		return false
	GameState.set_flag("room_drawing_seen")
	GameState.set_subtitle("The drawing shows you holding the red rabbit outside Room 407.")
	GameState.set_objective("The final note is waiting at the back of the impossible room.")
	return true

func _open_final_clue(actor: Node) -> bool:
	if not GameState.has_flag("room_entered") or not GameState.has_flag("room_record_heard") or not GameState.has_flag("room_drawing_seen") or not bool(_observations.call("final_clue_ready")) or GameState.has_flag("final_clue_seen"):
		return false
	if _note_ui == null:
		_note_ui = NOTE_SCRIPT.new() as CanvasLayer
		add_child(_note_ui)
	_note_ui.open(_director, actor, "A CHILD'S NOTE", "Mum says the room is only a room if we leave it.\n\nI counted the clock four times. It always stops at 00:07.\n\nIf the hallway starts breathing, run toward the red exit sign.")
	return true

func _on_narrative_finished(flag: String) -> void:
	match flag:
		"desk_clock_observation_complete": GameState.set_objective("Read the night register, then sign the night log.")
		"lobby_register_observation_complete": GameState.set_objective("Sign the night log and take the fourth-floor key.")
		"phone_briefing_complete": GameState.set_objective("Sign the night log and take the fourth-floor key.")
		"floor_notice_observation_complete": GameState.set_objective("Find the spare fuse at the end of the dark corridor.")
		"power_stable": GameState.set_objective("Follow the humming lights into the changed hallway.")
		"radio_solved": GameState.set_objective("Room 407 is open. Do not look behind the door.")
		"room_record_heard": GameState.set_objective("Inspect the drawing, then search the bed and wardrobe.")
		"room_bed_observation_complete", "room_wardrobe_observation_complete", "room_family_table_observation_complete": GameState.set_objective("The last note is waiting at the back of the impossible room.")
		"chase_ready":
			GameState.set_objective("RUN. Follow the red lights to the lobby exit.")
			GameState.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "chase_start")
		"memory_photo_recalled", "memory_cassette_recalled": GameState.set_objective("The corridor remembers another object. Follow it to the impossible corner.")
		"memory_rabbit_recalled":
			GameState.set_objective("The rabbit has opened the impossible corner. Follow the final message.")
		"memory_echo_3":
			GameState.set_objective("The corridor is collapsing around the radio signal.")
			_run_loop_transition(_pending_memory_actor, 3, false)

func _run_loop_transition(actor: Node, iteration: int, teleport_to_start: bool) -> void:
	loop_transitioning = true
	var subtitle := "The elevator bell rings behind you. The corridor returns wrong."
	if iteration >= 3:
		subtitle = "Every light dies. The impossible corner opens toward Room 407."
	var midpoint := func() -> void:
		_hallway.reconfigure_for_memory(iteration)
		if teleport_to_start and actor is Node3D and is_instance_valid(actor):
			actor.global_position = Vector3(0, 0.02, WorldLayout.MEMORY_START_Z)
		if iteration >= 3:
			_disable_loop_gate()
			GameState.set_flag("memory_loop_complete")
			GameState.set_objective("The radio is repeating your voice. Tune it using the stopped clock.")
	if not _transition.play(actor, subtitle, midpoint, _narrative.duration_scale):
		loop_transitioning = false

func _on_hallway_transition_finished() -> void:
	loop_transitioning = false

func _disable_loop_gate() -> void:
	var gate := _director.get_node_or_null("hallway_loop") as StoryInteractable
	if gate == null:
		return
	gate.interaction_enabled = false
	gate.collision_layer = 0
	gate.visible = false

func _memory_label(action_id: String) -> String:
	return {"memory_photo": "Inspect the burned photograph", "memory_cassette": "Take the cassette", "memory_rabbit": "Pick up the red rabbit"}.get(action_id, "Inspect")

func _latest_memory_recalled() -> bool:
	if memory_count <= 0:
		return false
	var memory_id: String = ["memory_photo", "memory_cassette", "memory_rabbit"][memory_count - 1]
	return GameState.has_flag(memory_id + "_recalled")

func _latest_echo_heard() -> bool:
	return bool(_observations.call("memory_echo_ready"))

func _ending_ready() -> bool:
	return GameState.has_flag("memory_photo") and GameState.has_flag("memory_cassette") and GameState.has_flag("memory_rabbit") and GameState.has_flag("radio_solved") and GameState.has_flag("room_record_heard") and GameState.has_flag("room_drawing_seen") and GameState.has_flag("final_clue_seen") and GameState.has_flag("chase_started")
