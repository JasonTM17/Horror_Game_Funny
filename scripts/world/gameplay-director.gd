extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause-menu.tscn")
const HALLWAY_SCRIPT := preload("res://scripts/world/dynamic-hallway-controller.gd")
const HORROR_SCRIPT := preload("res://scripts/world/horror-event-director.gd")
const FAIL_SCENE := preload("res://scenes/ui/fail-overlay.tscn")
const NARRATIVE_SCRIPT := preload("res://scripts/world/narrative-sequencer.gd")
const HALLWAY_TRANSITION_SCRIPT := preload("res://scripts/ui/hallway-transition-layer.gd")
const VISUAL_EFFECTS_SCRIPT := preload("res://scripts/ui/visual-effects-layer.gd")
const STORY_CONTROLLER_SCRIPT := preload("res://scripts/world/story-progression-controller.gd")
const CHASE_CONTROLLER_SCRIPT := preload("res://scripts/world/chase-sequence-controller.gd")

var player: CharacterBody3D
var _hallway: Node3D
var _horror: Node3D
var _narrative: Node
var _story: StoryProgressionController
var _chase: ChaseSequenceController
var _fail_overlay: CanvasLayer

func _ready() -> void:
	var fresh_run := GameState.checkpoint.is_empty()
	if fresh_run:
		GameState.reset_run()
	ContinuousWorldBuilder.build(self)
	_hallway = HALLWAY_SCRIPT.new()
	add_child(_hallway)
	_hallway.build(self)
	_horror = HORROR_SCRIPT.new()
	add_child(_horror)
	_horror.setup(self, _hallway)
	_narrative = NARRATIVE_SCRIPT.new()
	add_child(_narrative)
	var transition := HALLWAY_TRANSITION_SCRIPT.new() as HallwayTransitionLayer
	add_child(transition)
	add_child(VISUAL_EFFECTS_SCRIPT.new())
	_spawn_player()
	_horror.set_player(player)
	ContinuousStoryLayout.build(self)
	_story = STORY_CONTROLLER_SCRIPT.new() as StoryProgressionController
	add_child(_story)
	_story.setup(self, _hallway, _horror, _narrative, transition)
	_chase = CHASE_CONTROLLER_SCRIPT.new() as ChaseSequenceController
	add_child(_chase)
	_chase.setup(player, self, _fail_overlay)
	if fresh_run:
		GameState.set_objective("Answer the desk phone and sign the night log.")
	AudioManager.start_drone("building_ambience", 43.0, -34.0, "Ambience")

func _exit_tree() -> void:
	AudioManager.stop_tone("building_ambience")
	AudioManager.stop_tone("chase_drone")

func _process(_delta: float) -> void:
	if player == null or (_chase != null and _chase.ending):
		return
	var z := player.global_position.z
	if z < WorldLayout.FLOOR_TRIGGER_Z and not GameState.has_flag("floor_reached"):
		GameState.set_flag("floor_reached")
		GameState.advance_stage(GameState.Stage.FLOOR4_DARK)
		GameState.set_objective("The fourth floor is dark. Find the spare fuse.")
		AudioManager.play_tone("door_slam", 58.0, 0.32, -11.0)
		_narrative.play([
			"The elevator display skips from 3 to 4, then goes dark.",
			"A fuse rattles somewhere beyond the dead emergency lights.",
			"At the far end, a silhouette steps behind a door that never opened."
		], "floor_arrival_complete", 4.0)
	if z < WorldLayout.MEMORY_TRIGGER_Z and GameState.has_flag("power_stable") and not GameState.has_flag("memory_loop_started"):
		GameState.set_flag("memory_loop_started")
		GameState.advance_stage(GameState.Stage.MEMORY_LOOP)
		GameState.set_objective("The hallway has changed. Find three things that remember you.")
		_narrative.play([
			"The room numbers repeat in the wrong order.",
			"Your footsteps return one beat late.",
			"A family photograph waits where the corridor should end."
		], "memory_arrival_complete", 4.0)
	if z < WorldLayout.ROOM_TRIGGER_Z and GameState.has_flag("radio_solved") and not GameState.has_flag("room_entered"):
		GameState.set_flag("room_entered")
		GameState.advance_stage(GameState.Stage.ROOM_407)
		GameState.set_objective("Room 407 is open. Find what was left behind.")
		GameState.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "room_entrance")
		_narrative.play([
			"Room 407 is longer inside than the building is wide.",
			"The wallpaper carries the height marks of a missing child.",
			"A family recording clicks on by itself."
		], "room_arrival_complete", 4.0)
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
	add_child(HUD_SCENE.instantiate())
	add_child(PAUSE_SCENE.instantiate())
	_fail_overlay = FAIL_SCENE.instantiate()
	add_child(_fail_overlay)

func get_story_prompt(action_id: String, actor: Node) -> String:
	return _story.get_prompt(action_id, actor) if _story != null else ""

func handle_story_action(action_id: String, actor: Node) -> bool:
	return _story.handle_action(action_id, actor) if _story != null else false

func on_radio_solved() -> void:
	_story.on_radio_solved()

func on_note_closed() -> void:
	_story.on_note_closed()

func _start_chase() -> void:
	_chase.start()

func fail_chase() -> void:
	_chase.request_failure()

func finish_ending() -> void:
	_chase.finish()
