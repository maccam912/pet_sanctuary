class_name Technique
extends Control
## Base for the calm-down mini-exercises. The child does the exercise WITH the
## pet: every exercise drives the close-up pet (stage) so they move together.

signal done

var flow: FeelingsFlow
var stage: PetStage
var pet_name := "the pet"
var friend_name := ""
var skill_stage := Content.STAGE_LEARNING
var scenario := {}
var _finished := false


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 400)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	begin()


func begin() -> void:
	pass


## True once the pet "knows" the tool: fewer repetitions, fewer words.
func learned() -> bool:
	return skill_stage >= Content.STAGE_LEARNED


func tell(text: String, speak := true) -> void:
	if flow:
		flow.set_prompt(text, speak)


func finish() -> void:
	if _finished:
		return
	_finished = true
	if stage:
		stage.breath = 1.0
		stage.shake = 0.0
		stage.squash = 1.0
	Sfx.play("great")
	await get_tree().create_timer(0.6).timeout
	done.emit()


## Is this event a press (true) / release (false) of finger or mouse? Else null.
static func press_state(event: InputEvent) -> Variant:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		return event.pressed
	return null


func progress_dots(total: int, filled: int, color: Color) -> void:
	var gap := 44.0
	var start := Vector2(size.x / 2.0 - gap * (total - 1) / 2.0, size.y - 26.0)
	for i in total:
		draw_circle(start + Vector2(gap * i, 0), 15.0, UI.INK_SOFT.lightened(0.5))
		draw_circle(start + Vector2(gap * i, 0), 12.0, color if i < filled else UI.WHITE)
