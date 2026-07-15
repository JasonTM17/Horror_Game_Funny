extends CharacterBody3D

@export var speed := 1.9
var target: Node3D
var active := false
var _director: Node

func setup(player: Node3D, director: Node) -> void:
	target = player
	_director = director

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	if offset.length() > 0.1:
		velocity = offset.normalized() * speed
		move_and_slide()
	look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
	if global_position.distance_to(target.global_position) < 1.25 and _director != null:
		_director.fail_chase()

