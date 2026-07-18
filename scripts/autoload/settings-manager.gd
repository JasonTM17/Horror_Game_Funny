extends Node

signal setting_changed(name: String, value: Variant)
signal settings_save_failed(path: String, error: Error)

const CONFIG_PATH := "user://room407.cfg"
var mouse_sensitivity: float = 0.08
var field_of_view: float = 74.0
var master_volume: float = 0.0
var music_volume: float = -10.0
var sfx_volume: float = -4.0
var ambience_volume: float = -8.0
var flicker_enabled: bool = true
var comfort_head_bob: bool = true
var camera_shake_enabled: bool = true
var film_grain_enabled: bool = true
var fullscreen_enabled: bool = false

func _ready() -> void:
	load_settings()

func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.01, 0.25)
	setting_changed.emit("mouse_sensitivity", mouse_sensitivity)

func set_field_of_view(value: float) -> void:
	field_of_view = clampf(value, 60.0, 95.0)
	setting_changed.emit("field_of_view", field_of_view)

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, -40.0, 6.0)
	_set_bus_volume("Master", master_volume)
	setting_changed.emit("master_volume", master_volume)

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, -40.0, 6.0)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("Chase", music_volume)
	setting_changed.emit("music_volume", music_volume)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, -40.0, 6.0)
	_set_bus_volume("SFX", sfx_volume)
	setting_changed.emit("sfx_volume", sfx_volume)

func set_ambience_volume(value: float) -> void:
	ambience_volume = clampf(value, -40.0, 6.0)
	_set_bus_volume("Ambience", ambience_volume)
	setting_changed.emit("ambience_volume", ambience_volume)

func set_flicker_enabled(enabled: bool) -> void:
	flicker_enabled = enabled
	setting_changed.emit("flicker_enabled", flicker_enabled)

func set_comfort_head_bob(enabled: bool) -> void:
	comfort_head_bob = enabled
	setting_changed.emit("comfort_head_bob", comfort_head_bob)

func set_camera_shake_enabled(enabled: bool) -> void:
	camera_shake_enabled = enabled
	setting_changed.emit("camera_shake_enabled", camera_shake_enabled)

func set_film_grain_enabled(enabled: bool) -> void:
	film_grain_enabled = enabled
	setting_changed.emit("film_grain_enabled", film_grain_enabled)

func set_fullscreen_enabled(enabled: bool) -> void:
	fullscreen_enabled = enabled
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	SceneRouter.call_deferred("apply_player_window_title")
	setting_changed.emit("fullscreen_enabled", fullscreen_enabled)

func reset_defaults() -> void:
	set_mouse_sensitivity(0.08)
	set_field_of_view(74.0)
	set_master_volume(0.0)
	set_music_volume(-10.0)
	set_sfx_volume(-4.0)
	set_ambience_volume(-8.0)
	set_flicker_enabled(true)
	set_comfort_head_bob(true)
	set_camera_shake_enabled(true)
	set_film_grain_enabled(true)
	set_fullscreen_enabled(false)

func save_settings(config_path: String = CONFIG_PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("display", "field_of_view", field_of_view)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ambience_volume", ambience_volume)
	config.set_value("accessibility", "flicker_enabled", flicker_enabled)
	config.set_value("accessibility", "comfort_head_bob", comfort_head_bob)
	config.set_value("accessibility", "camera_shake_enabled", camera_shake_enabled)
	config.set_value("accessibility", "film_grain_enabled", film_grain_enabled)
	config.set_value("display", "fullscreen_enabled", fullscreen_enabled)
	var save_error := config.save(config_path)
	if save_error != OK:
		settings_save_failed.emit(config_path, save_error)
	return save_error

func load_settings(config_path: String = CONFIG_PATH) -> void:
	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		set_master_volume(master_volume)
		set_music_volume(music_volume)
		set_sfx_volume(sfx_volume)
		set_ambience_volume(ambience_volume)
		return
	set_mouse_sensitivity(_finite_number(config, "controls", "mouse_sensitivity", mouse_sensitivity))
	set_field_of_view(_finite_number(config, "display", "field_of_view", field_of_view))
	set_master_volume(_finite_number(config, "audio", "master_volume", master_volume))
	set_music_volume(_finite_number(config, "audio", "music_volume", music_volume))
	set_sfx_volume(_finite_number(config, "audio", "sfx_volume", sfx_volume))
	set_ambience_volume(_finite_number(config, "audio", "ambience_volume", ambience_volume))
	set_flicker_enabled(_boolean(config, "accessibility", "flicker_enabled", flicker_enabled))
	set_comfort_head_bob(_boolean(config, "accessibility", "comfort_head_bob", comfort_head_bob))
	set_camera_shake_enabled(_boolean(config, "accessibility", "camera_shake_enabled", camera_shake_enabled))
	set_film_grain_enabled(_boolean(config, "accessibility", "film_grain_enabled", film_grain_enabled))
	set_fullscreen_enabled(_boolean(config, "display", "fullscreen_enabled", fullscreen_enabled))

func _finite_number(config: ConfigFile, section: String, key: String, fallback: float) -> float:
	var value: Variant = config.get_value(section, key, fallback)
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return fallback
	var number := float(value)
	return number if is_finite(number) else fallback

func _boolean(config: ConfigFile, section: String, key: String, fallback: bool) -> bool:
	var value: Variant = config.get_value(section, key, fallback)
	return bool(value) if typeof(value) == TYPE_BOOL else fallback

func _set_bus_volume(bus_name: String, volume_db: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, volume_db)
