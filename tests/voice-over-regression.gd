extends RefCounted

const VOICE_OVER_PLAYER_SCRIPT := preload("res://scripts/audio/voice-over-player.gd")
const NARRATIVE_SEQUENCER_SCRIPT := preload("res://scripts/world/narrative-sequencer.gd")
const EXPECTED_SEQUENCE_LENGTHS := {
	"floor_arrival_complete": 3,
	"memory_arrival_complete": 3,
	"room_arrival_complete": 3,
	"radio_solved": 4,
	"chase_ready": 4,
	"phone_briefing_complete": 4,
	"power_stable": 4,
	"memory_photo_recalled": 2,
	"memory_cassette_recalled": 2,
	"memory_rabbit_recalled": 2,
	"room_record_heard": 3,
	"desk_clock_observation_complete": 4,
	"lobby_register_observation_complete": 4,
	"floor_notice_observation_complete": 4,
	"room_bed_observation_complete": 4,
	"room_wardrobe_observation_complete": 4,
	"room_family_table_observation_complete": 4,
	"memory_echo_1": 4,
	"memory_echo_2": 4,
	"memory_echo_3": 4,
	"ending_notice_complete": 3,
	"ending_roster_complete": 3,
}

var _host: Node

func run(host: Node) -> bool:
	_host = host
	var player := VOICE_OVER_PLAYER_SCRIPT.new() as VoiceOverPlayer
	host.add_child(player)
	await host.get_tree().process_frame
	if not _require(player.bus == "SFX", "voice does not follow the SFX volume bus"): return false
	if not _require(player.process_mode == Node.PROCESS_MODE_PAUSABLE, "voice playback is not pause-aware"): return false
	if not _require(player.max_polyphony == 1, "voice player can overlap multiple cues"): return false
	if not _require(player.manifest_error().is_empty(), "manifest load failed: " + player.manifest_error()): return false
	if not _require(player.cue_count() == 76, "manifest does not contain all 76 reviewed narrative cues"): return false
	for completion_flag: String in EXPECTED_SEQUENCE_LENGTHS:
		for line_index in range(EXPECTED_SEQUENCE_LENGTHS[completion_flag]):
			if not _require(player.has_cue_id(completion_flag, line_index), "%s line %d has no cue id" % [completion_flag, line_index + 1]): return false
	var asset_failures := player.validate_assets()
	if not _require(asset_failures.is_empty(), "voice asset validation failed: " + "; ".join(asset_failures)): return false
	if not _require(player.cached_stream_count() == 76, "asset validation did not load every reviewed cue"): return false
	if not _require(VoiceOverPlayer.make_cue_id("phone_briefing_complete", 0) == "phone_briefing_complete-01", "cue id mapping is unstable"): return false

	var manager_subtitle := "MANAGER: You are covering the last shift, yes?"
	if not _require(player.has_cue("phone_briefing_complete", 0, manager_subtitle), "manager's first line has no matching cue"): return false
	if not _require(not player.has_cue("phone_briefing_complete", 0, "changed subtitle"), "stale audio can play under changed subtitle text"): return false
	if not _require(player.cue_duration("missing_flag", 0, "missing") == 0.0, "missing cue does not fall back cleanly"): return false
	if not _require(player.play_cue("phone_briefing_complete", 0, "changed subtitle") == 0.0 and not player.playing and player.stream == null, "subtitle mismatch did not fall back without stale playback"): return false

	var long_subtitle := "Dust covers the bed, except for one clean hollow in the blankets."
	var long_duration := player.cue_duration("room_bed_observation_complete", 0, long_subtitle)
	if not _require(long_duration > 4.0 and long_duration < 10.0, "long narration cue is truncated or unbounded"): return false
	var scaled_wait := VoiceOverPlayer.line_wait_seconds(4.0, 0.05, long_duration)
	if not _require(scaled_wait >= long_duration + VoiceOverPlayer.END_PADDING_SECONDS, "duration scale can cut off a long voice cue"): return false
	if not _require(is_equal_approx(VoiceOverPlayer.line_wait_seconds(5.0, 0.5, 1.0), 2.5), "short voice cue changed the scaled authored hold"): return false
	var epilogue_hold := 0.0
	for completion_flag in ["ending_notice_complete", "ending_roster_complete"]:
		for line_index in 3:
			epilogue_hold += player.cue_duration(completion_flag, line_index, _epilogue_subtitle(completion_flag, line_index))
	if not _require(epilogue_hold >= 21.0, "six voiced epilogue cues provide less than 21 seconds of meaningful hold"): return false

	var first_duration := player.play_cue("phone_briefing_complete", 0, manager_subtitle)
	var first_stream := player.stream
	if not _require(first_duration > 0.0 and first_stream != null and player.playing, "valid manager cue did not start"): return false
	var child_subtitle := "CHILD: I put the rabbit where the hallway cannot see."
	var child_duration := player.play_cue("room_record_heard", 1, child_subtitle)
	if not _require(child_duration > 0.0 and player.stream != null and player.stream != first_stream and player.playing, "replacement cue overlapped or reused stale audio"): return false
	player.stop_cue()
	if not _require(not player.playing and player.stream == null, "voice stop retained active playback or stream state"): return false

	player.queue_free()
	await host.get_tree().process_frame
	if not _require(not is_instance_valid(player), "voice player survived teardown"): return false
	if not await _verify_manifest_rejection(host): return false
	if not await _verify_voice_enabled_sequencer(host): return false
	if not await _verify_sequencer_contracts(host): return false
	_host = null
	return true

func _verify_manifest_rejection(host: Node) -> bool:
	var valid_cue := {
		"id": "fixture-01",
		"subtitle": "Fixture subtitle.",
		"spoken_text": "Fixture subtitle.",
		"role": "narrator",
		"file": "res://assets/audio/voice-over/fixture-01.ogg",
	}
	var wrong_path_cue: Dictionary = valid_cue.duplicate(true)
	wrong_path_cue["file"] = "res://assets/audio/voice-over/other-01.ogg"
	var fixtures: Array[String] = [
		JSON.stringify({"schema_version": 2, "cues": [valid_cue]}),
		JSON.stringify({"schema_version": 1, "cues": [{"id": "fixture-01"}]}),
		JSON.stringify({"schema_version": 1, "cues": [wrong_path_cue]}),
		JSON.stringify({"schema_version": 1, "cues": [valid_cue, valid_cue]}),
	]
	var fixture_player := VOICE_OVER_PLAYER_SCRIPT.new() as VoiceOverPlayer
	host.add_child(fixture_player)
	await host.get_tree().process_frame
	for fixture_text in fixtures:
		fixture_player._load_manifest_text(fixture_text, false)
		if not _require(not fixture_player.manifest_error().is_empty() and fixture_player.cue_count() == 0, "malformed manifest fixture was accepted"): return false
	fixture_player.queue_free()
	await host.get_tree().process_frame
	return _require(not is_instance_valid(fixture_player), "manifest fixture player survived teardown")

func _verify_voice_enabled_sequencer(host: Node) -> bool:
	var completion_flag := "room_record_heard"
	var subtitle := "RECORDING: You promised you would come back for us."
	GameState.flags.erase(completion_flag)
	GameState.set_subtitle("")
	var sequencer := NARRATIVE_SEQUENCER_SCRIPT.new()
	sequencer.duration_scale = 0.05
	host.add_child(sequencer)
	if not _require(sequencer.play([subtitle], completion_flag, 0.05), "voice-enabled sequencer rejected a manifest-backed line"): return false
	await host.get_tree().process_frame
	var voice_player := sequencer.get_node("VoiceOverPlayer") as VoiceOverPlayer
	if not _require(voice_player != null and voice_player.playing and voice_player.stream != null, "sequencer did not start its real manifest-backed voice cue"): return false
	await host.get_tree().create_timer(0.1).timeout
	var position_before_pause := voice_player.get_playback_position()
	host.get_tree().paused = true
	await host.get_tree().create_timer(0.25, true).timeout
	var position_during_pause := voice_player.get_playback_position()
	host.get_tree().paused = false
	if not _require(position_before_pause > 0.0 and absf(position_during_pause - position_before_pause) < 0.08, "real voice playback advanced while the scene tree was paused"): return false
	# Headless audio servers can take more than one short fixed sleep to advance
	# stream position after NOTIFICATION_UNPAUSED; poll the production player.
	var resume_deadline_msec := Time.get_ticks_msec() + 1500
	var resumed := false
	while Time.get_ticks_msec() < resume_deadline_msec:
		await host.get_tree().process_frame
		if voice_player.playing and voice_player.get_playback_position() > position_during_pause + 0.01:
			resumed = true
			break
	if not _require(resumed, "real voice playback did not resume after pause"): return false
	GameState.set_subtitle("The fuse box interrupts the narration.")
	if not _require(not voice_player.playing and voice_player.stream == null, "external subtitle feedback did not stop mismatched narration"): return false
	sequencer.queue_free()
	await host.get_tree().process_frame
	if not _require(GameState.subtitle.is_empty() and not GameState.has_flag(completion_flag), "interrupted voice sequence leaked subtitle or completion state"): return false
	GameState.flags.erase(completion_flag)
	return true

func _verify_sequencer_contracts(host: Node) -> bool:
	var sequencer := NARRATIVE_SEQUENCER_SCRIPT.new()
	sequencer.voice_over_enabled = false
	sequencer.duration_scale = 0.001
	host.add_child(sequencer)
	var finished_flags: Array[String] = []
	var first_flag := "voice_regression_queue_first"
	var second_flag := "voice_regression_queue_second"
	var reentrant_flag := "voice_regression_queue_reentrant"
	sequencer.beat_finished.connect(func(flag: String) -> void:
		finished_flags.append(flag)
		if flag == first_flag:
			sequencer.play(["reentrant"], reentrant_flag)
	)
	if not _require(sequencer.play(["first"], first_flag), "sequencer rejected first fixture"): return false
	if not _require(not sequencer.play(["duplicate"], first_flag), "sequencer queued its active completion flag twice"): return false
	if not _require(sequencer.play(["second"], second_flag), "sequencer rejected queued fixture"): return false
	if not _require(not sequencer.play(["duplicate queued"], second_flag), "sequencer queued a pending completion flag twice"): return false
	var queue_deadline_msec := Time.get_ticks_msec() + 1000
	while finished_flags.size() < 3 and Time.get_ticks_msec() < queue_deadline_msec:
		await host.get_tree().process_frame
	if not _require(finished_flags == [first_flag, second_flag, reentrant_flag], "sequencer queue result was %s" % [finished_flags]): return false

	var pause_flag := "voice_regression_pause"
	sequencer.duration_scale = 0.05
	if not _require(sequencer.play(["pause"], pause_flag, 4.0), "sequencer rejected pause fixture"): return false
	await host.get_tree().process_frame
	host.get_tree().paused = true
	# The watchdog must keep processing while the sequencer's pausable timer is frozen.
	await host.get_tree().create_timer(0.25, true).timeout
	var stayed_paused := not GameState.has_flag(pause_flag) and GameState.subtitle == "pause"
	host.get_tree().paused = false
	if not _require(stayed_paused, "sequencer advanced while the scene tree was paused"): return false
	await host.get_tree().create_timer(0.3).timeout
	if not _require(GameState.has_flag(pause_flag), "sequencer did not resume after pause"): return false

	var exit_flag := "voice_regression_exit"
	sequencer.duration_scale = 1.0
	if not _require(sequencer.play(["exit"], exit_flag, 0.5), "sequencer rejected teardown fixture"): return false
	if not _require(GameState.subtitle == "exit", "teardown fixture did not publish its subtitle"): return false
	sequencer.queue_free()
	await host.get_tree().process_frame
	if not _require(GameState.subtitle.is_empty(), "freed sequencer left an abandoned subtitle visible"): return false
	await host.get_tree().create_timer(0.6).timeout
	if not _require(not GameState.has_flag(exit_flag) and GameState.subtitle.is_empty(), "freed sequencer completed an abandoned line after its timer expired"): return false
	for flag in [first_flag, second_flag, reentrant_flag, pause_flag, exit_flag]:
		GameState.flags.erase(flag)
	return true

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("VOICE_OVER_ASSERT: " + message)
	if _host != null:
		_host.get_tree().quit(2)
	return false

func _epilogue_subtitle(completion_flag: String, line_index: int) -> String:
	var lines := {
		"ending_notice_complete": [
			"The condemnation notice is dated October 2007, sixteen years before tonight.",
			"Room 407 is named as the origin of a fire the hotel never reported.",
			"Your childhood signature appears beneath one line: only survivor.",
		],
		"ending_roster_complete": [
			"The night roster lists no manager, no guard, and no scheduled shift.",
			"Every voice you heard belongs to the Room 407 casualty list.",
			"Your name is crossed out. Beside it, the clock reads 23:47.",
		],
	}
	return str((lines[completion_flag] as Array)[line_index])
