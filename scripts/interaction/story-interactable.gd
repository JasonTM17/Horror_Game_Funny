class_name StoryInteractable
extends Interactable

@export var action_id := ""
var _director: Node

func setup(director: Node, id: String, label: String) -> void:
	_director = director
	action_id = id
	prompt_text = label

func get_prompt(actor: Node) -> String:
	if not interaction_enabled:
		return ""
	if _director != null and _director.has_method("get_story_prompt"):
		return str(_director.get_story_prompt(action_id, actor))
	return "[E] " + prompt_text

func interact(actor: Node) -> bool:
	if not super.interact(actor):
		return false
	if _director != null and _director.has_method("handle_story_action"):
		var accepted := bool(_director.handle_story_action(action_id, actor))
		if not accepted:
			_cooldown_left = 0.0
		return accepted
	return true

