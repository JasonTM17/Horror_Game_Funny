extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func show_ending() -> void:
	visible = true
	$Panel/Replay.grab_focus()

func _on_replay_pressed() -> void:
	GameState.reset_run()
	SceneRouter.change_scene("res://scenes/gameplay/gameplay.tscn")

func _on_menu_pressed() -> void:
	GameState.reset_run()
	SceneRouter.change_scene("res://scenes/boot/boot.tscn")
