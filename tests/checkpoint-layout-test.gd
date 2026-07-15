extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const ENTITY_SCRIPT := preload("res://scripts/world/chase-entity.gd")
const PACING_SCRIPT := preload("res://scripts/world/playthrough-pacing-telemetry.gd")

func _ready() -> void:
	GameState.reset_run()
	GameState.set_flag("phone_briefing_complete")
	GameState.set_flag("log_signed")
	for flag in ["floor_reached", "fuse_installed", "power_stable", "memory_loop_started", "memory_photo", "memory_cassette", "memory_rabbit", "radio_solved", "room_entered"]:
		GameState.set_flag(flag)
	GameState.advance_stage(GameState.Stage.ROOM_407)
	GameState.set_objective("Restored checkpoint objective")
	GameState.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "room_entrance")
	GameState.set_objective("Mutated after snapshot")
	if not _require(GameState.restore_checkpoint(), "checkpoint should restore"): return
	var gameplay: Node3D = GAMEPLAY_SCENE.instantiate() as Node3D
	add_child(gameplay)
	await get_tree().process_frame
	await get_tree().process_frame
	var player: Node3D = gameplay.get_node("Player") as Node3D
	if not _require(is_equal_approx(player.position.z, WorldLayout.ROOM_TRIGGER_Z + 3.0), "room spawn marker ignored"): return
	if not _require(GameState.objective == "Restored checkpoint objective", "checkpoint objective overwritten"): return
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
	var prop_signatures := {
		"phone": ["PhoneBase", "PhoneHandset", "PhoneIndicator"],
		"desk_clock": ["ClockBody", "ClockDigits"],
		"lobby_register": ["BookPages", "BookTitle"],
		"memory_rabbit": ["RabbitBody", "RabbitEarLeft", "RabbitEarRight"],
		"radio": ["RadioBody", "RadioDial", "RadioChannel"],
		"room_family_table": ["FamilyPhoto", "Plate3"]
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
	if not _require(world_environment != null and world_environment.environment.ambient_light_energy >= 0.7, "ambient light regressed below the readability floor"): return
	if not _require(world_environment.environment.tonemap_exposure >= 1.2 and world_environment.environment.fog_density <= 0.007, "corridor exposure or fog regressed below the navigation readability floor"): return
	var lobby_light := gameplay.get_node_or_null("CorridorLight00") as OmniLight3D
	if not _require(lobby_light != null and lobby_light.light_energy >= 3.0 and lobby_light.omni_range >= 12.0, "lobby task lighting regressed below the readability floor"): return
	var lobby_task_light := gameplay.get_node_or_null("LobbyTaskLight") as OmniLight3D
	if not _require(lobby_task_light != null and lobby_task_light.light_energy >= 1.8, "warm lobby focus light missing"): return
	var corridor_light := gameplay.get_node_or_null("CorridorLight01") as OmniLight3D
	if not _require(corridor_light != null and corridor_light.light_energy >= 1.1 and corridor_light.omni_range >= 10.0, "corridor pool lights regressed below the readability floor"): return
	if not _require(player.flashlight.light_energy >= 3.0 and player.flashlight.spot_range >= 20.0, "flashlight regressed below the navigation readability floor"): return
	var navigation_region := gameplay.get_node_or_null("ContinuousCorridorNavigation") as NavigationRegion3D
	if not _require(navigation_region != null and navigation_region.navigation_mesh != null, "chase navigation surface missing"): return
	if not _require(navigation_region.navigation_mesh.get_polygon_count() == 1, "continuous navigation polygon missing"): return
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
	var chase_entity: CharacterBody3D = ENTITY_SCRIPT.new() as CharacterBody3D
	chase_entity.position = player.position + Vector3(0, 0, 18.0)
	gameplay.add_child(chase_entity)
	chase_entity.setup(player, gameplay)
	chase_entity.start_chase()
	await get_tree().create_timer(0.8).timeout
	if not _require(chase_entity.state == chase_entity.State.STALK, "enemy never reaches stalk state"): return
	if not _require(chase_entity.speed > player.walk_speed, "enemy cannot catch a walking player"): return
	if not _require(chase_entity.speed < player.walk_speed * player.sprint_multiplier, "enemy makes a full sprint escape impossible"): return
	gameplay._chase.entity = chase_entity
	GameState.set_flag("chase_started")
	player.global_position = Vector3(0, 0.02, WorldLayout.CHASE_TRIGGER_Z + 26.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _require(gameplay._chase.recovering, "retreating out of the chase did not request checkpoint recovery"): return
	await get_tree().create_timer(1.4).timeout
	if not _require(is_equal_approx(player.global_position.z, WorldLayout.CHASE_RESPAWN_Z), "retreat recovery did not restore the chase marker"): return
	chase_entity.stop_chase()
	chase_entity.queue_free()
	var loop_distance := absf(WorldLayout.LOOP_GATE_Z - WorldLayout.MEMORY_START_Z)
	var chase_distance := absf(WorldLayout.EXIT_Z - WorldLayout.CHASE_TRIGGER_Z)
	if not _require(loop_distance >= 180.0, "memory loop is too short for authored pacing"): return
	if not _require(chase_distance >= 280.0, "chase route is too short"): return
	if not _require(WorldLayout.FLOOR_LENGTH >= 850.0, "continuous world length regressed"): return
	gameplay._chase.ending_reveal_duration = 0.01
	gameplay.finish_ending()
	if not _require(await _wait_for_node(gameplay, "EndingOverlay"), "restored run did not show credits before pacing finalization"): return
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
