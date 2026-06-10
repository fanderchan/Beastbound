class_name DialogBox
extends PanelContainer
# 宝可梦式底部对话框：打字机文本 + 选项分支

signal finished
signal chosen(index: int)

var _lines: Array = []
var _line_idx := 0
var _char_t := 0.0
var _typing := false
var _label: Label
var _arrow: Label
var _choice_box: VBoxContainer
var _buttons: Array = []
const CPS := 45.0

func _init() -> void:
	theme_type_variation = "DialogPanel"
	custom_minimum_size = Vector2(0, 132)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var margin := MarginContainer.new()
	add_child(margin)
	var hbox := HBoxContainer.new()
	margin.add_child(hbox)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.add_theme_color_override("font_color", Color(0.13, 0.15, 0.22))
	_label.add_theme_font_size_override("font_size", 26)
	hbox.add_child(_label)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 6)
	_choice_box.visible = false
	hbox.add_child(_choice_box)
	_arrow = Label.new()
	_arrow.text = "▼"
	_arrow.add_theme_color_override("font_color", Color(0.25, 0.3, 0.45))
	_arrow.size_flags_vertical = Control.SIZE_SHRINK_END
	hbox.add_child(_arrow)
	visible = false

func is_busy() -> bool:
	return visible

func show_lines(lines: Array) -> void:
	_lines = lines.duplicate()
	_line_idx = 0
	_clear_choices()
	visible = true
	_start_line()

# options: Array[String]
func show_choice(prompt: String, options: Array) -> void:
	_lines = [prompt]
	_line_idx = 0
	visible = true
	_label.text = prompt
	_typing = false
	_arrow.visible = false
	_clear_choices()
	_choice_box.visible = true
	for i in options.size():
		var b := Button.new()
		b.text = options[i]
		b.custom_minimum_size = Vector2(220, 0)
		b.pressed.connect(func() -> void: _on_choice(i))
		_choice_box.add_child(b)
		_buttons.append(b)
	if _buttons.size() > 0:
		(_buttons[0] as Button).grab_focus()

func _clear_choices() -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	_choice_box.visible = false

func _on_choice(i: int) -> void:
	visible = false
	_clear_choices()
	chosen.emit(i)

func _start_line() -> void:
	_char_t = 0.0
	_typing = true
	_label.text = ""
	_arrow.visible = false

func _process(delta: float) -> void:
	if not visible or _choice_box.visible:
		return
	if _typing:
		_char_t += delta * CPS
		var full: String = str(_lines[_line_idx])
		var n: int = mini(int(_char_t), full.length())
		_label.text = full.substr(0, n)
		if n >= full.length():
			_typing = false
			_arrow.visible = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _choice_box.visible:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		_advance()
		get_viewport().set_input_as_handled()

func _advance() -> void:
	if not visible or _choice_box.visible:
		return
	if _typing:
		_typing = false
		_label.text = str(_lines[_line_idx])
		_arrow.visible = true
		return
	_line_idx += 1
	if _line_idx >= _lines.size():
		visible = false
		finished.emit()
	else:
		_start_line()
