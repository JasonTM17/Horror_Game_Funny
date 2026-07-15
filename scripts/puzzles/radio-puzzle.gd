extends CanvasLayer

var director: Node
var player: Node
var panel: Panel
var entry: LineEdit
var result: Label
var failures := 0
var submit_button: Button
var _accepting_input := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func open(owner: Node, actor: Node) -> void:
	director = owner
	player = actor
	entry.text = ""
	result.text = "The voice repeats: zero, zero, zero..."
	_accepting_input = true
	entry.editable = true
	if submit_button != null:
		submit_button.disabled = false
	visible = true
	entry.grab_focus()
	if player != null and player.has_method("set_input_locked"):
		player.set_input_locked("radio", true)

func _build_ui() -> void:
	panel = Panel.new()
	panel.position = Vector2(300, 125)
	panel.size = Vector2(360, 270)
	add_child(panel)
	var title := Label.new()
	title.text = "RADIO  /  CHANNEL 04"
	title.position = Vector2(32, 24)
	title.add_theme_font_size_override("font_size", 20)
	panel.add_child(title)
	var hint := Label.new()
	hint.text = "The static is counting. Enter four digits."
	hint.position = Vector2(32, 66)
	hint.add_theme_color_override("font_color", Color(0.58, 0.63, 0.68))
	panel.add_child(hint)
	entry = LineEdit.new()
	entry.position = Vector2(32, 112)
	entry.size = Vector2(296, 46)
	entry.placeholder_text = "0000"
	entry.max_length = 4
	entry.alignment = HORIZONTAL_ALIGNMENT_CENTER
	entry.add_theme_font_size_override("font_size", 24)
	entry.text_changed.connect(_on_text_changed)
	entry.text_submitted.connect(func(_text: String) -> void: _submit())
	panel.add_child(entry)
	submit_button = Button.new()
	submit_button.text = "TUNE"
	submit_button.position = Vector2(32, 172)
	submit_button.size = Vector2(140, 42)
	submit_button.pressed.connect(_submit)
	panel.add_child(submit_button)
	var cancel := Button.new()
	cancel.text = "STEP AWAY"
	cancel.position = Vector2(188, 172)
	cancel.size = Vector2(140, 42)
	cancel.pressed.connect(close)
	panel.add_child(cancel)
	result = Label.new()
	result.position = Vector2(32, 224)
	result.size = Vector2(296, 32)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(result)

func _on_text_changed(value: String) -> void:
	var filtered := ""
	for character in value:
		if character >= "0" and character <= "9":
			filtered += character
	if filtered != value:
		entry.text = filtered

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		close()

func _submit() -> void:
	if not _accepting_input:
		return
	if entry.text.length() != 4:
		result.text = "The radio needs exactly four digits."
		return
	if entry.text == "0007":
		if director != null and director.has_method("on_radio_solved"):
			director.on_radio_solved()
		close()
		return
	failures += 1
	result.text = "Wrong. Static swallows the channel."
	if failures >= 3:
		result.text = "Hint: the clock stopped at 00:07."
	_accepting_input = false
	entry.editable = false
	submit_button.disabled = true
	AudioManager.play_tone("radio_wrong_static", 96.0, 0.45, -18.0)
	_finish_wrong_feedback()

func _finish_wrong_feedback() -> void:
	await get_tree().create_timer(0.55).timeout
	if not is_inside_tree() or not visible:
		return
	entry.text = ""
	entry.editable = true
	submit_button.disabled = false
	_accepting_input = true
	entry.grab_focus()

func close() -> void:
	visible = false
	if player != null and is_instance_valid(player) and player.has_method("set_input_locked"):
		player.set_input_locked("radio", false)
