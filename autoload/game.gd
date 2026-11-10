extends Node
## Holds the loaded save, device settings and the save store.

signal hearts_changed(total: int)

const SETTINGS_PATH := "user://settings.json"

var store: SaveStore
var voice: VoiceStore
var state: GameState
var slot := 0
var rng := RandomNumberGenerator.new()
## Device-wide settings (not per child).
var settings := {"music": 0.6, "sfx": 0.9, "read_aloud": true, "pin_hash": ""}


func _ready() -> void:
	store = SaveStore.new()
	voice = VoiceStore.new()
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


func new_game(slot_number: int) -> void:
	slot = slot_number
	state = GameState.new_game()
	save()


func load_game(slot_number: int) -> bool:
	var s := store.load_slot(slot_number)
	if s == null:
		return false
	slot = slot_number
	state = s
	return true


func save() -> void:
	if state != null and slot > 0:
		store.save(slot, state)
	voice.save_heard()


func close_game() -> void:
	save()
	state = null
	slot = 0


func add_hearts(n: int) -> void:
	state.hearts += n
	hearts_changed.emit(state.hearts)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save()
