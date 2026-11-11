extends Node
## Holds the loaded save, device settings and the save store.

signal hearts_changed(total: int)

const SETTINGS_PATH := "user://settings.json"

var store: SaveStore
## The playing child's own recordings (the booth records here), and the
## recordings the game plays: the same ones, or a brother's or sister's.
## Both null on the title screen.
var voice: VoiceStore
var listen: VoiceStore
var state: GameState
var slot := 0
var rng := RandomNumberGenerator.new()
## Device-wide settings (not per child).
var settings := {"music": 0.6, "sfx": 0.9, "read_aloud": true, "pin_hash": ""}


func _ready() -> void:
	store = SaveStore.new()
	store.adopt_old_recordings("user://voice")
	rng.randomize()
	_load_settings()


func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if d is Dictionary:
			for k in d:
				if settings.has(k):
					settings[k] = d[k]


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings, "\t"))


func new_game(slot_number: int, child_name := "") -> void:
	slot = slot_number
	state = GameState.new_game()
	state.child_name = child_name
	open_voices()
	save()


func load_game(slot_number: int) -> bool:
	var s := store.load_slot(slot_number)
	if s == null:
		return false
	slot = slot_number
	state = s
	open_voices()
	return true


## (Re)reads the playing child's recordings and the ones they chose to hear.
func open_voices() -> void:
	if voice:
		voice.save_heard()
	voice = VoiceStore.new(store.voice_dir(state.profile_id))
	listen = voice
	var from: String = state.voice.from
	if from != "" and from != state.profile_id:
		if store.slot_of_profile(from) > 0:
			listen = VoiceStore.new(store.voice_dir(from))
		else:
			state.voice.from = ""  # that save is gone


## Everyone else's profiles that have recordings: [{id, name}].
func other_voices() -> Array:
	var out := []
	for i in range(1, SaveStore.SLOTS + 1):
		var st := store.load_slot(i)
		if st != null and st.profile_id != state.profile_id and not VoiceStore.new(store.voice_dir(st.profile_id)).is_empty():
			out.append({"id": st.profile_id, "name": st.child_name if st.child_name != "" else "Save %d" % i})
	return out


func save() -> void:
	if state != null and slot > 0:
		store.save(slot, state)
	if voice:
		voice.save_heard()


func close_game() -> void:
	save()
	state = null
	slot = 0
	voice = null
	listen = null


func add_hearts(n: int) -> void:
	state.hearts += n
	hearts_changed.emit(state.hearts)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save()
