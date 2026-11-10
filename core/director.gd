class_name Director
extends RefCounted
## The teaching brain of the game: decides which feeling scenario comes next,
## which coping tools to offer, how skills move through stages, and when an
## activity stages a small setback. Pure logic: pass in a GameState and an RNG.

const MOMENT_DELAYS := [420.0, 270.0, 150.0]       # seconds, by adult "frequency"
const FRUSTRATION_CHANCE := [0.0, 0.12, 0.25, 0.45]  # by adult "frustration_level"
const LEARN_TO_PRACTICE := 3   # practices before Learning -> Practicing
const PRACTICE_TO_LEARNED := 9 # practices before Practicing -> Learned
const RECENT_MEMORY := 6
const TRAIT_STORY_CHANCE := 0.5
const OFFERS := 3  # animals to choose between when a new friend arrives


## Seconds of play until the next pet needs help.
static func next_moment_delay(state: GameState, rng: RandomNumberGenerator) -> float:
	var base: float = MOMENT_DELAYS[state.adult.frequency]
	if state.moments_done == 0:
		base = 45.0  # the first one comes quickly so the game shows what it is about
	return base * rng.randf_range(0.8, 1.2)


static func unlocked_techniques(state: GameState) -> Array:
	var out := []
	for id in Content.TECHNIQUE_ORDER:
		if state.stage_of(id) > Content.STAGE_LOCKED:
			out.append(id)
	return out


## Scenario for a regular feelings moment. Skips recently seen ones, feelings the
## adult switched off, and scenarios no unlocked tool fits.
## `pet_trait` is the trait of the pet the story is for: "perfect" pets get a
## perfectionism story about half the time, and other pets never do.
static func pick_scenario(state: GameState, rng: RandomNumberGenerator, tag := "", pet_trait := "") -> Dictionary:
	if tag != "":
		for s in Content.SCENARIOS:
			if s.get("tag", "") == tag:
				return s
	var unlocked := unlocked_techniques(state)
	var pool := []
	var fallback := []
	var own := []  # fresh stories written for this pet's trait
	for s in Content.all_scenarios():
		if s.has("tag") or s.get("trait", pet_trait) != pet_trait:
			continue
		if not _any_tool_fits(unlocked, s.emotion):
			continue
		fallback.append(s)
		if state.recent_scenarios.has(s.id) or not state.focus_enabled(s.emotion):
			continue
		pool.append(s)
		if s.has("trait"):
			own.append(s)
	if not own.is_empty() and rng.randf() < TRAIT_STORY_CHANCE:
		pool = own
	if pool.is_empty():
		for s in fallback:
			if state.focus_enabled(s.emotion):
				pool.append(s)
	if pool.is_empty():
		pool = fallback
	if pool.is_empty():
		pool = Content.SCENARIOS.filter(func(s): return not s.has("tag"))
	return pool[rng.randi() % pool.size()]


## The animals the child can choose between for the next arrival: mostly
## everyday animals, plus one in a special colour. Stays the same until a pet
## is welcomed, so closing and reopening the picker does not re-roll it.
static func arrival_offers(state: GameState) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(state.created) + state.arrivals_done * 7919
	var plain := []
	var special := []
	for sp in Content.SPECIES:
		if not state.has_pet(sp):
			plain.append({"species": sp, "look": ""})
		for look in Content.LOOK_ORDER:
			if not state.has_pet(sp, look):
				special.append({"species": sp, "look": look})
	_shuffle(plain, rng)
	_shuffle(special, rng)
	var out: Array = plain.slice(0, OFFERS - 1)
	for o in special:
		if out.size() >= OFFERS:
			break
		# Three different animals to choose from, never the same one twice.
		if not out.any(func(x): return x.species == o.species):
			out.append(o)
	var names: Array = Content.EXTRA_NAMES.duplicate()
	_shuffle(names, rng)
	for o in out:
		o.name = Content.SPECIES[o.species]
		if o.look != "" or state.name_taken(o.name):
			for n in names:
				if not state.name_taken(n) and not out.any(func(x): return x.get("name", "") == n):
					o.name = n
					break
	return out


static func _any_tool_fits(unlocked: Array, emotion: String) -> bool:
	for id in unlocked:
		if Content.TECHNIQUES[id]["for"].has(emotion):
			return true
	return false


static func remember_scenario(state: GameState, id: String) -> void:
	state.recent_scenarios.append(id)
	while state.recent_scenarios.size() > RECENT_MEMORY:
		state.recent_scenarios.pop_front()


## Feeling choices for "how does the pet feel?": the right one plus two others.
static func emotion_choices(scenario: Dictionary, rng: RandomNumberGenerator) -> Array:
	var wrong := []
	for e in Content.BIG_FEELINGS:
		if e != scenario.emotion and not scenario.also.has(e):
			wrong.append(e)
	_shuffle(wrong, rng)
	var out := [scenario.emotion, wrong[0], wrong[1]]
	_shuffle(out, rng)
	return out


static func emotion_is_right(scenario: Dictionary, pick: String) -> bool:
	return pick == scenario.emotion or scenario.also.has(pick)


## Tools offered for this feeling (max `n`). Tools still being learned come
## first so they get the practice; `exclude` drops tools already used this moment.
static func tool_choices(state: GameState, emotion: String, rng: RandomNumberGenerator, n := 2, exclude: Array = []) -> Array:
	var learning := []
	var others := []
	for id in unlocked_techniques(state):
		if exclude.has(id) or not Content.TECHNIQUES[id]["for"].has(emotion):
			continue
		if state.stage_of(id) == Content.STAGE_LEARNING:
			learning.append(id)
		else:
			others.append(id)
	_shuffle(learning, rng)
	_shuffle(others, rng)
	var out := learning + others
	if out.is_empty():
		# Nothing fits (adult locked a lot): breathing always works.
		for id in unlocked_techniques(state):
			if not exclude.has(id):
				out.append(id)
		if out.is_empty():
			out = ["balloon"]
	return out.slice(0, n)


## A pet that has "learned" a tool often asks for it by itself, so the child
## shifts from teacher to practice buddy.
static func pet_initiates(state: GameState, tool_id: String, rng: RandomNumberGenerator) -> bool:
	return state.stage_of(tool_id) == Content.STAGE_LEARNED and rng.randf() < 0.6


## Record one finished practice. Returns what changed:
## {"stage_up": bool, "unlocked": id or ""}.
static func record_practice(state: GameState, tool_id: String) -> Dictionary:
	var result := {"stage_up": false, "unlocked": ""}
	var t: Dictionary = state.techniques[tool_id]
	t.count = int(t.count) + 1
	if state.adult.auto_progress:
		if t.stage == Content.STAGE_LEARNING and t.count >= LEARN_TO_PRACTICE:
			t.stage = Content.STAGE_PRACTICE
			result.stage_up = true
		elif t.stage == Content.STAGE_PRACTICE and t.count >= PRACTICE_TO_LEARNED:
			t.stage = Content.STAGE_LEARNED
			result.stage_up = true
		result.unlocked = maybe_unlock(state)
	return result


## Introduce the next tool once every tool so far has left the Learning stage,
## so only one new thing is being learned at a time.
static func maybe_unlock(state: GameState) -> String:
	for id in Content.TECHNIQUE_ORDER:
		if state.stage_of(id) == Content.STAGE_LEARNING:
			return ""
	for id in Content.TECHNIQUE_ORDER:
		if state.stage_of(id) == Content.STAGE_LOCKED:
			state.techniques[id].stage = Content.STAGE_LEARNING
			return id
	return ""


## Should this play of an activity include a staged setback (tower wobble,
## cards shuffled...)? Never on the first two plays, never two plays in a row.
static func frustration_event(state: GameState, activity: String, rng: RandomNumberGenerator) -> bool:
	var plays := int(state.activity_plays.get(activity, 0))
	if plays < 2:
		return false
	if int(state.last_frustration_play.get(activity, -10)) >= plays - 1:
		return false
	if rng.randf() >= FRUSTRATION_CHANCE[state.adult.frustration_level]:
		return false
	state.last_frustration_play[activity] = plays
	state.stats.frustration_events = int(state.stats.frustration_events) + 1
	return true


static func note_activity_play(state: GameState, activity: String) -> void:
	state.activity_plays[activity] = int(state.activity_plays.get(activity, 0)) + 1


## How far the feeling thermometer drops after one tool. Big and HUGE feelings
## only come down one step, so they need a second tool: one is not always enough.
static func level_after_tool(level: int) -> int:
	return maxi(1, level - (1 if level >= 4 else 2))


static func finish_moment(state: GameState, scenario: Dictionary, pet_index: int) -> int:
	state.moments_done += 1
	var be: Dictionary = state.stats.by_emotion
	be[scenario.emotion] = int(be.get(scenario.emotion, 0)) + 1
	if pet_index >= 0 and pet_index < state.pets.size():
		state.pets[pet_index].friendship = int(state.pets[pet_index].friendship) + 2
	if scenario.id != "activity":
		remember_scenario(state, scenario.id)
	var reward := 8
	state.hearts += reward
	return reward


static func note_child_checkin(state: GameState, before: int, after: int) -> void:
	var list: Array = state.stats.child_checkins
	list.append([before, after])
	while list.size() > 30:
		list.pop_front()


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
