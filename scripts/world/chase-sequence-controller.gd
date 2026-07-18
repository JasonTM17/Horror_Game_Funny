class_name ChaseSequenceController
extends Node

signal credits_shown

const ENTITY_SCRIPT := preload("res://scripts/world/chase-entity.gd")
const ENTITY_VISUALS := preload("res://scripts/world/chase-entity-visual-builder.gd")
const ENDING_SCENE := preload("res://scenes/ui/ending-overlay.tscn")
const ENTITY_PRESENCE_CUE_ID := "chase_entity_presence"

var entity: CharacterBody3D
var ending := false
var recovering := false
var _credits_visible := false

var _player: CharacterBody3D
var _director: Node3D
var _fail_overlay: CanvasLayer

func setup(player: CharacterBody3D, director: Node3D, fail_overlay: CanvasLayer) -> void:
	_player = player
	_director = director
	_fail_overlay = fail_overlay

func start() -> void:
	if GameState.has_flag("chase_started") or is_instance_valid(entity):
		return
	GameState.set_flag("chase_started")
	GameState.advance_stage(GameState.Stage.CHASE)
	GameState.set_objective("RUN. The exit is at the far end of the corridor.")
	entity = ENTITY_SCRIPT.new() as CharacterBody3D
	entity.name = "TheEntity"
	entity.position = _player.global_position + Vector3(0, 0, 8.5)
	entity.collision_layer = 8
	entity.collision_mask = 1
	_director.add_child(entity)
	entity.setup(_player, _director)
	_build_entity_body()
	_fail_corridor_lights()
	entity.start_chase()
	_play_entity_presence_cue()
	AudioManager.play_tone("chase_alarm", 72.0, 1.2, -9.0)
	AudioManager.start_drone("chase_drone", 58.0, -19.0, "Chase")
	_player.add_camera_shake(0.06, 1.0)

func request_failure() -> void:
	if not GameState.has_flag("chase_started") or ending or recovering:
		return
	recovering = true
	_recover_from_failure()

func finish() -> bool:
	if ending:
		return false
	ending = true
	_cancel_failure_recovery()
	_player.set_input_locked("ending", false)
	GameState.advance_stage(GameState.Stage.ENDING)
	if entity != null:
		entity.stop_chase()
		entity.visible = false
	AudioManager.stop_tone(ENTITY_PRESENCE_CUE_ID)
	AudioManager.stop_tone("chase_drone")
	_build_abandoned_lobby_reveal()
	AudioManager.play_tone("ending", 130.0, 2.0, -15.0)
	return true

func show_credits() -> bool:
	if not ending or not is_instance_valid(_director) or _credits_visible:
		return false
	_player.set_input_locked("ending", true)
	var overlay := ENDING_SCENE.instantiate()
	overlay.name = "EndingOverlay"
	_director.add_child(overlay)
	overlay.show_ending()
	_credits_visible = true
	credits_shown.emit()
	return true

func _recover_from_failure() -> void:
	_player.set_input_locked("fail", true)
	if entity != null:
		entity.stop_chase()
		entity.visible = false
	AudioManager.stop_tone(ENTITY_PRESENCE_CUE_ID)
	AudioManager.stop_tone("chase_drone")
	_fail_overlay.show_failure()
	AudioManager.play_tone("fail", 48.0, 0.5, -12.0)
	await get_tree().create_timer(1.25).timeout
	if ending or not recovering:
		_cancel_failure_recovery()
		return
	GameState.restore_checkpoint()
	GameState.set_flag("chase_started")
	GameState.advance_stage(GameState.Stage.CHASE)
	_player.global_position = Vector3(0, 0.02, WorldLayout.CHASE_RESPAWN_Z)
	GameState.set_objective("It caught you once. Run earlier and keep the light ahead.")
	if entity != null:
		entity.global_position = _player.global_position + Vector3(0, 0, 8.5)
		entity.visible = true
		entity.start_chase()
		_play_entity_presence_cue()
	AudioManager.start_drone("chase_drone", 58.0, -19.0, "Chase")
	_cancel_failure_recovery()

func _cancel_failure_recovery() -> void:
	AudioManager.stop_tone("fail")
	recovering = false
	if is_instance_valid(_player):
		_player.set_input_locked("fail", false)
	if is_instance_valid(_fail_overlay):
		_fail_overlay.visible = false

func _play_entity_presence_cue() -> void:
	AudioManager.stop_tone(ENTITY_PRESENCE_CUE_ID)
	if is_instance_valid(entity):
		AudioManager.play_spatial_tone(entity, ENTITY_PRESENCE_CUE_ID, 92.0, 1.4, -11.0)

func _build_entity_body() -> void:
	ENTITY_VISUALS.build(entity)
	var shape := CollisionShape3D.new()
	shape.name = "EntityCollider"
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.42
	capsule_shape.height = 2.4
	shape.shape = capsule_shape
	shape.position.y = 1.2
	entity.add_child(shape)

func _fail_corridor_lights() -> void:
	for child in _director.get_children():
		if child is OmniLight3D and child.name.begins_with("CorridorLight"):
			child.light_energy *= 0.08

func _build_abandoned_lobby_reveal() -> void:
	var reveal_z := _player.global_position.z - 4.0
	LevelGeometry.add_box(_director, "AbandonedLobbyFloor", Vector3(0, -0.08, reveal_z), Vector3(7.5, 0.16, 8.0), Color(0.035, 0.03, 0.03))
	LevelGeometry.add_box(_director, "CondemnedDesk", Vector3(-2.2, 0.5, reveal_z - 1.0), Vector3(2.5, 1.0, 1.2), Color(0.07, 0.045, 0.035))
	LevelGeometry.add_label(_director, "BUILDING CONDEMNED — 2007", Vector3(0, 2.15, reveal_z - 3.2), Color(0.66, 0.16, 0.12))
	LevelGeometry.add_label(_director, "NO NIGHT STAFF ASSIGNED", Vector3(0, 1.45, reveal_z - 3.15), Color(0.48, 0.46, 0.42))
