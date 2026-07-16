class_name DrawerInteractable
extends Interactable

@export var open_offset := Vector3(0, 0, 0.62)
@export_range(0.1, 1.5, 0.05) var motion_duration := 0.45
@export_range(0.0, 3.0, 0.05) var motion_sweep_radius := 1.45
@export var open_feedback := "The drawer is empty. 00:07 is scratched into the wood."
@export var close_feedback := "The drawer slides shut."

var is_open := false
var _moving := false
var _closed_position := Vector3.ZERO
var _tone_id := ""
var _motion_actor: Node
var _motion_lock_reason := ""

func _ready() -> void:
	_closed_position = position
	_tone_id = "drawer_%d" % get_instance_id()

func get_prompt(actor: Node) -> String:
	if not interaction_enabled or _cooldown_left > 0.0 or _moving:
		return ""
	if _actor_blocks_motion(actor):
		return "Step back to use drawer"
	return "[E] Close desk drawer" if is_open else "[E] Open desk drawer"

func interact(actor: Node) -> bool:
	if not interaction_enabled or _cooldown_left > 0.0 or _moving:
		return false
	if _actor_blocks_motion(actor):
		feedback_text = "Step back before moving the drawer."
		_cooldown_left = cooldown
		_play_motion_tone(false)
		return true
	var target_open := not is_open
	_moving = true
	_cooldown_left = cooldown
	feedback_text = open_feedback if target_open else close_feedback
	interacted.emit(actor)
	_play_motion_tone(target_open)
	_lock_actor_movement(actor)
	var target_position := _closed_position + open_offset if target_open else _closed_position
	var tween := create_tween()
	tween.tween_property(self, "position", target_position, motion_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func() -> void:
		is_open = target_open
		_moving = false
		_release_actor_movement()
	)
	return true

func _actor_blocks_motion(actor: Node) -> bool:
	if motion_sweep_radius <= 0.0 or not actor is Node3D or not is_instance_valid(actor):
		return false
	var actor_3d := actor as Node3D
	var horizontal_offset := Vector2(
		actor_3d.global_position.x - global_position.x,
		actor_3d.global_position.z - global_position.z
	)
	return horizontal_offset.length() < motion_sweep_radius

func _lock_actor_movement(actor: Node) -> void:
	if not is_instance_valid(actor) or not actor.has_method("set_movement_locked"):
		return
	_motion_actor = actor
	_motion_lock_reason = "drawer_motion_%d" % get_instance_id()
	_motion_actor.call("set_movement_locked", _motion_lock_reason, true)

func _release_actor_movement() -> void:
	if is_instance_valid(_motion_actor) and _motion_actor.has_method("set_movement_locked"):
		_motion_actor.call("set_movement_locked", _motion_lock_reason, false)
	_motion_actor = null
	_motion_lock_reason = ""

func _play_motion_tone(opening: bool) -> void:
	AudioManager.stop_tone(_tone_id)
	AudioManager.play_spatial_tone(self, _tone_id, 132.0 if opening else 104.0, 0.28, -22.0)

func _exit_tree() -> void:
	_release_actor_movement()
	if not _tone_id.is_empty():
		AudioManager.stop_tone(_tone_id)
