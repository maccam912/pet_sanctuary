class_name UpdatePanel
extends Control
## Grown-ups screen for a newer build (opened through AdultGateDialog from the
## title screen). On Android it downloads the APK and opens Android's installer;
## on a computer it opens the release page.

const FIRST_TIME := "First time only: Android asks to allow installs from Sunny Paws. Tap Settings, switch on \"Allow from this source\", then come back here and tap Try again."

var _android := true
var _status: Label
var _bar: ProgressBar
var _buttons: HBoxContainer


func _init(android := Updates.can_install()) -> void:
	_android = android


func _ready() -> void:
	UI.full(self)
	theme = UI.theme()
	add_child(UI.backdrop())
	var v := UI.vbox(16)
	v.add_child(UI.label("Build %d is ready" % Updates.available.build, 36))
	var have := UpdateCheck.this_build()
	v.add_child(UI.label(("You have build %d. " % have if have > 0 else "") + "Saves and recordings stay.", 24, UI.INK_SOFT))
	_status = UI.text("", 24)
	v.add_child(_status)
	_bar = ProgressBar.new()
	_bar.max_value = 1.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 36)
	v.add_child(_bar)
	_buttons = UI.hbox(14)
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_buttons)
	add_child(UI.centered(v, Vector2(720, 0)))
	Updates.changed.connect(_refresh)
	_refresh()


func _process(_delta: float) -> void:
	if Updates.state == "downloading":
		_bar.value = Updates.fraction()
		_status.text = "Downloading... %d%%" % roundi(_bar.value * 100.0)


func _refresh() -> void:
	for b in _buttons.get_children():
		b.queue_free()
	_bar.visible = Updates.state == "downloading"
	match Updates.state:
		"downloading":
			_status.text = "Downloading..."
			_button("Cancel", UI.PAPER, Updates.cancel)
		"installing":
			_status.text = "Tap Update on Android's screen. " + FIRST_TIME
			_button("Close", UI.PAPER, _close)
			_button("Try again", UI.LEAF, Updates.start)
		"failed":
			_status.text = Updates.error
			_button("Close", UI.PAPER, _close)
			_button("Try again", UI.LEAF, Updates.start)
		_:
			if _android:
				_status.text = "Download it (%d MB), then tap Update when Android asks. %s" % [maxi(1, roundi(Updates.available.size / 1048576.0)), FIRST_TIME]
				_button("Not now", UI.PAPER, _close)
				_button("Update", UI.LEAF, Updates.start)
			else:
				_status.text = "Download it from the release page on GitHub."
				_button("Not now", UI.PAPER, _close)
				_button("Open download page", UI.LEAF, func(): Updates.start(); _close())


func _button(text: String, color: Color, on_press: Callable) -> void:
	var b := UI.button(text, color, 26)
	b.custom_minimum_size = Vector2(200, 76)
	b.pressed.connect(on_press)
	_buttons.add_child(b)


func _close() -> void:
	Updates.cancel()
	queue_free()
