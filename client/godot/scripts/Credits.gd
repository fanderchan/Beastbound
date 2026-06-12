class_name CreditsScreen
extends Control
# 通关结局：滚动制作名单

signal finished

const LINES := [
	"",
	"宝可梦·青叶物语",
	"",
	"—— 制作名单 ——",
	"",
	"企划 / 程序 / 美术",
	"Cursor Agent",
	"",
	"制作人",
	"fanderchan",
	"",
	"原创宝可梦设计",
	"叶芽犬 · 叶冠犬",
	"炎尾狐 · 炎魄狐",
	"水灵螈 · 澜尾螈",
	"绒绒鼠 · 啾啾雀 · 菇菇虫",
	"石拳蟹 · 电光鼬 · 波纹蛙",
	"夜翎枭 · 熔岩蜥 · 岩盾龟",
	"雷鸣鹰",
	"",
	"特别感谢",
	"每一位陪伴宝可梦长大的训练家",
	"",
	"",
	"你的冒险还在继续——",
	"",
	"THE END",
]

var scroller: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	theme = UiTheme.build()

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	scroller = VBoxContainer.new()
	scroller.add_theme_constant_override("separation", 14)
	scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroller)
	scroller.custom_minimum_size = Vector2(size.x, 0)
	for line in LINES:
		var lbl := Label.new()
		lbl.text = line
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 30 if line == "宝可梦·青叶物语" or line == "THE END" else 22)
		lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.9))
		scroller.add_child(lbl)
	scroller.position = Vector2(0, size.y)

	var total := LINES.size() * 38.0 + size.y
	var tw := create_tween()
	tw.tween_property(scroller, "position:y", -total + size.y * 0.6, 26.0)
	tw.tween_interval(2.0)
	tw.tween_callback(func() -> void: finished.emit())

func _unhandled_input(event: InputEvent) -> void:
	# 任意确认键跳过
	if event.is_action_pressed("confirm") and Input.is_action_pressed("cancel"):
		finished.emit()
