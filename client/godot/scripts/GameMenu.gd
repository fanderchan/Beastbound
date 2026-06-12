class_name GameMenu
extends Control
# 游戏内菜单：宝可梦 / 背包 / 图鉴 / 保存

signal closed

var world_cell := Vector2i.ZERO
var content: VBoxContainer
var info_lbl: Label
var _pending_item := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	theme = UiTheme.build()

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.03, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.theme_type_variation = "DialogPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(880, 560)
	panel.position = Vector2(200, 80)
	add_child(panel)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	panel.add_child(h)

	var tabs := VBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	tabs.custom_minimum_size = Vector2(170, 0)
	h.add_child(tabs)
	for item in [["宝可梦", _show_party], ["背包", _show_bag], ["图鉴", _show_dex], ["保存", _do_save], ["关闭", _close]]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(160, 48)
		b.pressed.connect(item[1])
		tabs.add_child(b)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	info_lbl = Label.new()
	info_lbl.add_theme_font_size_override("font_size", 20)
	info_lbl.add_theme_color_override("font_color", Color(0.25, 0.3, 0.42))
	right.add_child(info_lbl)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	_show_party()
	(tabs.get_child(0) as Button).grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	closed.emit()
	queue_free()

func _clear_content() -> void:
	_pending_item = ""
	for c in content.get_children():
		c.queue_free()

func _mon_row_text(p: Dictionary) -> String:
	var st := str(p.get("status", ""))
	var st_txt: String = "（%s）" % Db.STATUS_NAMES[st] if st != "" else ""
	var types: Array = Db.species(str(p.species)).get("types", [])
	return "%s %s Lv.%d%s\nHP %d/%d　EXP %d/%d" % [
		p.name, "/".join(types), int(p.level), st_txt,
		int(p.hp), int(p.stats.maxhp), int(p.exp), Game.exp_to_next(int(p.level))]

# ===== 宝可梦 =====
func _show_party() -> void:
	_clear_content()
	info_lbl.text = "队伍（%d/6）" % Game.party.size()
	for p in Game.party:
		var lbl := Label.new()
		lbl.text = _mon_row_text(p)
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0.15, 0.18, 0.3))
		content.add_child(lbl)
		var sep := HSeparator.new()
		content.add_child(sep)

# ===== 背包 =====
func _show_bag() -> void:
	_clear_content()
	info_lbl.text = "背包　所持金：%d 元" % Game.money
	var any := false
	for id in Db.ITEMS:
		var cnt := int(Game.bag.get(id, 0))
		if cnt <= 0:
			continue
		any = true
		var item: Dictionary = Db.ITEMS[id]
		var b := Button.new()
		b.text = "%s ×%d　%s" % [item.name, cnt, item.desc]
		b.custom_minimum_size = Vector2(0, 44)
		var usable: bool = item.has("heal") or item.has("cure")
		b.disabled = not usable
		var iid := str(id)
		b.pressed.connect(func() -> void: _pick_target(iid))
		content.add_child(b)
	if not any:
		var lbl := Label.new()
		lbl.text = "背包空空如也。"
		lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
		content.add_child(lbl)

func _pick_target(item_id: String) -> void:
	_clear_content()
	_pending_item = item_id
	info_lbl.text = "对哪只宝可梦使用 %s？" % Db.ITEMS[item_id].name
	for i in Game.party.size():
		var p: Dictionary = Game.party[i]
		var b := Button.new()
		b.text = _mon_row_text(p).replace("\n", "　")
		b.custom_minimum_size = Vector2(0, 44)
		var idx := i
		b.pressed.connect(func() -> void: _use_on(idx))
		content.add_child(b)
	var back := Button.new()
	back.text = "返回"
	back.pressed.connect(_show_bag)
	content.add_child(back)

func _use_on(idx: int) -> void:
	var item: Dictionary = Db.ITEMS[_pending_item]
	var p: Dictionary = Game.party[idx]
	var used := false
	if item.has("heal") and int(p.hp) > 0 and int(p.hp) < int(p.stats.maxhp):
		p.hp = mini(int(p.hp) + int(item.heal), int(p.stats.maxhp))
		used = true
	elif item.has("cure") and str(p.get("status", "")) != "":
		p.status = ""
		used = true
	if used:
		Game.bag[_pending_item] = int(Game.bag[_pending_item]) - 1
		info_lbl.text = "%s 使用了 %s！" % [p.name, item.name]
		_pending_item = ""
		_show_bag.call_deferred()
	else:
		info_lbl.text = "没有效果……"

# ===== 图鉴 =====
func _show_dex() -> void:
	_clear_content()
	var caught := Game.dex_caught.size()
	var seen := Game.dex_seen.size()
	info_lbl.text = "青叶图鉴　捕获 %d / 目击 %d / 共 %d 种" % [caught, seen, Db.DEX_ORDER.size()]
	for sid in Db.DEX_ORDER:
		var sp := Db.species(sid)
		var lbl := Label.new()
		var line: String
		if Game.dex_caught.has(sid):
			line = "No.%02d ● %s（%s）\n%s" % [int(sp.dex), sp.name, "/".join(sp.types), sp.desc]
		elif Game.dex_seen.has(sid):
			line = "No.%02d ○ %s（%s）" % [int(sp.dex), sp.name, "/".join(sp.types)]
		else:
			line = "No.%02d ？？？" % int(sp.dex)
		lbl.text = line
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(0.15, 0.18, 0.3))
		content.add_child(lbl)

# ===== 保存 =====
func _do_save() -> void:
	_clear_content()
	if Game.save_game(world_cell):
		info_lbl.text = "已保存！随时可以从标题画面继续冒险。"
	else:
		info_lbl.text = "保存失败……"
