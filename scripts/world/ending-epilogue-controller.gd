class_name EndingEpilogueController
extends Node

signal credits_requested

const STORY_SCRIPT := preload("res://scripts/interaction/story-interactable.gd")

const NOTICE_ACTION := "ending_notice"
const ROSTER_ACTION := "ending_roster"
const NOTICE_FLAG := "ending_notice_complete"
const ROSTER_FLAG := "ending_roster_complete"
const NOTICE_LINES := [
	"The condemnation notice is dated October 2007, sixteen years before tonight.",
	"Room 407 is named as the origin of a fire the hotel never reported.",
	"Your childhood signature appears beneath one line: only survivor.",
]
const ROSTER_LINES := [
	"The night roster lists no manager, no guard, and no scheduled shift.",
	"Every voice you heard belongs to the Room 407 casualty list.",
	"Your name is crossed out. Beside it, the clock reads 23:47.",
]

var active := false

var _director: Node3D
var _player: CharacterBody3D
var _narrative: Node
var _notice_started := false
var _roster_started := false
var _credits_requested := false

func setup(director: Node3D, player: CharacterBody3D, narrative: Node) -> void:
	_director = director
	_player = player
	_narrative = narrative
	_narrative.beat_finished.connect(_on_narrative_finished)

func begin(reveal_origin: Vector3) -> bool:
	if active or not is_instance_valid(_director) or not is_instance_valid(_player):
		return false
	active = true
	_build_reveal_interactables(reveal_origin)
	GameState.set_objective("Read the condemnation notice on the abandoned desk.")
	return true

func owns_action(action_id: String) -> bool:
	return active and action_id in [NOTICE_ACTION, ROSTER_ACTION]

func get_prompt(action_id: String, actor: Node) -> String:
	if not owns_action(action_id) or actor != _player:
		return ""
	if action_id == NOTICE_ACTION and not _notice_started and not GameState.has_flag(NOTICE_FLAG):
		return "[E] Read the 2007 condemnation notice"
	if action_id == ROSTER_ACTION and GameState.has_flag(NOTICE_FLAG) and not _roster_started and not GameState.has_flag(ROSTER_FLAG):
		return "[E] Read the night roster"
	return ""

func handle_action(action_id: String, actor: Node) -> bool:
	if get_prompt(action_id, actor).is_empty():
		return false
	if action_id == NOTICE_ACTION:
		_notice_started = true
		if not _narrative.play(NOTICE_LINES, NOTICE_FLAG, 4.5):
			_notice_started = false
			return false
		return true
	if action_id == ROSTER_ACTION:
		_roster_started = true
		if not _narrative.play(ROSTER_LINES, ROSTER_FLAG, 4.5):
			_roster_started = false
			return false
		return true
	return false

func _on_narrative_finished(flag: String) -> void:
	if not active:
		return
	if flag == NOTICE_FLAG:
		GameState.set_objective("Read the night roster beside the condemned desk.")
	elif flag == ROSTER_FLAG and not _credits_requested:
		_credits_requested = true
		GameState.set_objective("23:47. The shift was never scheduled.")
		credits_requested.emit()

func _build_reveal_interactables(reveal_origin: Vector3) -> void:
	var reveal_z := reveal_origin.z - 4.0
	var notice_position := Vector3(-2.2, 1.38, reveal_z - 0.34)
	var roster_position := Vector3(2.2, 1.38, reveal_z - 0.34)
	var notice := _add_interactable(
		NOTICE_ACTION,
		notice_position,
		Vector3(0.9, 0.72, 0.18),
		Color(0.42, 0.35, 0.25),
		"CONDEMNED\nOCT 2007"
	)
	_add_visual_box(notice, "NoticePaper", Vector3(0.82, 0.64, 0.07), Vector3.ZERO, Color(0.56, 0.49, 0.36))
	var roster := _add_interactable(
		ROSTER_ACTION,
		roster_position,
		Vector3(0.95, 0.68, 0.2),
		Color(0.22, 0.08, 0.07),
		"NIGHT ROSTER\n23:47"
	)
	_add_visual_box(roster, "RosterPages", Vector3(0.86, 0.58, 0.08), Vector3.ZERO, Color(0.5, 0.45, 0.35))
	LevelGeometry.add_box(_director, "RosterStand", Vector3(2.2, 0.48, reveal_z - 0.8), Vector3(1.5, 0.96, 1.0), Color(0.055, 0.035, 0.03))
	LevelGeometry.add_light(_director, notice_position + Vector3(0, 1.0, 0.6), Color(0.72, 0.18, 0.12), 0.8, 4.2)
	LevelGeometry.add_light(_director, roster_position + Vector3(0, 1.0, 0.6), Color(0.35, 0.08, 0.07), 0.65, 4.0)

func _add_interactable(
	action_id: String,
	position: Vector3,
	collider_size: Vector3,
	color: Color,
	label_text: String
) -> StoryInteractable:
	var item := STORY_SCRIPT.new() as StoryInteractable
	item.name = action_id
	item.position = position
	item.setup(_director, action_id, label_text)
	item.feedback_text = label_text
	item.collision_layer = 5
	item.collision_mask = 0
	_director.add_child(item)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = collider_size
	shape.shape = box
	item.add_child(shape)
	_add_label(item, label_text, color)
	return item

func _add_visual_box(parent: Node3D, name: String, size: Vector3, position: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	mesh_instance.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = LevelGeometry.material(color)
	parent.add_child(mesh_instance)

func _add_label(parent: Node3D, text: String, color: Color) -> void:
	var label := Label3D.new()
	label.name = "RevealWriting"
	label.text = text
	label.position = Vector3(0, 0, 0.11)
	label.font_size = 16
	label.outline_size = 6
	label.modulate = color.lightened(0.45)
	label.no_depth_test = true
	parent.add_child(label)
