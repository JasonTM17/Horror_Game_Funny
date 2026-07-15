class_name DoorInteractable
extends Interactable

@export var open_angle := 92.0
@export var locked_flag := ""
@export var required_item := ""
var is_open := false
var _moving := false

func get_prompt(_actor: Node) -> String:
	if _moving:
		return ""
	if is_open:
		return "[E] Close door"
	return "[E] Open door"

func interact(actor: Node) -> bool:
	if _moving:
		return false
	if not is_open:
		if not locked_flag.is_empty() and not GameState.has_flag(locked_flag):
			feedback_text = "The lock refuses to turn."
			return super.interact(actor)
		if not required_item.is_empty() and not GameState.has_item(required_item):
			feedback_text = "Something is missing."
			return super.interact(actor)
	_moving = true
	var target := deg_to_rad(open_angle if not is_open else 0.0)
	var tween := create_tween()
	tween.tween_property(self, "rotation:y", target, 0.55).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func() -> void:
		is_open = not is_open
		_moving = false
	)
	return super.interact(actor)

