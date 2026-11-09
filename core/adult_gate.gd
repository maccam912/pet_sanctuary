class_name AdultGate
extends RefCounted
## Keeps the grown-ups area for grown-ups: a multiplication question a young
## child can't answer, or a 4-digit PIN once an adult has set one.


static func make_challenge(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(12, 19)
	var b := rng.randi_range(6, 9)
	return {"question": "%d × %d" % [a, b], "answer": a * b}


static func check_answer(challenge: Dictionary, typed: String) -> bool:
	return typed.is_valid_int() and int(typed) == int(challenge.answer)


static func hash_pin(pin: String) -> String:
	return ("sunny-paws:" + pin).sha256_text()


static func valid_pin(pin: String) -> bool:
	return pin.length() == 4 and pin.is_valid_int()


static func check_pin(pin_hash: String, typed: String) -> bool:
	return pin_hash != "" and hash_pin(typed) == pin_hash
