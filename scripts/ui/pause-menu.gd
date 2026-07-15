extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/Resume.pressed.connect(_resume)
	$Panel/Settings.pressed.connect(_settings)
	$Panel/Restart.pressed.connect(_restart)
	$Panel/Menu.pressed.connect(_menu)
	$SettingsPanel.panel_closed.connect(_on_settings_closed)

func _process(_delta: float) -> void:
	$Panel.visible = get_tree().paused

func _resume() -> void:
	get_tree().paused = false
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set_input_locked("pause", false)

func _restart() -> void:
	get_tree().paused = false
	GameState.reset_run()
	SceneRouter.change_scene("res://scenes/gameplay/gameplay.tscn")

func _settings() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set_input_locked("settings", true)
	$SettingsPanel.open_panel()

func _on_settings_closed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set_input_locked("settings", false)

func _menu() -> void:
	get_tree().paused = false
	SceneRouter.change_scene("res://scenes/boot/boot.tscn")
