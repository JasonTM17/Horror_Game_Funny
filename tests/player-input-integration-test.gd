extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const NOTE_SCRIPT := preload("res://scripts/ui/note-reader.gd")
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
	if not await _verify_pause_and_flashlight(player): return
	if not await _verify_note_escape_restores_input(player): return
	if not await _verify_door_spam_and_reopen(player, interaction): return
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
	if not _require(flashlight.visible != paused_visibility, "flashlight did not toggle after input resumed"): return false
	if not flashlight.visible:
		flashlight.visible = true
	SettingsManager.set_flicker_enabled(true)
	if not _require(flashlight.process_mode == Node.PROCESS_MODE_PAUSABLE, "flashlight inherited always-on process mode from the paused player"): return false
	flashlight.flicker_chance = 1.0
	flashlight.flicker_interval_min = 0.01
	flashlight.flicker_interval_max = 0.01
	flashlight.pulse_duration_min = 0.05
	flashlight.pulse_duration_max = 0.05
	flashlight.flicker_min_energy = 0.2
	flashlight._flicker_check_remaining = 0.0
	flashlight._process(0.016)
	if not _require(flashlight.light_energy >= flashlight.flicker_min_energy - 0.01 and flashlight.light_energy <= flashlight._base_energy + 0.01, "flashlight pulse exceeded its authored energy bounds"): return false
	var paused_energy := flashlight.light_energy
	var paused_check_remaining: float = float(flashlight._flicker_check_remaining)
	get_tree().paused = true
	await get_tree().process_frame
	OS.delay_msec(120)
	await get_tree().process_frame
	var flicker_stayed_paused := is_equal_approx(flashlight.light_energy, paused_energy) and is_equal_approx(float(flashlight._flicker_check_remaining), paused_check_remaining)
	get_tree().paused = false
	await get_tree().process_frame
	return _require(flicker_stayed_paused, "flashlight pulse advanced while the game was paused")

func _verify_note_escape_restores_input(player: CharacterBody3D) -> bool:
	var note := NOTE_SCRIPT.new() as CanvasLayer
	_gameplay.add_child(note)
	await get_tree().process_frame
	note.open(null, player, "TEST NOTE", "Input must return after closing this note.")
	if not _require(note.visible and player.is_input_locked(), "opening a note did not lock player input"): return false
	var escape_event := InputEventAction.new()
	escape_event.action = "pause_game"
	escape_event.pressed = true
	note._unhandled_input(escape_event)
	if not _require(not note.visible and not player.is_input_locked(), "Escape did not close the note and restore player input"): return false
	note.queue_free()
	await get_tree().process_frame
	return true

func _verify_door_spam_and_reopen(player: CharacterBody3D, interaction: Node) -> bool:
	var door := _gameplay.get_node("floor_door") as DoorInteractable
	player.global_position = Vector3(0.8, 0.02, door.global_position.z + 1.35)
	player.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	interaction.ray.force_raycast_update()
	if not _require(interaction.ray.get_collider() == door, "interaction ray did not reach the floor door"): return false
	var interact_event := InputEventAction.new()
	interact_event.action = "interact"
	interact_event.pressed = true
	var denied_interactions := [0]
	var denied_callback := func(_actor: Node) -> void:
		denied_interactions[0] += 1
	door.interacted.connect(denied_callback)
	var denied_cooldown := door._cooldown_left
	interaction._unhandled_input(interact_event)
	door.interacted.disconnect(denied_callback)
	if not _require(not door.is_open and not door._moving and is_equal_approx(door._cooldown_left, denied_cooldown), "locked door started or cooled down through production E input"): return false
	if not _require(denied_interactions[0] == 0, "locked door emitted a successful interaction signal"): return false
	await get_tree().create_timer(0.3).timeout
	door.interaction_enabled = false
	var disabled_cooldown := door._cooldown_left
	interaction._unhandled_input(interact_event)
	if not _require(door.get_prompt(player).is_empty() and not door._moving and is_equal_approx(door._cooldown_left, disabled_cooldown), "disabled door interaction caused a side effect"): return false
	door.interaction_enabled = true
	GameState.set_flag("log_signed")
	GameState.add_item("floor_key")
	interaction._unhandled_input(interact_event)
	interaction._unhandled_input(interact_event)
	if not _require(door._moving, "door spam cancelled the opening transition"): return false
	if not _require(not GameState.has_item("floor_key") and GameState.has_flag("floor_door_unlocked"), "production door interaction did not consume and persist the key unlock"): return false
	await get_tree().create_timer(0.65).timeout
	if not _require(door.is_open and not door._moving, "door did not finish one clean open transition"): return false
	player.global_position = Vector3(1.75, 0.02, door.global_position.z)
	player.rotation.y = PI / 2.0
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	interaction.ray.force_raycast_update()
	if not _require(interaction.ray.get_collider() == door, "production ray could not reacquire the rotated open door"): return false
	interaction._unhandled_input(interact_event)
	await get_tree().create_timer(0.65).timeout
	if not _require(not door.is_open, "door did not close after reopening test"): return false
	player.global_position = Vector3(0.8, 0.02, door.global_position.z + 1.35)
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	interaction.ray.force_raycast_update()
	if not _require(interaction.ray.get_collider() == door, "production ray could not reacquire the closed door from the front"): return false
	interaction._unhandled_input(interact_event)
	await get_tree().create_timer(0.65).timeout
	return _require(door.is_open, "door did not reopen after a full close cycle")

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
