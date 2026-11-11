class_name SaveStore
extends RefCounted
## Reads and writes save slots as JSON. Deleting never destroys data: the file
## is moved to a trash folder that only the grown-ups menu can restore from or empty.
## Each save is one child's profile; their recordings live in voices/<profile id>.

const SLOTS := 3

var base_dir: String


func _init(dir := "user://saves") -> void:
	base_dir = dir
	DirAccess.make_dir_recursive_absolute(base_dir + "/trash")
	DirAccess.make_dir_recursive_absolute(base_dir + "/voices")


func voice_dir(profile_id: String) -> String:
	return "%s/voices/%s" % [base_dir, profile_id]


## The slot holding this profile (0 if none).
func slot_of_profile(profile_id: String) -> int:
	for i in range(1, SLOTS + 1):
		var st := load_slot(i)
		if st != null and st.profile_id == profile_id:
			return i
	return 0


## Recordings from before profiles existed were shared by every save: each
## save gets its own copy, so nothing anyone hears changes.
func adopt_old_recordings(old_dir: String) -> void:
	if not DirAccess.dir_exists_absolute(old_dir):
		return
	var files := DirAccess.get_files_at(old_dir)
	var adopted := false
	for i in range(1, SLOTS + 1):
		var st := load_slot(i)
		if st == null:
			continue
		var dir := voice_dir(st.profile_id)
		DirAccess.make_dir_recursive_absolute(dir)
		for f in files:
			if not FileAccess.file_exists(dir + "/" + f):
				DirAccess.copy_absolute(old_dir + "/" + f, dir + "/" + f)
		adopted = true
	if adopted:
		for f in files:
			DirAccess.remove_absolute(old_dir + "/" + f)
		DirAccess.remove_absolute(old_dir)


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [base_dir, slot]


func exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save(slot: int, state: GameState) -> bool:
	state.last_played = Time.get_datetime_string_from_system()
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(state.to_dict(), "\t"))
	f.close()
	# Keep the previous good save as a backup, then swap the new one in.
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(tmp, path) == OK


func load_slot(slot: int) -> GameState:
	var state := _read(slot_path(slot))
	if state == null:
		state = _read(slot_path(slot) + ".bak")
	return state


func _read(path: String) -> GameState:
	if not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
		return GameState.from_dict(json.data)
	return null


## Moves the slot into the trash. Returns the trash file name ("" on failure).
func delete_to_trash(slot: int) -> String:
	if not exists(slot):
		return ""
	var name := "slot_%d_%s.json" % [slot, Time.get_datetime_string_from_system().replace(":", "-")]
	if DirAccess.rename_absolute(slot_path(slot), base_dir + "/trash/" + name) != OK:
		return ""
	if FileAccess.file_exists(slot_path(slot) + ".bak"):
		DirAccess.remove_absolute(slot_path(slot) + ".bak")
	return name


func list_trash() -> Array:
	var out := []
	var d := DirAccess.open(base_dir + "/trash")
	if d:
		for f in d.get_files():
			if f.ends_with(".json"):
				out.append(f)
	out.sort()
	return out


func restore_from_trash(file_name: String, slot: int) -> bool:
	if exists(slot):
		return false
	return DirAccess.rename_absolute(base_dir + "/trash/" + file_name, slot_path(slot)) == OK


## Deletes the trashed saves for good, and the recordings of anyone who no
## longer has a save.
func empty_trash() -> void:
	for f in list_trash():
		DirAccess.remove_absolute(base_dir + "/trash/" + f)
	var live := {}
	for i in range(1, SLOTS + 1):
		var st := load_slot(i)
		if st != null:
			live[st.profile_id] = true
	for id in DirAccess.get_directories_at(base_dir + "/voices"):
		if not live.has(id):
			var dir := base_dir + "/voices/" + id
			for f in DirAccess.get_files_at(dir):
				DirAccess.remove_absolute(dir + "/" + f)
			DirAccess.remove_absolute(dir)


func first_free_slot() -> int:
	for i in range(1, SLOTS + 1):
		if not exists(i):
			return i
	return 0
