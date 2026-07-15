extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/Resume.pressed.connect(_resume)
	$Panel/Restart.pressed.connect(_restart)
	$Panel/Menu.pressed.connect(_menu)

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

func _menu() -> void:
	get_tree().paused = false
	SceneRouter.change_scene("res://scenes/boot/boot.tscn")
