extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

func _ready() -> void:
	GameState.reset_run()
	var gameplay := GAMEPLAY_SCENE.instantiate()
	add_child(gameplay)
	await get_tree().process_frame
	await get_tree().physics_frame
	gameplay._narrative.duration_scale = 0.001
	gameplay._narrative.voice_over_enabled = false
	var player := gameplay.player as CharacterBody3D

	if not await _verify_door_gate(gameplay, player, "floor_door", "log_signed"): return
	if not await _cross_trigger_without_flag(player, WorldLayout.FLOOR_TRIGGER_Z, "floor_reached", true): return
	var floor_door := gameplay.get_node("floor_door") as DoorInteractable
	var elevator_display := gameplay.get_node("ElevatorDisplay") as Label3D
	if not _require(not floor_door.is_open and is_zero_approx(floor_door.rotation.y), "fourth-floor crossing did not slam the real door behind the player"): return
	if not _require(elevator_display.text != "3" and gameplay._horror.has_node("FloorArrivalApparition"), "fourth-floor crossing did not render its display/apparition beat"): return

	player.global_position = Vector3(0.8, 0.02, WorldLayout.MEMORY_TRIGGER_Z - 0.6)
	await get_tree().process_frame
	if not _require(not GameState.has_flag("memory_loop_started"), "memory loop started before power stabilized"): return
	if not await _verify_door_gate(gameplay, player, "power_door", "power_stable"): return
	if not await _cross_trigger_without_flag(player, WorldLayout.MEMORY_TRIGGER_Z, "memory_loop_started", true): return

	if not await _verify_door_gate(gameplay, player, "room_door", "radio_solved"): return
	gameplay._story._on_narrative_finished("radio_solved")
	if not _require(str(GameState.checkpoint.get("spawn_id", "")) == "room_entrance", "radio completion did not create the entrance checkpoint"): return
	var room_checkpoint_snapshot := JSON.stringify(GameState.checkpoint)
	if not await _cross_trigger_without_flag(player, WorldLayout.ROOM_TRIGGER_Z, "room_entered", true): return
	if not _require(JSON.stringify(GameState.checkpoint) == room_checkpoint_snapshot, "room threshold overwrote the pre-door checkpoint"): return

	if not await _cross_trigger_without_flag(player, WorldLayout.CHASE_TRIGGER_Z, "chase_started", false): return
	GameState.set_flag("chase_ready")
	await get_tree().process_frame
	await get_tree().physics_frame
	if not _require(GameState.has_flag("chase_started"), "chase did not start after crossing with chase_ready"): return
	if not _require(is_instance_valid(gameplay._chase.entity), "chase threshold did not create the entity"): return
	gameplay._chase.entity.stop_chase()
	AudioManager.stop_all()
	print("PHYSICAL_ROUTE_SMOKE_TEST_OK")
	gameplay.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _verify_door_gate(gameplay: Node3D, player: CharacterBody3D, door_id: String, unlock_flag: String) -> bool:
	var door := gameplay.get_node(door_id) as DoorInteractable
	player.global_position = Vector3(0.8, 0.02, door.global_position.z + 0.95)
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	door.interact(player)
	await get_tree().process_frame
	if not _require(not door.is_open and is_zero_approx(door.rotation.y), "%s opened without %s" % [door_id, unlock_flag]): return false
	var locked_start_z := player.global_position.z
	await _drive_forward(player, 45)
	if not _require(player.global_position.z < locked_start_z - 0.2, "%s received no forward movement while testing its locked collision" % door_id): return false
	if not _require(player.global_position.z > door.global_position.z + 0.3, "%s did not block the player capsule while locked" % door_id): return false

	GameState.set_flag(unlock_flag)
	if not door.required_item.is_empty():
		GameState.add_item(door.required_item)
	# A real interaction happens from ray range, not while the capsule is pressed
	# into the rotating panel. Step back outside the authored sweep before opening.
	player.global_position = Vector3(0.8, 0.02, door.global_position.z + 1.35)
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	if not _require(door.interact(player), "%s rejected its valid unlock flag" % door_id): return false
	if door.consume_required_item:
		if not _require(not GameState.has_item(door.required_item), "%s did not consume its one-shot key" % door_id): return false
		if not _require(GameState.has_flag(door.permanent_unlock_flag), "%s did not persist its session unlock" % door_id): return false
	await get_tree().create_timer(0.65).timeout
	if not _require(door.is_open, "%s did not finish opening" % door_id): return false
	player.global_position = Vector3(0.8, 0.02, door.global_position.z + 0.95)
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	await _drive_forward(player, 60)
	if not _require(player.global_position.z < door.global_position.z - 0.45, "%s blocked the player capsule after opening" % door_id): return false
	return true

func _cross_trigger_without_flag(player: CharacterBody3D, trigger_z: float, flag: String, expected: bool) -> bool:
	GameState.set_flag(flag, false)
	player.global_position = Vector3(0.8, 0.02, trigger_z + 0.75)
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	await _drive_forward(player, 45)
	return _require(GameState.has_flag(flag) == expected, "%s threshold result did not match prerequisites" % flag)

func _drive_forward(player: CharacterBody3D, frames: int) -> void:
	player.rotation.y = 0.0
	Input.action_press("move_forward")
	for _frame in frames:
		await get_tree().physics_frame
	Input.action_release("move_forward")
	await get_tree().physics_frame
	player.velocity = Vector3.ZERO

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	Input.action_release("move_forward")
	push_error("PHYSICAL_ROUTE_ASSERT: " + message)
	get_tree().quit(2)
	return false
