class_name ContinuousStoryLayout
extends RefCounted

const STORY_SCRIPT := preload("res://scripts/interaction/story-interactable.gd")
const DOOR_SCRIPT := preload("res://scripts/interaction/door-interactable.gd")

static func build(director: Node3D) -> void:
	_add_story(director, "phone", Vector3(-1.8, 1.18, WorldLayout.LOBBY_PROP_Z - 0.25), "Answer the phone", Color(0.16, 0.12, 0.1))
	_add_story(director, "logbook", Vector3(1.8, 1.12, WorldLayout.LOBBY_PROP_Z - 0.25), "Sign the night log", Color(0.25, 0.18, 0.12))
	_add_door(director, "floor_door", Vector3(0, 1.25, WorldLayout.FLOOR_DOOR_Z), "log_signed", 92.0)
	_add_story(director, "fuse_pickup", Vector3(2.3, 0.45, WorldLayout.FUSE_PICKUP_Z), "Take the spare fuse", Color(0.74, 0.55, 0.2))
	_add_story(director, "fuse_box", Vector3(-2.8, 1.15, WorldLayout.FUSE_BOX_Z), "Open the fuse box", Color(0.2, 0.22, 0.24))
	_add_door(director, "power_door", Vector3(0, 1.25, WorldLayout.POWER_DOOR_Z), "power_stable", -92.0)
	_add_story(director, "memory_photo", Vector3(-2.4, 0.6, WorldLayout.MEMORY_PHOTO_Z), "Inspect the burned photograph", Color(0.28, 0.18, 0.12))
	_add_story(director, "memory_cassette", Vector3(2.2, 0.35, WorldLayout.MEMORY_CASSETTE_Z), "Take the cassette", Color(0.12, 0.08, 0.06))
	_add_story(director, "memory_rabbit", Vector3(-2.4, 0.42, WorldLayout.MEMORY_RABBIT_Z), "Pick up the red rabbit", Color(0.5, 0.08, 0.07))
	_add_loop_gate(director)
	_add_story(director, "radio", Vector3(2.2, 0.7, WorldLayout.RADIO_Z), "Tune the radio", Color(0.12, 0.16, 0.17))
	_add_door(director, "room_door", Vector3(0, 1.25, WorldLayout.ROOM_DOOR_Z), "radio_solved", -92.0)
	_add_story(director, "room_record", Vector3(-2.4, 0.55, WorldLayout.ROOM_RECORD_Z), "Play the family recording", Color(0.2, 0.12, 0.1))
	_add_story(director, "room_drawing", Vector3(2.4, 0.6, WorldLayout.ROOM_DRAWING_Z), "Inspect the wall drawing", Color(0.35, 0.12, 0.1))
	_add_story(director, "final_clue", Vector3(0, 0.5, WorldLayout.FINAL_CLUE_Z), "Read the child's note", Color(0.32, 0.26, 0.19))
	_add_story(director, "exit", Vector3(0, 1.0, WorldLayout.EXIT_Z), "Run for the lobby", Color(0.18, 0.22, 0.24))

static func _add_story(director: Node3D, id: String, position: Vector3, label: String, color: Color) -> void:
	var item := STORY_SCRIPT.new() as StoryInteractable
	item.name = id
	item.position = position
	item.setup(director, id, label)
	item.collision_layer = 9
	director.add_child(item)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.65, 0.45)
	mesh.mesh = box
	mesh.material_override = LevelGeometry.material(color)
	item.add_child(mesh)
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(0.55, 0.65, 0.45)
	shape.shape = collider
	item.add_child(shape)

static func _add_door(director: Node3D, id: String, position: Vector3, locked_flag: String, angle: float) -> void:
	var door := DOOR_SCRIPT.new() as DoorInteractable
	door.name = id
	door.position = position
	door.open_angle = angle
	door.locked_flag = locked_flag
	door.prompt_text = "Door"
	door.collision_layer = 9
	director.add_child(door)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.2, 2.5, 0.2)
	mesh.mesh = box
	mesh.material_override = LevelGeometry.material(Color(0.16, 0.12, 0.12))
	door.add_child(mesh)
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(2.2, 2.5, 0.2)
	shape.shape = collider
	door.add_child(shape)

static func _add_loop_gate(director: Node3D) -> void:
	var gate := STORY_SCRIPT.new() as StoryInteractable
	gate.name = "hallway_loop"
	gate.position = Vector3(0, 1.25, WorldLayout.LOOP_GATE_Z)
	gate.setup(director, "hallway_loop", "Follow the impossible corner")
	gate.collision_layer = 9
	director.add_child(gate)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(7.4, 2.5, 0.22)
	mesh.mesh = box
	mesh.material_override = LevelGeometry.material(Color(0.015, 0.02, 0.025))
	gate.add_child(mesh)
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(7.4, 2.5, 0.22)
	shape.shape = collider
	gate.add_child(shape)
