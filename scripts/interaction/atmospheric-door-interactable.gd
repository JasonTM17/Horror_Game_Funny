class_name AtmosphericDoorInteractable
extends Interactable

@export var response_text := "The handle is painted onto the door. It was never meant to open."
var _tone_id := ""

func _ready() -> void:
	_tone_id = "atmospheric_door_%d" % get_instance_id()

func interact(actor: Node) -> bool:
	feedback_text = response_text
	if not super.interact(actor):
		return false
	AudioManager.stop_tone(_tone_id)
	AudioManager.play_spatial_tone(self, _tone_id, 71.0, 0.24, -18.0)
	return true

func _exit_tree() -> void:
	if not _tone_id.is_empty():
		AudioManager.stop_tone(_tone_id)
