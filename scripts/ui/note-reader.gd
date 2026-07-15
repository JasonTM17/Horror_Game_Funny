extends CanvasLayer

var director: Node
var player: Node
var panel: Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func open(owner: Node, actor: Node, title: String, body: String) -> void:
	director = owner
	player = actor
	$Panel/Title.text = title
	$Panel/Body.text = body
	visible = true
	if player != null and player.has_method("set_input_locked"):
		player.set_input_locked("note", true)
	$Panel/Close.grab_focus()

func _build_ui() -> void:
	panel = Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(210, 90)
	panel.size = Vector2(540, 360)
	add_child(panel)
	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(34, 24)
	title.size = Vector2(470, 42)
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)
	var body := Label.new()
	body.name = "Body"
	body.position = Vector2(34, 84)
	body.size = Vector2(470, 180)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 17)
	body.add_theme_color_override("font_color", Color(0.76, 0.72, 0.65))
	panel.add_child(body)
	var close := Button.new()
	close.name = "Close"
	close.text = "CLOSE NOTE"
	close.position = Vector2(34, 290)
	close.size = Vector2(220, 44)
	close.pressed.connect(close_note)
	panel.add_child(close)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause_game"):
		close_note()

func close_note() -> void:
	if not visible:
		return
	visible = false
	if player != null and is_instance_valid(player) and player.has_method("set_input_locked"):
		player.set_input_locked("note", false)
	if director != null and director.has_method("on_note_closed"):
		director.on_note_closed()
