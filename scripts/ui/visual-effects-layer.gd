class_name VisualEffectsLayer
extends CanvasLayer

const OVERLAY_SHADER := preload("res://shaders/retro-screen-overlay.gdshader")

var _overlay: ColorRect
var _material: ShaderMaterial
var _fear_intensity := 0.0
var _target_fear_intensity := 0.0

func _ready() -> void:
	layer = 40
	_overlay = ColorRect.new()
	_overlay.name = "RetroOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = OVERLAY_SHADER
	_overlay.material = _material
	add_child(_overlay)
	_apply_film_grain(SettingsManager.film_grain_enabled)
	SettingsManager.setting_changed.connect(_on_setting_changed)
	GameState.stage_changed.connect(_on_stage_changed)
	_on_stage_changed(GameState.stage)

func _process(delta: float) -> void:
	_fear_intensity = move_toward(_fear_intensity, _target_fear_intensity, delta * 3.5)
	if _material != null:
		_material.set_shader_parameter("fear_intensity", _fear_intensity)

func get_fear_intensity() -> float:
	return _fear_intensity

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
