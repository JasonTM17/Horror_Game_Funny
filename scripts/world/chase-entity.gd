extends CharacterBody3D

@export var speed := 1.9
var target: Node3D
var active := false
var _director: Node
enum State { DORMANT, APPEAR, STALK, SEARCH, CHASE, LOST_TARGET, DESPAWN }
signal state_changed(state: State)
var state: State = State.DORMANT
var _state_time := 0.0
var _last_target_position := Vector3.ZERO

func setup(player: Node3D, director: Node) -> void:
	target = player
	_director = director
	state = State.DORMANT

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
	_state_time += delta
	if state == State.APPEAR and _state_time > 0.7:
		_transition_to(State.CHASE)
	if state == State.LOST_TARGET and _state_time > 1.6:
		_transition_to(State.SEARCH)
	if state == State.DESPAWN:
		return
	var offset := target.global_position - global_position
	_last_target_position = target.global_position
	if state == State.SEARCH:
		offset = _last_target_position - global_position
	if offset.length() > 0.1:
		velocity = offset.normalized() * speed
		move_and_slide()
	look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
	if state == State.SEARCH and offset.length() < 1.0:
		_transition_to(State.CHASE)
	if state == State.CHASE and offset.length() > 18.0:
		_transition_to(State.LOST_TARGET)
	if global_position.distance_to(target.global_position) < 1.25 and _director != null:
		_director.fail_chase()

func _transition_to(next_state: State) -> void:
	if state == next_state:
		return
	var allowed := {
		State.DORMANT: [State.APPEAR, State.DESPAWN],
		State.APPEAR: [State.CHASE, State.DESPAWN],
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
