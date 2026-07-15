extends Node

signal setting_changed(name: String, value: float)

const CONFIG_PATH := "user://room407.cfg"
var mouse_sensitivity: float = 0.08
var field_of_view: float = 74.0
var master_volume: float = 0.0
var flicker_enabled: bool = true
var comfort_head_bob: bool = true

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
	AudioServer.set_bus_volume_db(0, master_volume)
	setting_changed.emit("master_volume", master_volume)

func set_flicker_enabled(enabled: bool) -> void:
	flicker_enabled = enabled

func set_comfort_head_bob(enabled: bool) -> void:
	comfort_head_bob = enabled

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("display", "field_of_view", field_of_view)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("accessibility", "flicker_enabled", flicker_enabled)
	config.set_value("accessibility", "comfort_head_bob", comfort_head_bob)
	config.save(CONFIG_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		set_master_volume(master_volume)
		return
	set_mouse_sensitivity(float(config.get_value("controls", "mouse_sensitivity", mouse_sensitivity)))
	set_field_of_view(float(config.get_value("display", "field_of_view", field_of_view)))
	set_master_volume(float(config.get_value("audio", "master_volume", master_volume)))
	set_flicker_enabled(bool(config.get_value("accessibility", "flicker_enabled", flicker_enabled)))
	set_comfort_head_bob(bool(config.get_value("accessibility", "comfort_head_bob", comfort_head_bob)))

