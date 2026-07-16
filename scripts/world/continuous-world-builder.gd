class_name ContinuousWorldBuilder
extends RefCounted

const CHASE_BARRIERS := [
	{"z": -570.0, "blocked_center_x": -1.4, "blocked_probe_x": -1.4, "blocked_width": 4.8, "bypass_x": 2.35, "safe_min_x": 1.8, "safe_max_x": 3.35, "label": "RIGHT"},
	{"z": -650.0, "blocked_center_x": 1.4, "blocked_probe_x": 1.4, "blocked_width": 4.8, "bypass_x": -2.35, "safe_min_x": -3.35, "safe_max_x": -1.8, "label": "LEFT"},
	{"z": -730.0, "blocked_center_x": -1.4, "blocked_probe_x": -1.4, "blocked_width": 4.8, "bypass_x": 2.35, "safe_min_x": 1.8, "safe_max_x": 3.35, "label": "RIGHT"},
]
const CHASE_NAV_SEGMENT_COUNT := 13

static func build(parent: Node3D) -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.009, 0.016)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.24, 0.28, 0.36)
	environment.ambient_light_energy = 0.78
	environment.tonemap_exposure = 1.35
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.08, 0.1, 0.13)
	environment.fog_density = 0.0065
	world.environment = environment
	parent.add_child(world)
	LevelGeometry.add_box(parent, "Floor", Vector3(0, -0.15, WorldLayout.FLOOR_CENTER_Z), Vector3(8, 0.3, WorldLayout.FLOOR_LENGTH), Color(0.085, 0.09, 0.11))
	LevelGeometry.add_box(parent, "Ceiling", Vector3(0, 4.1, WorldLayout.FLOOR_CENTER_Z), Vector3(8, 0.2, WorldLayout.FLOOR_LENGTH), Color(0.07, 0.075, 0.09))
	LevelGeometry.add_box(parent, "LeftWall", Vector3(-4, 2.0, WorldLayout.FLOOR_CENTER_Z), Vector3(0.25, 4.0, WorldLayout.FLOOR_LENGTH), Color(0.13, 0.12, 0.14))
	LevelGeometry.add_box(parent, "RightWall", Vector3(4, 2.0, WorldLayout.FLOOR_CENTER_Z), Vector3(0.25, 4.0, WorldLayout.FLOOR_LENGTH), Color(0.13, 0.12, 0.14))
	LevelGeometry.add_box(parent, "LobbyBack", Vector3(0, 2.0, 35), Vector3(8, 4, 0.25), Color(0.11, 0.1, 0.12))
	_add_partition(parent, "LobbyPartition", WorldLayout.FLOOR_DOOR_Z, Color(0.1, 0.09, 0.11))
	_add_partition(parent, "PowerPartition", WorldLayout.POWER_DOOR_Z, Color(0.08, 0.09, 0.1))
	_add_partition(parent, "Room407Partition", WorldLayout.ROOM_DOOR_Z, Color(0.12, 0.07, 0.08))
	LevelGeometry.add_box(parent, "Room407Floor", Vector3(0, -0.05, -423), Vector3(8, 0.2, 155), Color(0.09, 0.055, 0.06))
	LevelGeometry.add_box(parent, "ChildBed", Vector3(-2.45, 0.35, -407.0), Vector3(2.1, 0.7, 3.8), Color(0.18, 0.11, 0.12))
	LevelGeometry.add_box(parent, "RoomWardrobe", Vector3(2.95, 1.25, -447.0), Vector3(1.5, 2.5, 0.8), Color(0.13, 0.075, 0.065))
	LevelGeometry.add_box(parent, "FamilyTable", Vector3(-2.6, 0.55, -462.0), Vector3(1.8, 1.1, 1.2), Color(0.17, 0.1, 0.08))
	LevelGeometry.add_box(parent, "BackWall", Vector3(0, 2.0, WorldLayout.BACK_WALL_Z), Vector3(8, 4, 0.25), Color(0.13, 0.06, 0.07))
	LevelGeometry.add_box(parent, "NightDeskBase", Vector3(0, 0.43, WorldLayout.LOBBY_PROP_Z + 0.15), Vector3(5.2, 0.86, 1.35), Color(0.09, 0.065, 0.055))
	LevelGeometry.add_box(parent, "NightDeskTop", Vector3(0, 0.92, WorldLayout.LOBBY_PROP_Z + 0.15), Vector3(5.5, 0.12, 1.55), Color(0.19, 0.13, 0.09))
	LevelGeometry.add_label(parent, "NIGHT DESK", Vector3(-2.8, 1.65, WorldLayout.LOBBY_PROP_Z))
	LevelGeometry.add_label(parent, "FLOOR 4", Vector3(-2.9, 2.1, WorldLayout.FLOOR_TRIGGER_Z - 12.0), Color(0.42, 0.46, 0.48))
	LevelGeometry.add_label(parent, "407", Vector3(-1.0, 2.1, WorldLayout.ROOM_DOOR_Z - 2.0), Color(0.65, 0.3, 0.28))
	LevelGeometry.add_label(parent, "EXIT", Vector3(0, 2.55, WorldLayout.EXIT_Z + 1.0), Color(0.85, 0.16, 0.12))
	_add_elevator_dressing(parent)
	_add_room_407_dressing(parent)
	_add_chase_dressing(parent)
	var corridor_light_index := 0
	for z in [24.0, -18.0, -55.0, -92.0, -130.0, -170.0, -210.0, -250.0, -290.0, -330.0, -370.0, -415.0, -460.0, -505.0, -565.0, -625.0, -685.0, -745.0, -795.0]:
		var light_energy := 3.2 if is_equal_approx(z, 24.0) else 1.25
		var light_range := 13.0 if is_equal_approx(z, 24.0) else 10.5
		var corridor_light := LevelGeometry.add_light(parent, Vector3(0, 2.8, z), Color(0.48, 0.57, 0.68), light_energy, light_range)
		corridor_light.name = "CorridorLight%02d" % corridor_light_index
		corridor_light_index += 1
	var lobby_task_light := LevelGeometry.add_light(parent, Vector3(0, 2.25, WorldLayout.LOBBY_PROP_Z - 0.5), Color(0.92, 0.58, 0.34), 2.0, 5.5)
	lobby_task_light.name = "LobbyTaskLight"
	LevelGeometry.add_light(parent, Vector3(0, 2.6, WorldLayout.FINAL_CLUE_Z), Color(0.52, 0.12, 0.1), 1.6, 8.0)
	for chase_z in [-540.0, -610.0, -690.0, -770.0, -800.0]:
		var guide_light := LevelGeometry.add_light(parent, Vector3(0, 2.35, chase_z), Color(0.62, 0.035, 0.025), 1.05, 9.0)
		guide_light.name = "ChaseGuideLight"
	for index: int in CHASE_BARRIERS.size():
		var barrier: Dictionary = CHASE_BARRIERS[index]
		var bypass_light := LevelGeometry.add_light(
			parent,
			Vector3(float(barrier["bypass_x"]), 2.35, float(barrier["z"]) + 1.8),
			Color(0.9, 0.045, 0.025),
			1.35,
			8.0
		)
		bypass_light.name = "ChaseBypassLight%02d" % index
	_add_navigation_surface(parent)

static func _add_elevator_dressing(parent: Node3D) -> void:
	var metal := Color(0.11, 0.12, 0.14)
	LevelGeometry.add_visual_box(parent, "ElevatorFrameLeft", Vector3(-1.32, 2.0, 0.18), Vector3(0.28, 3.7, 0.22), metal)
	LevelGeometry.add_visual_box(parent, "ElevatorFrameRight", Vector3(1.32, 2.0, 0.18), Vector3(0.28, 3.7, 0.22), metal)
	LevelGeometry.add_visual_box(parent, "ElevatorFrameHeader", Vector3(0, 3.72, 0.18), Vector3(2.9, 0.28, 0.22), metal)
	LevelGeometry.add_visual_box(parent, "ElevatorDisplayHousing", Vector3(0, 3.28, 0.32), Vector3(0.72, 0.42, 0.12), Color(0.025, 0.025, 0.03))
	var floor_arrived := GameState.has_flag("floor_reached") or bool(GameState.completed_events.get("floor_arrival", false))
	var display_text := "--" if floor_arrived else "3"
	var display_color := Color(0.22, 0.035, 0.025) if floor_arrived else Color(0.78, 0.6, 0.26)
	var display := LevelGeometry.add_label(parent, display_text, Vector3(0, 3.28, 0.4), display_color)
	display.name = "ElevatorDisplay"
	display.font_size = 38
	display.no_depth_test = false
	LevelGeometry.add_visual_box(parent, "ElevatorCallPanel", Vector3(1.72, 1.45, 0.28), Vector3(0.22, 0.48, 0.12), Color(0.16, 0.16, 0.18))
	LevelGeometry.add_visual_box(parent, "FloorFalseDoor", Vector3(3.82, 1.3, -54.0), Vector3(0.12, 2.6, 1.65), Color(0.075, 0.065, 0.07))

static func _add_room_407_dressing(parent: Node3D) -> void:
	var panel_index := 0
	for z in [-366.0, -386.0, -406.0, -426.0, -446.0, -466.0]:
		var panel_color := Color(0.19, 0.105, 0.11) if panel_index % 2 == 0 else Color(0.15, 0.09, 0.105)
		LevelGeometry.add_visual_box(parent, "Room407WallpaperPanel%02d" % panel_index, Vector3(-3.82, 2.0, z), Vector3(0.1, 3.75, 15.0), panel_color)
		LevelGeometry.add_visual_box(parent, "Room407WallpaperPanelR%02d" % panel_index, Vector3(3.82, 2.0, z), Vector3(0.1, 3.75, 15.0), panel_color.darkened(0.08))
		panel_index += 1
	var rib_index := 0
	for z in [-370.0, -402.0, -434.0, -466.0]:
		LevelGeometry.add_visual_box(parent, "Room407CeilingRib%02d" % rib_index, Vector3(0, 3.82, z), Vector3(7.45, 0.24, 0.34), Color(0.085, 0.05, 0.055))
		LevelGeometry.add_visual_box(parent, "Room407ArchLeft%02d" % rib_index, Vector3(-3.45, 2.0, z), Vector3(0.22, 3.7, 0.34), Color(0.085, 0.05, 0.055))
		LevelGeometry.add_visual_box(parent, "Room407ArchRight%02d" % rib_index, Vector3(3.45, 2.0, z), Vector3(0.22, 3.7, 0.34), Color(0.085, 0.05, 0.055))
		rib_index += 1
	for mark_index in 6:
		var mark_y := 0.72 + float(mark_index) * 0.2
		var mark_width := 0.38 if mark_index % 2 == 0 else 0.24
		LevelGeometry.add_visual_box(parent, "Room407HeightMark%02d" % mark_index, Vector3(-3.73, mark_y, -414.0), Vector3(0.12, 0.035, mark_width), Color(0.64, 0.21, 0.17))
	var warning := LevelGeometry.add_label(parent, "DON'T GROW PAST THIS LINE", Vector3(-2.65, 1.78, -414.0), Color(0.58, 0.2, 0.18))
	warning.name = "Room407HeightWarning"
	warning.font_size = 14
	warning.no_depth_test = false

static func _add_chase_dressing(parent: Node3D) -> void:
	var scar_index := 0
	for z in [-535.0, -575.0, -615.0, -655.0, -695.0, -735.0, -775.0]:
		var side := -1.0 if scar_index % 2 == 0 else 1.0
		LevelGeometry.add_visual_box(parent, "ChaseWallScar%02d" % scar_index, Vector3(side * 3.73, 1.35, z), Vector3(0.13, 2.3, 2.6), Color(0.055, 0.035, 0.04))
		LevelGeometry.add_visual_box(parent, "ChaseBrokenFrame%02d" % scar_index, Vector3(side * 3.35, 2.15, z - 1.2), Vector3(0.18, 2.8, 0.22), Color(0.11, 0.055, 0.05))
		scar_index += 1
	for index: int in CHASE_BARRIERS.size():
		var barrier: Dictionary = CHASE_BARRIERS[index]
		var barrier_position := Vector3(float(barrier["blocked_center_x"]), 1.3, float(barrier["z"]))
		var barrier_body := LevelGeometry.add_box(
			parent,
			"ChaseBarrier%02d" % index,
			barrier_position,
			Vector3(float(barrier["blocked_width"]), 2.6, 1.2),
			Color(0.07, 0.025, 0.03)
		)
		barrier_body.collision_layer = 1
		LevelGeometry.add_visual_box(
			parent,
			"ChaseBarrierFrame%02d" % index,
			barrier_position + Vector3(0, 1.35, 0),
			Vector3(float(barrier["blocked_width"]) + 0.12, 0.16, 1.34),
			Color(0.15, 0.035, 0.04)
		)
		var cue := LevelGeometry.add_label(
			parent,
			"GO " + str(barrier["label"]),
			Vector3(float(barrier["bypass_x"]), 2.15, float(barrier["z"]) + 2.35),
			Color(0.95, 0.12, 0.08)
		)
		cue.name = "ChaseBypassCue%02d" % index
		cue.font_size = 20
		LevelGeometry.add_visual_box(
			parent,
			"ChaseBypassMarker%02d" % index,
			Vector3(float(barrier["bypass_x"]), 0.015, float(barrier["z"]) + 1.8),
			Vector3(1.35, 0.03, 0.2),
			Color(0.58, 0.025, 0.02)
		)

static func _add_partition(parent: Node3D, name: String, z: float, color: Color) -> void:
	LevelGeometry.add_box(parent, name + "Left", Vector3(-2.65, 2.0, z), Vector3(2.7, 4.0, 0.25), color)
	LevelGeometry.add_box(parent, name + "Right", Vector3(2.65, 2.0, z), Vector3(2.7, 4.0, 0.25), color)
	LevelGeometry.add_box(parent, name + "Header", Vector3(0, 3.55, z), Vector3(2.6, 0.9, 0.3), color)

static func _add_navigation_surface(parent: Node3D) -> void:
	var region := NavigationRegion3D.new()
	region.name = "ContinuousCorridorNavigation"
	var navigation_mesh := NavigationMesh.new()
	var sections: Array[Dictionary] = [{"z": WorldLayout.PLAYER_START_Z + 4.0, "min_x": -3.45, "max_x": 3.45}]
	for barrier: Dictionary in CHASE_BARRIERS:
		var barrier_z := float(barrier["z"])
		sections.append({"z": barrier_z + 3.0, "min_x": -3.45, "max_x": 3.45})
		sections.append({"z": barrier_z + 1.0, "min_x": float(barrier["safe_min_x"]), "max_x": float(barrier["safe_max_x"])})
		sections.append({"z": barrier_z - 1.0, "min_x": float(barrier["safe_min_x"]), "max_x": float(barrier["safe_max_x"])})
		sections.append({"z": barrier_z - 3.0, "min_x": -3.45, "max_x": 3.45})
	sections.append({"z": WorldLayout.EXIT_Z - 10.0, "min_x": -3.45, "max_x": 3.45})
	var vertices := PackedVector3Array()
	for section: Dictionary in sections:
		vertices.append(Vector3(float(section["min_x"]), 0.02, float(section["z"])))
		vertices.append(Vector3(float(section["max_x"]), 0.02, float(section["z"])))
	navigation_mesh.vertices = vertices
	for section_index in range(sections.size() - 1):
		var start_index := section_index * 2
		var end_index := (section_index + 1) * 2
		navigation_mesh.add_polygon(PackedInt32Array([start_index, start_index + 1, end_index + 1, end_index]))
	region.navigation_mesh = navigation_mesh
	parent.add_child(region)
