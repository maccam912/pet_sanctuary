class_name VoiceStore
extends RefCounted
## The child's own recordings, kept in one folder for the whole device:
## animal sounds (one per animal and feeling) and voice lines that are played
## instead of the read-aloud voice. Also remembers which lines the game has
## spoken, so the recording booth can offer the ones heard most often.

const MAX_HEARD := 400
const TARGET_RATE := 24000  # recordings are stored mono at about this rate

var base_dir: String
var heard := {}    # line key -> {"text": String, "n": int}
var _have := {}    # file name (no extension) -> true
var _cache := {}   # file name -> AudioStreamWAV
var _dirty := false


func _init(dir := "user://voice") -> void:
	base_dir = dir
	DirAccess.make_dir_recursive_absolute(base_dir)
	var d := DirAccess.open(base_dir)
	if d:
		for f in d.get_files():
			if f.ends_with(".wav"):
				_have[f.trim_suffix(".wav")] = true
	var path := base_dir + "/heard.json"
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary:
			for k in data:
				if data[k] is Dictionary:
					heard[k] = {"text": str(data[k].get("text", "")), "n": int(data[k].get("n", 1))}


# ------------------------------------------------------------ text ----

## Lower-case letters and digits only, so "Oops!" and "oops" are the same line.
static func normalize(text: String) -> String:
	var out := ""
	var gap := false
	for ch in text.to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			if gap and out != "":
				out += " "
			out += ch
			gap = false
		elif ch != "'":
			gap = true
	return out


## How a line looks on a recording card: no quote marks around it.
static func display(text: String) -> String:
	var t := text.strip_edges()
	while t.begins_with("\""):
		t = t.substr(1)
	while t.ends_with("\""):
		t = t.substr(0, t.length() - 1)
	return t.strip_edges()


## Cuts spoken text into lines that can each be recorded: one sentence or so.
## A line break and the start of a quote (Biscuit: "...") always start a new
## line; very short bits ("Yes!") stay joined to their neighbour.
static func split(text: String) -> Array:
	var out := []
	for block in text.replace(": \"", ":\n\"").split("\n", false):
		var parts := []
		var current := ""
		var i := 0
		while i < block.length():
			var ch := block[i]
			current += ch
			if ch in ".!?":
				# Swallow "...", "?!" and a closing quote, then look for a space.
				while i + 1 < block.length() and block[i + 1] in ".!?\"":
					i += 1
					current += block[i]
				if i + 1 >= block.length() or block[i + 1] == " ":
					parts.append(current.strip_edges())
					current = ""
			i += 1
		if current.strip_edges() != "":
			parts.append(current.strip_edges())
		var merged := []
		var carry := ""
		for p in parts:
			var piece: String = (carry + " " + p).strip_edges()
			if normalize(piece).split(" ", false).size() < 3:
				carry = piece
			else:
				merged.append(piece)
				carry = ""
		if carry != "":
			if merged.is_empty():
				merged.append(carry)
			else:
				merged[-1] = merged[-1] + " " + carry
		for m in merged:
			if normalize(m) != "":
				out.append(m)
	return out


static func line_file(text: String) -> String:
	return "line_" + normalize(text).md5_text().substr(0, 16)


static func animal_file(species: String, emotion: String) -> String:
	return "animal_%s_%s" % [species, emotion]


# ------------------------------------------------------------ files ----

func has(file: String) -> bool:
	return _have.has(file)


func stream(file: String) -> AudioStreamWAV:
	if not _have.has(file):
		return null
	if not _cache.has(file):
		_cache[file] = AudioStreamWAV.load_from_file(base_dir + "/" + file + ".wav")
		if _cache[file] == null:
			_have.erase(file)
	return _cache.get(file)


func save(file: String, wav: AudioStreamWAV) -> bool:
	if wav == null or wav.save_to_wav(base_dir + "/" + file + ".wav") != OK:
		return false
	_have[file] = true
	_cache[file] = wav
	return true


func erase(file: String) -> void:
	_have.erase(file)
	_cache.erase(file)
	DirAccess.remove_absolute(base_dir + "/" + file + ".wav")


func has_line(text: String) -> bool:
	return has(line_file(text))


## The child's sound for this animal and feeling, or for a close feeling.
func animal_stream(species: String, emotion: String) -> AudioStreamWAV:
	for e in [emotion] + Content.SOUND_FALLBACK.get(emotion, []):
		var s := stream(animal_file(species, e))
		if s:
			return s
	return null


func animal_count(species: String) -> int:
	var n := 0
	for e in Content.EMOTIONS:
		if has(animal_file(species, e)):
			n += 1
	return n


# ----------------------------------------------------------- speech ----

## Turns text into what to play: [{"text", "stream"}], where `stream` is the
## child's recording or null for the read-aloud voice. Unrecorded neighbours
## are joined so the read-aloud voice says them in one go.
func plan(text: String) -> Array:
	var out := []
	for line in split(text):
		note_heard(line)
		var s := stream(line_file(line))
		if s == null and not out.is_empty() and out[-1].stream == null:
			out[-1].text += " " + line
		else:
			out.append({"text": line, "stream": s})
	return out


func note_heard(line: String) -> void:
	var key := normalize(line)
	if key == "":
		return
	if heard.has(key):
		heard[key].n += 1
	elif heard.size() < MAX_HEARD:
		heard[key] = {"text": display(line), "n": 1}
	_dirty = true


func save_heard() -> void:
	if not _dirty:
		return
	_dirty = false
	var f := FileAccess.open(base_dir + "/heard.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(heard))


## Lines for the recording booth, best first: the starter script (the pets' own
## words), then lines the game has spoken, most heard first. Lines that name a
## pet come last, because they only fit that one pet.
## Each entry: {"text", "recorded"}.
func booth_lines(starter: Array, pet_names: Array) -> Array:
	var out := []
	var seen := {}
	for raw in starter:
		for line in split(raw):
			var key := normalize(line)
			if not seen.has(key):
				seen[key] = true
				out.append({"text": display(line), "recorded": has_line(line)})
	var rest := []
	for key in heard:
		if not seen.has(key):
			var named := false
			for n in pet_names:
				if (" " + key + " ").contains(" " + normalize(n) + " "):
					named = true
			rest.append({"text": heard[key].text, "recorded": has_line(heard[key].text), "n": int(heard[key].n), "named": named})
	rest.sort_custom(func(a, b):
		if a.named != b.named:
			return b.named
		return a.n > b.n)
	return out + rest


# ------------------------------------------------------------ audio ----

## Tidies a fresh microphone take: mono, smaller, silence trimmed from both
## ends, volume evened out. Returns null when nothing was really recorded.
static func clean(take: AudioStreamWAV) -> AudioStreamWAV:
	if take == null or take.format != AudioStreamWAV.FORMAT_16_BITS:
		return null
	var data := take.data
	var channels := 2 if take.stereo else 1
	var step := maxi(1, roundi(float(take.mix_rate) / TARGET_RATE))
	var frame_bytes := 2 * channels
	var count := data.size() / (frame_bytes * step)
	if count < 10:
		return null
	var samples := PackedFloat32Array()
	samples.resize(count)
	var peak := 0.0
	for i in count:
		var sum := 0.0
		var at := i * step * frame_bytes
		for j in step * channels:
			sum += data.decode_s16(at + j * 2)
		var v := sum / (step * channels * 32768.0)
		samples[i] = v
		peak = maxf(peak, absf(v))
	if peak < 0.02:
		return null
	var rate := take.mix_rate / step
	var quiet := maxf(0.03, peak * 0.08)
	var first := 0
	while first < count and absf(samples[first]) < quiet:
		first += 1
	var last := count - 1
	while last > first and absf(samples[last]) < quiet:
		last -= 1
	first = maxi(0, first - int(rate * 0.06))
	last = mini(count - 1, last + int(rate * 0.18))
	if last - first < int(rate * 0.12):
		return null
	var gain := minf(0.9 / peak, 6.0)
	var bytes := PackedByteArray()
	bytes.resize((last - first + 1) * 2)
	for i in range(first, last + 1):
		bytes.encode_s16((i - first) * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.mix_rate = rate
	wav.data = bytes
	return wav
