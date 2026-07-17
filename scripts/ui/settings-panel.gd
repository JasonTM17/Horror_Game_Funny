extends CanvasLayer

signal panel_closed

var _save_path := SettingsManager.CONFIG_PATH
var _last_save_error: Error = OK

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_sync_controls()
	_clear_save_error()
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
	$Panel/CloseWithoutSaving.pressed.connect(_close_without_saving)

func open_panel() -> void:
	_sync_controls()
	_clear_save_error()
	visible = true
	$Panel/Close.grab_focus()

func close_panel() -> void:
	if not visible:
		return
	var save_error := SettingsManager.save_settings(_save_path)
	if save_error != OK:
		_show_save_error(save_error)
		return
	_finish_close()

func _finish_close() -> void:
	_release_panel_focus()
	visible = false
	panel_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		if _last_save_error == OK:
			close_panel()
		else:
			_close_without_saving()

func _on_sensitivity(value: float) -> void:
	SettingsManager.set_mouse_sensitivity(value)

func _on_fov(value: float) -> void:
	SettingsManager.set_field_of_view(value)

func _on_volume(value: float) -> void:
	SettingsManager.set_master_volume(value)

func _reset_defaults() -> void:
	SettingsManager.reset_defaults()
	_sync_controls()

func _sync_controls() -> void:
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

func _show_save_error(save_error: Error) -> void:
	_last_save_error = save_error
	$Panel/SaveStatus.text = "Your settings could not be saved. They will remain active until you close the game."
	$Panel/SaveStatus.visible = true
	$Panel/CloseWithoutSaving.visible = true
	$Panel/Close.text = "RETRY SAVE"
	$Panel/Close.grab_focus()

func _clear_save_error() -> void:
	_last_save_error = OK
	$Panel/SaveStatus.text = ""
	$Panel/SaveStatus.visible = false
	$Panel/CloseWithoutSaving.visible = false
	$Panel/Close.text = "SAVE & CLOSE"

func _close_without_saving() -> void:
	if not visible:
		return
	_finish_close()

func _release_panel_focus() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus_owner) and $Panel.is_ancestor_of(focus_owner):
		focus_owner.release_focus()
