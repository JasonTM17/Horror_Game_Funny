extends Node

const SETTINGS_SCENE := preload("res://scenes/ui/settings-panel.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause-menu.tscn")
const BOOT_SCENE := preload("res://scenes/boot/boot.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

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
	AudioManager.play_tone("test_cleanup", 51.0, 0.1, -30.0, "Ambience")
	await get_tree().process_frame
	if not _require(AudioManager._players.has("test_cleanup") and AudioManager._cache.has("test_cleanup") and AudioManager._sample_bytes > 0, "audio cleanup fixture was not created"): return
	AudioManager.stop_all()
	if not _require(AudioManager._players.is_empty() and AudioManager._cache.is_empty() and AudioManager._sample_bytes == 0, "audio teardown left cached state"): return
	var pause_menu := PAUSE_SCENE.instantiate()
	add_child(pause_menu)
	var player := PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame
	if not _require(pause_menu.has_node("Panel/Settings") and pause_menu.has_node("SettingsPanel"), "pause settings entry missing"): return
	player.set_input_locked("pause", true)
	pause_menu._settings()
	if not _require(pause_menu.get_node("SettingsPanel").visible and player.is_input_locked(), "pause settings did not preserve the input lock"): return
	var escape := InputEventAction.new()
	escape.action = "pause_game"
	escape.pressed = true
	pause_menu.get_node("SettingsPanel")._unhandled_input(escape)
	if not _require(not pause_menu.get_node("SettingsPanel").visible, "Escape did not close pause settings"): return
	if not _require(player.is_input_locked(), "closing settings cleared the pause lock"): return
	player.set_input_locked("pause", false)
	GameState.set_objective("Continue test")
	GameState.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "room_entrance")
	var boot_menu := BOOT_SCENE.instantiate()
	add_child(boot_menu)
	await get_tree().process_frame
	var continue_button := boot_menu.find_child("Continue", true, false) as Button
	if not _require(continue_button != null and continue_button.visible, "checkpoint continue button missing"): return
	SettingsManager.reset_defaults()
	print("SETTINGS_AUDIO_TEST_OK")
	panel.queue_free()
	pause_menu.queue_free()
	player.queue_free()
	boot_menu.queue_free()
	GameState.reset_run()
	await get_tree().process_frame
	get_tree().quit()

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SETTINGS_AUDIO_ASSERT: " + message)
	get_tree().quit(2)
	return false
