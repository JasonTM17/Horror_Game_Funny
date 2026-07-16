class_name DoorInteractable
extends Interactable

@export var open_angle := 92.0
@export var locked_flag := ""
@export var required_item := ""
@export var permanent_unlock_flag := ""
@export var consume_required_item := false
@export_range(0.0, 3.0, 0.05) var motion_sweep_radius := 1.5
var is_open := false
var _moving := false
var _motion_actor: Node
var _motion_lock_reason := ""

func get_prompt(actor: Node) -> String:
	if not interaction_enabled or _cooldown_left > 0.0 or _moving:
		return ""
	if _actor_blocks_motion(actor):
		return "Move clear to use door"
	if is_open:
		return "[E] Close door"
	return "[E] Open door"

func interact(actor: Node) -> bool:
	if not interaction_enabled or _cooldown_left > 0.0 or _moving:
		return false
	var opening := not is_open
	var permanently_unlocked := _is_permanently_unlocked()
	if _actor_blocks_motion(actor):
		return _reject_with_feedback(actor, "Step clear before moving the door.", "door_motion_blocked", 68.0)
	if opening and not permanently_unlocked:
		if not locked_flag.is_empty() and not GameState.has_flag(locked_flag):
			return _reject_with_feedback(actor, "The lock refuses to turn.", "door_locked", 82.0)
		if not required_item.is_empty() and not GameState.has_item(required_item):
			return _reject_with_feedback(actor, "The keyhole is empty.", "door_locked_item", 74.0)
	_moving = true
	if opening and not permanently_unlocked and not _commit_unlock():
		_moving = false
		return false
	feedback_text = ""
	_commit_interaction(actor)
	_start_motion(not is_open, 0.55, "door_motion", 118.0 if not is_open else 92.0, -22.0, actor)
	return true

func close_for_event(duration := 0.22) -> bool:
	if _moving or not is_open:
		return false
	_moving = true
	feedback_text = ""
	_start_motion(false, duration, "floor_door_slam", 58.0, -11.0)
	return true

func _is_permanently_unlocked() -> bool:
	return not permanent_unlock_flag.is_empty() and GameState.has_flag(permanent_unlock_flag)

func _commit_unlock() -> bool:
	if consume_required_item and not required_item.is_empty():
		if not permanent_unlock_flag.is_empty():
			return GameState.consume_item_and_set_flag(required_item, permanent_unlock_flag)
		return GameState.consume_item(required_item)
	if not permanent_unlock_flag.is_empty():
		GameState.set_flag(permanent_unlock_flag)
	return true

func _reject_with_feedback(_actor: Node, text: String, tone_id: String, frequency: float) -> bool:
	feedback_text = text
	AudioManager.stop_tone(tone_id)
	AudioManager.play_spatial_tone(self, tone_id, frequency, 0.16, -18.0)
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

func _commit_interaction(actor: Node) -> void:
	_cooldown_left = cooldown
	interacted.emit(actor)

func _start_motion(target_open: bool, duration: float, tone_id: String, frequency: float, volume_db: float, actor: Node = null) -> void:
	var target := deg_to_rad(open_angle if target_open else 0.0)
	var tween := create_tween()
	_lock_actor_movement(actor)
	AudioManager.play_spatial_tone(self, tone_id, frequency, duration, volume_db)
	tween.tween_property(self, "rotation:y", target, duration).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func() -> void:
		is_open = target_open
		_moving = false
		_release_actor_movement()
	)

func _lock_actor_movement(actor: Node) -> void:
	if not is_instance_valid(actor) or not actor.has_method("set_movement_locked"):
		return
	_motion_actor = actor
	_motion_lock_reason = "door_motion_%d" % get_instance_id()
	_motion_actor.call("set_movement_locked", _motion_lock_reason, true)

func _release_actor_movement() -> void:
	if is_instance_valid(_motion_actor) and _motion_actor.has_method("set_movement_locked"):
		_motion_actor.call("set_movement_locked", _motion_lock_reason, false)
	_motion_actor = null
	_motion_lock_reason = ""

func _exit_tree() -> void:
	_release_actor_movement()
