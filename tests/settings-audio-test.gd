extends Node

const SETTINGS_SCENE := preload("res://scenes/ui/settings-panel.tscn")

func _ready() -> void:
	await get_tree().process_frame
	for bus_name in ["Master", "Music", "SFX", "Ambience", "Chase"]:
		if not _require(AudioServer.get_bus_index(bus_name) >= 0, "%s audio bus missing" % bus_name): return
	SettingsManager.set_mouse_sensitivity(99.0)
	SettingsManager.set_field_of_view(12.0)
	SettingsManager.set_master_volume(-99.0)
	if not _require(is_equal_approx(SettingsManager.mouse_sensitivity, 0.25), "mouse sensitivity clamp failed"): return
	if not _require(is_equal_approx(SettingsManager.field_of_view, 60.0), "field of view clamp failed"): return
	if not _require(is_equal_approx(SettingsManager.master_volume, -40.0), "master volume clamp failed"): return
	var panel := SETTINGS_SCENE.instantiate()
	add_child(panel)
	await get_tree().process_frame
	for node_path in ["Panel/Music", "Panel/Sfx", "Panel/Ambience", "Panel/Fullscreen", "Panel/CameraShake", "Panel/FilmGrain", "Panel/Reset"]:
		if not _require(panel.has_node(node_path), "%s control missing" % node_path): return
	AudioManager.start_drone("test_drone", 51.0, -30.0, "Ambience")
	await get_tree().process_frame
	AudioManager.stop_tone("test_drone")
	SettingsManager.reset_defaults()
	print("SETTINGS_AUDIO_TEST_OK")
	panel.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SETTINGS_AUDIO_ASSERT: " + message)
	get_tree().quit(2)
	return false
