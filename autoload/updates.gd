extends Node
## Looks on GitHub for a newer build when the game starts. A grown-up starts
## the update from the title screen: on Android the game downloads the new APK
## and opens Android's installer (saves and recordings in user:// stay); on a
## computer it opens the release page.

signal found(info: Dictionary)
signal changed  ## `state` moved on

const DIR := "user://updates"

## The newer release, {} until one is found (see UpdateCheck.newer).
var available := {}
## "" (idle), "downloading", "installing" (Android's installer was opened) or "failed".
var state := ""
## Why it failed, for the grown-ups.
var error := ""
var _download: HTTPRequest


func _ready() -> void:
	if UpdateCheck.this_build() <= 0 or DisplayServer.get_name() == "headless" or UpdateCheck.asset_suffix(OS.get_name()) == "":
		return
	var check := HTTPRequest.new()
	check.timeout = 20.0
	add_child(check)
	check.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
		check.queue_free()
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			_on_release(JSON.parse_string(body.get_string_from_utf8())))
	check.request(UpdateCheck.LATEST_URL, ["Accept: application/vnd.github+json"])


func _on_release(release: Variant) -> void:
	if not release is Dictionary:
		return
	available = UpdateCheck.newer(release, UpdateCheck.this_build(), UpdateCheck.asset_suffix(OS.get_name()))
	_tidy()
	if not available.is_empty():
		found.emit(available)


## True where the game installs the update itself (Android).
func can_install() -> bool:
	return OS.get_name() == "Android"


## Android: download the APK (unless a good copy is already here), check it,
## then open Android's installer. Elsewhere: open the release page.
func start() -> void:
	if available.is_empty() or state == "downloading":
		return
	if not can_install():
		OS.shell_open(available.page)
		return
	var path := _apk()
	if _intact(path):
		_install(path)
		return
	DirAccess.make_dir_recursive_absolute(DIR)
	_download = HTTPRequest.new()
	_download.use_threads = true
	_download.download_file = path + ".part"
	add_child(_download)
	_download.request_completed.connect(_on_downloaded)
	_set_state("downloading")
	if _download.request(available.url) != OK:
		_on_downloaded(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())


## How much of the APK has arrived, 0..1.
func fraction() -> float:
	if _download == null or available.get("size", 0) <= 0:
		return 0.0
	return clampf(float(_download.get_downloaded_bytes()) / available.size, 0.0, 1.0)


## Stops a download and goes back to idle.
func cancel() -> void:
	if _download:
		_download.cancel_request()
		_download.queue_free()
		_download = null
		DirAccess.remove_absolute(_apk() + ".part")
	_set_state("")


func _on_downloaded(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_download.queue_free()
	_download = null
	var path := _apk()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not _intact(path + ".part"):
		DirAccess.remove_absolute(path + ".part")
		_set_state("failed", "The download did not work. Check the Wi-Fi and try again.")
		return
	DirAccess.rename_absolute(path + ".part", path)
	_install(path)


func _install(path: String) -> void:
	if OS.shell_open(ProjectSettings.globalize_path(path)) == OK:
		_set_state("installing")
	else:
		_set_state("failed", "Android's installer did not open.")


func _apk() -> String:
	return DIR + "/" + available.name


## The whole file is there and matches the checksum GitHub lists.
func _intact(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_length() != available.size:
		return false
	f.close()
	return available.sha256 == "" or FileAccess.get_sha256(path) == available.sha256


## Deletes downloads that are installed or out of date.
func _tidy() -> void:
	if not DirAccess.dir_exists_absolute(DIR):
		return
	for f in DirAccess.get_files_at(DIR):
		if f != available.get("name", ""):
			DirAccess.remove_absolute(DIR + "/" + f)


func _set_state(new_state: String, why := "") -> void:
	state = new_state
	error = why
	changed.emit()
