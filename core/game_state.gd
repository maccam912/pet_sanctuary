class_name GameState
extends RefCounted
## Everything stored in one save slot. Plain data with to_dict / from_dict.

const VERSION := 1

var hearts := 0
var pets: Array = []            # [{species, name, friendship, look}]
var techniques := {}            # id -> {stage, count}
var recent_scenarios: Array = []  # ids, newest last
var moments_done := 0
var arrivals_done := 0
var garden: Array = []          # [{stage, t}] t = seconds grown at this stage
var activity_plays := {}        # activity id -> times played
var last_frustration_play := {} # activity id -> play number of last staged setback
var play_seconds := 0.0
var created := ""
var last_played := ""

## Numbers for the grown-ups page.
var stats := {
	"emotion_right": 0, "emotion_total": 0,
	"impulse_picked": 0, "tool_picked_first": 0,
	"by_emotion": {},        # emotion -> moments helped
	"child_checkins": [],    # last 30 self-rated feeling sizes, [before, after]
	"frustration_events": 0,
}

## Grown-up settings, saved per child.
var adult := {
	"frustration_level": 1,  # 0 off, 1 gentle, 2 medium, 3 lots
	"frequency": 1,          # feelings moments: 0 fewer, 1 normal, 2 more
	"auto_progress": true,   # skills move up stages on their own
	"session_minutes": 0,    # 0 = no reminder
	"focus": {},             # emotion -> false to leave out
	"child_checkin": true,   # ask the child about their own feeling size
}


static func new_game() -> GameState:
	var s := GameState.new()
	for sp in Content.STARTER_SPECIES:
		s.pets.append({"species": sp, "name": Content.SPECIES[sp], "friendship": 0, "look": ""})
	for id in Content.TECHNIQUE_ORDER:
		s.techniques[id] = {"stage": Content.STAGE_LOCKED, "count": 0}
	s.techniques["balloon"].stage = Content.STAGE_LEARNING
	for i in 6:
		s.garden.append({"stage": 0, "t": 0.0})
	s.created = Time.get_datetime_string_from_system()
	s.last_played = s.created
	return s


func to_dict() -> Dictionary:
	return {
		"version": VERSION, "hearts": hearts, "pets": pets, "techniques": techniques,
		"recent_scenarios": recent_scenarios, "moments_done": moments_done,
		"arrivals_done": arrivals_done, "garden": garden,
		"activity_plays": activity_plays, "last_frustration_play": last_frustration_play,
		"play_seconds": play_seconds, "created": created, "last_played": last_played,
		"stats": stats, "adult": adult,
	}


## Tolerant loader: missing keys keep their defaults so old saves keep working.
static func from_dict(d: Dictionary) -> GameState:
	var s := new_game()
	s.hearts = int(d.get("hearts", 0))
	var loaded_pets := []
	if d.get("pets") is Array:
		for p in d.pets:
			if p is Dictionary and Content.SPECIES.has(p.get("species", "")):
				var look := str(p.get("look", ""))
				loaded_pets.append({"species": p.species, "name": str(p.get("name", Content.SPECIES[p.species])),
					"friendship": int(p.get("friendship", 0)), "look": look if Content.LOOKS.has(look) else ""})
	if not loaded_pets.is_empty():
		s.pets = loaded_pets
	var t: Dictionary = d.get("techniques", {})
	for id in t:
		if s.techniques.has(id):
			s.techniques[id] = {"stage": clampi(int(t[id].get("stage", 0)), 0, 3), "count": int(t[id].get("count", 0))}
	s.recent_scenarios = d.get("recent_scenarios", [])
	s.moments_done = int(d.get("moments_done", 0))
	s.arrivals_done = int(d.get("arrivals_done", 0))
	var g: Array = d.get("garden", [])
	for i in mini(g.size(), s.garden.size()):
		s.garden[i] = {"stage": int(g[i].get("stage", 0)), "t": float(g[i].get("t", 0.0))}
	s.activity_plays = d.get("activity_plays", {})
	s.last_frustration_play = d.get("last_frustration_play", {})
	s.play_seconds = float(d.get("play_seconds", 0.0))
	s.created = str(d.get("created", s.created))
	s.last_played = str(d.get("last_played", s.last_played))
	var st: Dictionary = d.get("stats", {})
	for k in st:
		s.stats[k] = st[k]
	var ad: Dictionary = d.get("adult", {})
	for k in ad:
		if s.adult.has(k):
			s.adult[k] = ad[k]
	s.adult.frustration_level = clampi(int(s.adult.frustration_level), 0, 3)
	s.adult.frequency = clampi(int(s.adult.frequency), 0, 2)
	s.adult.session_minutes = int(s.adult.session_minutes)
	return s


func stage_of(tech: String) -> int:
	return int(techniques[tech].stage)


func count_of(tech: String) -> int:
	return int(techniques[tech].count)


func has_pet(sp: String, look := "") -> bool:
	for p in pets:
		if p.species == sp and p.get("look", "") == look:
			return true
	return false


## Pets still out there to invite (every animal in every look).
func roster_left() -> int:
	return Content.roster_size() - pets.size()


## Hearts for the next new friend. Each friend costs more than the last, so a
## new arrival stays a big event: about one or two a play session, not a stream.
func arrival_cost() -> int:
	return mini(30 + 15 * maxi(0, pets.size() - Content.STARTER_SPECIES.size()), 150)


func can_welcome() -> bool:
	return roster_left() > 0 and hearts >= arrival_cost()


func name_taken(pet_name: String) -> bool:
	for p in pets:
		if str(p.name).to_lower() == pet_name.to_lower():
			return true
	return false


## Keeps a typed name short and safe to drop into story text.
static func clean_name(typed: String, fallback: String) -> String:
	var out := ""
	for ch in typed.strip_edges():
		if ch in "{}%\"\\\n\t":
			continue
		out += ch
	out = out.substr(0, 12).strip_edges()
	return out if out != "" else fallback


func add_pet(sp: String, look := "", pet_name := "") -> Dictionary:
	var p := {"species": sp, "name": clean_name(pet_name, Content.SPECIES[sp]), "friendship": 0, "look": look}
	pets.append(p)
	arrivals_done += 1
	return p


func focus_enabled(emotion: String) -> bool:
	return bool(adult.focus.get(emotion, true))


func playtime_text() -> String:
	var m := int(play_seconds / 60.0)
	if m < 60:
		return "%d min" % m
	return "%d h %d min" % [m / 60, m % 60]
