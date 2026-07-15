extends Node3D

signal prompt_changed(text: String)
signal feedback_requested(text: String)

@export var max_distance := 2.5
@onready var ray: RayCast3D = $RayCast3D
var _last_prompt := ""

func _process(_delta: float) -> void:
	var text := ""
	if ray.is_colliding():
		var target := ray.get_collider()
		if target != null and target.has_method("get_prompt"):
			text = str(target.get_prompt(_get_actor()))
	if text != _last_prompt:
		_last_prompt = text
		prompt_changed.emit(text)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or not ray.is_colliding():
		return
	var target := ray.get_collider()
	if target == null or not target.has_method("interact"):
		return
	var actor := _get_actor()
	if bool(target.interact(actor)):
		feedback_requested.emit(str(target.get_feedback()))

func _get_actor() -> Node:
	var actor := get_parent()
	while actor != null and not actor.is_in_group("player"):
		actor = actor.get_parent()
	return actor
