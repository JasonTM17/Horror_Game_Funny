extends SceneTree

const CANONICAL_COPY_PATH := "user://project-settings-canonical.godot"

func _initialize() -> void:
	var save_error := ProjectSettings.save_custom(CANONICAL_COPY_PATH)
	if save_error != OK:
		_fail("could not serialize canonical settings: %s" % error_string(save_error))
		return
	var committed_bytes := FileAccess.get_file_as_bytes("res://project.godot")
	var canonical_bytes := FileAccess.get_file_as_bytes(CANONICAL_COPY_PATH)
	if committed_bytes.is_empty() or canonical_bytes.is_empty():
		_fail("could not read committed or canonical project settings")
		return
	if committed_bytes != canonical_bytes:
		_fail("project.godot changes when Godot saves ProjectSettings")
		return
	print("PROJECT_SETTINGS_STABILITY_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error("PROJECT_SETTINGS_STABILITY_ASSERT: %s" % message)
	quit(1)

