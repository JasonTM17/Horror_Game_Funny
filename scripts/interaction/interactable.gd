class_name Interactable
extends StaticBody3D

signal interacted(actor: Node)

@export var prompt_text := "Interact"
@export var feedback_text := ""
@export var interaction_enabled := true
@export var cooldown := 0.25
var _cooldown_left := 0.0

func _process(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)

func get_prompt(_actor: Node) -> String:
	if not interaction_enabled or _cooldown_left > 0.0:
		return ""
	return prompt_text

func interact(actor: Node) -> bool:
	if not interaction_enabled or _cooldown_left > 0.0:
		return false
	_cooldown_left = cooldown
	interacted.emit(actor)
	return true

func get_feedback() -> String:
	return feedback_text

