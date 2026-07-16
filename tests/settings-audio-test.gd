extends Node

const SETTINGS_SCENE := preload("res://scenes/ui/settings-panel.tscn")
const MENU_SETTINGS_REGRESSION := preload("res://tests/menu-settings-regression.gd")

func _ready() -> void:
	await get_tree().process_frame
	for bus_name in ["Master", "Music", "SFX", "Ambience", "Chase"]:
		if not _require(AudioServer.get_bus_index(bus_name) >= 0, "%s audio bus missing" % bus_name): return
	if not _verify_initial_audio_bus_volumes(): return
	SettingsManager.set_mouse_sensitivity(99.0)
	SettingsManager.set_field_of_view(12.0)
	SettingsManager.set_master_volume(-99.0)
	if not _require(is_equal_approx(SettingsManager.mouse_sensitivity, 0.25), "mouse sensitivity clamp failed"): return
	if not _require(is_equal_approx(SettingsManager.field_of_view, 60.0), "field of view clamp failed"): return
	if not _require(is_equal_approx(SettingsManager.master_volume, -40.0), "master volume clamp failed"): return
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
	AudioManager.stop_tone("spatial_orphan_fixture")
	if not _require(AudioManager._spatial_players.is_empty() and AudioManager._spatial_player_ids.is_empty(), "parent-free spatial tone was not pruned safely"): return
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
	var menu_settings_regression := MENU_SETTINGS_REGRESSION.new()
	add_child(menu_settings_regression)
	if not await menu_settings_regression.run(): return
	menu_settings_regression.queue_free()
	await get_tree().process_frame
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

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SETTINGS_AUDIO_ASSERT: " + message)
	get_tree().quit(2)
	return false
