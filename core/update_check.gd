class_name UpdateCheck
extends RefCounted
## Decides whether a GitHub release is newer than this build, and which of its
## files is the download for this platform. CI numbers every build: the release
## tag is "build-N" and the game's version is "1.0.N". A local export keeps
## version "1.0" (build 0) and never looks for updates.

const LATEST_URL := "https://api.github.com/repos/maccam912/pet_sanctuary/releases/latest"


## The CI build number in a version like "1.0.42"; 0 for a local build.
static func build_number(version: String) -> int:
	var parts := version.split(".")
	if parts.size() < 3 or not parts[2].is_valid_int():
		return 0
	return int(parts[2])


static func this_build() -> int:
	return build_number(str(ProjectSettings.get_setting("application/config/version", "")))


## The end of the release file name for a platform (OS.get_name()).
static func asset_suffix(os_name: String) -> String:
	return {"Android": "-android.apk", "Windows": "-windows.zip", "Linux": "-linux.tar.gz", "macOS": "-macos.zip"}.get(os_name, "")


## `release` is GitHub's "latest release" reply. Returns {} unless it is newer
## than build `current` and has a finished file ending in `suffix`; otherwise
## {build, name, url, size, sha256, page}.
static func newer(release: Dictionary, current: int, suffix: String) -> Dictionary:
	var tag := str(release.get("tag_name", ""))
	if current <= 0 or suffix == "" or not tag.begins_with("build-") or not tag.trim_prefix("build-").is_valid_int():
		return {}
	var build := int(tag.trim_prefix("build-"))
	if build <= current or release.get("draft", false) or release.get("prerelease", false):
		return {}
	for a in release.get("assets", []):
		if a is Dictionary and str(a.get("name", "")).ends_with(suffix) and a.get("state", "uploaded") == "uploaded":
			return {
				"build": build,
				"name": a.name,
				"url": a.browser_download_url,
				"size": int(a.size),
				"sha256": str(a.get("digest", "")).trim_prefix("sha256:"),
				"page": str(release.get("html_url", "")),
			}
	return {}
