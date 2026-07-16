extends RefCounted

func verify(host: Node, gameplay: Node3D, player: CharacterBody3D) -> bool:
	var gameplay_was_processing := gameplay.is_processing()
	gameplay.set_process(false)
	var drawer := gameplay.get_node_or_null("night_desk_drawer") as StaticBody3D
	if not _require(drawer != null, "continuous layout has no interactive night-desk drawer"): return false
	var false_door := gameplay.get_node_or_null("false_door") as StaticBody3D
	if not _require(false_door != null, "fourth-floor false door has no interaction body"): return false
	if not _require(drawer.collision_layer == 4 and false_door.collision_layer == 4, "optional interactions can collide with the player capsule"): return false
	var drawer_front := drawer.get_node_or_null("DrawerFront") as MeshInstance3D
	var desk := gameplay.get_node_or_null("NightDeskBase") as StaticBody3D
	var false_door_visual := gameplay.get_node_or_null("FloorFalseDoor") as MeshInstance3D
	var false_door_collider := false_door.get_node_or_null("FalseDoorCollider") as CollisionShape3D
	if not _require(drawer_front != null and desk != null and false_door_visual != null and false_door_collider != null, "optional interaction visuals or colliders are incomplete"): return false
	var drawer_front_box := drawer_front.mesh as BoxMesh
	var desk_box := (desk.get_child(0) as MeshInstance3D).mesh as BoxMesh
	if not _require(drawer_front.global_position.z + drawer_front_box.size.z * 0.5 >= desk.global_position.z + desk_box.size.z * 0.5 + 0.04, "closed drawer face is hidden inside the opaque desk"): return false
	var false_door_shape := false_door_collider.shape as BoxShape3D
	var false_door_box := false_door_visual.mesh as BoxMesh
	if not _require(false_door.global_position.is_equal_approx(false_door_visual.global_position) and false_door_shape.size.is_equal_approx(false_door_box.size), "false-door collider does not align with its visible panel"): return false

	var interaction := player.get_node("Head/Camera3D/Interaction")
	var ray := interaction.get_node("RayCast3D") as RayCast3D
	var feedback_messages: Array[String] = []
	interaction.feedback_requested.connect(func(text: String) -> void: feedback_messages.append(text))
	var story_snapshot := _story_state_snapshot()
	var interact_event := InputEventAction.new()
	interact_event.action = "interact"
	interact_event.pressed = true

	var drawer_closed_position: Vector3 = drawer.position
	player.global_position = Vector3(0, 0.02, 23.2)
	if not _require(drawer.interact(player) and not bool(drawer.get("_moving")) and "step back" in str(drawer.get_feedback()).to_lower(), "drawer did not reject its closest unsafe stance with feedback"): return false
	if not _require(not player.is_movement_locked() and drawer.position == drawer_closed_position, "rejected drawer motion locked the player or moved the prop"): return false
	await host.get_tree().create_timer(0.6).timeout
	player.global_position = Vector3(0, 0.02, 24.8)
	player.rotation.y = 0.0
	player.head.rotation.x = deg_to_rad(-24.0)
	await host.get_tree().physics_frame
	ray.force_raycast_update()
	if not _require(ray.get_collider() == drawer, "production ray cannot acquire the authored desk drawer"): return false
	interaction._unhandled_input(interact_event)
	if not _require(bool(drawer.get("_moving")) and feedback_messages.size() == 1 and "00:07" in feedback_messages[0], "mapped drawer interaction did not start one clear opening response"): return false
	interaction._unhandled_input(interact_event)
	if not _require(feedback_messages.size() == 1, "drawer interaction spam emitted a second response during motion"): return false
	if not _require(player.is_movement_locked() and not player.is_input_locked(), "drawer motion did not apply a movement-only safety lock"): return false
	var motion_position := player.global_position
	Input.action_press("move_forward")
	for _frame in 5:
		await host.get_tree().physics_frame
	Input.action_release("move_forward")
	if not _require(player.global_position.distance_to(motion_position) < 0.01, "held movement entered the active drawer sweep"): return false
	await host.get_tree().create_timer(0.65).timeout
	if not _require(bool(drawer.get("is_open")) and drawer.position.distance_to(drawer_closed_position) > 0.4 and not player.is_movement_locked(), "desk drawer did not finish safely or release movement"): return false
	ray.force_raycast_update()
	if not _require(ray.get_collider() == drawer, "opened desk drawer left production interaction range"): return false
	interaction._unhandled_input(interact_event)
	await host.get_tree().create_timer(0.65).timeout
	if not _require(not bool(drawer.get("is_open")) and drawer.position.distance_to(drawer_closed_position) < 0.01 and feedback_messages.size() == 2 and "shut" in feedback_messages[-1].to_lower(), "desk drawer did not close with clear feedback at its authored origin"): return false

	player.global_position = Vector3(1.5, 0.02, -54.0)
	player.rotation.y = -PI / 2.0
	player.head.rotation.x = 0.0
	await host.get_tree().physics_frame
	ray.force_raycast_update()
	if not _require(ray.get_collider() == false_door, "production ray cannot acquire the authored false door"): return false
	var false_door_position: Vector3 = false_door.position
	var feedback_count := feedback_messages.size()
	interaction._unhandled_input(interact_event)
	if not _require(feedback_messages.size() == feedback_count + 1 and "painted" in feedback_messages[-1].to_lower(), "false door did not return clear mapped interaction feedback"): return false
	interaction._unhandled_input(interact_event)
	if not _require(feedback_messages.size() == feedback_count + 1 and false_door.position == false_door_position, "false door spam moved the prop or bypassed cooldown"): return false
	await host.get_tree().create_timer(0.85).timeout
	ray.force_raycast_update()
	interaction._unhandled_input(interact_event)
	if not _require(feedback_messages.size() == feedback_count + 2 and false_door.position == false_door_position, "false-door interaction did not recover after its bounded cooldown"): return false

	var drawer_tone_id := str(drawer.get("_tone_id"))
	var false_door_tone_id := str(false_door.get("_tone_id"))
	if not _require(drawer.interact(player) and bool(drawer.get("_moving")) and player.is_movement_locked(), "drawer could not start an active teardown fixture"): return false
	var spatial_tone_ids := AudioManager._spatial_player_ids.values()
	if not _require(AudioManager._cache_ids.has(drawer_tone_id) and spatial_tone_ids.has(drawer_tone_id), "drawer SFX has no active generated-audio ownership"): return false
	if not _require(AudioManager._cache_ids.has(false_door_tone_id) and spatial_tone_ids.has(false_door_tone_id), "false-door SFX has no active generated-audio ownership"): return false
	if not _require(_story_state_snapshot() == story_snapshot, "optional environmental interactions mutated story state"): return false
	drawer.queue_free()
	false_door.queue_free()
	await host.get_tree().process_frame
	spatial_tone_ids = AudioManager._spatial_player_ids.values()
	if not _require(not AudioManager._cache_ids.has(drawer_tone_id) and not AudioManager._cache_ids.has(false_door_tone_id) and not spatial_tone_ids.has(drawer_tone_id) and not spatial_tone_ids.has(false_door_tone_id), "environmental interaction teardown retained audio ownership"): return false
	if not _require(not player.is_movement_locked(), "active drawer teardown retained its movement lock"): return false
	gameplay.set_process(gameplay_was_processing)
	player._pitch = -8.0
	player.head.rotation.x = deg_to_rad(player._pitch)
	return true

func _story_state_snapshot() -> String:
	return JSON.stringify({
		"stage": GameState.stage,
		"objective": GameState.objective,
		"inventory": GameState.inventory,
		"flags": GameState.flags,
		"checkpoint": GameState.checkpoint,
		"completed_events": GameState.completed_events,
	})

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	Input.action_release("move_forward")
	push_error("PHYSICAL_ROUTE_ASSERT: " + message)
	return false
