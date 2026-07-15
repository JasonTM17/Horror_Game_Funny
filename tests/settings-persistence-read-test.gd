extends Node

func _ready() -> void:
	await get_tree().process_frame
	if not _require(is_equal_approx(SettingsManager.mouse_sensitivity, 0.17), "mouse sensitivity was not restored"): return
	if not _require(is_equal_approx(SettingsManager.field_of_view, 89.0), "field of view was not restored"): return
	if not _require(is_equal_approx(SettingsManager.master_volume, -7.0), "master volume was not restored"): return
	if not _require(is_equal_approx(SettingsManager.music_volume, -13.0), "music volume was not restored"): return
	if not _require(is_equal_approx(SettingsManager.sfx_volume, -6.0), "SFX volume was not restored"): return
	if not _require(is_equal_approx(SettingsManager.ambience_volume, -9.0), "ambience volume was not restored"): return
	if not _require(not SettingsManager.flicker_enabled, "flicker setting was not restored"): return
	if not _require(not SettingsManager.comfort_head_bob, "head-bob setting was not restored"): return
	if not _require(not SettingsManager.camera_shake_enabled, "camera-shake setting was not restored"): return
	if not _require(not SettingsManager.film_grain_enabled, "film-grain setting was not restored"): return
	if not _require(not SettingsManager.fullscreen_enabled, "fullscreen setting was not restored"): return
	print("SETTINGS_PERSISTENCE_READ_OK")
	get_tree().quit()

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SETTINGS_PERSISTENCE_ASSERT: " + message)
	get_tree().quit(2)
	return false
