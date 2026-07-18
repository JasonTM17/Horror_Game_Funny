class_name VoiceOverPlayer
extends AudioStreamPlayer

const MANIFEST_PATH := "res://assets/audio/voice-over/voice-over-manifest.json"
const VOICE_ROOT := "res://assets/audio/voice-over/"
const END_PADDING_SECONDS := 0.35
const ALLOWED_ROLES := ["manager", "radio", "recording", "child", "whisper", "narrator"]

var _cues: Dictionary = {}
var _stream_cache: Dictionary = {}
var _manifest_error := ""

func _ready() -> void:
	bus = AudioManager.VOICE_BUS_NAME
	max_polyphony = 1
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_load_manifest()

func play_cue(completion_flag: String, zero_based_line_index: int, subtitle: String) -> float:
	var cue := _matching_cue(completion_flag, zero_based_line_index, subtitle)
	if cue.is_empty():
		stop_cue()
		return 0.0
	var cue_id := make_cue_id(completion_flag, zero_based_line_index)
	var voice_stream := _load_cue_stream(cue_id, cue)
	if voice_stream == null or voice_stream.get_length() <= 0.0:
		stop_cue()
		return 0.0
	stop()
	stream = voice_stream
	play()
	return voice_stream.get_length()

func stop_cue() -> void:
	stop()
	stream = null

func has_cue(completion_flag: String, zero_based_line_index: int, subtitle: String) -> bool:
	return not _matching_cue(completion_flag, zero_based_line_index, subtitle).is_empty()

func has_cue_id(completion_flag: String, zero_based_line_index: int) -> bool:
	return _cues.has(make_cue_id(completion_flag, zero_based_line_index))

func cue_duration(completion_flag: String, zero_based_line_index: int, subtitle: String) -> float:
	var cue := _matching_cue(completion_flag, zero_based_line_index, subtitle)
	if cue.is_empty():
		return 0.0
	var cue_id := make_cue_id(completion_flag, zero_based_line_index)
	var voice_stream := _load_cue_stream(cue_id, cue)
	return voice_stream.get_length() if voice_stream != null else 0.0

func validate_assets() -> PackedStringArray:
	var failures := PackedStringArray()
	if not _manifest_error.is_empty():
		failures.append(_manifest_error)
	for cue_id: String in _cues:
		var cue: Dictionary = _cues[cue_id]
		var path := str(cue.get("file", ""))
		if path.is_empty() or not ResourceLoader.exists(path, "AudioStream"):
			failures.append("%s has no importable AudioStream at %s" % [cue_id, path])
			continue
		var voice_stream := _load_cue_stream(cue_id, cue)
		if voice_stream == null or voice_stream.get_length() <= 0.0:
			failures.append("%s has an empty or invalid AudioStream" % cue_id)
	return failures

func cue_count() -> int:
	return _cues.size()

func cached_stream_count() -> int:
	return _stream_cache.size()

func manifest_error() -> String:
	return _manifest_error

static func make_cue_id(completion_flag: String, zero_based_line_index: int) -> String:
	return "%s-%02d" % [completion_flag, zero_based_line_index + 1]

static func line_wait_seconds(base_seconds: float, duration_scale: float, voice_duration: float) -> float:
	var authored_wait := maxf(0.001, base_seconds * duration_scale)
	if voice_duration <= 0.0:
		return authored_wait
	return maxf(authored_wait, voice_duration + END_PADDING_SECONDS)

func _matching_cue(completion_flag: String, zero_based_line_index: int, subtitle: String) -> Dictionary:
	if zero_based_line_index < 0:
		return {}
	var cue_id := make_cue_id(completion_flag, zero_based_line_index)
	var cue: Dictionary = _cues.get(cue_id, {})
	if cue.is_empty():
		return {}
	if str(cue.get("subtitle", "")) != subtitle:
		return {}
	return cue

func _load_cue_stream(cue_id: String, cue: Dictionary) -> AudioStream:
	if _stream_cache.has(cue_id):
		return _stream_cache[cue_id] as AudioStream
	var path := str(cue.get("file", ""))
	if path.is_empty() or not ResourceLoader.exists(path, "AudioStream"):
		return null
	var voice_stream := ResourceLoader.load(path, "AudioStream") as AudioStream
	if voice_stream != null:
		_stream_cache[cue_id] = voice_stream
	return voice_stream

func _load_manifest() -> void:
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		_set_manifest_error("cannot open %s" % MANIFEST_PATH)
		return
	_load_manifest_text(manifest_file.get_as_text())

func _load_manifest_text(manifest_text: String, emit_warning := true) -> void:
	_cues.clear()
	_stream_cache.clear()
	_manifest_error = ""
	var parsed: Variant = JSON.parse_string(manifest_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_set_manifest_error("manifest root is not a dictionary", emit_warning)
		return
	var schema_version: Variant = parsed.get("schema_version", null)
	if (typeof(schema_version) != TYPE_INT and typeof(schema_version) != TYPE_FLOAT) or float(schema_version) != 1.0:
		_set_manifest_error("manifest schema_version must be 1", emit_warning)
		return
	var raw_cues: Variant = parsed.get("cues", [])
	if typeof(raw_cues) != TYPE_ARRAY:
		_set_manifest_error("manifest cues field is not an array", emit_warning)
		return
	if raw_cues.is_empty():
		_set_manifest_error("manifest cues field is empty", emit_warning)
		return
	var cue_id_pattern := RegEx.new()
	if cue_id_pattern.compile("^[a-z0-9_]+-[0-9]{2}$") != OK:
		_set_manifest_error("cannot compile the cue id contract", emit_warning)
		return
	var seen_files: Dictionary = {}
	for raw_cue: Variant in raw_cues:
		if typeof(raw_cue) != TYPE_DICTIONARY:
			_set_manifest_error("manifest contains a non-dictionary cue", emit_warning)
			return
		var cue := raw_cue as Dictionary
		var cue_id := str(cue.get("id", ""))
		if cue_id_pattern.search(cue_id) == null or _cues.has(cue_id):
			_set_manifest_error("manifest contains an invalid or duplicate cue id", emit_warning)
			return
		for required_field in ["subtitle", "spoken_text", "role", "file"]:
			if typeof(cue.get(required_field, null)) != TYPE_STRING or str(cue[required_field]).strip_edges().is_empty():
				_set_manifest_error("cue %s has an invalid %s field" % [cue_id, required_field], emit_warning)
				return
		var role := str(cue["role"])
		if role not in ALLOWED_ROLES:
			_set_manifest_error("cue %s has an unsupported role" % cue_id, emit_warning)
			return
		var path := str(cue["file"])
		if path != VOICE_ROOT + cue_id + ".ogg" or seen_files.has(path):
			_set_manifest_error("cue %s has a mismatched or duplicate file path" % cue_id, emit_warning)
			return
		seen_files[path] = true
		_cues[cue_id] = cue.duplicate(true)

func _set_manifest_error(message: String, emit_warning := true) -> void:
	_manifest_error = message
	_cues.clear()
	_stream_cache.clear()
	if emit_warning:
		push_warning("Voice-over disabled: %s" % message)

func _exit_tree() -> void:
	stop_cue()
	_stream_cache.clear()
