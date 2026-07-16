extends CharacterBody3D

@export var speed := 3.0
@export var detection_range := 24.0
@export var stalk_speed_multiplier := 0.38
@export var lost_speed_multiplier := 0.55
@export var search_speed_multiplier := 0.3
@export var appear_duration := 0.7
@export var stalk_duration := 1.0
@export var lost_target_duration := 1.6
@export var search_duration := 2.4
@export_range(1, 8, 1) var max_search_cycles := 2

var target: Node3D
var active := false
var _director: Node
enum State { DORMANT, APPEAR, STALK, SEARCH, CHASE, LOST_TARGET, DESPAWN }
signal state_changed(state: State)
var state: State = State.DORMANT
var _state_time := 0.0
var _last_target_position := Vector3.ZERO
var _agent: NavigationAgent3D
var _los_timer := 0.0
var _target_visible := true
var _search_cycles := 0

func setup(player: Node3D, director: Node) -> void:
	target = player
	_director = director
	state = State.DORMANT
	_last_target_position = player.global_position
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 1.0
	_agent.avoidance_enabled = false
	add_child(_agent)

func start_chase() -> void:
	if active and state != State.DESPAWN:
		return
	active = true
	visible = true
	velocity = Vector3.ZERO
	_search_cycles = 0
	_los_timer = 0.0
	if is_instance_valid(target):
		_last_target_position = target.global_position
	if state == State.DESPAWN:
		state = State.DORMANT
	_transition_to(State.APPEAR)

func stop_chase() -> void:
	active = false
	visible = false
	_transition_to(State.DESPAWN)
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target):
		velocity = Vector3.ZERO
		return
	if target.global_position.z > WorldLayout.CHASE_TRIGGER_Z + 25.0:
		velocity = Vector3.ZERO
		if _director != null:
			_director.fail_chase()
		return
	if target.global_position.z < WorldLayout.EXIT_Z - 8.0:
		stop_chase()
		return
	_state_time += delta
	_update_visibility(delta)
	_advance_state()
	if state == State.DORMANT or state == State.APPEAR or state == State.DESPAWN:
		velocity = Vector3.ZERO
		_face_position(target.global_position)
		return
	var destination := _movement_destination()
	_move_toward(destination, _movement_speed())
	if (state == State.STALK or state == State.CHASE) and global_position.distance_to(target.global_position) < 1.25 and _director != null:
		_director.fail_chase()

func _update_visibility(delta: float) -> void:
	_los_timer -= delta
	if _los_timer > 0.0:
		return
	_los_timer = 0.2
	_target_visible = _has_line_of_sight()
	var target_is_detectable := global_position.distance_to(target.global_position) <= detection_range
	if _target_visible and (state == State.APPEAR or state == State.STALK or state == State.CHASE or target_is_detectable):
		_last_target_position = target.global_position

func _advance_state() -> void:
	var target_distance := global_position.distance_to(target.global_position)
	match state:
		State.APPEAR:
			if _state_time >= appear_duration:
				_transition_to(State.STALK)
		State.STALK:
			if _state_time >= stalk_duration:
				_transition_to(State.CHASE)
		State.CHASE:
			if not _target_visible or target_distance > detection_range:
				_transition_to(State.LOST_TARGET)
		State.LOST_TARGET:
			if _target_visible and target_distance <= detection_range:
				_transition_to(State.CHASE)
			elif _state_time >= lost_target_duration:
				_transition_to(State.SEARCH)
		State.SEARCH:
			if _target_visible and target_distance <= detection_range:
				_transition_to(State.CHASE)
			elif _state_time >= search_duration:
				if _search_cycles >= maxi(1, max_search_cycles):
					_transition_to(State.DESPAWN)
				else:
					_transition_to(State.LOST_TARGET)

func _movement_destination() -> Vector3:
	if state == State.STALK and _target_visible:
		return target.global_position
	if state == State.CHASE:
		return target.global_position
	return _last_target_position

func _movement_speed() -> float:
	match state:
		State.STALK:
			return speed * stalk_speed_multiplier
		State.LOST_TARGET:
			return speed * lost_speed_multiplier
		State.SEARCH:
			return speed * search_speed_multiplier
		State.CHASE:
			return speed
	return 0.0

func _move_toward(destination: Vector3, movement_speed: float) -> void:
	var offset := destination - global_position
	if _navigation_ready():
		_agent.target_position = destination
		var next_point := _agent.get_next_path_position()
		if next_point != Vector3.ZERO:
			offset = next_point - global_position
	offset.y = 0.0
	if offset.length() <= 0.1 or movement_speed <= 0.0:
		velocity = Vector3.ZERO
	else:
		velocity = offset.normalized() * movement_speed
		move_and_slide()
	_face_position(destination)

func _face_position(position: Vector3) -> void:
	var look_position := Vector3(position.x, global_position.y, position.z)
	if global_position.distance_squared_to(look_position) > 0.0025:
		look_at(look_position, Vector3.UP)

func _navigation_ready() -> bool:
	if _agent == null or get_world_3d() == null:
		return false
	var navigation_map := get_world_3d().navigation_map
	return navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(navigation_map) > 0

func _has_line_of_sight() -> bool:
	if not is_instance_valid(target) or get_world_3d() == null:
		return false
	var from := global_position + Vector3.UP
	var to := target.global_position + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(from, to, 3)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider: Object = hit.get("collider")
	return collider == target or (collider is Node and collider.is_in_group("player"))

func _transition_to(next_state: State) -> void:
	if state == next_state:
		return
	var allowed := {
		State.DORMANT: [State.APPEAR, State.DESPAWN],
		State.APPEAR: [State.STALK, State.DESPAWN],
		State.STALK: [State.CHASE, State.SEARCH, State.DESPAWN],
		State.SEARCH: [State.CHASE, State.LOST_TARGET, State.DESPAWN],
		State.CHASE: [State.LOST_TARGET, State.DESPAWN],
		State.LOST_TARGET: [State.SEARCH, State.CHASE, State.DESPAWN],
		State.DESPAWN: []
	}
	if not allowed.get(state, []).has(next_state):
		return
	state = next_state
	_state_time = 0.0
	if state == State.SEARCH:
		_search_cycles += 1
	elif state == State.CHASE:
		_search_cycles = 0
	if state == State.DESPAWN:
		active = false
		visible = false
		velocity = Vector3.ZERO
	state_changed.emit(state)
