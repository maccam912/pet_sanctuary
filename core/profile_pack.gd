class_name ProfilePack
extends RefCounted
## Moves one child's profile (their sanctuary and their recordings) to another
## device as a single .zip file: profile.json plus voice/<recording>.wav.

const FORMAT := 1


## Writes the save in `slot` and its recordings to `path` (a file path, or the
## content URI an Android file picker hands back).
static func export_slot(store: SaveStore, slot: int, path: String) -> Error:
	var st := store.load_slot(slot)
	if st == null:
		return ERR_DOES_NOT_EXIST
	# Zip into the game's own folder first, then copy: the destination may be
	# a URI that only FileAccess knows how to open.
	var tmp := store.base_dir + "/export.zip"
	var zip := ZIPPacker.new()
	var err := zip.open(tmp)
	if err != OK:
		return err
	_add(zip, "profile.json", JSON.stringify({"format": FORMAT, "save": st.to_dict()}, "\t").to_utf8_buffer())
	var dir := store.voice_dir(st.profile_id)
	for f in DirAccess.get_files_at(dir) if DirAccess.dir_exists_absolute(dir) else PackedStringArray():
		if _safe_name(f):
			_add(zip, "voice/" + f, FileAccess.get_file_as_bytes(dir + "/" + f))
	zip.close()
	err = _copy(tmp, path)
	DirAccess.remove_absolute(tmp)
	return err


## A file name like SunnyPaws-Emma.zip.
static func file_name(st: GameState, slot: int) -> String:
	var who := st.child_name.validate_filename().replace(" ", "")
	return "SunnyPaws-%s.zip" % (who if who != "" else "Save%d" % slot)


static func _add(zip: ZIPPacker, file_name: String, bytes: PackedByteArray) -> void:
	zip.start_file(file_name)
	zip.write_file(bytes)
	zip.close_file()


static func _copy(from: String, to: String) -> Error:
	var bytes := FileAccess.get_file_as_bytes(from)
	var f := FileAccess.open(to, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_buffer(bytes)
	f.close()
	return OK


## Reads a profile file. Returns {"state": GameState, "files": {name: bytes},
## "recordings": int}, or {} if it is not a Sunny Paws profile.
static func read(path: String, scratch_dir: String) -> Dictionary:
	var local := scratch_dir + "/import.zip"
	if _copy(path, local) != OK:
		return {}
	var out := {}
	var zip := ZIPReader.new()
	if zip.open(local) == OK:
		out = _read_zip(zip)
		zip.close()
	DirAccess.remove_absolute(local)
	return out


static func _read_zip(zip: ZIPReader) -> Dictionary:
	if not zip.file_exists("profile.json"):
		return {}
	var data = JSON.parse_string(zip.read_file("profile.json").get_string_from_utf8())
	if not (data is Dictionary) or not (data.get("save") is Dictionary) or int(data.get("format", 0)) > FORMAT:
		return {}
	var files := {}
	var recordings := 0
	for f in zip.get_files():
		if f.get_base_dir() == "voice" and _safe_name(f.get_file()):
			files[f.get_file()] = zip.read_file(f)
			if f.ends_with(".wav"):
				recordings += 1
	return {"state": GameState.from_dict(data.save), "files": files, "recordings": recordings}


## Recording file names only: no folders, nothing that could escape the voice folder.
static func _safe_name(file_name: String) -> bool:
	if file_name == "heard.json":
		return true
	if not file_name.ends_with(".wav") or file_name.length() > 80:
		return false
	for ch in file_name.trim_suffix(".wav"):
		if not (ch in "abcdefghijklmnopqrstuvwxyz0123456789_"):
			return false
	return true


## Puts the imported profile into `slot`. A save already there goes to the
## recycle bin first, like a delete. Returns false if that slot is busy.
static func import_profile(store: SaveStore, pack: Dictionary, slot: int) -> bool:
	if store.exists(slot) and store.delete_to_trash(slot) == "":
		return false
	var st: GameState = pack.state
	var owner := store.slot_of_profile(st.profile_id)
	if owner != 0 and owner != slot:
		# Already on this device in another save: keep the two apart.
		st.profile_id = GameState.new_profile_id()
	add_recordings(store, pack, st.profile_id)
	return store.save(slot, st)


## Adds the imported recordings to a profile: new ones are added, ones with
## the same line or sound are replaced, and nothing is deleted.
static func add_recordings(store: SaveStore, pack: Dictionary, profile_id: String) -> void:
	var dir := store.voice_dir(profile_id)
	DirAccess.make_dir_recursive_absolute(dir)
	for file_name in pack.files:
		var bytes: PackedByteArray = pack.files[file_name]
		if file_name == "heard.json":
			bytes = _merge_heard(dir + "/heard.json", bytes)
		var f := FileAccess.open(dir + "/" + file_name, FileAccess.WRITE)
		if f:
			f.store_buffer(bytes)


static func _merge_heard(path: String, incoming: PackedByteArray) -> PackedByteArray:
	var theirs = JSON.parse_string(incoming.get_string_from_utf8())
	var ours = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	if not (theirs is Dictionary):
		theirs = {}
	if not (ours is Dictionary):
		ours = {}
	for k in theirs:
		if theirs[k] is Dictionary and (not (ours.get(k) is Dictionary) or int(theirs[k].get("n", 0)) > int(ours[k].get("n", 0))):
			ours[k] = theirs[k]
	return JSON.stringify(ours).to_utf8_buffer()
