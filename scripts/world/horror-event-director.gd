extends Node3D

@export_range(0.01, 2.0, 0.01) var effect_duration_scale := 1.0

var _director: Node
var _hallway: Node
var _player: Node3D

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
			_spawn_message("YOU WERE HERE", Vector3(0, 2.2, WorldLayout.MEMORY_PHOTO_Z - 5.0), Color(0.72, 0.2, 0.18))
			AudioManager.play_tone("memory_whisper", 210.0, 0.6, -17.0)
		"memory_cassette":
			_spawn_message("DON'T TURN AROUND", Vector3(0, 2.2, WorldLayout.MEMORY_CASSETTE_Z - 5.0), Color(0.62, 0.58, 0.5))
			AudioManager.play_tone("memory_whisper_two", 95.0, 0.9, -18.0)
			_spawn_turn_away_apparition()
		"memory_rabbit":
			_spawn_apparition(Vector3(0, 1.25, WorldLayout.LOOP_GATE_Z - 6.0), "MemoryRabbitApparition", 4.0)
			AudioManager.play_tone("memory_whisper_three", 56.0, 1.1, -14.0)
		"fuse_power":
			_spawn_message("THE LIGHTS REMEMBER", Vector3(-2.8, 2.0, WorldLayout.FUSE_BOX_Z - 4.0), Color(0.48, 0.64, 0.72))
		"room_entity_reveal":
			var apparition := _spawn_apparition(
				Vector3(0, 1.35, WorldLayout.FINAL_CLUE_Z - 14.0),
				"RoomEntityManifestation",
				5.5,
				Vector3(1.15, 1.2, 0.82),
				true
			)
			AudioManager.play_spatial_tone(apparition, "room_entity_reveal", 47.0, 0.9, -12.0)

func _run_floor_arrival() -> void:
	var display := _director.get_node_or_null("ElevatorDisplay") as Label3D
	if display != null:
		display.text = "4"
		display.modulate = Color(0.86, 0.16, 0.1)
	var floor_door := _director.get_node_or_null("floor_door") as DoorInteractable
	if floor_door != null:
		floor_door.close_for_event()
	_spawn_apparition(Vector3(2.75, 1.3, -53.0), "FloorArrivalApparition", 3.2, Vector3(0.82, 1.05, 0.68))
	await get_tree().create_timer(_scaled_duration(0.55), false).timeout
	if is_instance_valid(display):
		display.text = "--"
		display.modulate = Color(0.22, 0.035, 0.025)

func _spawn_message(text: String, position: Vector3, color: Color) -> void:
	var label := LevelGeometry.add_label(self, text, position, color)
	label.font_size = 22
	_schedule_free(label, 6.0)

func _spawn_apparition(
	position: Vector3,
	actor_name: String,
	lifetime: float,
	actor_scale := Vector3.ONE,
	add_eyes := false
) -> Node3D:
	var apparition := Node3D.new()
	apparition.name = actor_name
	apparition.position = position
	apparition.scale = actor_scale
	add_child(apparition)
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.3
	body_mesh.height = 2.1
	body.mesh = body_mesh
	body.material_override = LevelGeometry.material(Color(0.008, 0.006, 0.01))
	apparition.add_child(body)
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.31
	head_mesh.height = 0.62
	head.mesh = head_mesh
	head.position.y = 1.02
	head.material_override = LevelGeometry.material(Color(0.006, 0.004, 0.008))
	apparition.add_child(head)
	if add_eyes:
		_add_eye(apparition, "EyeLeft", Vector3(-0.1, 1.07, 0.28))
		_add_eye(apparition, "EyeRight", Vector3(0.1, 1.07, 0.28))
	_schedule_free(apparition, lifetime)
	return apparition

func _add_eye(parent: Node3D, eye_name: String, eye_position: Vector3) -> void:
	var eye := MeshInstance3D.new()
	eye.name = eye_name
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.025
	eye_mesh.height = 0.05
	eye.mesh = eye_mesh
	eye.position = eye_position
	eye.material_override = LevelGeometry.material(Color(0.58, 0.025, 0.018), 0.3)
	parent.add_child(eye)

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
	var apparition := TurnAwayApparition.new()
	add_child(apparition)
	apparition.setup(_player, Vector3(0, 1.25, WorldLayout.MEMORY_CASSETTE_Z + 8.0))
