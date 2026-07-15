extends CharacterBody3D

@export var speed := 3.0
@export var detection_range := 24.0
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

func setup(player: Node3D, director: Node) -> void:
	target = player
	_director = director
	state = State.DORMANT
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 1.0
	_agent.avoidance_enabled = false
	add_child(_agent)

func start_chase() -> void:
	active = true
	if state == State.DESPAWN:
		state = State.DORMANT
	_transition_to(State.APPEAR)

func stop_chase() -> void:
	active = false
	_transition_to(State.DESPAWN)

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target):
		return
	if target.global_position.z > WorldLayout.CHASE_TRIGGER_Z + 25.0:
		if _director != null:
			_director.fail_chase()
		return
	if target.global_position.z < WorldLayout.EXIT_Z - 8.0:
		stop_chase()
		return
	_state_time += delta
	_los_timer -= delta
	if _los_timer <= 0.0:
		_los_timer = 0.2
		_target_visible = _has_line_of_sight()
	if state == State.APPEAR and _state_time > 0.7:
		_transition_to(State.STALK)
	if state == State.STALK and _state_time > 1.0:
		_transition_to(State.CHASE)
	if state == State.LOST_TARGET and _state_time > 1.6:
		_transition_to(State.SEARCH)
	if state == State.DESPAWN:
		return
	var offset := target.global_position - global_position
	if _target_visible:
		_last_target_position = target.global_position
	if state == State.CHASE and (not _target_visible or offset.length() > detection_range):
		_transition_to(State.LOST_TARGET)
	if state == State.SEARCH:
		offset = _last_target_position - global_position
	elif _navigation_ready():
		_agent.target_position = target.global_position
		var next_point := _agent.get_next_path_position()
		if next_point != Vector3.ZERO:
			offset = next_point - global_position
	if offset.length() > 0.1:
		velocity = offset.normalized() * speed
		move_and_slide()
	look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
	if state == State.SEARCH and offset.length() < 1.0:
		_transition_to(State.CHASE)
	if global_position.distance_to(target.global_position) < 1.25 and _director != null:
		_director.fail_chase()

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
		State.CHASE: [State.SEARCH, State.LOST_TARGET, State.DESPAWN],
		State.LOST_TARGET: [State.SEARCH, State.DESPAWN],
		State.DESPAWN: []
	}
	if not allowed.get(state, []).has(next_state):
		return
	state = next_state
	_state_time = 0.0
	state_changed.emit(state)
