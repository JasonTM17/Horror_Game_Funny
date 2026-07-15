extends Node

func _ready() -> void:
	GameState.reset_run()
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
	start.text = "START SHIFT"
	start.position = Vector2(92, 320)
	start.size = Vector2(220, 52)
	start.add_theme_font_size_override("font_size", 18)
	start.pressed.connect(_start_shift)
	panel.add_child(start)
	var settings := Button.new()
	settings.text = "SETTINGS"
	settings.position = Vector2(92, 385)
	settings.size = Vector2(220, 42)
	settings.pressed.connect(_show_settings)
	panel.add_child(settings)
	var quit := Button.new()
	quit.text = "QUIT"
	quit.position = Vector2(92, 440)
	quit.size = Vector2(220, 42)
	quit.pressed.connect(func() -> void: get_tree().quit())
	panel.add_child(quit)

func _start_shift() -> void:
	SceneRouter.change_scene("res://scenes/gameplay/gameplay.tscn")

func _show_settings() -> void:
	SettingsManager.set_comfort_head_bob(not SettingsManager.comfort_head_bob)
	SettingsManager.save_settings()
