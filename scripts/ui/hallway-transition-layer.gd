class_name HallwayTransitionLayer
extends CanvasLayer

signal transition_finished

var running := false
var _curtain: ColorRect

func _ready() -> void:
	layer = 80
	_curtain = ColorRect.new()
	_curtain.name = "BlackoutCurtain"
	_curtain.color = Color.BLACK
	_curtain.modulate.a = 0.0
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_curtain)

func play(actor: Node, subtitle: String, midpoint_action: Callable, duration_scale := 1.0) -> bool:
	if running or not midpoint_action.is_valid():
		return false
	running = true
	_run_transition(actor, subtitle, midpoint_action, duration_scale)
	return true

func _run_transition(actor: Node, subtitle: String, midpoint_action: Callable, duration_scale: float) -> void:
	if actor != null and actor.has_method("set_input_locked"):
		actor.set_input_locked("hallway", true)
	GameState.set_subtitle(subtitle)
	var scale := clampf(duration_scale, 0.001, 1.0)
	var fade_in := create_tween()
	fade_in.tween_property(_curtain, "modulate:a", 1.0, 0.35 * scale)
	await fade_in.finished
	midpoint_action.call()
	AudioManager.play_tone("hallway_blackout", 48.0, 0.8, -15.0, "Ambience")
	await get_tree().create_timer(3.3 * scale).timeout
	var fade_out := create_tween()
	fade_out.tween_property(_curtain, "modulate:a", 0.0, 0.35 * scale)
	await fade_out.finished
	GameState.set_subtitle("")
	if actor != null and is_instance_valid(actor) and actor.has_method("set_input_locked"):
		actor.set_input_locked("hallway", false)
	running = false
	transition_finished.emit()
