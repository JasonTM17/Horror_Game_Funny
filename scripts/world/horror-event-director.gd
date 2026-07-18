extends Node3D

@export_range(0.01, 2.0, 0.01) var effect_duration_scale := 1.0

const SCARE_SEQUENCE_SCRIPT := preload("res://scripts/world/horror-scare-sequence.gd")
const APPARITION_FACTORY := preload("res://scripts/world/horror-apparition-factory.gd")

var _director: Node
var _hallway: Node
var _player: Node3D
var _active_sequences: Array[HorrorScareSequence] = []

func setup(director: Node, hallway: Node) -> void:
	_director = director
	_hallway = hallway

func set_player(player: Node3D) -> void:
	_player = player

func trigger(event_id: String) -> void:
	if not GameState.mark_event_complete(event_id):
		return
	match event_id:
		"floor_arrival":
			_run_floor_arrival()
		"memory_photo":
			_run_photo_memory()
		"memory_cassette":
			_spawn_message("DON'T TURN AROUND", Vector3(0, 2.2, WorldLayout.MEMORY_CASSETTE_Z - 5.0), Color(0.62, 0.58, 0.5))
			_spawn_turn_away_apparition()
		"memory_rabbit":
			_run_rabbit_memory()
		"fuse_power":
			_run_fuse_power()
		"room_entity_reveal":
			_run_room_entity_reveal()

func _run_floor_arrival() -> void:
	var sequence := _create_sequence("FloorArrivalScare")
	var display := _director.get_node_or_null("ElevatorDisplay") as Label3D
	if display != null:
		display.text = "4"
		display.modulate = Color(0.86, 0.16, 0.1)
	var floor_door := _director.get_node_or_null("floor_door") as DoorInteractable
	if floor_door != null:
		floor_door.close_for_event()
	var apparition_position := _floor_arrival_position()
	var light := _find_nearest_light(apparition_position)
	sequence.set_light(light, 0.12, Color(0.72, 0.045, 0.025))
	sequence.play_spatial_at(apparition_position + Vector3(0.05, -0.3, 4.0), "scare_floor_lift_strain", 39.0, 0.62, -12.0)
	var apparition := _spawn_apparition(apparition_position, "FloorArrivalApparition", Vector3(0.82, 1.05, 0.68))
	sequence.own_node(apparition)
	apparition.visible = false
	if not await sequence.wait(0.32):
		return
	apparition.visible = true
	sequence.play_spatial_on(apparition, "scare_floor_heel_step", 73.0, 0.24, -8.0)
	sequence.play_spatial_on(apparition, "scare_floor_presence", 46.0, 0.54, -11.0)
	if not await sequence.wait(0.55):
		return
	if is_instance_valid(display):
		display.text = "--"
		display.modulate = Color(0.22, 0.035, 0.025)
	sequence.finish()

func _run_photo_memory() -> void:
	var sequence := _create_sequence("PhotoMemoryScare")
	var position := Vector3(0, 2.2, WorldLayout.MEMORY_PHOTO_Z - 5.0)
	var light := _find_nearest_light(position)
	sequence.set_light(light, 0.28, Color(0.38, 0.1, 0.08))
	sequence.play_spatial_at(position + Vector3(-3.2, -0.8, 2.0), "scare_photo_whisper_left", 132.0, 0.52, -15.0)
	if not await sequence.wait(0.22):
		return
	_spawn_message("YOU WERE HERE", position, Color(0.72, 0.2, 0.18))
	sequence.play_spatial_at(position + Vector3(3.2, -0.8, -1.0), "scare_photo_whisper_right", 198.0, 0.48, -14.0)
	if await sequence.wait(0.58):
		sequence.finish()

func _run_rabbit_memory() -> void:
	var sequence := _create_sequence("RabbitMemoryScare")
	var position := _scare_position_ahead(10.0, 1.25, 0.0, WorldLayout.MEMORY_RABBIT_Z - 10.0)
	var apparition := _spawn_apparition(position, "MemoryRabbitApparition")
	sequence.own_node(apparition)
	apparition.visible = false
	sequence.set_light(_find_nearest_light(position), 0.16, Color(0.68, 0.025, 0.018))
	sequence.play_spatial_at(position + Vector3(0, -0.6, 3.0), "scare_rabbit_music_box", 144.0, 0.46, -15.0)
	if not await sequence.wait(0.28):
		return
	apparition.visible = true
	sequence.play_spatial_on(apparition, "scare_rabbit_presence", 54.0, 0.82, -9.0)
	if await sequence.wait(0.72):
		sequence.finish()

func _run_room_entity_reveal() -> void:
	var sequence := _create_sequence("RoomEntityRevealScare")
	var position := _scare_position_ahead(9.0, 1.35, 0.0, WorldLayout.FINAL_CLUE_Z - 9.0)
	var apparition := _spawn_apparition(position, "RoomEntityManifestation", Vector3(1.15, 1.2, 0.82), true)
	sequence.own_node(apparition)
	apparition.visible = false
	sequence.set_light(_find_nearest_light(position), 0.08, Color(0.52, 0.018, 0.012))
	sequence.play_spatial_at(position + Vector3(0, 0.1, 4.0), "scare_room_wall_breath", 31.0, 0.86, -12.0)
	if not await sequence.wait(0.36):
		return
	apparition.visible = true
	sequence.play_spatial_on(apparition, "scare_room_entity_low", 47.0, 0.9, -8.0)
	sequence.play_spatial_on(apparition, "scare_room_entity_sting", 119.0, 0.26, -6.0)
	if await sequence.wait(1.0):
		sequence.finish()

func _run_fuse_power() -> void:
	_spawn_message("THE LIGHTS REMEMBER", Vector3(-2.8, 2.0, WorldLayout.FUSE_BOX_Z - 4.0), Color(0.48, 0.64, 0.72))
	var sequence := _create_sequence("FusePowerScare")
	var first_light := _find_nearest_light(Vector3(0, 2.5, WorldLayout.FUSE_BOX_Z - 5.0))
	var second_light := _find_nearest_light(Vector3(0, 2.5, WorldLayout.FUSE_BOX_Z - 18.0))
	sequence.set_light(first_light, 1.7, Color(0.45, 0.62, 0.72))
	sequence.play_spatial_at(Vector3(0, 1.2, WorldLayout.FUSE_BOX_Z - 9.0), "scare_fuse_arc", 91.0, 0.34, -12.0)
	if not await sequence.wait(0.24):
		return
	sequence.set_light(second_light, 1.5, Color(0.58, 0.16, 0.1))
	sequence.play_spatial_at(Vector3(2.8, 1.2, WorldLayout.FUSE_BOX_Z - 12.0), "scare_fuse_door_slam", 52.0, 0.44, -8.0)
	if await sequence.wait(0.82):
		sequence.finish()

func _create_sequence(sequence_name: String) -> HorrorScareSequence:
	var sequence := SCARE_SEQUENCE_SCRIPT.new() as HorrorScareSequence
	sequence.name = sequence_name
	sequence.setup(effect_duration_scale)
	add_child(sequence)
	_active_sequences.append(sequence)
	sequence.tree_exited.connect(_on_sequence_exited.bind(sequence))
	return sequence

func finish_sequence(sequence_name: String) -> void:
	var sequence := get_node_or_null(sequence_name) as HorrorScareSequence
	if sequence != null:
		sequence.finish()

func _on_sequence_exited(sequence: HorrorScareSequence) -> void:
	_active_sequences.erase(sequence)

func _find_nearest_light(position: Vector3) -> OmniLight3D:
	var nearest: OmniLight3D
	var nearest_distance := INF
	for child in _director.get_children():
		if not child is OmniLight3D:
			continue
		var light := child as OmniLight3D
		var distance := light.global_position.distance_squared_to(position)
		if distance < nearest_distance:
			nearest = light
			nearest_distance = distance
	return nearest

func _exit_tree() -> void:
	for sequence in _active_sequences.duplicate():
		if is_instance_valid(sequence):
			sequence.cancel()
	_active_sequences.clear()

func _spawn_message(text: String, position: Vector3, color: Color) -> void:
	var label := LevelGeometry.add_label(self, text, position, color)
	label.font_size = 22
	_schedule_free(label, 6.0)

func _spawn_apparition(
	position: Vector3,
	actor_name: String,
	actor_scale := Vector3.ONE,
	add_eyes := false
) -> Node3D:
	return APPARITION_FACTORY.spawn(self, position, actor_name, actor_scale, add_eyes)

func _floor_arrival_position() -> Vector3:
	return Vector3(2.75, 1.3, WorldLayout.FLOOR_TRIGGER_Z - 14.0)

func _scare_position_ahead(distance: float, height: float, lateral: float, fallback_z: float) -> Vector3:
	if is_instance_valid(_player):
		return Vector3(_player.global_position.x + lateral, height, _player.global_position.z - distance)
	# A restored checkpoint can trigger a beat before the player reference is
	# rebound. Keep the apparition at its authored chapter anchor instead of
	# silently dropping it back near the lobby/floor threshold.
	return Vector3(lateral, height, fallback_z)

func _schedule_free(node: Node, seconds: float) -> void:
	var timer := get_tree().create_timer(_scaled_duration(seconds), false)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(node):
			node.queue_free()
	)

func _scaled_duration(seconds: float) -> float:
	return maxf(0.001, seconds * effect_duration_scale)

func _spawn_turn_away_apparition() -> void:
	if not is_instance_valid(_player):
		return
	var sequence := _create_sequence("CassetteTurnAwayScare")
	var apparition := TurnAwayApparition.new()
	add_child(apparition)
	sequence.own_node(apparition)
	apparition.setup(_player, Vector3(0, 1.25, WorldLayout.MEMORY_CASSETTE_Z + 8.0), effect_duration_scale)
