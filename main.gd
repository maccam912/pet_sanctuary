extends Node
## Entry point: swaps between the title screen and the sanctuary.

var current: Node


func _ready() -> void:
	get_tree().auto_accept_quit = true
	show_title()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autopilot"):
			var pilot: Node = load("res://tests/autopilot.gd").new()
			pilot.main = self
			pilot.out_dir = arg.get_slice("=", 1)
			add_child(pilot)


func _swap(node: Node) -> void:
	if current:
		current.queue_free()
	current = node
	add_child(node)


func show_title() -> void:
	Game.close_game()
	var t := TitleScreen.new()
	t.play_slot.connect(_on_play_slot)
	_swap(t)


func _on_play_slot(slot: int, is_new: bool) -> void:
	if is_new:
		Game.new_game(slot)
	elif not Game.load_game(slot):
		return
	var s := Sanctuary.new()
	s.quit_to_title.connect(show_title)
	_swap(s)
