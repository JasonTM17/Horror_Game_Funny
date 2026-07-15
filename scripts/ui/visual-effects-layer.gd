class_name VisualEffectsLayer
extends CanvasLayer

const OVERLAY_SHADER := preload("res://shaders/retro-screen-overlay.gdshader")

var _overlay: ColorRect

func _ready() -> void:
	layer = 40
	_overlay = ColorRect.new()
	_overlay.name = "RetroOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material := ShaderMaterial.new()
	material.shader = OVERLAY_SHADER
	_overlay.material = material
	add_child(_overlay)
	_apply_film_grain(SettingsManager.film_grain_enabled)
	SettingsManager.setting_changed.connect(_on_setting_changed)

func _on_setting_changed(name: String, value: Variant) -> void:
	if name == "film_grain_enabled":
		_apply_film_grain(bool(value))

func _apply_film_grain(enabled: bool) -> void:
	if _overlay != null:
		_overlay.visible = enabled
