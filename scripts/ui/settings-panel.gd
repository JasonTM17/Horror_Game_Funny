extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Panel/Sensitivity.value = SettingsManager.mouse_sensitivity
	$Panel/Fov.value = SettingsManager.field_of_view
	$Panel/Volume.value = SettingsManager.master_volume
	$Panel/Music.value = SettingsManager.music_volume
	$Panel/Sfx.value = SettingsManager.sfx_volume
	$Panel/Ambience.value = SettingsManager.ambience_volume
	$Panel/Flicker.button_pressed = SettingsManager.flicker_enabled
	$Panel/HeadBob.button_pressed = SettingsManager.comfort_head_bob
	$Panel/CameraShake.button_pressed = SettingsManager.camera_shake_enabled
	$Panel/FilmGrain.button_pressed = SettingsManager.film_grain_enabled
	$Panel/Fullscreen.button_pressed = SettingsManager.fullscreen_enabled
	$Panel/Sensitivity.value_changed.connect(_on_sensitivity)
	$Panel/Fov.value_changed.connect(_on_fov)
	$Panel/Volume.value_changed.connect(_on_volume)
	$Panel/Music.value_changed.connect(SettingsManager.set_music_volume)
	$Panel/Sfx.value_changed.connect(SettingsManager.set_sfx_volume)
	$Panel/Ambience.value_changed.connect(SettingsManager.set_ambience_volume)
	$Panel/Flicker.toggled.connect(SettingsManager.set_flicker_enabled)
	$Panel/HeadBob.toggled.connect(SettingsManager.set_comfort_head_bob)
	$Panel/CameraShake.toggled.connect(SettingsManager.set_camera_shake_enabled)
	$Panel/FilmGrain.toggled.connect(SettingsManager.set_film_grain_enabled)
	$Panel/Fullscreen.toggled.connect(SettingsManager.set_fullscreen_enabled)
	$Panel/Reset.pressed.connect(_reset_defaults)
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

func _on_volume(value: float) -> void:
	SettingsManager.set_master_volume(value)

func _reset_defaults() -> void:
	SettingsManager.reset_defaults()
	$Panel/Sensitivity.value = SettingsManager.mouse_sensitivity
	$Panel/Fov.value = SettingsManager.field_of_view
	$Panel/Volume.value = SettingsManager.master_volume
	$Panel/Music.value = SettingsManager.music_volume
	$Panel/Sfx.value = SettingsManager.sfx_volume
	$Panel/Ambience.value = SettingsManager.ambience_volume
	$Panel/Flicker.button_pressed = SettingsManager.flicker_enabled
	$Panel/HeadBob.button_pressed = SettingsManager.comfort_head_bob
	$Panel/CameraShake.button_pressed = SettingsManager.camera_shake_enabled
	$Panel/FilmGrain.button_pressed = SettingsManager.film_grain_enabled
	$Panel/Fullscreen.button_pressed = SettingsManager.fullscreen_enabled
