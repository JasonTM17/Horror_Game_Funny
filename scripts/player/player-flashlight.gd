extends SpotLight3D

@export var flicker_chance := 0.12
@export var flicker_interval_min := 0.08
@export var flicker_interval_max := 0.16
@export var pulse_duration_min := 0.04
@export var pulse_duration_max := 0.12
@export var flicker_min_energy := 0.2
@export var recovery_rate := 18.0
var _base_energy := 1.8
var _flicker_check_remaining := 0.0
var _pulse_remaining := 0.0
var _pulse_target := 1.8

func _ready() -> void:
	# The player switches to PROCESS_MODE_ALWAYS to receive pause input. Keep
	# the light explicitly pausable so its pulse state cannot advance underneath
	# a paused game.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_base_energy = light_energy
	_pulse_target = _base_energy

func _process(delta: float) -> void:
	if not SettingsManager.flicker_enabled or not visible:
		_reset_flicker()
		return
	var step := clampf(delta, 0.0, 0.25)
	if _pulse_remaining > 0.0:
		_pulse_remaining = maxf(0.0, _pulse_remaining - step)
	light_energy = move_toward(light_energy, _pulse_target if _pulse_remaining > 0.0 else _base_energy, step * recovery_rate)
	_flicker_check_remaining -= step
	if _flicker_check_remaining > 0.0:
		return
	_flicker_check_remaining = _next_flicker_interval()
	if randf() >= clampf(flicker_chance, 0.0, 1.0):
		return
	var minimum_energy := clampf(flicker_min_energy, 0.0, _base_energy)
	var maximum_energy := maxf(minimum_energy, _base_energy * 0.65)
	_pulse_remaining = _random_range(pulse_duration_min, pulse_duration_max)
	_pulse_target = randf_range(minimum_energy, maximum_energy)
	light_energy = minf(light_energy, _pulse_target)

func _reset_flicker() -> void:
	_flicker_check_remaining = 0.0
	_pulse_remaining = 0.0
	_pulse_target = _base_energy
	light_energy = _base_energy

func _next_flicker_interval() -> float:
	return _random_range(flicker_interval_min, flicker_interval_max)

func _random_range(first: float, second: float) -> float:
	var minimum := maxf(0.0, minf(first, second))
	var maximum := maxf(minimum, maxf(first, second))
	return randf_range(minimum, maximum)
