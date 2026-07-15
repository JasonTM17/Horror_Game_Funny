extends Node

const MAX_CACHED_SAMPLES := 16 * 1024 * 1024
var _players: Dictionary = {}
var _cache: Dictionary = {}
var _sample_bytes: int = 0

func _ready() -> void:
	for bus_name in ["SFX", "Ambience", "Chase"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func play_tone(id: String, frequency: float, duration: float, volume_db: float = -16.0) -> void:
	if frequency <= 0.0 or duration <= 0.0:
		return
	var stream := _get_tone(id, frequency, duration)
	if stream == null:
		return
	var player: AudioStreamPlayer = _players.get(id)
	if not is_instance_valid(player):
		player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_players[id] = player
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func stop_tone(id: String) -> void:
	var player: AudioStreamPlayer = _players.get(id)
	if is_instance_valid(player):
		player.stop()

func _get_tone(id: String, frequency: float, duration: float) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var sample_rate := 22050
	var sample_count := mini(int(duration * sample_rate), sample_rate * 4)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in sample_count:
		var envelope := 1.0 - (float(index) / sample_count)
		var sample := sin(TAU * frequency * float(index) / sample_rate) * envelope * 0.2
		var value := int(sample * 32767.0)
		data[index * 2] = value & 0xff
		data[index * 2 + 1] = (value >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	if _sample_bytes + data.size() > MAX_CACHED_SAMPLES:
		return stream
	_sample_bytes += data.size()
	_cache[id] = stream
	return stream
