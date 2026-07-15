extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const EXPECTED_HEAD_HEIGHT := 1.52
const EXPECTED_INITIAL_PITCH := -8.0

var _gameplay: Node3D

func _ready() -> void:
	GameState.reset_run()
	_gameplay = GAMEPLAY_SCENE.instantiate()
	add_child(_gameplay)
	await get_tree().process_frame
	await get_tree().physics_frame
	_gameplay._narrative.duration_scale = 0.001
	var player := _gameplay.player as CharacterBody3D
	var head := player.get_node("Head") as Node3D
	var interaction := player.get_node("Head/Camera3D/Interaction")

	if not _require(is_equal_approx(head.position.y, EXPECTED_HEAD_HEIGHT), "head bob changed the authored eye height from %.2f to %.3f" % [EXPECTED_HEAD_HEIGHT, head.position.y]): return
	if not _require(is_equal_approx(rad_to_deg(head.rotation.x), EXPECTED_INITIAL_PITCH), "initial camera pitch was not applied to Head"): return
	if not _require(_has_physical_e_binding(), "interact action is not bound to the physical E key"): return
	if not _require(interaction.ray.collision_mask == 4, "interaction ray does not use the named Interactable physics layer"): return
	if not await _verify_production_interaction(player, interaction): return
	if not _verify_objective_review(): return
	if not _verify_pause_and_flashlight(player): return
	if not _verify_comfort_head_bob_restores_authored_origin(player, head): return

	SettingsManager.reset_defaults()
	AudioManager.stop_all()
	print("PLAYER_INPUT_INTEGRATION_TEST_OK")
	_gameplay.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _verify_production_interaction(player: CharacterBody3D, interaction: Node) -> bool:
	var phone := _gameplay.get_node("phone") as StoryInteractable
	if not _require((phone.collision_layer & 4) != 0 and (phone.collision_layer & 8) == 0, "phone collider is not assigned to the named Interactable layer"): return false
	player.global_position = Vector3(phone.global_position.x, 0.02, phone.global_position.z + 1.35)
	player.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	interaction.ray.force_raycast_update()
	if not _require(interaction.ray.is_colliding(), "production interaction ray did not reach the phone"): return false
	if not _require(interaction.ray.get_collider() == phone, "production interaction ray hit the wrong collider"): return false
	var interact_event := InputEventAction.new()
	interact_event.action = "interact"
	interact_event.pressed = true
	interaction._unhandled_input(interact_event)
	return _require(GameState.has_flag("phone_answered"), "production interact handler did not answer the phone")

func _verify_objective_review() -> bool:
	var hud := _gameplay.get_node("HUD")
	if not _require(hud.has_method("get_objective_focus_time"), "HUD does not consume the objective review action"): return false
	var focus_before: float = hud.get_objective_focus_time()
	var objective_event := InputEventAction.new()
	objective_event.action = "show_objective"
	objective_event.pressed = true
	hud._unhandled_input(objective_event)
	return _require(hud.get_objective_focus_time() > focus_before, "Tab did not refresh objective visibility")

func _verify_pause_and_flashlight(player: CharacterBody3D) -> bool:
	var pause_event := InputEventAction.new()
	pause_event.action = "pause_game"
	pause_event.pressed = true
	var flashlight_event := InputEventAction.new()
	flashlight_event.action = "flashlight"
	flashlight_event.pressed = true
	var flashlight := player.get_node("Head/Camera3D/Flashlight") as SpotLight3D

	player._unhandled_input(pause_event)
	if not _require(get_tree().paused and player.is_input_locked(), "pause did not freeze the SceneTree and lock player input"): return false
	var paused_visibility := flashlight.visible
	player._unhandled_input(flashlight_event)
	if not _require(flashlight.visible == paused_visibility, "flashlight toggled while the game was paused"): return false
	player._unhandled_input(pause_event)
	if not _require(not get_tree().paused and not player.is_input_locked(), "second pause action did not resume and unlock input"): return false
	player._unhandled_input(flashlight_event)
	return _require(flashlight.visible != paused_visibility, "flashlight did not toggle after input resumed")

func _verify_comfort_head_bob_restores_authored_origin(player: CharacterBody3D, head: Node3D) -> bool:
	SettingsManager.set_comfort_head_bob(false)
	head.position += Vector3(0.08, -0.2, 0.0)
	player._update_head_bob(1.0, false)
	return _require(head.position.is_equal_approx(Vector3(0.0, EXPECTED_HEAD_HEIGHT, 0.0)), "comfort mode did not restore the authored head origin")

func _has_physical_e_binding() -> bool:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey and (event.physical_keycode == KEY_E or event.keycode == KEY_E):
			return true
	return false

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	get_tree().paused = false
	push_error("PLAYER_INPUT_ASSERT: " + message)
	get_tree().quit(2)
	return false
