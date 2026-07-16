extends Node

const MAX_CACHED_SAMPLES := 16 * 1024 * 1024
const SAMPLE_RATE := 22050
var _players: Dictionary = {}
var _cache: Dictionary = {}
var _cache_sizes: Dictionary = {}
var _cache_owner: Dictionary = {}
var _cache_ids: Dictionary = {}
var _cache_order: Array[String] = []
var _sample_bytes: int = 0
var _cache_limit_bytes: int = MAX_CACHED_SAMPLES
var _spatial_players: Array[AudioStreamPlayer3D] = []
var _spatial_player_ids: Dictionary = {}

func _ready() -> void:
	for bus_name in ["Music", "SFX", "Ambience", "Chase"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func play_tone(id: String, frequency: float, duration: float, volume_db: float = -16.0, bus := "SFX") -> void:
	if id.is_empty() or frequency <= 0.0 or duration <= 0.0:
		return
	var stream := _get_tone(id, frequency, duration)
	if stream == null:
		return
	var player: AudioStreamPlayer = _players.get(id)
	if not is_instance_valid(player):
		player = AudioStreamPlayer.new()
		add_child(player)
		_players[id] = player
		player.finished.connect(_on_player_finished.bind(player))
	player.bus = bus
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func start_drone(id: String, frequency: float, volume_db: float, bus := "Ambience") -> void:
	if id.is_empty() or frequency <= 0.0 or DisplayServer.get_name() == "headless":
		return
	var stream := _get_looping_tone(id, frequency)
	if stream == null:
		return
	var player: AudioStreamPlayer = _players.get(id)
	if not is_instance_valid(player):
		player = AudioStreamPlayer.new()
		add_child(player)
		_players[id] = player
		player.finished.connect(_on_player_finished.bind(player))
	player.bus = bus
	player.stream = stream
	player.volume_db = volume_db
	if not player.playing:
		player.play()

func play_spatial_tone(parent: Node3D, id: String, frequency: float, duration: float, volume_db := -18.0) -> void:
	if not is_instance_valid(parent) or parent.is_queued_for_deletion() or id.is_empty() or frequency <= 0.0 or duration <= 0.0:
		return
	var player := AudioStreamPlayer3D.new()
	player.name = "SpatialTone"
	player.bus = "SFX"
	player.stream = _get_tone(id, frequency, duration)
	player.volume_db = volume_db
	player.max_distance = 18.0
	parent.add_child(player)
	_spatial_players.append(player)
	_spatial_player_ids[player.get_instance_id()] = id
	player.finished.connect(_on_spatial_player_finished.bind(player))
	player.play()

func stop_tone(id: String) -> void:
	var player: AudioStreamPlayer = _players.get(id)
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	_prune_spatial_players()
	for spatial_player in _spatial_players.duplicate():
		if str(_spatial_player_ids.get(spatial_player.get_instance_id(), "")) != id:
			continue
		if is_instance_valid(spatial_player):
			spatial_player.stop()
		_unregister_spatial_player(spatial_player)
		if is_instance_valid(spatial_player):
			spatial_player.free()
	var cached_keys: Array = []
	if _cache_ids.has(id):
		cached_keys = (_cache_ids[id] as Array).duplicate()
	for key_value in cached_keys:
		_remove_cached_key(str(key_value))

func stop_all() -> void:
	_prune_spatial_players()
	for player_value in _players.values():
		var player := player_value as AudioStreamPlayer
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.free()
	for spatial_player in _spatial_players.duplicate():
		if is_instance_valid(spatial_player):
			spatial_player.stop()
		_unregister_spatial_player(spatial_player)
		if is_instance_valid(spatial_player):
			spatial_player.free()
	_players.clear()
	_cache.clear()
	_cache_sizes.clear()
	_cache_owner.clear()
	_cache_ids.clear()
	_cache_order.clear()
	_sample_bytes = 0
	_cache_limit_bytes = MAX_CACHED_SAMPLES
	_spatial_players.clear()
	_spatial_player_ids.clear()

func _get_tone(id: String, frequency: float, duration: float) -> AudioStreamWAV:
	return _get_or_create_tone(id, frequency, duration, false)

func _get_looping_tone(id: String, frequency: float) -> AudioStreamWAV:
	return _get_or_create_tone(id, frequency, 2.0, true)

func _get_or_create_tone(id: String, frequency: float, duration: float, looping: bool) -> AudioStreamWAV:
	var cache_key := _make_cache_key(id, frequency, duration, looping)
	if _cache.has(cache_key):
		_touch_cached_key(cache_key)
		return _cache[cache_key] as AudioStreamWAV
	var sample_count := _effective_sample_count(duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in sample_count:
		var envelope := 1.0 - (float(index) / sample_count)
		var sample := sin(TAU * frequency * float(index) / SAMPLE_RATE) * envelope * 0.2
		var value := int(sample * 32767.0)
		data[index * 2] = value & 0xff
		data[index * 2 + 1] = (value >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	var cache_limit := maxi(0, _cache_limit_bytes)
	if data.size() > cache_limit:
		return stream
	while _sample_bytes + data.size() > cache_limit:
		var evictable_key := _find_oldest_evictable_key()
		if evictable_key.is_empty():
			return stream
		_remove_cached_key(evictable_key)
	_sample_bytes += data.size()
	_cache[cache_key] = stream
	_cache_sizes[cache_key] = data.size()
	_cache_owner[cache_key] = id
	var id_keys: Array = _cache_ids.get(id, [])
	id_keys.append(cache_key)
	_cache_ids[id] = id_keys
	_cache_order.append(cache_key)
	return stream

func _make_cache_key(id: String, frequency: float, duration: float, looping := false) -> String:
	return "%s|pcm16-mono-v2|%d|%.9f|%d|%s" % [id, SAMPLE_RATE, frequency, _effective_sample_count(duration), "loop" if looping else "one-shot"]

func _effective_sample_count(duration: float) -> int:
	return clampi(int(duration * SAMPLE_RATE), 1, SAMPLE_RATE * 4)

func _touch_cached_key(cache_key: String) -> void:
	_cache_order.erase(cache_key)
	_cache_order.append(cache_key)

func _find_oldest_evictable_key() -> String:
	for cache_key in _cache_order:
		if not _cache_key_in_use(cache_key):
			return cache_key
	return ""

func _cache_key_in_use(cache_key: String) -> bool:
	if not _cache.has(cache_key):
		return false
	var stream := _cache[cache_key] as AudioStreamWAV
	for player_value in _players.values():
		var player := player_value as AudioStreamPlayer
		if is_instance_valid(player) and player.stream == stream:
			return true
	for spatial_player in _spatial_players:
		if is_instance_valid(spatial_player) and spatial_player.stream == stream:
			return true
	return false

func _remove_cached_key(cache_key: String) -> void:
	if not _cache.has(cache_key):
		return
	_sample_bytes = maxi(0, _sample_bytes - int(_cache_sizes.get(cache_key, 0)))
	_cache.erase(cache_key)
	_cache_sizes.erase(cache_key)
	_cache_order.erase(cache_key)
	var owner_id := str(_cache_owner.get(cache_key, ""))
	_cache_owner.erase(cache_key)
	if not _cache_ids.has(owner_id):
		return
	var owner_keys: Array = (_cache_ids[owner_id] as Array).duplicate()
	owner_keys.erase(cache_key)
	if owner_keys.is_empty():
		_cache_ids.erase(owner_id)
	else:
		_cache_ids[owner_id] = owner_keys

func _on_spatial_player_finished(player: AudioStreamPlayer3D) -> void:
	_unregister_spatial_player(player)
	if is_instance_valid(player):
		player.queue_free()

func _on_player_finished(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player) and not player.playing:
		player.stream = null

func _unregister_spatial_player(player: AudioStreamPlayer3D) -> void:
	if player == null:
		return
	_spatial_players.erase(player)
	if is_instance_valid(player):
		_spatial_player_ids.erase(player.get_instance_id())

func _prune_spatial_players() -> void:
	var valid_players: Array[AudioStreamPlayer3D] = []
	var valid_ids: Dictionary = {}
	for spatial_player in _spatial_players:
		if not is_instance_valid(spatial_player):
			continue
		valid_players.append(spatial_player)
		valid_ids[spatial_player.get_instance_id()] = _spatial_player_ids.get(spatial_player.get_instance_id(), "")
	_spatial_players = valid_players
	_spatial_player_ids = valid_ids
