extends CanvasLayer

var director: Node
var player: Node
var panel: Panel
var entry: LineEdit
var result: Label
var failures := 0
var submit_button: Button
var _accepting_input := true
var _feedback_generation := 0
var _cooldown_until_msec := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func open(owner: Node, actor: Node) -> void:
	director = owner
	player = actor
	entry.text = ""
	var cooldown_active := Time.get_ticks_msec() < _cooldown_until_msec
	result.text = "Static is settling. Wait..." if cooldown_active else "The voice repeats: zero, zero, zero..."
	_set_input_enabled(not cooldown_active)
	visible = true
	if _accepting_input:
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
	_feedback_generation += 1
	_cooldown_until_msec = Time.get_ticks_msec() + 550
	_set_input_enabled(false)
	AudioManager.play_tone("radio_wrong_static", 96.0, 0.45, -18.0)
	_finish_wrong_feedback(_feedback_generation)

func _finish_wrong_feedback(generation: int) -> void:
	var remaining_seconds := maxf(0.0, float(_cooldown_until_msec - Time.get_ticks_msec()) / 1000.0)
	if remaining_seconds > 0.0:
		await get_tree().create_timer(remaining_seconds).timeout
	if not is_inside_tree() or generation != _feedback_generation:
		return
	_cooldown_until_msec = 0
	entry.text = ""
	_set_input_enabled(true)
	if visible:
		entry.grab_focus()

func _set_input_enabled(enabled: bool) -> void:
	_accepting_input = enabled
	entry.editable = enabled
	if submit_button != null:
		submit_button.disabled = not enabled

func close() -> void:
	visible = false
	if player != null and is_instance_valid(player) and player.has_method("set_input_locked"):
		player.set_input_locked("radio", false)
