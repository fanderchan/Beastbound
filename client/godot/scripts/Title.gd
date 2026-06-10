class_name TitleScreen
extends Control
# 标题画面

signal start_game

var _blink_t := 0.0
var _hint: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	theme = UiTheme.build()

	var bg_path := "res://assets/bg/title.png"
	if ResourceLoader.exists(bg_path):
		var tr := TextureRect.new()
		tr.texture = load(bg_path)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(tr)
	else:
		var grad := ColorRect.new()
		grad.color = Color(0.12, 0.25, 0.40)
		grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(grad)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.05, 0.18)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	add_child(vbox)

	var title := Label.new()
	title.text = "宝可梦·青叶物语"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 86)
	title.add_theme_color_override("font_color", Color(1, 0.97, 0.85))
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.22, 0.35, 0.95))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "—— 青叶镇的小小训练家 ——"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	sub.add_theme_constant_override("outline_size", 8)
	sub.add_theme_color_override("font_outline_color", Color(0.15, 0.22, 0.35, 0.9))
	vbox.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(spacer)

	_hint = Label.new()
	_hint.text = "按 Z / 回车 / 空格 开始冒险"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 30)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1))
	_hint.add_theme_constant_override("outline_size", 8)
	_hint.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.2, 0.9))
	vbox.add_child(_hint)

	var tip := Label.new()
	tip.text = "WASD/方向键 移动 · Z 确认/对话 · X 取消"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tip.offset_top = -48
	tip.offset_bottom = -16
	tip.add_theme_font_size_override("font_size", 20)
	tip.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 0.85))
	tip.add_theme_constant_override("outline_size", 6)
	tip.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.2, 0.8))
	add_child(tip)

func _process(delta: float) -> void:
	_blink_t += delta
	_hint.modulate.a = 0.45 + 0.55 * absf(sin(_blink_t * 2.5))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		start_game.emit()
