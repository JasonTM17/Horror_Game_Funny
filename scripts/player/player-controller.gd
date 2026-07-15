extends CharacterBody3D

signal input_lock_changed(locked: bool)
signal flashlight_changed(enabled: bool)

@export var walk_speed := 2.6
@export var sprint_multiplier := 1.65
@export var gravity := 12.0
@export var mouse_sensitivity := 0.08
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

var _locks: Dictionary = {}
var _pitch := -8.0
var _bob_time := 0.0
var _flashlight_on := true
var _step_time := 0.0
var _shake_remaining := 0.0
var _shake_strength := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_settings()
	SettingsManager.setting_changed.connect(_on_setting_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not is_input_locked():
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -78.0, 70.0)
		head.rotation.x = deg_to_rad(_pitch)
	if event.is_action_pressed("flashlight") and not is_input_locked():
		_flashlight_on = not _flashlight_on
		flashlight.visible = _flashlight_on
		flashlight_changed.emit(_flashlight_on)
	if event.is_action_pressed("pause_game"):
		if _locks.has("note") or _locks.has("radio") or _locks.has("settings") or _locks.has("fail") or _locks.has("ending"):
			return
		_toggle_pause()

func _physics_process(delta: float) -> void:
	if is_input_locked():
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_2d.x, 0.0, input_2d.y)).normalized()
	var speed := walk_speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 14.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 14.0)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.05
	move_and_slide()
	_update_head_bob(delta, direction.length() > 0.1)
	_update_camera_shake(delta)
	if direction.length() > 0.1 and is_on_floor():
		_step_time -= delta * (1.45 if Input.is_action_pressed("sprint") else 1.0)
		if _step_time <= 0.0:
			_step_time = 0.42
			AudioManager.play_tone("footstep", 95.0 if randf() > 0.5 else 112.0, 0.06, -27.0)
	else:
		_step_time = 0.0

func set_input_locked(reason: String, locked: bool) -> void:
	if reason.is_empty():
		return
	if locked:
		_locks[reason] = true
	else:
		_locks.erase(reason)
	var now_locked := is_input_locked()
	if now_locked:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	input_lock_changed.emit(now_locked)

func is_input_locked() -> bool:
	return not _locks.is_empty()

func add_camera_shake(strength: float, duration: float) -> void:
	if not SettingsManager.camera_shake_enabled:
		return
	_shake_strength = maxf(_shake_strength, clampf(strength, 0.0, 0.12))
	_shake_remaining = maxf(_shake_remaining, clampf(duration, 0.0, 1.5))

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_input_locked("pause", get_tree().paused)

func _update_head_bob(delta: float, moving: bool) -> void:
	if not SettingsManager.comfort_head_bob:
		head.position.y = move_toward(head.position.y, 0.7, delta * 4.0)
		return
	if moving and is_on_floor():
		_bob_time += delta * (10.0 if Input.is_action_pressed("sprint") else 7.0)
		head.position.y = 0.7 + sin(_bob_time * 2.0) * 0.018
		head.position.x = sin(_bob_time) * 0.012
	else:
		head.position.y = move_toward(head.position.y, 0.7, delta * 3.0)
		head.position.x = move_toward(head.position.x, 0.0, delta * 3.0)

func _update_camera_shake(delta: float) -> void:
	if _shake_remaining > 0.0 and SettingsManager.camera_shake_enabled:
		_shake_remaining -= delta
		camera.position = Vector3(randf_range(-1.0, 1.0), randf_range(-0.7, 0.7), 0.0) * _shake_strength
	else:
		_shake_remaining = 0.0
		_shake_strength = move_toward(_shake_strength, 0.0, delta * 0.3)
		camera.position = camera.position.move_toward(Vector3.ZERO, delta * 0.45)

func _apply_settings() -> void:
	mouse_sensitivity = SettingsManager.mouse_sensitivity
	camera.fov = SettingsManager.field_of_view

func _on_setting_changed(name: String, _value: float) -> void:
	if name == "mouse_sensitivity":
		mouse_sensitivity = SettingsManager.mouse_sensitivity
	elif name == "field_of_view":
		camera.fov = SettingsManager.field_of_view
