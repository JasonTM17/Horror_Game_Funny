extends CanvasLayer

const OBJECTIVE_CHANGE_FOCUS_SECONDS := 3.0
const OBJECTIVE_REVIEW_SECONDS := 5.0
const OBJECTIVE_DIM_ALPHA := 0.58

@onready var objective_label: Label = $Margin/Column/Objective
@onready var inventory_label: Label = $Margin/Column/Inventory
@onready var prompt_label: Label = $Prompt
@onready var feedback_label: Label = $Feedback
@onready var subtitle_label: Label = $Subtitle
var _feedback_time := 0.0
var _objective_focus_time := 0.0

func _ready() -> void:
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.subtitle_changed.connect(_on_subtitle_changed)
	_on_objective_changed(GameState.objective)
	_on_inventory_changed(GameState.inventory)
	_on_subtitle_changed(GameState.subtitle)
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var interaction := player.get_node_or_null("Head/Camera3D/Interaction")
		if interaction != null:
			interaction.prompt_changed.connect(_on_prompt_changed)
			interaction.feedback_requested.connect(_on_feedback_requested)

func _process(delta: float) -> void:
	if _objective_focus_time > 0.0:
		_objective_focus_time = maxf(0.0, _objective_focus_time - delta)
	else:
		objective_label.modulate.a = move_toward(objective_label.modulate.a, OBJECTIVE_DIM_ALPHA, delta * 1.8)
	if _feedback_time > 0.0:
		_feedback_time -= delta
		if _feedback_time <= 0.0:
			feedback_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("show_objective"):
		_focus_objective(OBJECTIVE_REVIEW_SECONDS)

func get_objective_focus_time() -> float:
	return _objective_focus_time

func _on_objective_changed(text: String) -> void:
	objective_label.text = "OBJECTIVE\n" + text
	_focus_objective(OBJECTIVE_CHANGE_FOCUS_SECONDS)

func _on_inventory_changed(items: Array[String]) -> void:
	if items.is_empty():
		inventory_label.text = "POCKETS\n(empty)"
	else:
		inventory_label.text = "POCKETS\n" + "\n".join(items)

func _on_prompt_changed(text: String) -> void:
	prompt_label.text = text

func _on_feedback_requested(text: String) -> void:
	if text.is_empty():
		return
	feedback_label.text = text
	_feedback_time = 2.4

func _on_subtitle_changed(text: String) -> void:
	subtitle_label.text = text

func _focus_objective(duration: float) -> void:
	_objective_focus_time = maxf(_objective_focus_time, duration)
	objective_label.modulate.a = 1.0
