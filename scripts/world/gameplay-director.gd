extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause-menu.tscn")
const ENTITY_SCRIPT := preload("res://scripts/world/chase-entity.gd")
const RADIO_SCRIPT := preload("res://scripts/puzzles/radio-puzzle.gd")
const HALLWAY_SCRIPT := preload("res://scripts/world/dynamic-hallway-controller.gd")
const HORROR_SCRIPT := preload("res://scripts/world/horror-event-director.gd")
const NOTE_SCRIPT := preload("res://scripts/ui/note-reader.gd")
const ENDING_SCRIPT := preload("res://scenes/ui/ending-overlay.tscn")
const FAIL_SCRIPT := preload("res://scenes/ui/fail-overlay.tscn")
const NARRATIVE_SCRIPT := preload("res://scripts/world/narrative-sequencer.gd")

var player: CharacterBody3D
var entity: CharacterBody3D
var _memory_count := 0
var _ending := false
var _radio_ui: CanvasLayer
var _hallway: Node3D
var _horror: Node3D
var _note_ui: CanvasLayer
var _fail_overlay: CanvasLayer
var _narrative: Node
var _loop_iteration := 0
var _recovering := false
var _loop_transitioning := false

func _ready() -> void:
	var fresh_run := GameState.checkpoint.is_empty()
	if fresh_run:
		GameState.reset_run()
	_memory_count = int(GameState.has_flag("memory_photo")) + int(GameState.has_flag("memory_cassette")) + int(GameState.has_flag("memory_rabbit"))
	_loop_iteration = mini(_memory_count, 2)
	ContinuousWorldBuilder.build(self)
	_hallway = HALLWAY_SCRIPT.new()
	add_child(_hallway)
	_hallway.build(self)
	_horror = HORROR_SCRIPT.new()
	add_child(_horror)
	_horror.setup(self, _hallway)
	_narrative = NARRATIVE_SCRIPT.new()
	add_child(_narrative)
	_narrative.beat_finished.connect(_on_narrative_finished)
	_spawn_player()
	ContinuousStoryLayout.build(self)
	if _memory_count >= 3:
		_disable_loop_gate()
	if fresh_run:
		GameState.set_objective("Answer the desk phone and sign the night log.")

func _process(_delta: float) -> void:
	if player == null or _ending:
		return
	var z := player.global_position.z
	if z < WorldLayout.FLOOR_TRIGGER_Z and not GameState.has_flag("floor_reached"):
		GameState.set_flag("floor_reached")
		GameState.advance_stage(GameState.Stage.FLOOR4_DARK)
		GameState.set_objective("The fourth floor is dark. Find the spare fuse.")
		AudioManager.play_tone("door_slam", 58.0, 0.32, -11.0)
	if z < WorldLayout.MEMORY_TRIGGER_Z and GameState.has_flag("power_stable") and not GameState.has_flag("memory_loop_started"):
		GameState.set_flag("memory_loop_started")
		GameState.advance_stage(GameState.Stage.MEMORY_LOOP)
		GameState.set_objective("The hallway has changed. Find three things that remember you.")
	if z < WorldLayout.ROOM_TRIGGER_Z and GameState.has_flag("radio_solved") and not GameState.has_flag("room_entered"):
		GameState.set_flag("room_entered")
		GameState.advance_stage(GameState.Stage.ROOM_407)
		GameState.set_objective("Room 407 is open. Find what was left behind.")
		GameState.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "room_entrance")
	if z < WorldLayout.CHASE_TRIGGER_Z and GameState.has_flag("chase_ready") and not GameState.has_flag("chase_started"):
		_start_chase()

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	var spawn_z := WorldLayout.PLAYER_START_Z
	if GameState.pending_spawn_id == "room_entrance":
		spawn_z = WorldLayout.ROOM_TRIGGER_Z + 3.0
	elif GameState.pending_spawn_id == "chase_start":
		spawn_z = WorldLayout.CHASE_RESPAWN_Z
	player.position = Vector3(0, 0.02, spawn_z)
	add_child(player)
	var hud := HUD_SCENE.instantiate()
	add_child(hud)
	add_child(PAUSE_SCENE.instantiate())
	_fail_overlay = FAIL_SCRIPT.instantiate()
	add_child(_fail_overlay)

func get_story_prompt(action_id: String, _actor: Node) -> String:
	if action_id == "phone" and not GameState.has_flag("phone_answered"):
		return "[E] Answer the ringing phone"
	if action_id == "logbook" and GameState.has_flag("phone_briefing_complete") and not GameState.has_flag("log_signed"):
		return "[E] Sign the night log"
	if action_id == "fuse_pickup" and not GameState.has_item("spare_fuse"):
		return "[E] Take the spare fuse"
	if action_id == "fuse_box" and not GameState.has_flag("fuse_installed"):
		return "[E] Install the fuse"
	if action_id == "memory_photo" and _loop_iteration == 0 and not GameState.has_flag(action_id):
		return "[E] " + _memory_label(action_id)
	if action_id == "memory_cassette" and _loop_iteration == 1 and not GameState.has_flag(action_id):
		return "[E] " + _memory_label(action_id)
	if action_id == "memory_rabbit" and _loop_iteration == 2 and not GameState.has_flag(action_id):
		return "[E] " + _memory_label(action_id)
	if action_id == "hallway_loop" and _memory_count < 3:
		return "[E] Enter the changed hallway" if _memory_count > _loop_iteration else "Find what the hallway is hiding"
	if action_id == "radio" and _memory_count >= 3 and not GameState.has_flag("radio_solved"):
		return "[E] Tune the radio to 0007"
	if action_id == "room_record" and not GameState.has_flag("room_record_started") and not GameState.has_flag("room_record_heard"):
		return "[E] Play the family recording"
	if action_id == "room_drawing" and not GameState.has_flag("room_drawing_seen"):
		return "[E] Inspect the wall drawing"
	if action_id == "final_clue" and GameState.has_flag("room_record_heard") and GameState.has_flag("room_drawing_seen") and not GameState.has_flag("final_clue_seen"):
		return "[E] Read the child's note"
	if action_id == "exit" and GameState.has_flag("final_clue_seen"):
		return "[E] Run for the lobby"
	return ""

func handle_story_action(action_id: String, _actor: Node) -> bool:
	match action_id:
		"phone":
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
		"logbook":
			if not GameState.has_flag("phone_briefing_complete") or GameState.has_flag("log_signed"):
				return false
			GameState.set_flag("log_signed")
			GameState.add_item("floor_key")
			GameState.set_objective("Unlock the fourth-floor door. The elevator is already waiting.")
			return true
		"fuse_pickup":
			if not GameState.add_item("spare_fuse"):
				return false
			GameState.set_objective("Find the fuse box at the end of the dark corridor.")
			return true
		"fuse_box":
			if not GameState.has_item("spare_fuse") or GameState.has_flag("fuse_installed"):
				return false
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
		"memory_photo":
			return _collect_memory(action_id)
		"memory_cassette":
			return _collect_memory(action_id)
		"memory_rabbit":
			return _collect_memory(action_id)
		"hallway_loop":
			if _memory_count <= _loop_iteration or _memory_count >= 3 or _loop_transitioning:
				return false
			_loop_iteration += 1
			if _actor is Node3D:
				_actor.global_position = Vector3(0, 0.02, WorldLayout.MEMORY_START_Z)
			GameState.set_objective("The same corridor returned, but the doors are wrong.")
			AudioManager.play_tone("hallway_turn", 52.0, 1.0, -11.0)
			_run_loop_transition(_actor, _loop_iteration)
			return true
		"radio":
			if _memory_count < 3 or GameState.has_flag("radio_solved"):
				return false
			if _radio_ui == null:
				_radio_ui = RADIO_SCRIPT.new() as CanvasLayer
				add_child(_radio_ui)
			_radio_ui.open(self, _actor)
			return true
		"room_record":
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
		"room_drawing":
			if not GameState.has_flag("room_record_heard") or GameState.has_flag("room_drawing_seen"):
				return false
			GameState.set_flag("room_drawing_seen")
			GameState.set_subtitle("The drawing shows you holding the red rabbit outside Room 407.")
			GameState.set_objective("The final note is waiting at the back of the impossible room.")
			return true
		"final_clue":
			if not GameState.has_flag("room_entered") or not GameState.has_flag("room_record_heard") or not GameState.has_flag("room_drawing_seen") or GameState.has_flag("final_clue_seen"):
				return false
			if _note_ui == null:
				_note_ui = NOTE_SCRIPT.new() as CanvasLayer
				add_child(_note_ui)
			_note_ui.open(self, _actor, "A CHILD'S NOTE", "Mum says the room is only a room if we leave it.\n\nI counted the clock four times. It always stops at 00:07.\n\nIf the hallway starts breathing, run toward the red exit sign.")
			return true
		"exit":
			if not GameState.has_flag("chase_started"):
				return false
			_finish_ending()
			return true
	return false

func _collect_memory(action_id: String) -> bool:
	if GameState.has_flag(action_id) or _loop_transitioning:
		return false
	var expected: String = ["memory_photo", "memory_cassette", "memory_rabbit"][_loop_iteration]
	if action_id != expected:
		return false
	GameState.set_flag(action_id)
	_memory_count += 1
	GameState.add_item(action_id.trim_prefix("memory_"))
	_hallway.reconfigure_for_memory(_memory_count)
	_horror.trigger(action_id)
	AudioManager.play_tone("memory_%s" % _memory_count, 180.0 + _memory_count * 55.0, 0.42, -18.0)
	if _memory_count >= 3:
		_disable_loop_gate()
		GameState.set_objective("The radio is repeating your voice. Find the number it wants.")
	else:
		GameState.set_objective("The corridor remembers another object. Keep looking.")
	return true

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

func _on_narrative_finished(flag: String) -> void:
	match flag:
		"phone_briefing_complete":
			GameState.set_objective("Sign the night log and take the fourth-floor key.")
		"power_stable":
			GameState.set_objective("Follow the humming lights into the changed hallway.")
		"radio_solved":
			GameState.set_objective("Room 407 is open. Do not look behind the door.")
		"room_record_heard":
			GameState.set_objective("A child's drawing is pinned deeper inside Room 407.")
		"chase_ready":
			GameState.set_objective("RUN. Follow the red lights to the lobby exit.")
			GameState.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "chase_start")

func _disable_loop_gate() -> void:
	var gate := get_node_or_null("hallway_loop") as StoryInteractable
	if gate == null:
		return
	gate.interaction_enabled = false
	gate.collision_layer = 0
	gate.visible = false

func _run_loop_transition(actor: Node, iteration: int) -> void:
	_loop_transitioning = true
	if actor != null and actor.has_method("set_input_locked"):
		actor.set_input_locked("hallway", true)
	GameState.set_subtitle("The elevator bell rings behind you. This is loop %d." % (iteration + 1))
	await get_tree().create_timer(4.0 * _narrative.duration_scale).timeout
	GameState.set_subtitle("")
	if actor != null and is_instance_valid(actor) and actor.has_method("set_input_locked"):
		actor.set_input_locked("hallway", false)
	_loop_transitioning = false

func _memory_label(action_id: String) -> String:
	return {
		"memory_photo": "Inspect the burned photograph",
		"memory_cassette": "Take the cassette",
		"memory_rabbit": "Pick up the red rabbit"
	}.get(action_id, "Inspect")

func _start_chase() -> void:
	if GameState.has_flag("chase_started") or is_instance_valid(entity):
		return
	GameState.set_flag("chase_started")
	GameState.advance_stage(GameState.Stage.CHASE)
	GameState.set_objective("RUN. The exit is at the far end of the corridor.")
	entity = ENTITY_SCRIPT.new() as CharacterBody3D
	entity.name = "TheEntity"
	entity.position = player.global_position + Vector3(0, 0, 8.5)
	entity.collision_layer = 8
	entity.collision_mask = 1
	add_child(entity)
	entity.setup(player, self)
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.height = 2.5
	mesh.mesh = capsule
	mesh.material_override = LevelGeometry.material(Color(0.015, 0.008, 0.012))
	entity.add_child(mesh)
	var shape := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.42
	capsule_shape.height = 2.4
	shape.shape = capsule_shape
	entity.add_child(shape)
	entity.start_chase()
	AudioManager.play_tone("chase_alarm", 72.0, 1.2, -9.0)

func fail_chase() -> void:
	if not GameState.has_flag("chase_started") or _ending or _recovering:
		return
	_recovering = true
	player.set_input_locked("fail", true)
	if entity != null:
		entity.stop_chase()
		entity.visible = false
	_fail_overlay.show_failure()
	AudioManager.play_tone("fail", 48.0, 0.5, -12.0)
	await get_tree().create_timer(1.25).timeout
	GameState.restore_checkpoint()
	GameState.set_flag("chase_started")
	GameState.advance_stage(GameState.Stage.CHASE)
	player.global_position = Vector3(0, 0.02, WorldLayout.CHASE_RESPAWN_Z)
	GameState.set_objective("It caught you once. Run earlier and keep the light ahead.")
	if entity != null:
		entity.global_position = player.global_position + Vector3(0, 0, 8.5)
		entity.visible = true
		entity.start_chase()
	player.set_input_locked("fail", false)
	_recovering = false

func _finish_ending() -> void:
	_ending = true
	GameState.advance_stage(GameState.Stage.ENDING)
	GameState.set_objective("23:47. The shift was never scheduled.")
	if entity != null:
		entity.stop_chase()
		entity.visible = false
	var ending := Label3D.new()
	ending.text = "THE SHIFT WAS NEVER SCHEDULED\n\nROOM 407 REMEMBERS"
	ending.font_size = 34
	ending.outline_size = 12
	ending.modulate = Color(0.86, 0.82, 0.74)
	ending.position = player.global_position + Vector3(0, 1.2, -3.0)
	ending.no_depth_test = true
	add_child(ending)
	player.set_input_locked("ending", true)
	AudioManager.play_tone("ending", 130.0, 2.0, -15.0)
	var overlay := ENDING_SCRIPT.instantiate()
	add_child(overlay)
	overlay.show_ending()
