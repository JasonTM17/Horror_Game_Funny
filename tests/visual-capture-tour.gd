extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")
const ENDING_SCENE := preload("res://scenes/ui/ending-overlay.tscn")
const DEFAULT_OUTPUT_ROOT := "res://.artifacts/visual-capture-current"

var _gameplay: Node3D
var _player: CharacterBody3D
var _output_root := DEFAULT_OUTPUT_ROOT
var _capture_failed := false

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("VISUAL_CAPTURE_REQUIRES_RENDERED_DISPLAY")
		get_tree().quit(2)
		return
	_output_root = _read_output_root()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_root))
	GameState.reset_run()
	_gameplay = GAMEPLAY_SCENE.instantiate() as Node3D
	add_child(_gameplay)
	await get_tree().process_frame
	await get_tree().process_frame
	_gameplay.set_process(false)
	_gameplay._narrative.voice_over_enabled = false
	_player = _gameplay.player
	_player.set_physics_process(false)
	await _capture_lobby()
	if _abort_failed_capture(): return
	await _capture_memory_corridor()
	if _abort_failed_capture(): return
	await _capture_room_407()
	if _abort_failed_capture(): return
	await _capture_final_clue()
	if _abort_failed_capture(): return
	await _capture_chase_route()
	if _abort_failed_capture(): return
	await _capture_chase_entity()
	if _abort_failed_capture(): return
	await _capture_epilogue()
	if _abort_failed_capture(): return
	await _capture_credits()
	if _abort_failed_capture(): return
	AudioManager.stop_all()
	print("VISUAL_CAPTURE_TOUR_OK: " + ProjectSettings.globalize_path(_output_root))
	get_tree().quit()

func _capture_lobby() -> void:
	GameState.set_objective("Answer the desk phone and sign the night log.")
	_place_player(Vector3(0, 0.02, WorldLayout.PLAYER_START_Z), 0.0, -8.0)
	await _hold_and_capture("room-407-lobby.png", 0.9)

func _capture_memory_corridor() -> void:
	GameState.set_objective("The hallway has changed. Find three things that remember you.")
	_set_hallway_variant(3)
	_place_player(Vector3(0.4, 0.02, -245.0), 0.0, -5.0)
	await _hold_and_capture("room-407-memory-hallway.png", 0.9)

func _capture_room_407() -> void:
	GameState.set_objective("Room 407 is open. Find what was left behind.")
	_place_player(Vector3(0, 0.02, -397.0), 0.0, -7.0)
	await _hold_and_capture("room-407-bedroom.png", 0.9)

func _capture_final_clue() -> void:
	GameState.set_objective("The room has one last note for you.")
	_place_player(Vector3(0, 0.02, WorldLayout.FINAL_CLUE_Z + 7.0), 0.0, -14.0)
	await _hold_and_capture("room-407-final-clue.png", 0.9)

func _capture_chase_route() -> void:
	GameState.set_objective("RUN. The exit is at the far end of the corridor.")
	_place_player(Vector3(0, 0.02, -559.0), 0.0, -5.0)
	await _hold_and_capture("room-407-chase-route.png", 0.9)

func _capture_chase_entity() -> void:
	_place_player(Vector3(0, 0.02, -605.0), PI, -3.0)
	_gameplay._chase.start()
	await get_tree().process_frame
	var entity := _gameplay._chase.entity as CharacterBody3D
	entity.set_physics_process(false)
	entity.global_position = Vector3(0, 0.02, -595.0)
	entity.visible = true
	await _hold_and_capture("room-407-chase-entity.png", 1.1)

func _capture_epilogue() -> void:
	_place_player(Vector3(0, 0.02, WorldLayout.EXIT_Z), 0.0, -5.0)
	_gameplay._chase.finish()
	_gameplay._epilogue.begin(_player.global_position)
	GameState.set_objective("Read the condemnation notice on the abandoned desk.")
	await _hold_and_capture("room-407-ending-reveal.png", 1.1)

func _capture_credits() -> void:
	var overlay := ENDING_SCENE.instantiate()
	overlay.name = "CaptureEndingOverlay"
	_gameplay.add_child(overlay)
	overlay.show_ending()
	await _hold_and_capture("room-407-credits.png", 1.1)

func _hold_and_capture(file_name: String, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	await get_tree().process_frame
	var texture := get_viewport().get_texture()
	if texture == null:
		_capture_failed = true
		push_error("VISUAL_CAPTURE_VIEWPORT_UNAVAILABLE: " + file_name)
		return
	var image := texture.get_image()
	if image == null:
		_capture_failed = true
		push_error("VISUAL_CAPTURE_IMAGE_UNAVAILABLE: " + file_name)
		return
	var output_path := _output_root.path_join(file_name)
	var error := image.save_png(output_path)
	if error != OK:
		_capture_failed = true
		push_error("VISUAL_CAPTURE_SAVE_FAILED: %s (%s)" % [output_path, error])
		return
	print("VISUAL_CAPTURE_FRAME: " + ProjectSettings.globalize_path(output_path))

func _abort_failed_capture() -> bool:
	if not _capture_failed:
		return false
	AudioManager.stop_all()
	get_tree().quit(2)
	return true

func _place_player(position: Vector3, yaw: float, pitch: float) -> void:
	_player.global_position = position
	_player.rotation.y = yaw
	_player.head.rotation.x = deg_to_rad(pitch)
	_player.velocity = Vector3.ZERO

func _set_hallway_variant(variant: int) -> void:
	_gameplay._hallway.variant = variant
	for index in _gameplay._hallway.variant_roots.size():
		_gameplay._hallway.variant_roots[index].visible = index == variant

func _read_output_root() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-root="):
			var value := argument.trim_prefix("--output-root=").strip_edges()
			if not value.is_empty():
				return value
	return DEFAULT_OUTPUT_ROOT
