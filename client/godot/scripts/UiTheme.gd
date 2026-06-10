class_name UiTheme
extends RefCounted

# 全平台中文字体回退链（macOS / Windows / Android / Linux）
static func cjk_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray([
		"PingFang SC", "Hiragino Sans GB", "STHeiti",
		"Microsoft YaHei", "Noto Sans CJK SC", "Noto Sans", "Arial Unicode MS",
	])
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	return f

static func build() -> Theme:
	var t := Theme.new()
	t.default_font = cjk_font()
	t.default_font_size = 22

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.10, 0.13, 0.20, 0.92)
	panel.set_corner_radius_all(10)
	panel.set_border_width_all(2)
	panel.border_color = Color(0.55, 0.65, 0.85, 0.9)
	panel.set_content_margin_all(12)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel.duplicate())

	# 对话框：宝可梦式白底深字
	var dlg := StyleBoxFlat.new()
	dlg.bg_color = Color(0.98, 0.98, 0.95, 0.98)
	dlg.set_corner_radius_all(12)
	dlg.set_border_width_all(3)
	dlg.border_color = Color(0.25, 0.30, 0.45)
	dlg.set_content_margin_all(16)
	t.set_type_variation("DialogPanel", "PanelContainer")
	t.set_stylebox("panel", "DialogPanel", dlg)

	# 按钮
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(0.16, 0.22, 0.34)
	btn.set_corner_radius_all(8)
	btn.set_border_width_all(2)
	btn.border_color = Color(0.45, 0.55, 0.75)
	btn.set_content_margin_all(8)
	var btn_hover: StyleBoxFlat = btn.duplicate()
	btn_hover.bg_color = Color(0.24, 0.33, 0.50)
	var btn_press: StyleBoxFlat = btn.duplicate()
	btn_press.bg_color = Color(0.12, 0.16, 0.25)
	var btn_focus: StyleBoxFlat = btn.duplicate()
	btn_focus.border_color = Color(1.0, 0.85, 0.3)
	btn_focus.bg_color = Color(0.24, 0.33, 0.50)
	t.set_stylebox("normal", "Button", btn)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_press)
	t.set_stylebox("focus", "Button", btn_focus)
	t.set_color("font_color", "Button", Color(0.92, 0.95, 1.0))
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_focus_color", "Button", Color(1, 0.95, 0.75))

	# 血条
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.15, 0.17, 0.20)
	hp_bg.set_corner_radius_all(5)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.30, 0.85, 0.40)
	hp_fill.set_corner_radius_all(5)
	t.set_stylebox("background", "ProgressBar", hp_bg)
	t.set_stylebox("fill", "ProgressBar", hp_fill)

	return t
