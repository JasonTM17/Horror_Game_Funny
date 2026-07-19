extends Node

const SETTINGS_SCENE := preload("res://scenes/ui/settings-panel.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const MENU_SETTINGS_REGRESSION := preload("res://tests/menu-settings-regression.gd")
const VOICE_OVER_REGRESSION := preload("res://tests/voice-over-regression.gd")

func _ready() -> void:
	await get_tree().process_frame
	for bus_name in ["Master", "Music", "SFX", "Ambience", "Chase", AudioManager.VOICE_BUS_NAME]:
		if not _require(AudioServer.get_bus_index(bus_name) >= 0, "%s audio bus missing" % bus_name): return
	var initial_bus_count := AudioServer.bus_count
	var sfx_bus_index := AudioServer.get_bus_index("SFX")
	var master_bus_index := AudioServer.get_bus_index("Master")
	var initial_sfx_effect_count := AudioServer.get_bus_effect_count(sfx_bus_index)
	var initial_master_effect_count := AudioServer.get_bus_effect_count(master_bus_index)
	AudioManager._configure_audio_buses()
	AudioManager._configure_audio_buses()
	if not _require(AudioServer.bus_count == initial_bus_count and AudioServer.get_bus_effect_count(sfx_bus_index) == initial_sfx_effect_count and AudioServer.get_bus_effect_count(master_bus_index) == initial_master_effect_count, "audio mix setup duplicated a bus or effect"): return
	var voice_bus_index := AudioServer.get_bus_index(AudioManager.VOICE_BUS_NAME)
	var ducking := AudioManager._voice_ducking_effect()
	if not _require(AudioServer.get_bus_send(voice_bus_index) == "Master" and ducking != null and ducking.sidechain == AudioManager.VOICE_BUS_NAME and is_equal_approx(ducking.threshold, -26.0) and is_equal_approx(ducking.ratio, 6.0) and AudioManager._has_master_limiter(), "voice routing, SFX ducking, or master limiting is not configured"): return
	if not _verify_initial_audio_bus_volumes(): return
	SettingsManager.set_mouse_sensitivity(99.0)
	SettingsManager.set_field_of_view(12.0)
	SettingsManager.set_master_volume(-99.0)
	if not _require(is_equal_approx(SettingsManager.mouse_sensitivity, 0.25), "mouse sensitivity clamp failed"): return
	if not _require(is_equal_approx(SettingsManager.field_of_view, 60.0), "field of view clamp failed"): return
	if not _require(is_equal_approx(SettingsManager.master_volume, -40.0), "master volume clamp failed"): return
	var previous_sfx_volume := SettingsManager.sfx_volume
	SettingsManager.set_sfx_volume(-12.0)
	if not _require(is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus_index), -12.0) and is_equal_approx(AudioServer.get_bus_volume_db(voice_bus_index), -12.0), "SFX setting did not keep voice and effects under one user control"): return
	SettingsManager.set_sfx_volume(previous_sfx_volume)
	var player := PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame
	if not _require(_method_argument_type(player, "_on_setting_changed", 1) == TYPE_NIL, "production player narrowed the Variant settings signal payload type"): return
	SettingsManager.set_comfort_head_bob(false)
	SettingsManager.set_camera_shake_enabled(false)
	if not _require(is_instance_valid(player) and player.is_inside_tree(), "boolean settings signal invalidated the live production player"): return
	SettingsManager.set_comfort_head_bob(true)
	SettingsManager.set_camera_shake_enabled(true)
	player.queue_free()
	await get_tree().process_frame
	var panel := SETTINGS_SCENE.instantiate()
	add_child(panel)
	await get_tree().process_frame
	for node_path in ["Panel/Music", "Panel/Sfx", "Panel/Ambience", "Panel/Fullscreen", "Panel/CameraShake", "Panel/FilmGrain", "Panel/Reset", "Panel/SaveStatus", "Panel/CloseWithoutSaving"]:
		if not _require(panel.has_node(node_path), "%s control missing" % node_path): return
	AudioManager.stop_all()
	var cache_id := "audio_variant_fixture"
	var first_key := AudioManager._make_cache_key(cache_id, 95.0, 0.06)
	var second_key := AudioManager._make_cache_key(cache_id, 112.0, 0.06)
	var first_stream := AudioManager._get_tone(cache_id, 95.0, 0.06)
	var first_byte_total := AudioManager._sample_bytes
	var reused_stream := AudioManager._get_tone(cache_id, 95.0, 0.06)
	if not _require(first_stream == reused_stream and AudioManager._cache.size() == 1 and AudioManager._sample_bytes == first_byte_total, "identical tone parameters did not reuse one cached sample"): return
	var second_stream := AudioManager._get_tone(cache_id, 112.0, 0.06)
	if not _require(first_key != second_key and first_stream != second_stream and AudioManager._cache.has(first_key) and AudioManager._cache.has(second_key), "same-ID tone variants collided in the sample cache"): return
	if not _require(first_stream.data != second_stream.data, "same-ID frequency variants rendered identical PCM data"): return
	var duration_key := AudioManager._make_cache_key(cache_id, 95.0, 0.08)
	var duration_stream := AudioManager._get_tone(cache_id, 95.0, 0.08)
	if not _require(duration_key != first_key and duration_stream.data.size() != first_stream.data.size(), "same-ID duration variants collided in the sample cache"): return
	var capped_stream := AudioManager._get_tone(cache_id, 95.0, 4.5)
	var reused_capped_stream := AudioManager._get_tone(cache_id, 95.0, 8.0)
	if not _require(capped_stream == reused_capped_stream and AudioManager._make_cache_key(cache_id, 95.0, 4.5) == AudioManager._make_cache_key(cache_id, 95.0, 8.0), "durations above the PCM cap allocated duplicate samples"): return
	AudioManager._cache_limit_bytes = AudioManager.MAX_CACHED_SAMPLES
	AudioManager.stop_tone(cache_id)
	if not _require(AudioManager._cache.is_empty() and AudioManager._cache_sizes.is_empty() and AudioManager._cache_owner.is_empty() and AudioManager._cache_ids.is_empty() and AudioManager._cache_order.is_empty() and AudioManager._sample_bytes == 0, "stopping a tone did not reclaim all cached variants"): return
	var lru_probe := AudioManager._get_tone("lru_probe", 70.0, 0.06)
	var lru_bytes: int = lru_probe.data.size()
	AudioManager.stop_all()
	AudioManager._cache_limit_bytes = lru_bytes * 2
	var lru_a_key := AudioManager._make_cache_key("lru_a", 71.0, 0.06)
	var lru_b_key := AudioManager._make_cache_key("lru_b", 72.0, 0.06)
	var lru_c_key := AudioManager._make_cache_key("lru_c", 73.0, 0.06)
	AudioManager._get_tone("lru_a", 71.0, 0.06)
	AudioManager._get_tone("lru_b", 72.0, 0.06)
	AudioManager._get_tone("lru_a", 71.0, 0.06)
	AudioManager._get_tone("lru_c", 73.0, 0.06)
	if not _require(AudioManager._cache.has(lru_a_key) and not AudioManager._cache.has(lru_b_key) and AudioManager._cache.has(lru_c_key) and AudioManager._sample_bytes == lru_bytes * 2, "LRU eviction did not preserve the recently reused sample"): return
	AudioManager.stop_all()
	var loop_id := "loop_mode_fixture"
	var one_shot_stream := AudioManager._get_tone(loop_id, 60.0, 2.0)
	var looping_stream := AudioManager._get_looping_tone(loop_id, 60.0)
	if not _require(one_shot_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED and looping_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and one_shot_stream != looping_stream, "drone setup mutated the cached one-shot stream"): return
	var energy_window := 2048
	var one_shot_start_energy := _pcm16_window_energy(one_shot_stream, 0, energy_window)
	var one_shot_end_energy := _pcm16_window_energy(one_shot_stream, one_shot_stream.data.size() / 2 - energy_window, energy_window)
	if not _require(one_shot_end_energy < one_shot_start_energy * 0.2, "one-shot tone lost its fade-out envelope"): return
	var loop_start_energy := _pcm16_window_energy(looping_stream, 0, energy_window)
	var loop_end_energy := _pcm16_window_energy(looping_stream, looping_stream.data.size() / 2 - energy_window, energy_window)
	if not _require(loop_start_energy >= one_shot_start_energy * 0.9, "looping tone has no usable PCM energy"): return
	if not _require(loop_end_energy >= loop_start_energy * 0.9, "looping tone decays before its loop boundary and will pulse on restart"): return
	var loop_sample_count := looping_stream.data.size() / 2
	var seam_step := absi(_pcm16_sample(looping_stream, 0) - _pcm16_sample(looping_stream, loop_sample_count - 1))
	var reference_step := _pcm16_max_step(looping_stream, 0, energy_window)
	if not _require(reference_step > 0, "looping tone has no sample-to-sample motion"): return
	if not _require(seam_step <= reference_step, "looping tone boundary exceeds its normal sample-to-sample step"): return
	var one_shot_key := AudioManager._make_cache_key(loop_id, 60.0, 2.0)
	var looping_key := AudioManager._make_cache_key(loop_id, 60.0, 2.0, true)
	var loop_player := AudioStreamPlayer.new()
	AudioManager.add_child(loop_player)
	loop_player.stream = looping_stream
	AudioManager._players[loop_id] = loop_player
	AudioManager._cache_limit_bytes = looping_stream.data.size()
	var loop_pressure_key := AudioManager._make_cache_key("loop_pressure_fixture", 61.0, 0.05)
	var loop_pressure_stream := AudioManager._get_tone("loop_pressure_fixture", 61.0, 0.05)
	if not _require(not AudioManager._cache.has(one_shot_key) and AudioManager._cache.has(looping_key) and not AudioManager._cache.has(loop_pressure_key) and loop_pressure_stream.data.size() > 0, "cache pressure evicted a looping stream still held by a player"): return
	AudioManager._cache_limit_bytes = AudioManager.MAX_CACHED_SAMPLES
	AudioManager.stop_tone(loop_id)
	var spatial_parent := Node3D.new()
	add_child(spatial_parent)
	AudioManager.play_spatial_tone(spatial_parent, "spatial_fixture", 80.0, 2.0)
	await get_tree().process_frame
	if not _require(AudioManager._spatial_players.size() == 1, "spatial tone was not registered for teardown"): return
	AudioManager.stop_tone("spatial_fixture")
	await get_tree().process_frame
	if not _require(AudioManager._spatial_players.is_empty() and spatial_parent.get_child_count() == 0, "stop_tone left a spatial player running"): return
	spatial_parent.queue_free()
	var finished_parent := Node3D.new()
	add_child(finished_parent)
	AudioManager.play_spatial_tone(finished_parent, "spatial_finished_fixture", 81.0, 2.0)
	await get_tree().process_frame
	var finished_player: AudioStreamPlayer3D = AudioManager._spatial_players[0]
	finished_player.finished.emit()
	await get_tree().process_frame
	if not _require(AudioManager._spatial_players.is_empty() and AudioManager._spatial_player_ids.is_empty() and finished_parent.get_child_count() == 0, "finished spatial tone left stale registry state"): return
	AudioManager.stop_tone("spatial_finished_fixture")
	finished_parent.queue_free()
	var orphan_parent := Node3D.new()
	add_child(orphan_parent)
	AudioManager.play_spatial_tone(orphan_parent, "spatial_orphan_fixture", 82.0, 2.0)
	await get_tree().process_frame
	orphan_parent.queue_free()
	await get_tree().process_frame
	if not _require(AudioManager._spatial_players.is_empty() and AudioManager._spatial_player_ids.is_empty(), "parent-free spatial tone stayed registered until an explicit stop"): return
	AudioManager.stop_tone("spatial_orphan_fixture")
	var queued_parent := Node3D.new()
	add_child(queued_parent)
	queued_parent.queue_free()
	AudioManager.play_spatial_tone(queued_parent, "spatial_queued_parent_fixture", 82.5, 2.0)
	if not _require(AudioManager._spatial_players.is_empty() and not AudioManager._cache_ids.has("spatial_queued_parent_fixture"), "queued spatial parent accepted a new player"): return
	var stop_all_parent := Node3D.new()
	add_child(stop_all_parent)
	AudioManager.play_spatial_tone(stop_all_parent, "spatial_stop_all_fixture", 83.0, 2.0)
	await get_tree().process_frame
	var live_spatial_key := AudioManager._make_cache_key("spatial_stop_all_fixture", 83.0, 2.0)
	var live_spatial_player: AudioStreamPlayer3D = AudioManager._spatial_players[0]
	AudioManager._cache_limit_bytes = live_spatial_player.stream.data.size()
	var spatial_pressure_key := AudioManager._make_cache_key("spatial_pressure_fixture", 84.0, 0.05)
	var spatial_pressure_stream := AudioManager._get_tone("spatial_pressure_fixture", 84.0, 0.05)
	if not _require(AudioManager._cache.has(live_spatial_key) and not AudioManager._cache.has(spatial_pressure_key) and spatial_pressure_stream.data.size() > 0, "cache pressure evicted a stream held by a spatial player"): return
	AudioManager.stop_all()
	await get_tree().process_frame
	if not _require(AudioManager._spatial_players.is_empty() and AudioManager._spatial_player_ids.is_empty() and stop_all_parent.get_child_count() == 0, "stop_all left an active spatial player registered"): return
	stop_all_parent.queue_free()
	AudioManager.play_tone("audio_player_fixture", 51.0, 0.05, -30.0, "Ambience")
	var reused_player: AudioStreamPlayer = AudioManager._players.get("audio_player_fixture")
	AudioManager.play_tone("audio_player_fixture", 52.0, 0.05, -30.0, "Chase")
	if not _require(AudioManager._players.get("audio_player_fixture") == reused_player and reused_player.bus == "Chase", "replaying one tone ID allocated a second player or kept a stale bus"): return
	var live_key := AudioManager._make_cache_key("audio_player_fixture", 52.0, 0.05)
	AudioManager._cache_limit_bytes = reused_player.stream.data.size()
	var uncached_live_stream := AudioManager._get_tone("live_eviction_fixture", 53.0, 0.05)
	if not _require(AudioManager._cache.has(live_key) and not AudioManager._cache.has(AudioManager._make_cache_key("live_eviction_fixture", 53.0, 0.05)) and uncached_live_stream.data.size() > 0, "LRU eviction displaced a stream still held by a live player"): return
	AudioManager._cache_limit_bytes = AudioManager.MAX_CACHED_SAMPLES
	AudioManager.stop_tone("audio_player_fixture")
	AudioManager.play_tone("test_cleanup", 51.0, 0.1, -30.0, "Ambience")
	await get_tree().process_frame
	if not _require(AudioManager._players.has("test_cleanup") and AudioManager._cache.size() == 1 and AudioManager._sample_bytes > 0, "audio cleanup fixture was not created"): return
	AudioManager._cache_limit_bytes = 64
	AudioManager.stop_all()
	if not _require(AudioManager._players.is_empty() and AudioManager._cache.is_empty() and AudioManager._cache_order.is_empty() and AudioManager._sample_bytes == 0 and AudioManager._cache_limit_bytes == AudioManager.MAX_CACHED_SAMPLES, "audio teardown left cached state or a stale cache limit"): return
	if not _require(AudioManager.get_child_count() == 0, "audio teardown deferred a player past shutdown"): return
	# The audio server releases the active playback on its mix thread after the player is freed.
	await get_tree().create_timer(0.2).timeout
	SettingsManager.reset_defaults()
	var voice_over_regression := VOICE_OVER_REGRESSION.new()
	if not await voice_over_regression.run(self): return
	var menu_settings_regression := MENU_SETTINGS_REGRESSION.new()
	add_child(menu_settings_regression)
	if not await menu_settings_regression.run(): return
	menu_settings_regression.queue_free()
	await get_tree().process_frame
	if not _verify_malformed_settings_rejected(): return
	SettingsManager.reset_defaults()
	print("SETTINGS_AUDIO_TEST_OK")
	panel.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _verify_initial_audio_bus_volumes() -> bool:
	var expected_volumes := {
		"Master": SettingsManager.master_volume,
		"Music": SettingsManager.music_volume,
		"SFX": SettingsManager.sfx_volume,
		AudioManager.VOICE_BUS_NAME: SettingsManager.sfx_volume,
		"Ambience": SettingsManager.ambience_volume,
		"Chase": SettingsManager.music_volume,
	}
	for bus_name: String in expected_volumes:
		var bus_index := AudioServer.get_bus_index(bus_name)
		var actual_volume := AudioServer.get_bus_volume_db(bus_index)
		var expected_volume: float = expected_volumes[bus_name]
		if not _require(is_equal_approx(actual_volume, expected_volume), "%s bus started at %.1f dB instead of %.1f dB" % [bus_name, actual_volume, expected_volume]):
			return false
	return true

func _verify_malformed_settings_rejected() -> bool:
	var malformed_path := "user://room407-malformed-test.cfg"
	var config := ConfigFile.new()
	config.set_value("controls", "mouse_sensitivity", "fast")
	config.set_value("display", "field_of_view", "wide")
	config.set_value("audio", "master_volume", "loud")
	config.set_value("audio", "music_volume", [])
	config.set_value("audio", "sfx_volume", true)
	config.set_value("audio", "ambience_volume", "quiet")
	config.set_value("accessibility", "flicker_enabled", "false")
	config.set_value("accessibility", "comfort_head_bob", 0)
	config.set_value("accessibility", "camera_shake_enabled", "false")
	config.set_value("accessibility", "film_grain_enabled", 1)
	config.set_value("display", "fullscreen_enabled", "false")
	if not _require(config.save(malformed_path) == OK, "malformed settings fixture could not be written"): return false
	SettingsManager.reset_defaults()
	SettingsManager.load_settings(malformed_path)
	var kept_defaults := (
		is_equal_approx(SettingsManager.mouse_sensitivity, 0.08)
		and is_equal_approx(SettingsManager.field_of_view, 74.0)
		and is_equal_approx(SettingsManager.master_volume, 0.0)
		and is_equal_approx(SettingsManager.music_volume, -10.0)
		and is_equal_approx(SettingsManager.sfx_volume, -4.0)
		and is_equal_approx(SettingsManager.ambience_volume, -8.0)
		and SettingsManager.flicker_enabled
		and SettingsManager.comfort_head_bob
		and SettingsManager.camera_shake_enabled
		and SettingsManager.film_grain_enabled
		and not SettingsManager.fullscreen_enabled
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(malformed_path))
	return _require(kept_defaults, "malformed persisted values changed runtime settings")

func _pcm16_sample(stream: AudioStreamWAV, sample_index: int) -> int:
	var byte_index := sample_index * 2
	var value := int(stream.data[byte_index]) | (int(stream.data[byte_index + 1]) << 8)
	return value - 65536 if value >= 32768 else value

func _method_argument_type(instance: Object, method_name: String, argument_index: int) -> int:
	for method: Dictionary in instance.get_method_list():
		if str(method.get("name", "")) != method_name:
			continue
		var arguments: Array = method.get("args", [])
		if argument_index >= 0 and argument_index < arguments.size():
			return int((arguments[argument_index] as Dictionary).get("type", -1))
	return -1

func _pcm16_window_energy(stream: AudioStreamWAV, start_sample: int, sample_count: int) -> float:
	var energy := 0.0
	for sample_index in range(start_sample, start_sample + sample_count):
		energy += absf(float(_pcm16_sample(stream, sample_index)))
	return energy / maxf(1.0, float(sample_count))

func _pcm16_max_step(stream: AudioStreamWAV, start_sample: int, sample_count: int) -> int:
	var max_step := 0
	for sample_index in range(start_sample + 1, start_sample + sample_count):
		max_step = maxi(max_step, absi(_pcm16_sample(stream, sample_index) - _pcm16_sample(stream, sample_index - 1)))
	return max_step

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SETTINGS_AUDIO_ASSERT: " + message)
	get_tree().quit(2)
	return false
