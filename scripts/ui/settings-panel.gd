extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Panel/Sensitivity.value = SettingsManager.mouse_sensitivity
	$Panel/Fov.value = SettingsManager.field_of_view
	$Panel/Flicker.button_pressed = SettingsManager.flicker_enabled
	$Panel/HeadBob.button_pressed = SettingsManager.comfort_head_bob
	$Panel/Sensitivity.value_changed.connect(_on_sensitivity)
	$Panel/Fov.value_changed.connect(_on_fov)
	$Panel/Flicker.toggled.connect(SettingsManager.set_flicker_enabled)
	$Panel/HeadBob.toggled.connect(SettingsManager.set_comfort_head_bob)
	$Panel/Close.pressed.connect(close_panel)

func open_panel() -> void:
	visible = true
	$Panel/Close.grab_focus()

func close_panel() -> void:
	SettingsManager.save_settings()
	visible = false

func _on_sensitivity(value: float) -> void:
	SettingsManager.set_mouse_sensitivity(value)

func _on_fov(value: float) -> void:
	SettingsManager.set_field_of_view(value)
