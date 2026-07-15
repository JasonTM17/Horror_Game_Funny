extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause-menu.tscn")
const STORY_SCRIPT := preload("res://scripts/interaction/story-interactable.gd")
const DOOR_SCRIPT := preload("res://scripts/interaction/door-interactable.gd")
const ENTITY_SCRIPT := preload("res://scripts/world/chase-entity.gd")
const RADIO_SCRIPT := preload("res://scripts/puzzles/radio-puzzle.gd")
const HALLWAY_SCRIPT := preload("res://scripts/world/dynamic-hallway-controller.gd")
const HORROR_SCRIPT := preload("res://scripts/world/horror-event-director.gd")
const NOTE_SCRIPT := preload("res://scripts/ui/note-reader.gd")
const ENDING_SCRIPT := preload("res://scenes/ui/ending-overlay.tscn")
const FAIL_SCRIPT := preload("res://scenes/ui/fail-overlay.tscn")

var player: CharacterBody3D
var entity: CharacterBody3D
var exit_marker := Vector3(0, 1.0, -132.0)
var _beat_guard: Dictionary = {}
var _memory_count := 0
var _ending := false
var _radio_ui: CanvasLayer
var _hallway: Node3D
var _horror: Node3D
var _note_ui: CanvasLayer
var _fail_overlay: CanvasLayer

func _ready() -> void:
	GameState.reset_run()
	_build_environment()
	_hallway = HALLWAY_SCRIPT.new()
	add_child(_hallway)
	_hallway.build(self)
	_horror = HORROR_SCRIPT.new()
	add_child(_horror)
	_horror.setup(self, _hallway)
	_spawn_player()
	_spawn_story_objects()
	GameState.set_objective("Answer the desk phone and sign the night log.")

func _process(_delta: float) -> void:
	if player == null or _ending:
		return
	var z := player.global_position.z
	if z < -11.0 and not GameState.has_flag("floor_reached"):
		GameState.set_flag("floor_reached")
		GameState.advance_stage(GameState.Stage.FLOOR4_DARK)
		GameState.set_objective("The fourth floor is dark. Find the spare fuse.")
		AudioManager.play_tone("door_slam", 58.0, 0.32, -11.0)
	if z < -38.0 and GameState.has_flag("fuse_installed") and not GameState.has_flag("memory_loop_started"):
		GameState.set_flag("memory_loop_started")
		GameState.advance_stage(GameState.Stage.MEMORY_LOOP)
		GameState.set_objective("The hallway has changed. Find three things that remember you.")
	if z < -72.0 and GameState.has_flag("radio_solved") and not GameState.has_flag("room_entered"):
		GameState.set_flag("room_entered")
		GameState.advance_stage(GameState.Stage.ROOM_407)
		GameState.set_objective("Room 407 is open. Find what was left behind.")
	if z < -104.0 and GameState.has_flag("final_clue_seen") and not GameState.has_flag("chase_started"):
		_start_chase()

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.009, 0.016)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.12, 0.16, 0.22)
	environment.ambient_light_energy = 0.22
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.08, 0.1, 0.13)
	environment.fog_density = 0.012
	world.environment = environment
	add_child(world)
	LevelGeometry.add_box(self, "Floor", Vector3(0, -0.15, -62), Vector3(8, 0.3, 150), Color(0.055, 0.06, 0.075))
	LevelGeometry.add_box(self, "LeftWall", Vector3(-4, 2.0, -62), Vector3(0.25, 4.0, 150), Color(0.08, 0.075, 0.085))
	LevelGeometry.add_box(self, "RightWall", Vector3(4, 2.0, -62), Vector3(0.25, 4.0, 150), Color(0.08, 0.075, 0.085))
	LevelGeometry.add_box(self, "LobbyBack", Vector3(0, 2.0, 15), Vector3(8, 4, 0.25), Color(0.11, 0.1, 0.12))
	LevelGeometry.add_box(self, "Room407Wall", Vector3(0, 2.0, -78), Vector3(8, 4, 0.25), Color(0.12, 0.07, 0.08))
	LevelGeometry.add_box(self, "Room407Floor", Vector3(0, -0.05, -91), Vector3(8, 0.2, 24), Color(0.09, 0.055, 0.06))
	LevelGeometry.add_box(self, "Room407Back", Vector3(0, 2.0, -103), Vector3(8, 4, 0.25), Color(0.13, 0.06, 0.07))
	LevelGeometry.add_label(self, "NIGHT DESK", Vector3(-2.8, 1.65, 9.0))
	LevelGeometry.add_label(self, "FLOOR 4", Vector3(-2.9, 2.1, -15.0), Color(0.42, 0.46, 0.48))
	LevelGeometry.add_label(self, "407", Vector3(-1.0, 2.1, -80.0), Color(0.65, 0.3, 0.28))
	for z in [10.0, -17.0, -31.0, -46.0, -62.0, -87.0, -111.0, -128.0]:
		LevelGeometry.add_light(self, Vector3(0, 2.8, z), Color(0.48, 0.57, 0.68), 0.48, 6.5)
	LevelGeometry.add_light(self, Vector3(0, 2.6, -95), Color(0.52, 0.12, 0.1), 1.0, 7.0)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0.02, 11.0)
	add_child(player)
	var hud := HUD_SCENE.instantiate()
	add_child(hud)
	add_child(PAUSE_SCENE.instantiate())
	_fail_overlay = FAIL_SCRIPT.instantiate()
	add_child(_fail_overlay)

func _spawn_story_objects() -> void:
	_add_story("phone", Vector3(-1.8, 0.55, 8.8), "Answer the phone", Color(0.16, 0.12, 0.1))
	_add_story("logbook", Vector3(1.8, 0.42, 8.8), "Sign the night log", Color(0.25, 0.18, 0.12))
	_add_door("floor_door", Vector3(0, 1.25, -8.0), "log_signed", "", 92.0)
	_add_story("fuse_pickup", Vector3(2.3, 0.45, -24.0), "Take the spare fuse", Color(0.74, 0.55, 0.2))
	_add_story("fuse_box", Vector3(-2.8, 1.15, -34.0), "Open the fuse box", Color(0.2, 0.22, 0.24))
	_add_story("memory_photo", Vector3(-2.4, 0.6, -47.0), "Inspect the burned photograph", Color(0.28, 0.18, 0.12))
	_add_story("memory_cassette", Vector3(2.2, 0.35, -57.0), "Take the cassette", Color(0.12, 0.08, 0.06))
	_add_story("memory_rabbit", Vector3(-2.4, 0.42, -66.0), "Pick up the red rabbit", Color(0.5, 0.08, 0.07))
	_add_story("radio", Vector3(2.2, 0.7, -71.0), "Tune the radio", Color(0.12, 0.16, 0.17))
	_add_door("room_door", Vector3(0, 1.25, -78.0), "radio_solved", "", -92.0)
	_add_story("final_clue", Vector3(0, 0.5, -94.0), "Read the child's note", Color(0.32, 0.26, 0.19))
	_add_story("exit", Vector3(0, 1.0, -128.0), "Run for the lobby", Color(0.18, 0.22, 0.24))

func _add_story(id: String, position: Vector3, label: String, color: Color) -> StoryInteractable:
	var item := STORY_SCRIPT.new() as StoryInteractable
	item.name = id
	item.position = position
	item.setup(self, id, label)
	item.collision_layer = 9
	add_child(item)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.65, 0.45)
	mesh.mesh = box
	mesh.material_override = LevelGeometry.material(color)
	item.add_child(mesh)
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(0.55, 0.65, 0.45)
	shape.shape = collider
	item.add_child(shape)
	return item

func _add_door(id: String, position: Vector3, locked_flag: String, required_item: String, angle: float) -> DoorInteractable:
	var door := DOOR_SCRIPT.new() as DoorInteractable
	door.name = id
	door.position = position
	door.open_angle = angle
	door.locked_flag = locked_flag
	door.required_item = required_item
	door.prompt_text = "Door"
	door.collision_layer = 9
	add_child(door)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.2, 2.5, 0.2)
	mesh.mesh = box
	mesh.material_override = LevelGeometry.material(Color(0.16, 0.12, 0.12))
	door.add_child(mesh)
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(2.2, 2.5, 0.2)
	shape.shape = collider
	door.add_child(shape)
	return door

func get_story_prompt(action_id: String, _actor: Node) -> String:
	if action_id == "phone" and not GameState.has_flag("phone_answered"):
		return "[E] Answer the ringing phone"
	if action_id == "logbook" and GameState.has_flag("phone_answered") and not GameState.has_flag("log_signed"):
		return "[E] Sign the night log"
	if action_id == "fuse_pickup" and not GameState.has_item("spare_fuse"):
		return "[E] Take the spare fuse"
	if action_id == "fuse_box" and not GameState.has_flag("fuse_installed"):
		return "[E] Install the fuse"
	if action_id.begins_with("memory_") and not GameState.has_flag(action_id):
		return "[E] " + _memory_label(action_id)
	if action_id == "radio" and not GameState.has_flag("radio_solved"):
		return "[E] Tune the radio to 0007"
	if action_id == "final_clue" and not GameState.has_flag("final_clue_seen"):
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
			GameState.set_objective("Sign the night log, then take the fourth-floor key.")
			AudioManager.play_tone("phone_click", 440.0, 0.12)
			return true
		"logbook":
			if not GameState.has_flag("phone_answered") or GameState.has_flag("log_signed"):
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
			GameState.set_objective("Follow the humming lights. Something is waiting in the hall.")
			_horror.trigger("fuse_power")
			AudioManager.play_tone("power_restore", 110.0, 0.8, -13.0)
			return true
		["memory_photo", "memory_cassette", "memory_rabbit"]:
			if GameState.has_flag(action_id):
				return false
			GameState.set_flag(action_id)
			_memory_count += 1
			GameState.add_item(action_id.trim_prefix("memory_"))
			_hallway.reconfigure_for_memory(_memory_count)
			_horror.trigger(action_id)
			AudioManager.play_tone("memory_%s" % _memory_count, 180.0 + _memory_count * 55.0, 0.42, -18.0)
			if _memory_count >= 3:
				GameState.set_objective("The radio is repeating your voice. Find the number it wants.")
			else:
				GameState.set_objective("The corridor remembers another object. Keep looking.")
			return true
		"radio":
			if _memory_count < 3 or GameState.has_flag("radio_solved"):
				return false
			if _radio_ui == null:
				_radio_ui = RADIO_SCRIPT.new() as CanvasLayer
				add_child(_radio_ui)
			_radio_ui.open(self, _actor)
			return true
		"final_clue":
			if not GameState.has_flag("room_entered") or GameState.has_flag("final_clue_seen"):
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

func on_radio_solved() -> void:
	if GameState.has_flag("radio_solved"):
		return
	GameState.set_flag("radio_solved")
	GameState.set_objective("Room 407 is open. Do not look behind the door.")
	AudioManager.play_tone("radio_code", 700.0, 0.2)

func on_note_closed() -> void:
	if GameState.has_flag("final_clue_seen"):
		return
	GameState.set_flag("final_clue_seen")
	GameState.set_objective("The lights are going out. Reach the lobby before it finds you.")
	GameState.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "chase_start")

func _memory_label(action_id: String) -> String:
	return {
		"memory_photo": "Inspect the burned photograph",
		"memory_cassette": "Take the cassette",
		"memory_rabbit": "Pick up the red rabbit"
	}.get(action_id, "Inspect")

func _start_chase() -> void:
	GameState.set_flag("chase_started")
	GameState.advance_stage(GameState.Stage.CHASE)
	GameState.set_objective("RUN. The exit is at the far end of the corridor.")
	entity = ENTITY_SCRIPT.new() as CharacterBody3D
	entity.name = "TheEntity"
	entity.position = player.global_position + Vector3(0, 0, 8.5)
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
	if not GameState.has_flag("chase_started") or _ending:
		return
	if entity != null:
		entity.stop_chase()
		entity.visible = false
	GameState.restore_checkpoint()
	player.global_position = Vector3(0, 0.02, -108.0)
	GameState.set_objective("It caught you once. Run earlier and keep the light ahead.")
	_fail_overlay.show_failure()
	AudioManager.play_tone("fail", 48.0, 0.5, -12.0)
	if entity != null:
		entity.global_position = player.global_position + Vector3(0, 0, 8.5)
		entity.visible = true
		entity.start_chase()

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
