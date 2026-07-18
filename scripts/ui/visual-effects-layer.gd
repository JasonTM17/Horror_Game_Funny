class_name VisualEffectsLayer
extends CanvasLayer

const OVERLAY_SHADER := preload("res://shaders/retro-screen-overlay.gdshader")
const BASE_VIGNETTE_STRENGTH := 0.085
const FEAR_VIGNETTE_STRENGTH := 0.34

var _overlay: ColorRect
var _material: ShaderMaterial
var _fear_intensity := 0.0
var _target_fear_intensity := 0.0
var _pulse_intensity := 0.0
var _pulse_peak_intensity := 0.0
var _pulse_remaining := 0.0
var _pulse_total := 0.0

func _ready() -> void:
	name = "VisualEffects"
	add_to_group("visual_effects")
	layer = 40
	_overlay = ColorRect.new()
	_overlay.name = "RetroOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = OVERLAY_SHADER
	_material.set_shader_parameter("base_vignette_strength", BASE_VIGNETTE_STRENGTH)
	_material.set_shader_parameter("fear_vignette_strength", FEAR_VIGNETTE_STRENGTH)
	_overlay.material = _material
	add_child(_overlay)
	_apply_film_grain(SettingsManager.film_grain_enabled)
	SettingsManager.setting_changed.connect(_on_setting_changed)
	GameState.stage_changed.connect(_on_stage_changed)
	_on_stage_changed(GameState.stage)

func _process(delta: float) -> void:
	if _pulse_remaining > 0.0:
		# Recalculate from the original peak, rather than multiplying the
		# previous frame's value. Repeated multiplication collapses a planned
		# scare cue in a few frames at normal frame rates.
		var fade := clampf(_pulse_remaining / _pulse_total, 0.0, 1.0)
		_pulse_intensity = _pulse_peak_intensity * fade
		_pulse_remaining = maxf(0.0, _pulse_remaining - delta)
	else:
		_pulse_intensity = 0.0
		_pulse_peak_intensity = 0.0
	var desired := maxf(_target_fear_intensity, _pulse_intensity)
	_fear_intensity = move_toward(_fear_intensity, desired, delta * 3.5)
	if _material != null:
		_material.set_shader_parameter("fear_intensity", _fear_intensity)

func get_fear_intensity() -> float:
	return _fear_intensity

## Story-scare vignette spike. Does not change stage-driven chase target.
func pulse_fear(intensity: float, hold_seconds: float) -> void:
	_pulse_peak_intensity = maxf(_pulse_intensity, clampf(intensity, 0.0, 1.0))
	_pulse_total = maxf(0.05, hold_seconds)
	_pulse_remaining = _pulse_total
	_pulse_intensity = _pulse_peak_intensity

func _on_setting_changed(name: String, value: Variant) -> void:
	if name == "film_grain_enabled":
		_apply_film_grain(bool(value))

func _on_stage_changed(stage: int) -> void:
	match stage:
		GameState.Stage.CHASE:
			_target_fear_intensity = 1.0
		GameState.Stage.ENDING:
			_target_fear_intensity = 0.12
		_:
			_target_fear_intensity = 0.0

func _apply_film_grain(enabled: bool) -> void:
	if _overlay != null:
		_overlay.visible = enabled
