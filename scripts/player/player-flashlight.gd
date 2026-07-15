extends SpotLight3D

@export var flicker_chance := 0.015
var _base_energy := 1.8

func _ready() -> void:
	_base_energy = light_energy

func _process(_delta: float) -> void:
	if not SettingsManager.flicker_enabled or not visible:
		light_energy = _base_energy
		return
	if randf() < flicker_chance:
		light_energy = randf_range(0.2, _base_energy)
	else:
		light_energy = move_toward(light_energy, _base_energy, 0.08)

