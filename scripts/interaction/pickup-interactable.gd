class_name PickupInteractable
extends Interactable

@export var item_id := ""
@export var collected_flag := ""

func get_prompt(_actor: Node) -> String:
	if not interaction_enabled or (not collected_flag.is_empty() and GameState.has_flag(collected_flag)):
		return ""
	return "[E] Take " + prompt_text

func interact(actor: Node) -> bool:
	if not super.interact(actor):
		return false
	if item_id.is_empty() or not GameState.add_item(item_id):
		return false
	if not collected_flag.is_empty():
		GameState.set_flag(collected_flag)
	interaction_enabled = false
	visible = false
	return true

