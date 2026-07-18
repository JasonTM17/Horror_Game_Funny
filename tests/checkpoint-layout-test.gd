extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const PACING_SCRIPT := preload("res://scripts/world/playthrough-pacing-telemetry.gd")
const EXPECTED_ENTITY_PRESENCE_CUE_ID := "chase_entity_presence"

func _ready() -> void:
	GameState.reset_run()
	GameState.set_flag("phone_briefing_complete")
	GameState.set_flag("log_signed")
	for flag in ["floor_door_unlocked", "floor_reached", "fuse_collected", "fuse_installed", "power_stable", "memory_loop_started", "memory_photo", "memory_cassette", "memory_rabbit", "memory_loop_complete", "radio_solved"]:
		GameState.set_flag(flag)
	GameState.mark_event_complete("floor_arrival")
	GameState.advance_stage(GameState.Stage.MEMORY_LOOP)
	GameState.set_objective("Restored checkpoint objective")
	GameState.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "room_entrance")
	GameState.set_objective("Mutated after snapshot")
	if not _require(GameState.restore_checkpoint(), "checkpoint should restore"): return
	var gameplay: Node3D = GAMEPLAY_SCENE.instantiate() as Node3D
	add_child(gameplay)
	await get_tree().process_frame
	await get_tree().process_frame
	gameplay._narrative.duration_scale = 0.001
	gameplay._narrative.voice_over_enabled = false
	var player: Node3D = gameplay.get_node("Player") as Node3D
	if not _require(is_equal_approx(player.position.z, WorldLayout.ROOM_CHECKPOINT_Z), "safe pre-door room spawn marker ignored"): return
	if not _require(GameState.objective == "Restored checkpoint objective", "checkpoint objective overwritten"): return
	if not _require(not GameState.has_flag("room_entered") and GameState.stage == GameState.Stage.MEMORY_LOOP, "pre-room checkpoint restored after Room 407 entry"): return
	if not _require(gameplay.has_method("get_playthrough_pacing_report"), "gameplay director does not expose pacing telemetry"): return
	var restored_pacing: Dictionary = gameplay.get_playthrough_pacing_report()
	if not _require(not bool(restored_pacing.get("eligible_full_run", true)), "checkpoint-start session was accepted as full-run pacing evidence"): return
	if not _require(not bool(restored_pacing.get("complete", true)), "checkpoint-start session produced a complete pacing report"): return
	if not _require(restored_pacing.get("within_target") == null, "ineligible checkpoint session produced a pacing verdict"): return
	if not _require((restored_pacing.get("missing_milestones", []) as Array).has("lobby"), "checkpoint pacing did not expose missing opening milestone"): return
	if not _require((restored_pacing.get("chapter_active_seconds", {}) as Dictionary).get("opening") == null, "checkpoint pacing represented a missing chapter as zero duration"): return
	var hallway: Node3D = gameplay._hallway
	if not _require(hallway.variant == 3, "checkpoint did not restore the final hallway variant"): return
	if not _require(hallway.get_node("Variant3").visible and not hallway.get_node("Variant0").visible, "restored hallway visibility does not match memory state"): return
	for node_name in ["LobbyPartitionLeft", "LobbyPartitionRight", "PowerPartitionLeft", "PowerPartitionRight", "Room407PartitionLeft", "Room407PartitionRight"]:
		if not _require(gameplay.has_node(node_name), "%s partition missing" % node_name): return
	if not _require(not gameplay.has_node("Room407Wall"), "full-width Room407 wall blocks the route"): return
	if not _require(gameplay.has_node("floor_door") and gameplay.has_node("power_door") and gameplay.has_node("room_door"), "guarded doors missing"): return
	if not _require(gameplay.has_node("Ceiling") and gameplay.has_node("NightDeskBase"), "continuous corridor dressing missing"): return
	for observation_id in ["desk_clock", "lobby_register", "floor_notice", "memory_echo", "room_bed_observation", "room_wardrobe_observation", "room_family_table"]:
		if not _require(gameplay.has_node(observation_id), "%s observation prop missing" % observation_id): return
	for dressing_id in ["ElevatorDisplay", "ElevatorFrameLeft", "FloorFalseDoor", "Room407WallpaperPanel00", "Room407CeilingRib00", "Room407HeightMark00", "Room407HeightWarning", "ChaseWallScar00", "ChaseBrokenFrame00"]:
		if not _require(gameplay.has_node(dressing_id), "%s authored horror dressing missing" % dressing_id): return
	var elevator_display := gameplay.get_node("ElevatorDisplay") as Label3D
	if not _require(elevator_display.text == "--", "checkpoint did not reconstruct the completed elevator scare state"): return
	for safe_dressing_id in ["FloorFalseDoor", "Room407WallpaperPanel00", "Room407CeilingRib00", "ChaseWallScar00", "ChaseBrokenFrame00"]:
		var dressing := gameplay.get_node(safe_dressing_id) as MeshInstance3D
		if not _require(dressing != null and dressing.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s is not low-cost visual-only dressing" % safe_dressing_id): return
	var prop_signatures := {
		"phone": ["PhoneBase", "PhoneHandset", "PhoneIndicator"],
		"desk_clock": ["ClockBody", "ClockDigits"],
		"lobby_register": ["BookPages", "BookTitle"],
		"memory_rabbit": ["RabbitBody", "RabbitEarLeft", "RabbitEarRight"],
		"radio": ["RadioBody", "RadioDial", "RadioChannel"],
		"room_family_table": ["FamilyPhoto", "Plate3"],
		"final_clue": ["FinalClueBacking", "PaperWriting"],
	}
	for prop_id: String in prop_signatures:
		var prop := gameplay.get_node(prop_id)
		for part_name: String in prop_signatures[prop_id]:
			if not _require(prop.has_node(part_name), "%s lost recognizable visual part %s" % [prop_id, part_name]): return
	var world_environment: WorldEnvironment
	for child in gameplay.get_children():
		if child is WorldEnvironment:
			world_environment = child as WorldEnvironment
			break
	if not _require(world_environment != null and world_environment.environment.ambient_light_energy >= 0.8, "ambient light regressed below the readability floor"): return
	if not _require(world_environment.environment.tonemap_exposure >= 1.4 and world_environment.environment.fog_density <= 0.006, "corridor exposure or fog regressed below the navigation readability floor"): return
	var lobby_light := gameplay.get_node_or_null("CorridorLight00") as OmniLight3D
	if not _require(lobby_light != null and lobby_light.light_energy >= 3.0 and lobby_light.omni_range >= 12.0, "lobby task lighting regressed below the readability floor"): return
	var lobby_task_light := gameplay.get_node_or_null("LobbyTaskLight") as OmniLight3D
	if not _require(lobby_task_light != null and lobby_task_light.light_energy >= 1.8, "warm lobby focus light missing"): return
	var corridor_light := gameplay.get_node_or_null("CorridorLight01") as OmniLight3D
	if not _require(corridor_light != null and corridor_light.light_energy >= 1.1 and corridor_light.omni_range >= 10.0, "corridor pool lights regressed below the readability floor"): return
	for task_light_name in ["Room407RecordTaskLight", "Room407BedTaskLight", "Room407WardrobeTaskLight", "Room407FamilyTaskLight", "FinalClueTaskLight"]:
		var task_light := gameplay.get_node_or_null(task_light_name) as OmniLight3D
		if not _require(task_light != null and task_light.light_energy >= 1.1 and task_light.omni_range >= 6.0, "%s no longer provides local clue contrast" % task_light_name): return
	var first_chase_guide := gameplay.get_node_or_null("ChaseGuideLight00") as OmniLight3D
	var final_chase_guide := gameplay.get_node_or_null("ChaseGuideLight08") as OmniLight3D
	var exit_guide := gameplay.get_node_or_null("ExitGuideLight") as OmniLight3D
	if not _require(first_chase_guide != null and final_chase_guide != null and first_chase_guide.light_energy >= 1.6 and first_chase_guide.omni_range >= 10.0, "chase guide pools regressed below the blackout readability floor"): return
	if not _require(exit_guide != null and exit_guide.light_energy >= 2.5 and exit_guide.omni_range >= 11.0, "exit no longer has a distinct chase beacon"): return
	var floor_guide := gameplay.get_node_or_null("ChaseFloorGuide00") as MeshInstance3D
	var floor_guide_material := floor_guide.material_override as StandardMaterial3D if floor_guide != null else null
	if not _require(floor_guide_material != null and floor_guide_material.emission_enabled and floor_guide_material.emission_energy_multiplier >= 1.5, "chase floor guidance no longer survives the corridor blackout"): return
	var flashlight_base_energy := float(player.flashlight.get("_base_energy"))
	if not _require(flashlight_base_energy >= 3.0 and player.flashlight.spot_range >= 20.0, "flashlight regressed below the navigation readability floor"): return
	var navigation_region := gameplay.get_node_or_null("ContinuousCorridorNavigation") as NavigationRegion3D
	if not _require(navigation_region != null and navigation_region.navigation_mesh != null, "chase navigation surface missing"): return
	if not _require(navigation_region.navigation_mesh.get_polygon_count() == ContinuousWorldBuilder.CHASE_NAV_SEGMENT_COUNT, "chase navigation topology did not include every bypass segment"): return
	var chase_barriers: Array = ContinuousWorldBuilder.CHASE_BARRIERS
	if not _require(chase_barriers.size() == 3, "chase barrier count drifted from the authored route"): return
	await get_tree().physics_frame
	var navigation_map := gameplay.get_world_3d().navigation_map
	if not _require(navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(navigation_map) > 0, "chase navigation map did not synchronize"): return
	var route_start := Vector3(0, 0.02, WorldLayout.CHASE_TRIGGER_Z - 4.0)
	var route_end := Vector3(0, 0.02, WorldLayout.EXIT_Z + 8.0)
	var chase_path := NavigationServer3D.map_get_path(navigation_map, route_start, route_end, true)
	if not _require(chase_path.size() >= chase_barriers.size() * 2 + 2, "chase navigation path did not expose the authored bypass turns"): return
	if not _require(chase_path[0].distance_to(route_start) < 0.25 and chase_path[-1].distance_to(route_end) < 0.25, "chase navigation path did not reach the authored start and exit (actual %s -> %s, expected %s -> %s)" % [chase_path[0], chase_path[-1], route_start, route_end]): return
	for index: int in chase_barriers.size():
		var barrier: Dictionary = chase_barriers[index]
		var barrier_z := float(barrier["z"])
		var blocked_x := float(barrier["blocked_probe_x"])
		var bypass_x := float(barrier["bypass_x"])
		if index > 0:
			var previous_bypass_x := float((chase_barriers[index - 1] as Dictionary)["bypass_x"])
			if not _require(previous_bypass_x * bypass_x < 0.0, "chase bypass lanes do not alternate at barrier %d" % index): return
		var barrier_body := gameplay.get_node_or_null("ChaseBarrier%02d" % index) as StaticBody3D
		if not _require(barrier_body != null and barrier_body.collision_layer == 1 and barrier_body.get_child_count() > 0, "chase barrier %d has no physical collision body" % index): return
		var blocked_query := PhysicsRayQueryParameters3D.create(Vector3(blocked_x, 1.0, barrier_z + 2.0), Vector3(blocked_x, 1.0, barrier_z - 2.0), 1)
		var blocked_hit := gameplay.get_world_3d().direct_space_state.intersect_ray(blocked_query)
		if not _require(blocked_hit.get("collider") == barrier_body, "chase barrier %d does not block its authored lane" % index): return
		var bypass_query := PhysicsRayQueryParameters3D.create(Vector3(bypass_x, 1.0, barrier_z + 2.0), Vector3(bypass_x, 1.0, barrier_z - 2.0), 1)
		var bypass_hit := gameplay.get_world_3d().direct_space_state.intersect_ray(bypass_query)
		if not _require(bypass_hit.is_empty(), "chase barrier %d blocks its safe bypass lane" % index): return
		var cue := gameplay.get_node_or_null("ChaseBypassCue%02d" % index) as Label3D
		var marker := gameplay.get_node_or_null("ChaseBypassMarker%02d" % index) as MeshInstance3D
		var lane := gameplay.get_node_or_null("ChaseBypassLane%02d" % index) as MeshInstance3D
		var bypass_light := gameplay.get_node_or_null("ChaseBypassLight%02d" % index) as OmniLight3D
		var expected_lane := "RIGHT" if bypass_x > 0.0 else "LEFT"
		var cue_position := Vector3(bypass_x, 2.15, barrier_z + 2.35)
		var guide_position := Vector3(bypass_x, 0.015, barrier_z + 1.8)
		if not _require(cue != null and cue.text == "GO " + expected_lane and cue.position.distance_to(cue_position) < 0.05, "chase barrier %d has an incorrect safe-lane label or position" % index): return
		if not _require(cue.modulate.r > cue.modulate.g * 2.0 and cue.modulate.r > cue.modulate.b * 2.0, "chase barrier %d text cue is not visibly red" % index): return
		if not _require(marker != null and marker.position.distance_to(guide_position) < 0.05, "chase barrier %d floor marker does not align with its safe lane" % index): return
		if not _require(lane != null and is_equal_approx(lane.position.x, bypass_x) and lane.position.z < barrier_z, "chase barrier %d emissive lane does not continue through its safe side" % index): return
		if not _require(bypass_light != null and bypass_light.position.distance_to(Vector3(bypass_x, 2.35, barrier_z + 1.8)) < 0.05, "chase barrier %d guide light does not align with its safe lane" % index): return
		if not _require(bypass_light.light_energy >= 2.0 and bypass_light.omni_range >= 10.0 and bypass_light.light_color.r > bypass_light.light_color.g * 4.0 and bypass_light.light_color.r > bypass_light.light_color.b * 4.0, "chase barrier %d guide light is not strong and visibly red" % index): return
		var path_uses_bypass := false
		for path_point: Vector3 in chase_path:
			if absf(path_point.z - barrier_z) <= 3.5 and path_point.x * bypass_x > 0.5:
				path_uses_bypass = true
				break
		if not _require(path_uses_bypass, "chase navigation path ignored bypass lane %d" % index): return
	for barrier_z in [WorldLayout.FLOOR_DOOR_Z, WorldLayout.POWER_DOOR_Z, WorldLayout.ROOM_DOOR_Z]:
		for x in [0.0, 3.0]:
			var query := PhysicsRayQueryParameters3D.create(Vector3(x, 1.0, barrier_z + 2.0), Vector3(x, 1.0, barrier_z - 2.0), 1)
			var hit := gameplay.get_world_3d().direct_space_state.intersect_ray(query)
			if not _require(not hit.is_empty(), "barrier at z=%s can be bypassed near x=%s" % [barrier_z, x]): return
	for door_id in ["floor_door", "power_door", "room_door"]:
		var door := gameplay.get_node(door_id) as DoorInteractable
		if not _require(door.interact(player), "%s did not accept valid progression" % door_id): return
		await get_tree().create_timer(0.65).timeout
		var open_query := PhysicsRayQueryParameters3D.create(Vector3(0.8, 1.0, door.global_position.z + 2.0), Vector3(0.8, 1.0, door.global_position.z - 2.0), 1)
		var open_hit := gameplay.get_world_3d().direct_space_state.intersect_ray(open_query)
		if not _require(open_hit.is_empty(), "%s collision still blocks the open passage" % door_id): return
	player.global_position = Vector3(0, 0.02, WorldLayout.CHASE_RESPAWN_Z)
	if not _require(ChaseSequenceController.ENTITY_PRESENCE_CUE_ID == EXPECTED_ENTITY_PRESENCE_CUE_ID, "chase entity presence cue ID changed unexpectedly"): return
	gameplay._chase.start()
	var chase_entity: CharacterBody3D = gameplay._chase.entity
	if not _require(is_instance_valid(chase_entity), "production chase controller did not create its entity"): return
	if not _verify_chase_bypass_clearance(gameplay, player, chase_entity, chase_barriers): return
	if not _verify_entity_presence_cue(chase_entity, "chase start"): return
	chase_entity.global_position = player.global_position + Vector3(0, 0, 18.0)
	var appear_origin := chase_entity.global_position
	for _frame in 18:
		await get_tree().physics_frame
	if not _require(chase_entity.state == chase_entity.State.APPEAR, "enemy skipped its warning appearance"): return
	if not _require(chase_entity.global_position.distance_to(appear_origin) < 0.01 and is_zero_approx(chase_entity.velocity.length()), "enemy moved during its warning appearance"): return
	if not _require(await _wait_for_entity_state(chase_entity, chase_entity.State.STALK), "enemy never reaches stalk state"): return
	var stalk_origin := chase_entity.global_position
	for _frame in 12:
		await get_tree().physics_frame
	var stalk_distance := chase_entity.global_position.distance_to(stalk_origin)
	if not _require(chase_entity.state == chase_entity.State.STALK and stalk_distance > 0.05, "enemy did not visibly stalk before chasing"): return
	if not _require(absf(chase_entity.velocity.length() - chase_entity.speed * chase_entity.stalk_speed_multiplier) < 0.05, "stalk state does not use its authored speed"): return
	if not _require(await _wait_for_entity_state(chase_entity, chase_entity.State.CHASE), "enemy never reaches chase state"): return
	var chase_origin := chase_entity.global_position
	for _frame in 12:
		await get_tree().physics_frame
	var measured_chase_distance := chase_entity.global_position.distance_to(chase_origin)
	if not _require(chase_entity.state == chase_entity.State.CHASE and measured_chase_distance > stalk_distance * 1.7, "full chase is not materially faster than stalking"): return
	if not _require(absf(chase_entity.velocity.length() - chase_entity.speed) < 0.05, "chase state does not use its authored speed"): return
	if not _require(is_equal_approx(player.walk_speed, 2.0) and is_equal_approx(player.sprint_multiplier, 1.55) and is_equal_approx(chase_entity.speed, 3.0), "production walk/sprint/chase speed contract drifted from 2.0/3.1/3.0"): return
	if not _require(chase_entity.speed > player.walk_speed, "enemy cannot catch a walking player"): return
	if not _require(chase_entity.speed < player.walk_speed * player.sprint_multiplier, "enemy makes a full sprint escape impossible"): return
	var traversal_player_position := player.global_position
	var traversal_entity_position := chase_entity.global_position
	var traversal_last_seen: Vector3 = chase_entity._last_target_position
	player.global_position = Vector3(0, 0.02, -580.0)
	chase_entity.global_position = Vector3(0, 0.02, -563.0)
	chase_entity._last_target_position = player.global_position
	chase_entity._target_visible = true
	chase_entity._los_timer = 0.0
	chase_entity.state = chase_entity.State.CHASE
	chase_entity.active = true
	var crossed_first_barrier := false
	var max_bypass_offset := 0.0
	for _frame in 315:
		await get_tree().physics_frame
		max_bypass_offset = maxf(max_bypass_offset, absf(chase_entity.global_position.x))
		if chase_entity.global_position.z < -571.0:
			crossed_first_barrier = true
	if not _require(crossed_first_barrier and max_bypass_offset > 0.5, "chase entity stuck at the first physical obstruction instead of navigating the bypass (state=%s, position=%s, last_seen=%s, max_x=%.2f)" % [chase_entity.state, chase_entity.global_position, chase_entity._last_target_position, max_bypass_offset]): return
	if not _require(chase_entity.active and chase_entity.state == chase_entity.State.CHASE and not gameplay._chase.recovering, "chase obstruction caused an immediate failure, despawn, or state downgrade"): return
	player.global_position = traversal_player_position
	chase_entity.global_position = traversal_entity_position
	chase_entity._last_target_position = traversal_last_seen
	chase_entity._los_timer = 0.0
	var pause_position := chase_entity.global_position
	var pause_state_time: float = float(chase_entity._state_time)
	get_tree().paused = true
	await get_tree().process_frame
	OS.delay_msec(120)
	await get_tree().process_frame
	var chase_stayed_paused := chase_entity.global_position.distance_to(pause_position) < 0.01 and is_equal_approx(chase_entity._state_time, pause_state_time)
	get_tree().paused = false
	await get_tree().process_frame
	if not _require(chase_stayed_paused, "chase simulation advanced while the game was paused"): return
	var recorded_last_seen: Vector3 = chase_entity._last_target_position
	chase_entity.lost_target_duration = 0.12
	chase_entity.search_duration = 0.5
	var occluder_z := (chase_entity.global_position.z + player.global_position.z) * 0.5
	var chase_occluder := LevelGeometry.add_box(gameplay, "ChaseLosOccluder", Vector3(0, 1.5, occluder_z), Vector3(8.0, 3.0, 0.4), Color(0.01, 0.01, 0.01))
	await get_tree().physics_frame
	chase_entity._los_timer = 0.0
	if not _require(await _wait_for_entity_state(chase_entity, chase_entity.State.LOST_TARGET, 20), "occluded enemy never enters lost-target state"): return
	player.global_position += Vector3(0, 0, -6.0)
	if not _require(chase_entity._movement_destination().distance_to(recorded_last_seen) < 0.05, "lost enemy tracks the hidden player instead of the last seen position"): return
	if not _require(await _wait_for_entity_state(chase_entity, chase_entity.State.SEARCH, 30), "lost enemy never enters search state"): return
	if not _require(chase_entity._last_target_position.distance_to(recorded_last_seen) < 0.05, "search state leaked the hidden player's position"): return
	if not _require(is_equal_approx(chase_entity._movement_speed(), chase_entity.speed * chase_entity.search_speed_multiplier), "search state does not use its authored movement speed"): return
	chase_occluder.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	player.global_position = chase_entity.global_position + Vector3(0, 0, -8.0)
	chase_entity._los_timer = 0.0
	if not _require(await _wait_for_entity_state(chase_entity, chase_entity.State.CHASE, 30), "enemy did not reacquire a visible nearby player"): return
	player.global_position = chase_entity.global_position + Vector3(0, 0, -20.0)
	chase_entity._los_timer = 0.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	var far_last_seen_distance: float = chase_entity._last_target_position.distance_to(chase_entity.global_position)
	if not _require(chase_entity.state == chase_entity.State.CHASE and far_last_seen_distance >= 18.0, "bounded-search fixture did not record a far visible target (state=%s, last_seen_distance=%.2f, visible=%s)" % [chase_entity.state, far_last_seen_distance, chase_entity._target_visible]): return
	chase_entity.max_search_cycles = 1
	chase_entity.lost_target_duration = 0.05
	chase_entity.search_duration = 0.05
	var persistent_occluder_z := (chase_entity.global_position.z + player.global_position.z) * 0.5
	var persistent_occluder := LevelGeometry.add_box(gameplay, "PersistentChaseLosOccluder", Vector3(0, 1.5, persistent_occluder_z), Vector3(8.0, 3.0, 0.4), Color(0.01, 0.01, 0.01))
	await get_tree().physics_frame
	chase_entity._los_timer = 0.0
	if not _require(await _wait_for_entity_state(chase_entity, chase_entity.State.DESPAWN, 60), "persistent target loss left the enemy searching forever"): return
	var despawn_origin := chase_entity.global_position
	await get_tree().create_timer(0.1).timeout
	if not _require(not chase_entity.active and not chase_entity.visible and is_zero_approx(chase_entity.velocity.length()), "despawned enemy retained active or visible chase state"): return
	if not _require(chase_entity.global_position.distance_to(despawn_origin) < 0.01, "despawned enemy continued moving"): return
	persistent_occluder.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	chase_entity.start_chase()
	if not _require(chase_entity.active and chase_entity.visible and chase_entity.state == chase_entity.State.APPEAR, "despawned enemy did not restart cleanly"): return
	player.global_position = Vector3(0, 0.02, WorldLayout.EXIT_Z - 8.1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _require(chase_entity.state == chase_entity.State.DESPAWN and not chase_entity.active and not chase_entity.visible, "exit boundary left a visible or active enemy"): return
	var exit_despawn_origin := chase_entity.global_position
	player.global_position = Vector3(0, 0.02, WorldLayout.CHASE_RESPAWN_Z)
	await get_tree().create_timer(0.1).timeout
	if not _require(chase_entity.global_position.distance_to(exit_despawn_origin) < 0.01 and not chase_entity.active, "backtracking restarted an escaped enemy without a chase reset"): return
	chase_entity.start_chase()
	if not _require(chase_entity.visible and chase_entity._last_target_position.distance_to(player.global_position) < 0.05, "checkpoint restart retained stale target memory"): return
	GameState.set_flag("chase_started")
	gameplay._chase._play_entity_presence_cue()
	if not _verify_entity_presence_cue(chase_entity, "pre-recovery replay"): return
	player.global_position = Vector3(0, 0.02, WorldLayout.CHASE_TRIGGER_Z + 26.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _require(gameplay._chase.recovering, "retreating out of the chase did not request checkpoint recovery"): return
	if not _require(_entity_presence_players().is_empty(), "failure recovery left the stale entity cue playing"): return
	await get_tree().create_timer(1.4).timeout
	if not _require(is_equal_approx(player.global_position.z, WorldLayout.CHASE_RESPAWN_Z), "retreat recovery did not restore the chase marker"): return
	if not _verify_entity_presence_cue(chase_entity, "checkpoint recovery"): return
	var loop_distance := absf(WorldLayout.LOOP_GATE_Z - WorldLayout.MEMORY_START_Z)
	var chase_distance := absf(WorldLayout.EXIT_Z - WorldLayout.CHASE_TRIGGER_Z)
	if not _require(loop_distance >= 180.0, "memory loop is too short for authored pacing"): return
	if not _require(chase_distance >= 280.0, "chase route is too short"): return
	if not _require(WorldLayout.FLOOR_LENGTH >= 850.0, "continuous world length regressed"): return
	gameplay._chase._play_entity_presence_cue()
	if not _verify_entity_presence_cue(chase_entity, "ending teardown fixture"): return
	var checkpoint_before_ending := JSON.stringify(GameState.checkpoint)
	gameplay.finish_ending()
	if not _require(_entity_presence_players().is_empty(), "ending teardown retained the entity presence player"): return
	if not _require(not AudioManager._cache_ids.has(EXPECTED_ENTITY_PRESENCE_CUE_ID), "ending teardown retained entity presence cache ownership"): return
	var ending_notice := gameplay.get_node_or_null("ending_notice") as StoryInteractable
	var ending_roster := gameplay.get_node_or_null("ending_roster") as StoryInteractable
	if not _require(ending_notice != null and ending_roster != null, "restored run did not build both epilogue interactables"): return
	if not _require(ending_notice.get_parent() == gameplay and ending_roster.get_parent() == gameplay, "epilogue interactables left the active gameplay scene"): return
	for task_light_name in ["EndingRevealLight", "EndingNoticeTaskLight", "EndingRosterTaskLight"]:
		var ending_task_light := gameplay.get_node_or_null(task_light_name) as OmniLight3D
		if not _require(ending_task_light != null and ending_task_light.light_energy >= 1.0, "%s is missing from the interactive epilogue" % task_light_name): return
	if not _require(await _verify_epilogue_ray_target(player, ending_notice), "production ray cannot acquire the ending notice"): return
	if not _require(not gameplay.handle_story_action("ending_roster", player), "restored run bypassed the notice gate"): return
	if not _require(ending_notice.interact(player), "production notice interactable rejected the restored player"): return
	if not _require(await _wait_for_flag("ending_notice_complete"), "restored notice narration did not complete"): return
	if not _require(await _verify_epilogue_ray_target(player, ending_roster), "production ray cannot acquire the ending roster"): return
	if not _require(ending_roster.interact(player), "production roster interactable rejected the restored player"): return
	if not _require(not gameplay.has_node("EndingOverlay") and not player.is_input_locked(), "restored epilogue locked input before roster narration completed"): return
	if not _require(await _wait_for_flag("ending_roster_complete"), "restored roster narration did not complete"): return
	if not _require(await _wait_for_node(gameplay, "EndingOverlay"), "restored run did not show credits after the interactive epilogue"): return
	if not _require(player.is_input_locked() and player._locks.has("ending"), "restored credits did not apply the terminal input lock"): return
	if not _require(JSON.stringify(GameState.checkpoint) == checkpoint_before_ending, "restored epilogue mutated its checkpoint"): return
	var finalized_report: Dictionary = gameplay.get_playthrough_pacing_report()
	if not _require(not bool(finalized_report.get("eligible_full_run", true)), "finalized checkpoint run became eligible for pacing evidence"): return
	if not _require(finalized_report.get("within_target") == null, "finalized checkpoint run produced a pacing verdict"): return
	if not _require(not bool(finalized_report.get("complete", true)), "finalized checkpoint run became a complete pacing report"): return
	var finalized_pacing := JSON.stringify(finalized_report)
	GameState.reset_run()
	await get_tree().process_frame
	if not _require(JSON.stringify(gameplay.get_playthrough_pacing_report()) == finalized_pacing, "post-credits reset mutated finalized checkpoint pacing"): return
	if not _require(_verify_out_of_order_pacing_rejected(), "out-of-order pacing fixture was accepted"): return
	AudioManager.stop_all()
	print("CHECKPOINT_LAYOUT_TEST_OK")
	gameplay.queue_free()
	await get_tree().process_frame
	# The audio server releases the ending playback on its mix thread.
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _verify_entity_presence_cue(entity: CharacterBody3D, phase: String) -> bool:
	var matching_players := _entity_presence_players()
	if not _require(matching_players.size() == 1, "%s created %d entity presence cues instead of one" % [phase, matching_players.size()]): return false
	var cue := matching_players[0]
	if not _require(cue.get_parent() == entity and cue.position.is_equal_approx(Vector3.ZERO), "%s cue is not attached to the chase entity" % phase): return false
	if not _require(cue.bus == "SFX" and cue.max_distance > 0.0 and cue.max_distance <= 18.0, "%s cue is not bounded or routed through SFX" % phase): return false
	if not _require(cue.stream != null and AudioManager._cache_ids.has(EXPECTED_ENTITY_PRESENCE_CUE_ID), "%s cue has no stream or cache ownership" % phase): return false
	return true

func _verify_chase_bypass_clearance(gameplay: Node3D, player: Node3D, entity: CharacterBody3D, barriers: Array) -> bool:
	var player_collider := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var entity_collider := entity.get_node_or_null("EntityCollider") as CollisionShape3D
	var player_capsule: CapsuleShape3D = player_collider.shape as CapsuleShape3D if player_collider != null else null
	var entity_capsule: CapsuleShape3D = entity_collider.shape as CapsuleShape3D if entity_collider != null else null
	if not _require(player_capsule != null and entity_capsule != null, "chase clearance fixtures are not capsule-shaped"): return false
	var max_capsule_radius := maxf(player_capsule.radius, entity_capsule.radius)
	var left_wall := gameplay.get_node_or_null("LeftWall") as StaticBody3D
	var right_wall := gameplay.get_node_or_null("RightWall") as StaticBody3D
	var left_wall_box := _body_box_shape(left_wall)
	var right_wall_box := _body_box_shape(right_wall)
	if not _require(left_wall_box != null and right_wall_box != null, "corridor walls have no box collision for clearance checks"): return false
	var left_wall_inner_x := left_wall.global_position.x + left_wall_box.size.x * 0.5
	var right_wall_inner_x := right_wall.global_position.x - right_wall_box.size.x * 0.5
	for index: int in barriers.size():
		var barrier: Dictionary = barriers[index]
		var barrier_body := gameplay.get_node_or_null("ChaseBarrier%02d" % index) as StaticBody3D
		var barrier_box := _body_box_shape(barrier_body)
		if not _require(barrier_box != null, "chase barrier %d has no box collision for clearance checks" % index): return false
		var safe_min_x := float(barrier["safe_min_x"])
		var safe_max_x := float(barrier["safe_max_x"])
		var obstacle_clearance: float
		var wall_clearance: float
		var obstacle_edge := 0.0
		if float(barrier["bypass_x"]) > 0.0:
			obstacle_edge = barrier_body.global_position.x + barrier_box.size.x * 0.5
			obstacle_clearance = safe_min_x - obstacle_edge
			wall_clearance = right_wall_inner_x - safe_max_x
		else:
			obstacle_edge = barrier_body.global_position.x - barrier_box.size.x * 0.5
			obstacle_clearance = obstacle_edge - safe_max_x
			wall_clearance = safe_min_x - left_wall_inner_x
		var required_edge_clearance := max_capsule_radius + 0.08
		var required_lane_width := max_capsule_radius * 2.0 + 0.4
		if not _require(obstacle_clearance >= required_edge_clearance and wall_clearance >= required_edge_clearance, "chase bypass %d lacks capsule edge clearance" % index): return false
		if not _require(safe_max_x - safe_min_x >= required_lane_width, "chase bypass %d navigation lane is narrower than both production capsules" % index): return false
	return true

func _body_box_shape(body: StaticBody3D) -> BoxShape3D:
	if body == null:
		return null
	for child in body.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			return child.shape as BoxShape3D
	return null

func _entity_presence_players() -> Array[AudioStreamPlayer3D]:
	AudioManager._prune_spatial_players()
	var matching_players: Array[AudioStreamPlayer3D] = []
	for spatial_player: AudioStreamPlayer3D in AudioManager._spatial_players:
		var cue_id := str(AudioManager._spatial_player_ids.get(spatial_player.get_instance_id(), ""))
		if cue_id == EXPECTED_ENTITY_PRESENCE_CUE_ID:
			matching_players.append(spatial_player)
	return matching_players

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("LAYOUT_ASSERT: " + message)
	get_tree().quit(2)
	return false

func _wait_for_node(parent: Node, node_name: String, max_frames := 30) -> bool:
	for _frame in max_frames:
		if parent.has_node(node_name):
			return true
		await get_tree().process_frame
	return false

func _wait_for_flag(flag: String, max_frames := 180) -> bool:
	for _frame in max_frames:
		if GameState.has_flag(flag):
			return true
		await get_tree().process_frame
	return false

func _verify_epilogue_ray_target(player: CharacterBody3D, target: StoryInteractable) -> bool:
	var ray := player.get_node("Head/Camera3D/Interaction/RayCast3D") as RayCast3D
	player.global_position = Vector3(target.global_position.x, 0.02, target.global_position.z + 1.6)
	player.rotation.y = 0.0
	var camera_height: float = player.global_position.y + player.head.position.y
	player.head.rotation.x = atan2(target.global_position.y - camera_height, 1.6)
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	ray.force_raycast_update()
	return ray.get_collider() == target

func _wait_for_entity_state(entity: CharacterBody3D, expected_state: int, max_frames := 120) -> bool:
	for _frame in max_frames:
		if entity.state == expected_state:
			return true
		await get_tree().process_frame
	return false

func _verify_out_of_order_pacing_rejected() -> bool:
	var telemetry = PACING_SCRIPT.new()
	add_child(telemetry)
	telemetry.begin(false, GameState.Stage.ROOM_407)
	var stages: Array[int] = [
		GameState.Stage.LOBBY,
		GameState.Stage.FLOOR4_DARK,
		GameState.Stage.FLOOR4_POWERED,
		GameState.Stage.MEMORY_LOOP,
		GameState.Stage.CHASE,
		GameState.Stage.ENDING,
	]
	for index: int in stages.size():
		telemetry._active_seconds = float(index + 1)
		telemetry._record_stage(stages[index])
	telemetry._active_seconds = float(stages.size() + 1)
	telemetry._record_boundary("credits")
	var report: Dictionary = telemetry.get_report()
	telemetry.free()
	var chapter_seconds: Dictionary = report.get("chapter_active_seconds", {}) as Dictionary
	return (
		(report.get("missing_milestones", []) as Array).is_empty()
		and not bool(report.get("boundary_order_valid", true))
		and not bool(report.get("complete", true))
		and chapter_seconds.get("memory_loop") == null
	)
