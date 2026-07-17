extends Node

var _start_button: Button
var _continue_button: Button
var _settings_button: Button
var _focus_before_settings: Control
var _menu_buttons: Array[Button] = []

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.008, 0.012, 0.02, 1.0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(panel)
	var title := Label.new()
	title.text = "ROOM 407\nTHE LAST SHIFT"
	title.position = Vector2(88, 92)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.84, 0.86, 0.88))
	panel.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "23:47. One last room remains unchecked.\nKeep the light on. Finish the shift."
	subtitle.position = Vector2(92, 215)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.48, 0.55, 0.62))
	panel.add_child(subtitle)
	_start_button = Button.new()
	_start_button.name = "Start"
	_start_button.text = "START SHIFT"
	_start_button.position = Vector2(92, 320)
	_start_button.size = Vector2(220, 52)
	_start_button.add_theme_font_size_override("font_size", 18)
	_start_button.pressed.connect(_start_shift)
	panel.add_child(_start_button)
	_continue_button = Button.new()
	_continue_button.name = "Continue"
	_continue_button.text = "CONTINUE SHIFT"
	_continue_button.position = Vector2(92, 378)
	_continue_button.size = Vector2(220, 42)
	_continue_button.visible = not GameState.checkpoint.is_empty()
	_continue_button.pressed.connect(_continue_shift)
	panel.add_child(_continue_button)
	_settings_button = Button.new()
	_settings_button.name = "Settings"
	_settings_button.text = "SETTINGS"
	_settings_button.position = Vector2(92, 433)
	_settings_button.size = Vector2(220, 42)
	_settings_button.pressed.connect(_show_settings)
	panel.add_child(_settings_button)
	var quit := Button.new()
	quit.name = "Quit"
	quit.text = "QUIT"
	quit.position = Vector2(92, 488)
	quit.size = Vector2(220, 42)
	quit.pressed.connect(func() -> void: get_tree().quit())
	panel.add_child(quit)
	_menu_buttons = [_start_button, _continue_button, _settings_button, quit]
	var settings_panel := preload("res://scenes/ui/settings-panel.tscn").instantiate()
	add_child(settings_panel)
	settings_panel.name = "SettingsPanel"
	settings_panel.panel_closed.connect(_on_settings_closed)
	call_deferred("_focus_primary_action")

func _start_shift() -> void:
	GameState.reset_run()
	SceneRouter.change_scene("res://scenes/gameplay/gameplay.tscn")

func _continue_shift() -> void:
	SceneRouter.reload_checkpoint()

func _show_settings() -> void:
	var settings_panel := get_node_or_null("SettingsPanel")
	if settings_panel == null:
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	_focus_before_settings = focus_owner if is_instance_valid(focus_owner) else _settings_button
	_set_menu_enabled(false)
	settings_panel.open_panel()

func _on_settings_closed() -> void:
	_set_menu_enabled(true)
	var target := _focus_before_settings
	if not is_instance_valid(target) or not target.is_visible_in_tree():
		target = _settings_button
	if is_instance_valid(target) and target.is_visible_in_tree():
		target.grab_focus()
	_focus_before_settings = null

func _focus_primary_action() -> void:
	if is_instance_valid(_continue_button) and _continue_button.visible:
		_continue_button.grab_focus()
	elif is_instance_valid(_start_button):
		_start_button.grab_focus()

func _set_menu_enabled(enabled: bool) -> void:
	for button in _menu_buttons:
		if not is_instance_valid(button):
			continue
		button.disabled = not enabled
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
