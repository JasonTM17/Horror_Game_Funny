extends Node

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
	subtitle.text = "A continuous 15–20 minute night shift.\nNo combat. Keep the light on."
	subtitle.position = Vector2(92, 215)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.48, 0.55, 0.62))
	panel.add_child(subtitle)
	var start := Button.new()
	start.name = "Start"
	start.text = "START SHIFT"
	start.position = Vector2(92, 320)
	start.size = Vector2(220, 52)
	start.add_theme_font_size_override("font_size", 18)
	start.pressed.connect(_start_shift)
	panel.add_child(start)
	var continue_shift := Button.new()
	continue_shift.name = "Continue"
	continue_shift.text = "CONTINUE CHECKPOINT"
	continue_shift.position = Vector2(92, 378)
	continue_shift.size = Vector2(220, 42)
	continue_shift.visible = not GameState.checkpoint.is_empty()
	continue_shift.pressed.connect(_continue_shift)
	panel.add_child(continue_shift)
	var settings := Button.new()
	settings.name = "Settings"
	settings.text = "SETTINGS"
	settings.position = Vector2(92, 433)
	settings.size = Vector2(220, 42)
	settings.pressed.connect(_show_settings)
	panel.add_child(settings)
	var quit := Button.new()
	quit.name = "Quit"
	quit.text = "QUIT"
	quit.position = Vector2(92, 488)
	quit.size = Vector2(220, 42)
	quit.pressed.connect(func() -> void: get_tree().quit())
	panel.add_child(quit)
	var settings_panel := preload("res://scenes/ui/settings-panel.tscn").instantiate()
	add_child(settings_panel)
	settings_panel.name = "SettingsPanel"

func _start_shift() -> void:
	GameState.reset_run()
	SceneRouter.change_scene("res://scenes/gameplay/gameplay.tscn")

func _continue_shift() -> void:
	SceneRouter.reload_checkpoint()

func _show_settings() -> void:
	var settings_panel := get_node_or_null("SettingsPanel")
	if settings_panel != null:
		settings_panel.open_panel()
