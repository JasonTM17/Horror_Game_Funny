class_name ContinuousWorldBuilder
extends RefCounted

static func build(parent: Node3D) -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.009, 0.016)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.12, 0.16, 0.22)
	environment.ambient_light_energy = 0.22
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.08, 0.1, 0.13)
	environment.fog_density = 0.012
	world.environment = environment
	parent.add_child(world)
	LevelGeometry.add_box(parent, "Floor", Vector3(0, -0.15, WorldLayout.FLOOR_CENTER_Z), Vector3(8, 0.3, WorldLayout.FLOOR_LENGTH), Color(0.055, 0.06, 0.075))
	LevelGeometry.add_box(parent, "LeftWall", Vector3(-4, 2.0, WorldLayout.FLOOR_CENTER_Z), Vector3(0.25, 4.0, WorldLayout.FLOOR_LENGTH), Color(0.08, 0.075, 0.085))
	LevelGeometry.add_box(parent, "RightWall", Vector3(4, 2.0, WorldLayout.FLOOR_CENTER_Z), Vector3(0.25, 4.0, WorldLayout.FLOOR_LENGTH), Color(0.08, 0.075, 0.085))
	LevelGeometry.add_box(parent, "LobbyBack", Vector3(0, 2.0, 35), Vector3(8, 4, 0.25), Color(0.11, 0.1, 0.12))
	_add_partition(parent, "LobbyPartition", WorldLayout.FLOOR_DOOR_Z, Color(0.1, 0.09, 0.11))
	_add_partition(parent, "PowerPartition", WorldLayout.POWER_DOOR_Z, Color(0.08, 0.09, 0.1))
	_add_partition(parent, "Room407Partition", WorldLayout.ROOM_DOOR_Z, Color(0.12, 0.07, 0.08))
	LevelGeometry.add_box(parent, "Room407Floor", Vector3(0, -0.05, -423), Vector3(8, 0.2, 155), Color(0.09, 0.055, 0.06))
	LevelGeometry.add_box(parent, "BackWall", Vector3(0, 2.0, WorldLayout.BACK_WALL_Z), Vector3(8, 4, 0.25), Color(0.13, 0.06, 0.07))
	LevelGeometry.add_label(parent, "NIGHT DESK", Vector3(-2.8, 1.65, WorldLayout.LOBBY_PROP_Z))
	LevelGeometry.add_label(parent, "FLOOR 4", Vector3(-2.9, 2.1, WorldLayout.FLOOR_TRIGGER_Z - 12.0), Color(0.42, 0.46, 0.48))
	LevelGeometry.add_label(parent, "407", Vector3(-1.0, 2.1, WorldLayout.ROOM_DOOR_Z - 2.0), Color(0.65, 0.3, 0.28))
	for z in [24.0, -18.0, -55.0, -92.0, -130.0, -170.0, -210.0, -250.0, -290.0, -330.0, -370.0, -415.0, -460.0, -505.0, -565.0, -625.0, -685.0, -745.0, -795.0]:
		LevelGeometry.add_light(parent, Vector3(0, 2.8, z), Color(0.48, 0.57, 0.68), 0.48, 6.5)
	LevelGeometry.add_light(parent, Vector3(0, 2.6, WorldLayout.FINAL_CLUE_Z), Color(0.52, 0.12, 0.1), 1.0, 7.0)

static func _add_partition(parent: Node3D, name: String, z: float, color: Color) -> void:
	LevelGeometry.add_box(parent, name + "Left", Vector3(-2.65, 2.0, z), Vector3(2.7, 4.0, 0.25), color)
	LevelGeometry.add_box(parent, name + "Right", Vector3(2.65, 2.0, z), Vector3(2.7, 4.0, 0.25), color)
