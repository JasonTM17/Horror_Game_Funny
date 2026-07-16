class_name DoorInteractable
extends Interactable

@export var open_angle := 92.0
@export var locked_flag := ""
@export var required_item := ""
@export var permanent_unlock_flag := ""
@export var consume_required_item := false
var is_open := false
var _moving := false

func get_prompt(_actor: Node) -> String:
	if not interaction_enabled or _cooldown_left > 0.0 or _moving:
		return ""
	if is_open:
		return "[E] Close door"
	return "[E] Open door"

func interact(actor: Node) -> bool:
	if not interaction_enabled or _cooldown_left > 0.0 or _moving:
		return false
	var opening := not is_open
	var permanently_unlocked := _is_permanently_unlocked()
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
	var target := deg_to_rad(open_angle if not is_open else 0.0)
	var tween := create_tween()
	AudioManager.play_spatial_tone(self, "door_motion", 118.0 if not is_open else 92.0, 0.55, -22.0)
	tween.tween_property(self, "rotation:y", target, 0.55).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func() -> void:
		is_open = not is_open
		_moving = false
	)
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

func _reject_with_feedback(actor: Node, text: String, tone_id: String, frequency: float) -> bool:
	feedback_text = text
	_commit_interaction(actor)
	AudioManager.play_spatial_tone(self, tone_id, frequency, 0.16, -18.0)
	return true

func _commit_interaction(actor: Node) -> void:
	_cooldown_left = cooldown
	interacted.emit(actor)
