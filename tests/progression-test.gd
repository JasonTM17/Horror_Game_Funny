extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

func _ready() -> void:
	var gameplay: Node3D = GAMEPLAY_SCENE.instantiate() as Node3D
	add_child(gameplay)
	await get_tree().process_frame
	await get_tree().process_frame
	var player: Node = gameplay.get_node("Player")
	var director: Node = gameplay
	director._narrative.duration_scale = 0.02
	director._narrative.voice_over_enabled = false
	director._horror.effect_duration_scale = 0.05
	GameState.reset_run()
	if not _require(
		_has_textured_mesh(gameplay.get_node("memory_photo"), "MemoryPhotoImage")
		and _has_textured_mesh(gameplay.get_node("room_drawing"), "RoomDrawingImage")
		and _has_textured_mesh(gameplay.get_node("room_family_table"), "FamilyTableImage")
		and _textured_quad_matches_source_aspect(gameplay.get_node("memory_photo"), "MemoryPhotoImage")
		and _textured_quad_matches_source_aspect(gameplay.get_node("room_drawing"), "RoomDrawingImage")
		and _textured_quad_matches_source_aspect(gameplay.get_node("room_family_table"), "FamilyTableImage"),
		"story clue textures were missing, backface-culled, or visibly stretched"
	): return
	if not _require(
		_room_drawing_faces_corridor_center(gameplay.get_node("room_drawing")),
		"Room 407 drawing still does not face the corridor approach (-X)"
	): return
	if not _require(
		_room_drawing_surfaces_align(gameplay.get_node("room_drawing")),
		"Room 407 drawing backing, image, and writing are not coplanar toward the corridor"
	): return
	var horror: Node = director._horror
	var saved_player: Node3D = horror._player as Node3D
	horror.set_player(null)
	var rabbit_fallback: Vector3 = horror.call("_scare_position_ahead", 10.0, 1.25, 0.0, WorldLayout.MEMORY_RABBIT_Z - 10.0) as Vector3
	var room_fallback: Vector3 = horror.call("_scare_position_ahead", 9.0, 1.35, 0.0, WorldLayout.FINAL_CLUE_Z - 9.0) as Vector3
	horror.set_player(saved_player)
	if not _require(
		is_equal_approx(rabbit_fallback.z, WorldLayout.MEMORY_RABBIT_Z - 10.0)
		and is_equal_approx(room_fallback.z, WorldLayout.FINAL_CLUE_Z - 9.0)
		and rabbit_fallback.distance_to(Vector3(0, 1.25, WorldLayout.MEMORY_RABBIT_Z)) <= 18.0
		and room_fallback.distance_to(Vector3(0, 1.35, WorldLayout.FINAL_CLUE_Z)) <= 18.0,
		"player-less scare fallback left the authored chapter Z anchors"
	): return
	var pacing_before_pause: Dictionary = director.get_playthrough_pacing_report()
	get_tree().paused = true
	await get_tree().process_frame
	OS.delay_msec(60)
	await get_tree().process_frame
	get_tree().paused = false
	var pacing_after_pause: Dictionary = director.get_playthrough_pacing_report()
	if not _require(is_equal_approx(float(pacing_after_pause["active_gameplay_seconds"]), float(pacing_before_pause["active_gameplay_seconds"])), "paused time leaked into active gameplay pacing"): return
	if not _require(float(pacing_after_pause["wall_clock_seconds"]) > float(pacing_before_pause["wall_clock_seconds"]), "wall pacing did not include paused time"): return
	if not _require(not director.handle_story_action("exit", player), "ending must reject a fresh run"): return
	if not _require(not director.handle_story_action("logbook", player), "logbook must stay gated"): return
	if not _require(not director.handle_story_action("lobby_register", player), "night register must stay gated before the phone briefing"): return
	if not _require(director.handle_story_action("phone", player), "phone should answer"): return
	var phone_subtitle := GameState.subtitle
	get_tree().paused = true
	await get_tree().process_frame
	OS.delay_msec(160)
	await get_tree().process_frame
	var narrative_stayed_paused := not GameState.has_flag("phone_briefing_complete") and GameState.subtitle == phone_subtitle
	get_tree().paused = false
	director._narrative.duration_scale = 0.001
	if not _require(narrative_stayed_paused, "narrative timer advanced story state while paused"): return
	if not _require(await _wait_for_flag("phone_briefing_complete"), "phone briefing should complete"): return
	if not _require(GameState.objective == "Read the stopped desk clock and night register, then sign the night log.", "phone objective skipped locked lobby observations"): return
	if not _require(not director.handle_story_action("phone", player), "phone answer must be one-shot"): return
	if not _require(not director.handle_story_action("logbook", player), "logbook must wait for both lobby observations"): return
	if not _require(director.handle_story_action("desk_clock", player), "desk clock should be readable after the briefing"): return
	if not _require(await _wait_for_flag("desk_clock_observation_complete"), "desk clock observation should complete"): return
	if not _require(GameState.objective == "Read the night register, then sign the night log.", "desk clock objective did not advance to the register"): return
	if not _require(director.handle_story_action("lobby_register", player), "night register should be readable"): return
	if not _require(await _wait_for_flag("lobby_register_observation_complete"), "night register observation should complete"): return
	if not _require(not director.handle_story_action("lobby_register", player), "night register observation must be one-shot"): return
	if not _require(director.handle_story_action("logbook", player), "logbook should grant key"): return
	if not _require(GameState.has_item("floor_key"), "logbook should add the floor key"): return
	var hud := gameplay.get_node("HUD")
	if not _require(hud.inventory_label.visible and hud.inventory_label.text == "Fourth-floor key" and not "floor_key" in hud.inventory_label.text and not "POCKETS" in hud.inventory_label.text, "HUD did not present the carried key as a clean player-facing name"): return
	if not _require(not director.handle_story_action("logbook", player), "logbook signing must be one-shot"): return
	var floor_door := gameplay.get_node("floor_door") as DoorInteractable
	GameState.consume_item("floor_key")
	var denied_cooldown := floor_door._cooldown_left
	if not _require(floor_door.interact(player), "missing-key door attempt was not handled"): return
	if not _require(not floor_door.is_open and not floor_door._moving and is_equal_approx(floor_door._cooldown_left, denied_cooldown) and not GameState.has_flag("floor_door_unlocked"), "floor door mutated or cooled down without the granted key"): return
	await get_tree().create_timer(0.3).timeout
	GameState.add_item("floor_key")
	var reentry_results: Array[bool] = []
	var inventory_reentry := func(_items: Array[String]) -> void:
		reentry_results.append(floor_door.interact(player))
	var flag_reentry := func(id: String, value: bool) -> void:
		if id == "floor_door_unlocked" and value:
			reentry_results.append(floor_door.interact(player))
	GameState.inventory_changed.connect(inventory_reentry)
	GameState.flag_changed.connect(flag_reentry)
	if not _require(floor_door.interact(player), "floor door rejected the granted key"): return
	GameState.inventory_changed.disconnect(inventory_reentry)
	GameState.flag_changed.disconnect(flag_reentry)
	if not _require(reentry_results == [false, false], "unlock signals reentered the door transaction"): return
	if not _require(not GameState.has_item("floor_key") and GameState.has_flag("floor_door_unlocked"), "floor-door unlock did not atomically consume the key and persist"): return
	await get_tree().create_timer(0.65).timeout
	if not _require(floor_door.is_open, "floor door did not finish opening"): return
	if not _require(floor_door.interact(player), "unlocked floor door did not close without restoring the key"): return
	await get_tree().create_timer(0.65).timeout
	if not _require(floor_door.interact(player), "permanently unlocked floor door did not reopen"): return
	await get_tree().create_timer(0.65).timeout
	if not _require(floor_door.is_open and not GameState.has_item("floor_key"), "floor door lost its session unlock invariant"): return
	if not _require(not director.handle_story_action("radio", player), "radio must wait for memories"): return
	if not _require(not director.handle_story_action("floor_notice", player), "floor notice must stay behind the fourth-floor gate"): return
	var floor_notice := gameplay.get_node("floor_notice") as StoryInteractable
	if not _require(floor_notice.global_position.z < WorldLayout.FLOOR_TRIGGER_Z and floor_notice.global_position.distance_to(Vector3(-2.8, 1.15, WorldLayout.FLOOR_TRIGGER_Z)) <= 4.1, "fourth-floor notice is not ahead of and near its activation threshold"): return
	var floor_scare_position := director._horror._floor_arrival_position() as Vector3
	var floor_scare_light := director._horror._find_nearest_light(floor_scare_position) as OmniLight3D
	var floor_light_energy := floor_scare_light.light_energy
	var floor_light_color := floor_scare_light.light_color
	player.global_position.z = WorldLayout.FLOOR_TRIGGER_Z - 0.1
	director._process(0.0)
	if not _require(GameState.has_flag("floor_reached") and GameState.stage == GameState.Stage.FLOOR4_DARK, "production floor threshold did not advance pacing stage"): return
	if not _require("maintenance notice" in GameState.objective.to_lower() and not director.get_story_prompt("floor_notice", player).is_empty(), "floor objective did not direct the player to the newly active notice"): return
	var elevator_display := gameplay.get_node_or_null("ElevatorDisplay") as Label3D
	var floor_apparition := director._horror.get_node_or_null("FloorArrivalApparition") as Node3D
	var floor_sequence := director._horror.get_node_or_null("FloorArrivalScare") as HorrorScareSequence
	if not _require(GameState.completed_events.has("floor_arrival") and elevator_display != null and elevator_display.text == "4", "floor threshold did not render the elevator event"): return
	if not _require(floor_apparition != null and floor_apparition.global_position.is_equal_approx(floor_scare_position) and floor_apparition.global_position.distance_to(player.global_position) <= 18.0 and not _contains_collision_object(floor_apparition), "floor apparition is missing, inaudibly staged, or can collide with the player"): return
	if not _require(floor_sequence != null and floor_sequence._owned_nodes.has(floor_apparition) and is_equal_approx(floor_sequence._scaled_duration(2.0), 0.1) and not floor_apparition.visible and floor_scare_light.light_energy < floor_light_energy and _has_spatial_cue("scare_floor_lift_strain"), "floor scare skipped ownership, scaling, or anticipation staging"): return
	director._horror.trigger("floor_arrival")
	if not _require(_count_named_children(director._horror, "FloorArrivalApparition") == 1 and _count_named_children(director._horror, "FloorArrivalScare") == 1, "floor event duplicated its sequence or apparition"): return
	get_tree().paused = true
	OS.delay_msec(80)
	await get_tree().process_frame
	if not _require(is_instance_valid(floor_sequence) and not floor_apparition.visible, "floor scare anticipation advanced while paused"): return
	get_tree().paused = false
	await get_tree().create_timer(0.3).timeout
	if not _require(not floor_door.is_open and not floor_door._moving and is_zero_approx(floor_door.rotation.y), "floor event did not close the real door behind the player"): return
	if not _require(elevator_display.text == "--" and not director._horror.has_node("FloorArrivalApparition"), "floor event did not dim its display and clean up"): return
	if not _require(not director._horror.has_node("FloorArrivalScare") and is_equal_approx(floor_scare_light.light_energy, floor_light_energy) and floor_scare_light.light_color.is_equal_approx(floor_light_color) and not _has_spatial_cue("scare_floor_lift_strain"), "floor scare did not restore light/audio ownership"): return
	if not _require(not director.handle_story_action("fuse_pickup", player), "fuse pickup must wait for the maintenance notice"): return
	if not _require(director.handle_story_action("floor_notice", player), "floor notice should be readable"): return
	if not _require(await _wait_for_flag("floor_notice_observation_complete"), "floor notice observation should complete"): return
	if not _require(not director.handle_story_action("floor_notice", player), "floor notice observation must be one-shot"): return
	if not _require(director.handle_story_action("fuse_pickup", player), "fuse pickup should work"): return
	if not _require(GameState.has_item("spare_fuse"), "fuse pickup should add the spare fuse"): return
	if not _require(not director.handle_story_action("fuse_pickup", player), "fuse pickup must be one-shot"): return
	var fuse_first_light := director._horror._find_nearest_light(Vector3(0, 2.5, WorldLayout.FUSE_BOX_Z - 5.0)) as OmniLight3D
	var fuse_second_light := director._horror._find_nearest_light(Vector3(0, 2.5, WorldLayout.FUSE_BOX_Z - 18.0)) as OmniLight3D
	var fuse_first_energy := fuse_first_light.light_energy
	var fuse_first_color := fuse_first_light.light_color
	var fuse_second_energy := fuse_second_light.light_energy
	var fuse_second_color := fuse_second_light.light_color
	if not _require(fuse_first_light != fuse_second_light, "fuse scare staging selected the same light twice"): return
	if not _require(director.handle_story_action("fuse_box", player), "fuse should install"): return
	var fuse_sequence := director._horror.get_node_or_null("FusePowerScare") as HorrorScareSequence
	if not _require(fuse_sequence != null and fuse_first_light.light_energy > fuse_first_energy and not fuse_first_light.light_color.is_equal_approx(fuse_first_color) and is_equal_approx(fuse_second_light.light_energy, fuse_second_energy) and _has_spatial_cue("scare_fuse_arc"), "fuse scare skipped its first light/audio warning"): return
	director._horror.trigger("fuse_power")
	if not _require(_count_named_children(director._horror, "FusePowerScare") == 1, "fuse scare trigger spam duplicated its sequence"): return
	get_tree().paused = true
	OS.delay_msec(40)
	await get_tree().process_frame
	if not _require(is_instance_valid(fuse_sequence) and is_equal_approx(fuse_second_light.light_energy, fuse_second_energy) and not _has_spatial_cue("scare_fuse_door_slam"), "fuse scare advanced while paused"): return
	get_tree().paused = false
	if not _require(await _wait_for_light_cue(fuse_second_light, fuse_second_energy, "scare_fuse_door_slam"), "fuse scare skipped its answering light/slam reveal"): return
	if not _require(is_instance_valid(fuse_sequence) and not fuse_second_light.light_color.is_equal_approx(fuse_second_color), "fuse scare answering light lost its authored color"): return
	if not _require(await _wait_for_node_removed(director._horror, "FusePowerScare"), "fuse scare did not finish within its bounded duration"): return
	if not _require(is_equal_approx(fuse_first_light.light_energy, fuse_first_energy) and fuse_first_light.light_color.is_equal_approx(fuse_first_color) and is_equal_approx(fuse_second_light.light_energy, fuse_second_energy) and fuse_second_light.light_color.is_equal_approx(fuse_second_color) and not _has_spatial_cue("scare_fuse_arc") and not _has_spatial_cue("scare_fuse_door_slam"), "fuse scare left light or spatial audio state behind"): return
	if not _require(GameState.has_flag("fuse_collected") and GameState.has_flag("fuse_installed") and not GameState.has_item("spare_fuse"), "fuse installation should consume the one-shot spare"): return
	if not _require(director.get_story_prompt("fuse_pickup", player).is_empty(), "installed fuse regained a backtracking prompt"): return
	if not _require(not director.handle_story_action("fuse_pickup", player) and not GameState.has_item("spare_fuse"), "installed fuse could be collected again after consumption"): return
	if not _require(not director.handle_story_action("fuse_box", player), "fuse installation must be one-shot"): return
	if not _require(await _wait_for_flag("power_stable"), "power sequence should stabilize"): return
	player.global_position.z = WorldLayout.MEMORY_TRIGGER_Z - 0.1
	director._process(0.0)
	if not _require(GameState.has_flag("memory_loop_started") and GameState.stage == GameState.Stage.MEMORY_LOOP, "production memory threshold did not advance pacing stage"): return
	if not _require(not director.handle_story_action("memory_cassette", player), "memories must be collected in authored order"): return
	if not _require(not director.handle_story_action("hallway_loop", player), "hallway loop must wait for the first memory echo"): return
	var photo_light := director._horror._find_nearest_light(Vector3(0, 2.2, WorldLayout.MEMORY_PHOTO_Z - 5.0)) as OmniLight3D
	var photo_light_energy := photo_light.light_energy
	if not _require(director.handle_story_action("memory_photo", player), "photo should collect"): return
	var photo_sequence := director._horror.get_node_or_null("PhotoMemoryScare") as HorrorScareSequence
	if not _require(photo_sequence != null and photo_light.light_energy < photo_light_energy and _has_spatial_cue("scare_photo_whisper_left"), "photo memory skipped its directional anticipation"): return
	director._horror.trigger("memory_photo")
	if not _require(_count_named_children(director._horror, "PhotoMemoryScare") == 1, "photo scare trigger spam duplicated its sequence"): return
	if not _require(await _wait_for_flag("memory_photo_recalled"), "photo memory should finish"): return
	if not _require(await _wait_for_node_removed(director._horror, "PhotoMemoryScare"), "photo scare did not finish within its bounded duration"): return
	if not _require(is_equal_approx(photo_light.light_energy, photo_light_energy) and not _has_spatial_cue("scare_photo_whisper_left") and not _has_spatial_cue("scare_photo_whisper_right"), "photo scare left light or spatial audio state behind"): return
	if not _require(not director.handle_story_action("hallway_loop", player), "hallway loop must wait for the environmental echo"): return
	if not _require(director.handle_story_action("memory_echo", player), "first memory echo should be readable"): return
	if not _require(await _wait_for_flag("memory_echo_1"), "first memory echo should finish"): return
	director._narrative.duration_scale = 0.05
	if not _require(director.handle_story_action("hallway_loop", player), "first hallway loop should turn"): return
	if not _require(await _wait_for_blackout(director._story._transition), "first hallway transition never reached its blackout hold"): return
	get_tree().paused = true
	OS.delay_msec(220)
	await get_tree().process_frame
	var blackout_stayed_paused: bool = bool(director._story._transition.running) and float(director._story._transition._curtain.modulate.a) > 0.99
	get_tree().paused = false
	if not _require(blackout_stayed_paused, "hallway blackout hold expired while the game was paused"): return
	if not _require(await _wait_for_transition(director), "first hallway transition should finish"): return
	director._narrative.duration_scale = 0.001
	if not _require(director.handle_story_action("memory_cassette", player), "cassette should collect"): return
	var turn_away := _find_turn_away_apparition(director._horror)
	if not _require(turn_away != null and is_equal_approx(turn_away._duration_scale, director._horror.effect_duration_scale) and is_equal_approx(turn_away._scaled_duration(2.0), 0.1) and not _contains_collision_object(turn_away), "cassette scare did not inherit duration scaling or remained physical"): return
	director._horror.trigger("memory_cassette")
	if not _require(_count_turn_away_apparitions(director._horror) == 1 and director._horror.has_node("CassetteTurnAwayScare"), "cassette scare trigger spam duplicated or lost its owned apparition"): return
	if not _require(await _wait_for_flag("memory_cassette_recalled"), "cassette memory should finish"): return
	await get_tree().process_frame
	if not _require(_find_turn_away_apparition(director._horror) == null and not director._horror.has_node("CassetteTurnAwayScare"), "unrevealed cassette apparition survived beyond its narration beat"): return
	var reveal_fixture := TurnAwayApparition.new()
	director._horror.add_child(reveal_fixture)
	reveal_fixture.setup(player, Vector3(0, 1.25, WorldLayout.MEMORY_CASSETTE_Z + 8.0), director._horror.effect_duration_scale)
	var cassette_camera := reveal_fixture._camera as Camera3D
	var cassette_camera_transform := cassette_camera.global_transform
	var away_direction := (cassette_camera.global_position - reveal_fixture.global_position).normalized()
	cassette_camera.look_at(cassette_camera.global_position + away_direction, Vector3.UP)
	reveal_fixture._process(0.0)
	if not _require(reveal_fixture._armed and reveal_fixture.visible and _has_spatial_cue("scare_cassette_breath_behind"), "cassette scare did not arm its behind-player breath cue"): return
	cassette_camera.look_at(reveal_fixture.global_position, Vector3.UP)
	reveal_fixture._process(0.0)
	if not _require(reveal_fixture._revealed and _has_spatial_cue("scare_cassette_reveal_low") and _has_spatial_cue("scare_cassette_reveal_snap"), "cassette look-back did not layer its reveal cues"): return
	cassette_camera.global_transform = cassette_camera_transform
	get_tree().paused = true
	OS.delay_msec(80)
	await get_tree().process_frame
	if not _require(is_instance_valid(reveal_fixture) and reveal_fixture.is_inside_tree(), "cassette reveal cleanup advanced while paused"): return
	get_tree().paused = false
	await get_tree().create_timer(0.2).timeout
	if not _require(_find_turn_away_apparition(director._horror) == null and not _has_spatial_cue("scare_cassette_breath_behind") and not _has_spatial_cue("scare_cassette_reveal_low") and not _has_spatial_cue("scare_cassette_reveal_snap"), "cassette apparition or owned audio survived its reveal"): return
	if not _require(not director.handle_story_action("memory_cassette", player), "cassette memory must be one-shot"): return
	if not _require(director.handle_story_action("memory_echo", player), "second memory echo should be readable"): return
	if not _require(await _wait_for_flag("memory_echo_2"), "second memory echo should finish"): return
	if not _require(director.handle_story_action("hallway_loop", player), "second hallway loop should turn"): return
	if not _require(await _wait_for_transition(director), "second hallway transition should finish"): return
	if not _require(director.handle_story_action("memory_rabbit", player), "rabbit should collect"): return
	var rabbit_sequence := director._horror.get_node_or_null("RabbitMemoryScare") as HorrorScareSequence
	var rabbit_apparition := director._horror.get_node_or_null("MemoryRabbitApparition") as Node3D
	if not _require(rabbit_sequence != null and rabbit_apparition != null and rabbit_sequence._owned_nodes.has(rabbit_apparition) and not _contains_collision_object(rabbit_apparition) and not rabbit_apparition.visible and _has_spatial_cue("scare_rabbit_music_box"), "rabbit scare skipped ownership or its non-physical music-box anticipation"): return
	director._horror.trigger("memory_rabbit")
	if not _require(_count_named_children(director._horror, "RabbitMemoryScare") == 1 and _count_named_children(director._horror, "MemoryRabbitApparition") == 1, "rabbit scare trigger spam duplicated its sequence or apparition"): return
	await get_tree().create_timer(0.025).timeout
	if not _require(is_instance_valid(rabbit_apparition) and rabbit_apparition.visible and _has_spatial_cue("scare_rabbit_presence"), "rabbit apparition did not reveal with its spatial presence cue"): return
	if not _require(await _wait_for_flag("memory_rabbit_recalled"), "rabbit memory should finish"): return
	if not _require(await _wait_for_node_removed(director._horror, "RabbitMemoryScare"), "rabbit scare did not finish within its bounded duration"): return
	if not _require(not director._horror.has_node("MemoryRabbitApparition") and not _has_spatial_cue("scare_rabbit_music_box") and not _has_spatial_cue("scare_rabbit_presence"), "rabbit scare left its owned actor, audio, or sequence state behind"): return
	if not _require(not director.handle_story_action("memory_rabbit", player), "rabbit memory must be one-shot"): return
	if not _require(director.handle_story_action("memory_echo", player), "final memory echo should be readable"): return
	if not _require(await _wait_for_flag("memory_echo_3"), "final memory echo should finish"): return
	if not _require(await _wait_for_flag("memory_loop_complete"), "final memory transition should finish"): return
	if not _require(await _wait_for_transition(director), "final hallway transition should release player input"): return
	if not _require(not director.handle_story_action("memory_echo", player), "final memory echo must be one-shot"): return
	if not _require(not director.handle_story_action("hallway_loop", player), "completed memory loop must stay closed"): return
	if not _require(not director.handle_story_action("memory_photo", player), "duplicate memory must be rejected"): return
	if not _require(director.handle_story_action("radio", player), "radio UI should open"): return
	var radio_ui: Variant = director._story._radio_ui
	var radio_escape := InputEventAction.new()
	radio_escape.action = "pause_game"
	radio_escape.pressed = true
	radio_ui._unhandled_input(radio_escape)
	if not _require(not radio_ui.visible and not player.is_input_locked(), "Escape did not close radio and restore player input"): return
	if not _require(director.handle_story_action("radio", player), "radio did not reopen after stepping away"): return
	radio_ui._on_text_changed("0x0y")
	if not _require(radio_ui.entry.text == "00", "radio entry did not filter non-digit input"): return
	radio_ui.entry.text = "1111"
	radio_ui._submit()
	if not _require(radio_ui.submit_button.disabled, "wrong radio code must start cooldown"): return
	radio_ui.close()
	radio_ui.open(director, player)
	if not _require(not radio_ui._accepting_input and radio_ui.submit_button.disabled, "closing and reopening radio bypassed cooldown"): return
	radio_ui.entry.text = "0007"
	radio_ui._submit()
	if not _require(not GameState.has_flag("radio_sequence_started"), "radio accepted a code during cooldown"): return
	if not _require(await _wait_for_radio(radio_ui), "radio cooldown should end"): return
	radio_ui.entry.text = "2222"
	radio_ui._submit()
	if not _require(await _wait_for_radio(radio_ui), "second radio cooldown should end"): return
	radio_ui.entry.text = "3333"
	radio_ui._submit()
	if not _require(radio_ui.result.text == "Hint: the clock stopped at 00:07.", "radio did not reveal its fallback hint after three failures"): return
	if not _require(await _wait_for_radio(radio_ui), "third radio cooldown should end"): return
	radio_ui.entry.text = "0007"
	radio_ui._submit()
	if not _require(await _wait_for_flag("radio_solved"), "radio flag missing"): return
	if not _require(await _wait_for_checkpoint("room_entrance"), "radio completion did not create the pre-room checkpoint"): return
	if not _require(int(GameState.checkpoint.get("stage", -1)) == GameState.Stage.MEMORY_LOOP and not bool((GameState.checkpoint.get("flags", {}) as Dictionary).get("room_entered", false)), "room checkpoint was not captured before Room 407 entry"): return
	var room_checkpoint_snapshot := JSON.stringify(GameState.checkpoint)
	if not _require(not director.handle_story_action("radio", player), "solved radio must not reopen"): return
	if not _require(not director.handle_story_action("room_record", player), "Room 407 recording must wait for room entry"): return
	if not _require(not director.handle_story_action("room_drawing", player), "room drawing must wait for the family recording"): return
	if not _require(not director.handle_story_action("room_bed_observation", player), "bed search must wait for the family recording"): return
	if not _require(not director.handle_story_action("room_wardrobe_observation", player), "wardrobe search must wait for the family recording"): return
	if not _require(not director.handle_story_action("room_family_table", player), "family table search must wait for the family recording"): return
	player.global_position.z = WorldLayout.ROOM_TRIGGER_Z - 0.1
	director._process(0.0)
	if not _require(GameState.has_flag("room_entered") and GameState.stage == GameState.Stage.ROOM_407, "production Room 407 threshold did not advance pacing stage"): return
	if not _require(JSON.stringify(GameState.checkpoint) == room_checkpoint_snapshot, "room threshold overwrote the safe pre-door checkpoint"): return
	if not _require(director.get_story_prompt("room_drawing", player).is_empty(), "room drawing advertised an interaction before its recording gate"): return
	if not _require(director.handle_story_action("room_record", player), "room recording should play"): return
	if not _require(await _wait_for_flag("room_record_heard"), "room recording should complete"): return
	if not _require(not director.handle_story_action("room_record", player), "room recording must be one-shot"): return
	if not _require(director.get_story_prompt("room_drawing", player) == "[E] Inspect the wall drawing", "room drawing did not become actionable after the recording"): return
	if not _require(director.handle_story_action("room_drawing", player), "room drawing should unlock"): return
	if not _require("bed" in GameState.objective and "wardrobe" in GameState.objective and "family table" in GameState.objective and director.get_story_prompt("final_clue", player).is_empty(), "Room 407 objective skipped a mandatory search or exposed the final note early"): return
	if not _require(not director.handle_story_action("final_clue", player), "final clue must wait for the three Room 407 searches"): return
	if not _require(director.handle_story_action("room_bed_observation", player), "room bed observation should unlock"): return
	if not _require(await _wait_for_flag("room_bed_observation_complete"), "room bed observation should complete"): return
	if not _require(not director.handle_story_action("room_bed_observation", player), "bed observation must be one-shot"): return
	if not _require(director.handle_story_action("room_wardrobe_observation", player), "wardrobe observation should unlock"): return
	if not _require(await _wait_for_flag("room_wardrobe_observation_complete"), "wardrobe observation should complete"): return
	if not _require(not director.handle_story_action("final_clue", player), "final clue must wait for the family table observation"): return
	if not _require(director.handle_story_action("room_family_table", player), "family table observation should unlock"): return
	if not _require(await _wait_for_flag("room_family_table_observation_complete"), "family table observation should complete"): return
	if not _require(not director.handle_story_action("room_family_table", player), "family table observation must be one-shot"): return
	if not _require("last note" in GameState.objective.to_lower() and director.get_story_prompt("final_clue", player) == "[E] Read the child's note", "completed Room 407 searches did not unlock and explain the final note"): return
	player.global_position.z = WorldLayout.FINAL_CLUE_Z + 1.0
	if not _require(director.handle_story_action("final_clue", player), "final clue should open note"): return
	if not _require(director._story._note_ui != null and director._story._note_ui.visible, "final clue note UI did not open"): return
	director._story._note_ui.close_note()
	if not _require(GameState.has_flag("final_clue_seen"), "final clue flag missing"): return
	if not _require(not player._locks.has("note"), "closing the final clue retained its input lock"): return
	var room_manifestation := director._horror.get_node_or_null("RoomEntityManifestation") as Node3D
	var room_sequence := director._horror.get_node_or_null("RoomEntityRevealScare") as HorrorScareSequence
	var room_eye_left: MeshInstance3D = room_manifestation.get_node_or_null("EyeLeft") as MeshInstance3D if room_manifestation != null else null
	var room_eye_right: MeshInstance3D = room_manifestation.get_node_or_null("EyeRight") as MeshInstance3D if room_manifestation != null else null
	var room_eye_material: StandardMaterial3D = room_eye_left.material_override as StandardMaterial3D if room_eye_left != null else null
	var room_eye_right_material: StandardMaterial3D = room_eye_right.material_override as StandardMaterial3D if room_eye_right != null else null
	if not _require(
		room_manifestation != null
		and room_eye_left != null
		and room_eye_right != null
		and room_eye_material != null
		and room_eye_right_material != null
		and room_eye_material.emission_enabled
		and room_eye_right_material.emission_enabled
		and room_eye_material.emission_energy_multiplier >= HorrorApparitionFactory.EYE_EMISSION_ENERGY - 0.01
		and room_eye_right_material.emission_energy_multiplier >= HorrorApparitionFactory.EYE_EMISSION_ENERGY - 0.01
		and not _contains_collision_object(room_manifestation),
		"pre-chase Room 407 manifestation is missing readable eyes or is physical (room=%s left=%s right=%s left_energy=%s right_energy=%s collision=%s)" % [
			room_manifestation != null,
			room_eye_left != null,
			room_eye_right != null,
			room_eye_material.emission_energy_multiplier if room_eye_material != null else -1.0,
			room_eye_right_material.emission_energy_multiplier if room_eye_right_material != null else -1.0,
			_contains_collision_object(room_manifestation) if room_manifestation != null else true,
		]
	): return
	if not _require(room_manifestation.global_position.distance_to(player.global_position) <= 18.0, "pre-chase manifestation spawned outside its spatial cue range"): return
	if not _require(not room_manifestation.visible and room_sequence != null and room_sequence._owned_nodes.has(room_manifestation) and _has_spatial_cue("scare_room_wall_breath"), "Room 407 manifestation skipped ownership or its pre-reveal warning"): return
	director._horror.trigger("room_entity_reveal")
	if not _require(_count_named_children(director._horror, "RoomEntityManifestation") == 1 and _count_named_children(director._horror, "RoomEntityRevealScare") == 1, "pre-chase manifestation or sequence duplicated"): return
	await get_tree().create_timer(0.03).timeout
	if not _require(room_manifestation.visible and _has_spatial_cue("scare_room_entity_low") and _has_spatial_cue("scare_room_entity_sting"), "Room 407 manifestation did not synchronize eyes and layered reveal cues"): return
	if not _require(await _wait_for_node_removed(director._horror, "RoomEntityRevealScare"), "pre-chase manifestation did not finish within its bounded duration"): return
	if not _require(not director._horror.has_node("RoomEntityManifestation") and not _has_spatial_cue("scare_room_wall_breath") and not _has_spatial_cue("scare_room_entity_low") and not _has_spatial_cue("scare_room_entity_sting"), "pre-chase manifestation did not clean up actor/sequence/audio"): return
	if not _require(await _wait_for_flag("chase_ready"), "chase build-up should complete"): return
	if not _require(str(GameState.checkpoint.get("spawn_id", "")) == "chase_start", "later chase checkpoint did not supersede the room checkpoint"): return
	player.global_position.z = WorldLayout.CHASE_TRIGGER_Z - 0.1
	director._process(0.0)
	if not _require(GameState.stage == GameState.Stage.CHASE, "chase stage missing"): return
	if not _require(is_instance_valid(director._chase.entity), "chase entity missing before capture test"): return
	var entity_body := director._chase.entity.get_node_or_null("EntityBody") as MeshInstance3D
	var entity_collider := director._chase.entity.get_node_or_null("EntityCollider") as CollisionShape3D
	if not _require(entity_body != null and is_equal_approx(entity_body.position.y, 1.25), "production enemy mesh is not centered above the floor"): return
	if not _require(entity_collider != null and is_equal_approx(entity_collider.position.y, 1.2), "production enemy collider is not centered above the floor"): return
	for visual_name in ["EntityHead", "EntityArmLeft", "EntityArmRight", "EntityEyeLeft", "EntityEyeRight", "EntityRib00", "EntityRimLight"]:
		if not _require(director._chase.entity.has_node(visual_name), "production enemy lost readable visual part %s" % visual_name): return
	var entity_eye := director._chase.entity.get_node("EntityEyeLeft") as MeshInstance3D
	var eye_material := entity_eye.material_override as StandardMaterial3D
	var rim_light := director._chase.entity.get_node("EntityRimLight") as OmniLight3D
	if not _require(eye_material != null and eye_material.emission_enabled and eye_material.emission_energy_multiplier >= 4.0, "production enemy eyes are no longer readable in motion"): return
	if not _require(rim_light.light_energy >= 0.5 and rim_light.omni_range <= 3.0, "production enemy rim signature is missing or washes out the corridor"): return
	if not _require(absf(director._chase.entity.global_position.y - player.global_position.y) < 0.05, "production enemy root no longer follows the floor plane"): return
	director._chase.entity.appear_duration = 0.01
	director._chase.entity.stalk_duration = 0.01
	if not _require(await _wait_for_entity_state(director._chase.entity, director._chase.entity.State.CHASE), "production enemy never armed its capture state"): return
	# Keep the root on the floor plane so proximity exercises the same production
	# mesh, collider, navigation, and recovery path used during gameplay.
	director._chase.entity.global_position = player.global_position + Vector3(0, 0, 0.05)
	director._chase.entity.velocity = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _require(director._chase.recovering, "enemy proximity did not trigger capture recovery"): return
	await get_tree().create_timer(1.4).timeout
	if not _require(not director._chase.recovering, "fail recovery should finish"): return
	if not _require(is_equal_approx(player.global_position.z, WorldLayout.CHASE_RESPAWN_Z), "fail recovery marker mismatch"): return
	var entity_count := 0
	for child in gameplay.get_children():
		if child.name.begins_with("TheEntity"):
			entity_count += 1
	if not _require(entity_count == 1, "fail recovery duplicated the entity"): return
	# Ending is terminal even if a capture coroutine already owns the fail delay.
	# This reproduces the production overlap without sacrificing the ordinary
	# checkpoint-recovery coverage above.
	director._chase.request_failure()
	if not _require(director._chase.recovering, "terminal race fixture did not start capture recovery"): return
	var fail_audio := AudioManager._players.get("fail") as AudioStreamPlayer
	if not _require(is_instance_valid(fail_audio) and fail_audio.stream != null and AudioManager._cache_ids.has("fail"), "terminal race fixture did not start failure audio"): return
	if not _require(not director.handle_story_action("ending_notice", player), "epilogue notice accepted before Ending"): return
	var checkpoint_before_ending := JSON.stringify(GameState.checkpoint)
	var credits_count := [0]
	director._chase.credits_shown.connect(func() -> void: credits_count[0] += 1)
	if not _require(director.handle_story_action("exit", player), "ending should accept the completed chase path"): return
	if not _require(GameState.stage == GameState.Stage.ENDING, "ending stage missing"): return
	if not _require(director.get_story_prompt("exit", player).is_empty() and not director.handle_story_action("exit", player), "obsolete chase exit remained interactive during the epilogue"): return
	if not _require(not fail_audio.playing and fail_audio.stream == null and not AudioManager._cache_ids.has("fail"), "terminal ending retained stale failure audio or cache ownership"): return
	if not _require(gameplay.has_node("AbandonedLobbyFloor"), "abandoned lobby reveal missing"): return
	var ending_notice := gameplay.get_node_or_null("ending_notice") as StoryInteractable
	var ending_roster := gameplay.get_node_or_null("ending_roster") as StoryInteractable
	if not _require(ending_notice != null and ending_roster != null and ending_notice.get_parent() == gameplay and ending_roster.get_parent() == gameplay, "epilogue props are not distinct gameplay-root interactables"): return
	if not _require(ending_notice.global_position.distance_to(ending_roster.global_position) >= 2.5, "epilogue props are not spatially separated"): return
	if not _require(ending_notice.get_node_or_null("CollisionShape3D") != null and ending_roster.get_node_or_null("CollisionShape3D") != null, "epilogue props have no production collision shapes"): return
	if not _require(not gameplay.has_node("EndingOverlay") and credits_count[0] == 0, "credits appeared before either epilogue reveal"): return
	if not _require(not player.is_input_locked() and not player.is_movement_locked() and not player._locks.has("fail") and not director._fail_overlay.visible, "epilogue investigation retained an input lock: %s" % [player._locks.keys()]): return
	if not _require(director.get_story_prompt("ending_notice", player) == "[E] Read the 2007 condemnation notice", "ending notice prompt is missing or unclear"): return
	if not _require(director.get_story_prompt("ending_roster", player).is_empty() and not director.handle_story_action("ending_roster", player), "night roster bypassed the notice narration gate"): return
	if not _require(director.handle_story_action("ending_notice", player), "ending notice did not start"): return
	if not _require(not director.handle_story_action("ending_notice", player), "ending notice accepted a duplicate action"): return
	if not _require(not gameplay.has_node("EndingOverlay") and not player.is_input_locked(), "notice interaction showed credits or locked investigation early"): return
	if not _require(await _wait_for_flag("ending_notice_complete"), "ending notice narration did not complete"): return
	if not _require(director.get_story_prompt("ending_roster", player) == "[E] Read the night roster", "night roster did not unlock after notice narration"): return
	if not _require(director.handle_story_action("ending_roster", player), "night roster did not start"): return
	if not _require(not director.handle_story_action("ending_roster", player), "night roster accepted a duplicate action"): return
	if not _require(not gameplay.has_node("EndingOverlay") and credits_count[0] == 0 and not player.is_input_locked(), "roster interaction finalized before its narration completed"): return
	if not _require(await _wait_for_flag("ending_roster_complete"), "night roster narration did not complete"): return
	if not _require(await _wait_for_node(gameplay, "EndingOverlay"), "credits did not follow the completed interactive epilogue"): return
	if not _require(credits_count[0] == 1 and player._locks.has("ending") and player.is_input_locked(), "visible credits did not apply exactly one terminal input lock and signal"): return
	if not _require(not (gameplay.get_node("HUD") as CanvasLayer).visible, "credits left gameplay directions visible behind the ending panel"): return
	if not _require(JSON.stringify(GameState.checkpoint) == checkpoint_before_ending, "interactive epilogue mutated the chase checkpoint"): return
	await get_tree().create_timer(1.4).timeout
	if not _require(GameState.stage == GameState.Stage.ENDING, "capture recovery overwrote the terminal ending stage"): return
	if not _require(GameState.objective == "23:47. The shift was never scheduled.", "capture recovery overwrote the terminal ending objective"): return
	if not _require(not director._chase.recovering and not director._chase.entity.active and not director._chase.entity.visible, "capture recovery restarted the entity after ending"): return
	if not _require(not player._locks.has("fail") and player._locks.has("ending") and not director._fail_overlay.visible, "ending retained stale capture UI or released its terminal lock"): return
	if not _verify_complete_pacing_report(director): return
	var pacing_before_duplicate: String = JSON.stringify(director.get_playthrough_pacing_report())
	director._chase.finish()
	director._chase.show_credits()
	await get_tree().process_frame
	if not _require(_count_named_children(gameplay, "EndingOverlay") == 1, "duplicate ending created a second credits overlay"): return
	if not _require(credits_count[0] == 1, "duplicate ending emitted credits more than once"): return
	if not _require(JSON.stringify(director.get_playthrough_pacing_report()) == pacing_before_duplicate, "duplicate ending mutated the pacing report"): return
	var voice_contract_failures: PackedStringArray = director._narrative.voice_contract_failures()
	if not _require(voice_contract_failures.is_empty(), "production narrative drifted from the voice manifest: " + "; ".join(voice_contract_failures)): return
	if not _require(director._narrative.validated_voice_cue_count() == 76, "full progression did not exercise all 76 manifest-backed narrative lines"): return
	var exit_light := director._horror._find_nearest_light(Vector3(0, 2.8, -92.0)) as OmniLight3D
	var exit_light_energy := exit_light.light_energy
	var exit_light_color := exit_light.light_color
	var exit_sequence := director._horror._create_sequence("ScareExitCleanupFixture") as HorrorScareSequence
	var owned_exit_fixture := Node3D.new()
	director._horror.add_child(owned_exit_fixture)
	exit_sequence.own_node(owned_exit_fixture)
	exit_sequence.set_light(exit_light, 0.05, Color.RED)
	exit_sequence.play_spatial_at(Vector3(0, 1.0, -92.0), "scare_exit_cleanup_fixture", 35.0, 1.0, -30.0)
	director._horror.queue_free()
	await get_tree().process_frame
	if not _require(not is_instance_valid(owned_exit_fixture) and is_equal_approx(exit_light.light_energy, exit_light_energy) and exit_light.light_color.is_equal_approx(exit_light_color) and not _has_spatial_cue("scare_exit_cleanup_fixture") and not AudioManager._cache_ids.has("scare_exit_cleanup_fixture"), "director exit did not release its owned node, light, or scare audio/cache ownership"): return
	AudioManager.stop_all()
	print("PROGRESSION_TEST_OK")
	gameplay.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("PROGRESSION_ASSERT: " + message)
	get_tree().quit(2)
	return false

func _verify_complete_pacing_report(director: Node) -> bool:
	if not _require(director.has_method("get_playthrough_pacing_report"), "gameplay director does not expose pacing telemetry"): return false
	var report: Dictionary = director.get_playthrough_pacing_report()
	if not _require(bool(report.get("eligible_full_run", false)), "fresh gameplay session was not eligible for pacing evidence"): return false
	if not _require(bool(report.get("complete", false)), "credits did not finalize the pacing report"): return false
	if not _require(report.get("within_target") == false, "compressed headless run was incorrectly accepted as a 15-20 minute playthrough"): return false
	if not _require((report.get("missing_milestones", []) as Array).is_empty(), "complete run retained missing pacing milestones"): return false
	var expected_order: Array[String] = ["lobby", "floor4_dark", "floor4_powered", "memory_loop", "room_407", "chase", "ending", "credits"]
	var actual_order: Array = report.get("boundary_order", []) as Array
	if not _require(actual_order == expected_order, "pacing boundary order did not follow production progression"): return false
	if not _require(bool(report.get("boundary_order_valid", false)), "complete pacing report marked its milestone order invalid"): return false
	var stage_seconds: Dictionary = report.get("stage_active_seconds", {}) as Dictionary
	var previous_seconds := -1.0
	for milestone: String in expected_order:
		if not _require(stage_seconds.has(milestone), "pacing report missing %s boundary" % milestone): return false
		var current_seconds := float(stage_seconds[milestone])
		if not _require(current_seconds >= previous_seconds, "pacing timestamps decreased at %s" % milestone): return false
		previous_seconds = current_seconds
	var chapter_seconds: Dictionary = report.get("chapter_active_seconds", {}) as Dictionary
	for chapter: String in ["opening", "floor4", "memory_loop", "room407", "chase_ending"]:
		var duration: Variant = chapter_seconds.get(chapter)
		if not _require(duration != null and float(duration) >= 0.0, "pacing chapter %s was incomplete" % chapter): return false
	var mutated_report: Dictionary = director.get_playthrough_pacing_report()
	mutated_report["eligible_full_run"] = false
	(mutated_report["target_seconds"] as Dictionary)["total"] = [0.0, 0.0]
	var fresh_report: Dictionary = director.get_playthrough_pacing_report()
	if not _require(bool(fresh_report["eligible_full_run"]), "pacing facade leaked top-level report mutations"): return false
	if not _require((fresh_report["target_seconds"] as Dictionary)["total"] == [900.0, 1200.0], "pacing facade leaked nested report mutations"): return false
	if not _require(float(report.get("paused_seconds", 0.0)) > 0.0, "pacing report lost the deliberate pause interval"): return false
	return _require(float(report.get("active_gameplay_seconds", -1.0)) >= 0.0 and float(report.get("wall_clock_seconds", -1.0)) >= float(report.get("active_gameplay_seconds", -1.0)), "pacing totals were invalid")

func _count_named_children(parent: Node, child_name: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.name == child_name:
			count += 1
	return count

func _contains_collision_object(parent: Node) -> bool:
	for child in parent.get_children():
		if child is CollisionObject3D or _contains_collision_object(child):
			return true
	return false

func _has_textured_mesh(parent: Node, child_name: String) -> bool:
	var mesh_instance := parent.get_node_or_null(child_name) as MeshInstance3D
	if mesh_instance == null or not mesh_instance.mesh is QuadMesh:
		return false
	var material := mesh_instance.material_override as StandardMaterial3D
	return material != null and material.albedo_texture != null and material.cull_mode == BaseMaterial3D.CULL_DISABLED

func _room_drawing_faces_corridor_center(parent: Node) -> bool:
	var mesh_instance := parent.get_node_or_null("RoomDrawingImage") as MeshInstance3D
	if mesh_instance == null:
		return false
	# The authored right-wall drawing must still face world -X even if an ancestor rotates.
	var world_normal := mesh_instance.global_transform.basis.z.normalized()
	return world_normal.dot(Vector3.LEFT) > 0.9

func _room_drawing_surfaces_align(parent: Node) -> bool:
	var backing := parent.get_node_or_null("PaperClue") as MeshInstance3D
	var image := parent.get_node_or_null("RoomDrawingImage") as MeshInstance3D
	var writing := parent.get_node_or_null("PaperWriting") as Label3D
	if backing == null or image == null or writing == null:
		return false
	var backing_normal := backing.global_transform.basis.z.normalized()
	var image_normal := image.global_transform.basis.z.normalized()
	var writing_normal := writing.global_transform.basis.z.normalized()
	if backing_normal.dot(image_normal) < 0.999 or backing_normal.dot(writing_normal) < 0.999:
		return false
	# Image and label use the exact shallow offsets authored by the builder, in one world plane.
	var image_delta := image.global_position - backing.global_position
	var writing_delta := writing.global_position - backing.global_position
	var image_depth := image_delta.dot(backing_normal)
	var writing_depth := writing_delta.dot(backing_normal)
	return (
		absf(image_depth - 0.027) <= 0.001
		and absf(writing_depth - 0.035) <= 0.001
		and absf((writing_depth - image_depth) - 0.008) <= 0.001
		and (image_delta - backing_normal * image_depth).length() < 0.001
		and (writing_delta - backing_normal * writing_depth).length() < 0.001
	)

func _textured_quad_matches_source_aspect(parent: Node, child_name: String) -> bool:
	var mesh_instance := parent.get_node_or_null(child_name) as MeshInstance3D
	if mesh_instance == null or not mesh_instance.mesh is QuadMesh:
		return false
	var quad := mesh_instance.mesh as QuadMesh
	var material := mesh_instance.material_override as StandardMaterial3D
	if material == null or material.albedo_texture == null or quad.size.y <= 0.0:
		return false
	var texture_size := material.albedo_texture.get_size()
	if texture_size.y <= 0.0:
		return false
	return absf((quad.size.x / quad.size.y) - (texture_size.x / texture_size.y)) <= 0.01

func _has_spatial_cue(cue_id: String) -> bool:
	return AudioManager._spatial_player_ids.values().has(cue_id)

func _find_turn_away_apparition(parent: Node) -> TurnAwayApparition:
	for child in parent.get_children():
		if child is TurnAwayApparition:
			return child as TurnAwayApparition
	return null

func _count_turn_away_apparitions(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is TurnAwayApparition:
			count += 1
	return count

func _wait_for_flag(flag: String, max_frames := 180) -> bool:
	for _frame in max_frames:
		if GameState.has_flag(flag):
			return true
		await get_tree().process_frame
	return false

func _wait_for_checkpoint(spawn_id: String, max_frames := 180) -> bool:
	for _frame in max_frames:
		if str(GameState.checkpoint.get("spawn_id", "")) == spawn_id:
			return true
		await get_tree().process_frame
	return false

func _wait_for_transition(director: Node, max_frames := 180) -> bool:
	for _frame in max_frames:
		if not director._story.loop_transitioning:
			return true
		await get_tree().process_frame
	return false

func _wait_for_blackout(transition: HallwayTransitionLayer, max_frames := 60) -> bool:
	for _frame in max_frames:
		if transition.running and transition._curtain.modulate.a > 0.99:
			return true
		await get_tree().process_frame
	return false

func _wait_for_radio(radio_ui: Variant, max_frames := 120) -> bool:
	for _frame in max_frames:
		if radio_ui._accepting_input:
			return true
		await get_tree().process_frame
	return false

func _wait_for_node(parent: Node, node_name: String, max_frames := 120) -> bool:
	for _frame in max_frames:
		if parent.has_node(node_name):
			return true
		await get_tree().process_frame
	return false

func _wait_for_node_removed(parent: Node, node_name: String, timeout_seconds := 0.35) -> bool:
	var deadline_msec := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while parent.has_node(node_name):
		if Time.get_ticks_msec() >= deadline_msec:
			return false
		await get_tree().create_timer(0.005, false).timeout
	return true

func _wait_for_light_cue(light: OmniLight3D, baseline_energy: float, cue_id: String, timeout_seconds := 0.25) -> bool:
	var deadline_msec := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline_msec:
		if is_instance_valid(light) and light.light_energy > baseline_energy and _has_spatial_cue(cue_id):
			return true
		await get_tree().create_timer(0.005, false).timeout
	return false

func _wait_for_entity_state(entity: CharacterBody3D, expected_state: int, max_frames := 120) -> bool:
	for _frame in max_frames:
		if entity.state == expected_state:
			return true
		await get_tree().process_frame
	return false
