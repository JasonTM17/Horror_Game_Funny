extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/Resume.pressed.connect(_resume)
	$Panel/Settings.pressed.connect(_settings)
	$Panel/Restart.pressed.connect(_restart)
	$Panel/Menu.pressed.connect(_menu)
	$SettingsPanel.panel_closed.connect(_on_settings_closed)

func _process(_delta: float) -> void:
	var should_show: bool = get_tree().paused and not bool($SettingsPanel.visible)
	if $Panel.visible == should_show:
		return
	$Panel.visible = should_show
	if should_show and not $SettingsPanel.visible:
		$Panel/Resume.grab_focus()
	elif not should_show:
		_release_panel_focus()

func _resume() -> void:
	$Panel.visible = false
	_release_panel_focus()
	get_tree().paused = false
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set_input_locked("pause", false)

func _restart() -> void:
	_release_panel_focus()
	get_tree().paused = false
	GameState.reset_run()
	SceneRouter.change_scene("res://scenes/gameplay/gameplay.tscn")

func _settings() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set_input_locked("settings", true)
	$Panel.visible = false
	_release_panel_focus()
	$SettingsPanel.open_panel()

func _on_settings_closed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set_input_locked("settings", false)
	if get_tree().paused:
		$Panel.visible = true
		$Panel/Settings.grab_focus()

func _menu() -> void:
	_release_panel_focus()
	get_tree().paused = false
	SceneRouter.change_scene("res://scenes/boot/boot.tscn")

func _release_panel_focus() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus_owner) and $Panel.is_ancestor_of(focus_owner):
		focus_owner.release_focus()
