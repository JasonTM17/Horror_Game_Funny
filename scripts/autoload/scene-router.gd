extends Node

signal transition_started
signal transition_finished

var transitioning: bool = false

func change_scene(scene_path: String, spawn_id: String = "start") -> bool:
	if transitioning or not ResourceLoader.exists(scene_path):
		return false
	transitioning = true
	GameState.pending_spawn_id = spawn_id
	transition_started.emit()
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		transitioning = false
		push_error("SceneRouter failed to load %s (%s)" % [scene_path, error])
		return false
	call_deferred("_finish_transition")
	return true

func _finish_transition() -> void:
	transitioning = false
	transition_finished.emit()

func reload_checkpoint() -> bool:
	if not GameState.restore_checkpoint():
		return false
	return change_scene(str(GameState.checkpoint.get("scene_path", "")), GameState.pending_spawn_id)
