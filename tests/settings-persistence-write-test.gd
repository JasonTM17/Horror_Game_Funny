extends Node

func _ready() -> void:
	await get_tree().process_frame
	SettingsManager.set_mouse_sensitivity(0.17)
	SettingsManager.set_field_of_view(89.0)
	SettingsManager.set_master_volume(-7.0)
	SettingsManager.set_music_volume(-13.0)
	SettingsManager.set_sfx_volume(-6.0)
	SettingsManager.set_ambience_volume(-9.0)
	SettingsManager.set_flicker_enabled(false)
	SettingsManager.set_comfort_head_bob(false)
	SettingsManager.set_camera_shake_enabled(false)
	SettingsManager.set_film_grain_enabled(false)
	SettingsManager.set_fullscreen_enabled(false)
	SettingsManager.save_settings()
	if not FileAccess.file_exists(SettingsManager.CONFIG_PATH):
		push_error("SETTINGS_PERSISTENCE_ASSERT: writer did not create room407.cfg")
		get_tree().quit(2)
		return
	print("SETTINGS_PERSISTENCE_WRITE_OK")
	get_tree().quit()
