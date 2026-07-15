extends CanvasLayer

var _timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func show_failure() -> void:
	visible = true
	$Panel.modulate.a = 0.0
	_timer = 1.25
	var tween := create_tween()
	tween.tween_property($Panel, "modulate:a", 1.0, 0.25)
	tween.tween_interval(0.55)
	tween.tween_property($Panel, "modulate:a", 0.0, 0.4)

func _process(delta: float) -> void:
	if not visible:
		return
	_timer -= delta
	if _timer <= 0.0:
		visible = false
