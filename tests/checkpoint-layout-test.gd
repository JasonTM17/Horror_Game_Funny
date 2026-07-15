extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

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
	for node_name in ["LobbyPartitionLeft", "LobbyPartitionRight", "PowerPartitionLeft", "PowerPartitionRight", "Room407PartitionLeft", "Room407PartitionRight"]:
		if not _require(gameplay.has_node(node_name), "%s partition missing" % node_name): return
	if not _require(not gameplay.has_node("Room407Wall"), "full-width Room407 wall blocks the route"): return
	if not _require(gameplay.has_node("floor_door") and gameplay.has_node("power_door") and gameplay.has_node("room_door"), "guarded doors missing"): return
	for barrier_z in [WorldLayout.FLOOR_DOOR_Z, WorldLayout.POWER_DOOR_Z, WorldLayout.ROOM_DOOR_Z]:
		for x in [0.0, 3.0]:
			var query := PhysicsRayQueryParameters3D.create(Vector3(x, 1.0, barrier_z + 2.0), Vector3(x, 1.0, barrier_z - 2.0), 1)
			var hit := gameplay.get_world_3d().direct_space_state.intersect_ray(query)
			if not _require(not hit.is_empty(), "barrier at z=%s can be bypassed near x=%s" % [barrier_z, x]): return
	var loop_distance := absf(WorldLayout.LOOP_GATE_Z - WorldLayout.MEMORY_START_Z)
	var chase_distance := absf(WorldLayout.EXIT_Z - WorldLayout.CHASE_TRIGGER_Z)
	if not _require(loop_distance >= 180.0, "memory loop is too short for authored pacing"): return
	if not _require(chase_distance >= 280.0, "chase route is too short"): return
	if not _require(WorldLayout.FLOOR_LENGTH >= 850.0, "continuous world length regressed"): return
	print("CHECKPOINT_LAYOUT_TEST_OK")
	gameplay.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("LAYOUT_ASSERT: " + message)
	get_tree().quit(2)
	return false
