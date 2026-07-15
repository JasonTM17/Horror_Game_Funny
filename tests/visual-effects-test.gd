extends Node

const VISUAL_EFFECTS_SCRIPT := preload("res://scripts/ui/visual-effects-layer.gd")

var _layer: VisualEffectsLayer

func _ready() -> void:
	GameState.reset_run()
	SettingsManager.set_film_grain_enabled(true)
	_layer = VISUAL_EFFECTS_SCRIPT.new() as VisualEffectsLayer
	add_child(_layer)
	await get_tree().process_frame

	if not _require(_layer.has_method("get_fear_intensity"), "visual layer does not expose its chase intensity"): return
	var overlay := _layer.get_node_or_null("RetroOverlay") as ColorRect
	if not _require(overlay != null and overlay.material is ShaderMaterial, "retro overlay material is missing"): return
	var material := overlay.material as ShaderMaterial
	var shader := material.shader
	for uniform_name in ["dither_strength", "vhs_strength", "fear_intensity"]:
		if not _require(_shader_has_uniform(shader, uniform_name), "%s shader uniform is missing" % uniform_name): return
	if not _require(is_zero_approx(_layer.get_fear_intensity()), "fear vignette started outside the chase"): return

	GameState.advance_stage(GameState.Stage.CHASE)
	await get_tree().create_timer(0.4).timeout
	if not _require(_layer.get_fear_intensity() > 0.9, "fear vignette did not intensify during the chase"): return
	GameState.advance_stage(GameState.Stage.ENDING)
	await get_tree().create_timer(0.4).timeout
	if not _require(_layer.get_fear_intensity() < 0.2, "fear vignette did not settle for the ending"): return

	SettingsManager.set_film_grain_enabled(false)
	if not _require(not overlay.visible, "comfort toggle did not disable retro screen effects"): return
	SettingsManager.set_film_grain_enabled(true)
	if not _require(overlay.visible, "comfort toggle did not restore retro screen effects"): return

	SettingsManager.reset_defaults()
	GameState.reset_run()
	print("VISUAL_EFFECTS_TEST_OK")
	_layer.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _shader_has_uniform(shader: Shader, uniform_name: String) -> bool:
	for uniform_data in shader.get_shader_uniform_list():
		if str(uniform_data.get("name", "")) == uniform_name:
			return true
	return false

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("VISUAL_EFFECTS_ASSERT: " + message)
	get_tree().quit(2)
	return false
