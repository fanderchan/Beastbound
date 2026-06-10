class_name BattleScreen
extends Control
# 回合制战斗：野生遭遇 / 训练家对战

signal finished(result: Dictionary)
signal _advance

enum Menu { NONE, COMMAND, MOVES, BAG, PARTY }

var cfg: Dictionary
var is_trainer := false
var enemy_team: Array = []
var enemy_idx := 0
var my_idx := 0
var enemy: Dictionary          # 敌方当前宝可梦实例
var busy := true
var waiting_msg := false
var menu := Menu.NONE
var result := {"whiteout": false, "beat_rival": false}

var my_spr: TextureRect
var en_spr: TextureRect
var my_panel: PanelContainer
var en_panel: PanelContainer
var my_name: Label
var my_lv: Label
var my_hp_bar: ProgressBar
var my_hp_text: Label
var my_exp_bar: ProgressBar
var en_name: Label
var en_lv: Label
var en_hp_bar: ProgressBar
var msg_label: Label
var msg_arrow: Label
var cmd_box: GridContainer
var moves_box: GridContainer
var sub_box: VBoxContainer
var _theme: Theme

func _init(p_cfg: Dictionary, p_theme: Theme) -> void:
	cfg = p_cfg
	_theme = p_theme

func mon_mine() -> Dictionary:
	return Game.party[my_idx]

func _ready() -> void:
	theme = _theme
	set_anchors_preset(Control.PRESET_FULL_RECT)
	is_trainer = str(cfg.get("kind", "wild")) == "trainer"
	if is_trainer:
		for t in cfg.team:
			enemy_team.append(Game.make_monster(str(t.species), int(t.level)))
	else:
		enemy_team.append(Game.make_monster(str(cfg.species), int(cfg.level)))
	enemy = enemy_team[0]
	my_idx = maxi(Game.first_alive_index(), 0)
	_build_ui()
	_intro()

# ============== UI 构建 ==============
func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = Util.load_tex("res://assets/bg/battle_grass.png", Vector2i(1280, 720), Color(0.55, 0.75, 0.45))
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 敌方
	en_spr = TextureRect.new()
	en_spr.texture = load_mon_tex(enemy)
	en_spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	en_spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	en_spr.size = Vector2(300, 300)
	en_spr.position = Vector2(820, 80)
	add_child(en_spr)

	# 我方（水平镜像）
	my_spr = TextureRect.new()
	my_spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	my_spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	my_spr.flip_h = true
	my_spr.size = Vector2(360, 360)
	my_spr.position = Vector2(150, 230)
	add_child(my_spr)

	# 敌方信息面板
	en_panel = PanelContainer.new()
	en_panel.position = Vector2(48, 42)
	en_panel.custom_minimum_size = Vector2(360, 0)
	add_child(en_panel)
	var ev := VBoxContainer.new()
	en_panel.add_child(ev)
	var eh := HBoxContainer.new()
	ev.add_child(eh)
	en_name = Label.new(); en_name.add_theme_font_size_override("font_size", 26); eh.add_child(en_name)
	var esp := Control.new(); esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; eh.add_child(esp)
	en_lv = Label.new(); en_lv.add_theme_font_size_override("font_size", 22); eh.add_child(en_lv)
	en_hp_bar = ProgressBar.new()
	en_hp_bar.show_percentage = false
	en_hp_bar.custom_minimum_size = Vector2(0, 16)
	ev.add_child(en_hp_bar)

	# 我方信息面板
	my_panel = PanelContainer.new()
	my_panel.position = Vector2(860, 420)
	my_panel.custom_minimum_size = Vector2(372, 0)
	add_child(my_panel)
	var mv := VBoxContainer.new()
	my_panel.add_child(mv)
	var mh := HBoxContainer.new()
	mv.add_child(mh)
	my_name = Label.new(); my_name.add_theme_font_size_override("font_size", 26); mh.add_child(my_name)
	var msp := Control.new(); msp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; mh.add_child(msp)
	my_lv = Label.new(); my_lv.add_theme_font_size_override("font_size", 22); mh.add_child(my_lv)
	my_hp_bar = ProgressBar.new()
	my_hp_bar.show_percentage = false
	my_hp_bar.custom_minimum_size = Vector2(0, 16)
	mv.add_child(my_hp_bar)
	my_hp_text = Label.new()
	my_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	my_hp_text.add_theme_font_size_override("font_size", 18)
	mv.add_child(my_hp_text)
	my_exp_bar = ProgressBar.new()
	my_exp_bar.show_percentage = false
	my_exp_bar.custom_minimum_size = Vector2(0, 6)
	my_exp_bar.add_theme_stylebox_override("fill", _exp_style())
	mv.add_child(my_exp_bar)

	# 底部消息 + 指令区
	var bottom := PanelContainer.new()
	bottom.theme_type_variation = "DialogPanel"
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -150
	add_child(bottom)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 16)
	bottom.add_child(bh)

	var msg_wrap := HBoxContainer.new()
	msg_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(msg_wrap)
	msg_label = Label.new()
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_label.add_theme_color_override("font_color", Color(0.13, 0.15, 0.22))
	msg_label.add_theme_font_size_override("font_size", 25)
	msg_wrap.add_child(msg_label)
	msg_arrow = Label.new()
	msg_arrow.text = "▼"
	msg_arrow.visible = false
	msg_arrow.size_flags_vertical = Control.SIZE_SHRINK_END
	msg_arrow.add_theme_color_override("font_color", Color(0.25, 0.3, 0.45))
	msg_wrap.add_child(msg_arrow)

	cmd_box = GridContainer.new()
	cmd_box.columns = 2
	cmd_box.add_theme_constant_override("h_separation", 10)
	cmd_box.add_theme_constant_override("v_separation", 10)
	bh.add_child(cmd_box)
	for item in [["战斗", _on_fight], ["背包", _on_bag], ["宝可梦", _on_party], ["逃跑", _on_run]]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(150, 44)
		b.pressed.connect(item[1])
		cmd_box.add_child(b)
	cmd_box.visible = false

	moves_box = GridContainer.new()
	moves_box.columns = 2
	moves_box.add_theme_constant_override("h_separation", 10)
	moves_box.add_theme_constant_override("v_separation", 10)
	bh.add_child(moves_box)
	moves_box.visible = false

	sub_box = VBoxContainer.new()
	sub_box.add_theme_constant_override("separation", 8)
	bh.add_child(sub_box)
	sub_box.visible = false

	_refresh_panels()

func _exp_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.35, 0.65, 0.95)
	sb.set_corner_radius_all(3)
	return sb

func load_mon_tex(mon: Dictionary) -> Texture2D:
	return Util.load_tex(str(Db.species(mon.species).get("sprite", "")), Vector2i(220, 220), Color(0.7, 0.7, 0.8))

func _hp_color(ratio: float) -> Color:
	if ratio > 0.5: return Color(0.30, 0.85, 0.40)
	if ratio > 0.2: return Color(0.95, 0.80, 0.25)
	return Color(0.90, 0.30, 0.25)

func _refresh_panels() -> void:
	var m := mon_mine()
	my_name.text = str(m.name)
	my_lv.text = "Lv.%d" % int(m.level)
	my_hp_bar.max_value = int(m.stats.maxhp)
	my_hp_bar.value = int(m.hp)
	my_hp_text.text = "%d / %d" % [int(m.hp), int(m.stats.maxhp)]
	(my_hp_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = _hp_color(float(m.hp) / float(m.stats.maxhp))
	my_exp_bar.max_value = Game.exp_to_next(int(m.level))
	my_exp_bar.value = int(m.exp)
	my_spr.texture = load_mon_tex(m)

	en_name.text = str(enemy.name)
	en_lv.text = "Lv.%d" % int(enemy.level)
	en_hp_bar.max_value = int(enemy.stats.maxhp)
	en_hp_bar.value = int(enemy.hp)
	(en_hp_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = _hp_color(float(enemy.hp) / float(enemy.stats.maxhp))
	en_spr.texture = load_mon_tex(enemy)

# ============== 消息 ==============
func _msg(text: String) -> void:
	msg_label.text = text
	msg_arrow.visible = true
	waiting_msg = true
	await _advance
	waiting_msg = false
	msg_arrow.visible = false

func _msg_silent(text: String) -> void:
	msg_label.text = text
	msg_arrow.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if waiting_msg and (event.is_action_pressed("confirm") or (event is InputEventMouseButton and event.pressed)):
		_advance.emit()
		get_viewport().set_input_as_handled()
	elif menu == Menu.MOVES and event.is_action_pressed("cancel"):
		_show_menu(Menu.COMMAND)
	elif menu in [Menu.BAG, Menu.PARTY] and event.is_action_pressed("cancel"):
		_show_menu(Menu.COMMAND)

func _show_menu(m: Menu) -> void:
	menu = m
	cmd_box.visible = m == Menu.COMMAND
	moves_box.visible = m == Menu.MOVES
	sub_box.visible = m in [Menu.BAG, Menu.PARTY]
	if m == Menu.COMMAND:
		_msg_silent("%s 要做什么？" % mon_mine().name)
		(cmd_box.get_child(0) as Button).grab_focus()

# ============== 流程 ==============
func _intro() -> void:
	busy = true
	en_spr.modulate.a = 0.0
	my_spr.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(en_spr, "modulate:a", 1.0, 0.35)
	await tw.finished
	if is_trainer:
		for line in cfg.get("intro", []):
			await _msg(str(line))
		await _msg("%s 派出了 %s！" % [str(cfg.get("trainer_name", "训练家")), enemy.name])
	else:
		await _msg("野生的 %s 出现了！" % enemy.name)
	var tw2 := create_tween()
	tw2.tween_property(my_spr, "modulate:a", 1.0, 0.35)
	await tw2.finished
	await _msg("就决定是你了，%s！" % mon_mine().name)
	busy = false
	_show_menu(Menu.COMMAND)

func _on_fight() -> void:
	for c in moves_box.get_children():
		c.queue_free()
	var m := mon_mine()
	for i in m.moves.size():
		var mv: Dictionary = m.moves[i]
		var info := Db.move(str(mv.id))
		var b := Button.new()
		b.text = "%s %s\nPP %d/%d" % [info.name, info.type, int(mv.pp), int(info.pp)]
		b.custom_minimum_size = Vector2(150, 44)
		b.disabled = int(mv.pp) <= 0
		var idx: int = i
		b.pressed.connect(func() -> void: _choose_move(idx))
		moves_box.add_child(b)
	_show_menu(Menu.MOVES)
	_msg_silent("选择技能！")
	for c in moves_box.get_children():
		if not (c as Button).disabled:
			(c as Button).grab_focus()
			break

func _choose_move(idx: int) -> void:
	if busy: return
	_show_menu(Menu.NONE)
	_do_round(idx)

func _enemy_move_idx() -> int:
	var options: Array[int] = []
	for i in enemy.moves.size():
		if int(enemy.moves[i].pp) > 0:
			options.append(i)
	if options.is_empty():
		return -1
	return options[randi() % options.size()]

func _do_round(my_move_idx: int) -> void:
	busy = true
	var m := mon_mine()
	var en_first: bool = int(enemy.stats.spd) > int(m.stats.spd) or (int(enemy.stats.spd) == int(m.stats.spd) and randf() < 0.5)
	var order: Array = []
	if en_first:
		order = [[enemy, m, _enemy_move_idx(), en_spr, my_spr], [m, enemy, my_move_idx, my_spr, en_spr]]
	else:
		order = [[m, enemy, my_move_idx, my_spr, en_spr], [enemy, m, _enemy_move_idx(), en_spr, my_spr]]
	for step in order:
		if int(step[0].hp) <= 0:
			continue
		await _use_move(step[0], step[1], int(step[2]), step[3], step[4])
		if await _check_faints():
			return
	busy = false
	_show_menu(Menu.COMMAND)

func _use_move(att: Dictionary, dfd: Dictionary, move_idx: int, att_spr: TextureRect, dfd_spr: TextureRect) -> void:
	if move_idx < 0:
		await _msg("%s 不知所措！" % att.name)
		return
	var slot: Dictionary = att.moves[move_idx]
	var info := Db.move(str(slot.id))
	slot.pp = int(slot.pp) - 1
	await _msg("%s 使用了 %s！" % [att.name, info.name])

	# 攻击位移动画
	var dir: float = 30.0 if att == mon_mine() else -30.0
	var orig: Vector2 = att_spr.position
	var tw := create_tween()
	tw.tween_property(att_spr, "position:x", orig.x + dir, 0.12)
	tw.tween_property(att_spr, "position:x", orig.x, 0.12)
	await tw.finished

	if randf() * 100.0 > float(info.acc):
		await _msg("但是没有命中！")
		return

	var eff := Db.effectiveness(str(info.type), Db.species(str(dfd.species)).types)
	var stab: float = 1.5 if str(info.type) in Db.species(str(att.species)).types else 1.0
	var lv := int(att.level)
	var dmg := int((((2.0 * lv / 5.0 + 2.0) * float(info.power) * float(att.stats.atk) / float(dfd.stats.def)) / 50.0 + 2.0) * eff * stab * randf_range(0.85, 1.0))
	dmg = maxi(dmg, 1)
	dfd.hp = maxi(int(dfd.hp) - dmg, 0)

	# 受击闪烁 + 血条动画
	var tw2 := create_tween()
	tw2.tween_property(dfd_spr, "modulate", Color(1, 0.4, 0.4), 0.08)
	tw2.tween_property(dfd_spr, "modulate", Color(1, 1, 1), 0.08)
	tw2.set_loops(2)
	var bar: ProgressBar = en_hp_bar if dfd == enemy else my_hp_bar
	var tw3 := create_tween()
	tw3.tween_property(bar, "value", int(dfd.hp), 0.4)
	await tw3.finished
	_refresh_panels()

	if eff > 1.5:
		await _msg("效果绝佳！")
	elif eff < 0.9:
		await _msg("收效甚微……")
	if bool(info.get("drain", false)) and dmg > 0:
		att.hp = mini(int(att.hp) + maxi(dmg / 2, 1), int(att.stats.maxhp))
		_refresh_panels()
		await _msg("%s 吸取了对手的体力！" % att.name)

# 返回 true 表示战斗已结束
func _check_faints() -> bool:
	var m := mon_mine()
	if int(enemy.hp) <= 0:
		await _fade_out(en_spr)
		await _msg("敌方的 %s 倒下了！" % enemy.name)
		var msgs := Game.gain_exp(m, int(Db.species(str(enemy.species)).get("base_exp", 50)) * int(enemy.level) / 5)
		for t in msgs:
			await _msg(t)
		_refresh_panels()
		enemy_idx += 1
		if enemy_idx < enemy_team.size():
			enemy = enemy_team[enemy_idx]
			en_spr.modulate.a = 0.0
			_refresh_panels()
			await _msg("%s 派出了 %s！" % [str(cfg.get("trainer_name", "训练家")), enemy.name])
			var tw := create_tween()
			tw.tween_property(en_spr, "modulate", Color(1, 1, 1, 1), 0.3)
			busy = false
			_show_menu(Menu.COMMAND)
			return true
		if is_trainer:
			for line in cfg.get("win_lines", []):
				await _msg(str(line))
			result.beat_rival = true
		_end()
		return true
	if int(m.hp) <= 0:
		await _fade_out(my_spr)
		await _msg("%s 倒下了！" % m.name)
		if Game.party_wiped():
			result.whiteout = true
			await _msg("你没有可以战斗的宝可梦了！")
			_end()
			return true
		await _force_switch()
		busy = false
		_show_menu(Menu.COMMAND)
		return true
	return false

func _fade_out(spr: TextureRect) -> void:
	var tw := create_tween()
	tw.tween_property(spr, "modulate", Color(1, 1, 1, 0), 0.3)
	await tw.finished

func _fade_in(spr: TextureRect) -> void:
	var tw := create_tween()
	tw.tween_property(spr, "modulate", Color(1, 1, 1, 1), 0.3)
	await tw.finished

func _force_switch() -> void:
	my_idx = Game.first_alive_index()
	_refresh_panels()
	my_spr.modulate.a = 0.0
	await _msg("就决定是你了，%s！" % mon_mine().name)
	await _fade_in(my_spr)

# ============== 背包 ==============
func _on_bag() -> void:
	for c in sub_box.get_children():
		c.queue_free()
	for id in ["pokeball", "potion"]:
		var item: Dictionary = Db.ITEMS[id]
		var b := Button.new()
		b.text = "%s ×%d" % [item.name, int(Game.bag[id])]
		b.custom_minimum_size = Vector2(310, 40)
		b.disabled = int(Game.bag[id]) <= 0 or (id == "pokeball" and is_trainer)
		var iid: String = id
		b.pressed.connect(func() -> void: _use_item(iid))
		sub_box.add_child(b)
	var back := Button.new()
	back.text = "返回"
	back.custom_minimum_size = Vector2(310, 40)
	back.pressed.connect(func() -> void: _show_menu(Menu.COMMAND))
	sub_box.add_child(back)
	_show_menu(Menu.BAG)
	_msg_silent("使用哪个道具？")
	(sub_box.get_child(0) as Button).grab_focus()

func _use_item(id: String) -> void:
	if busy: return
	_show_menu(Menu.NONE)
	busy = true
	Game.bag[id] = int(Game.bag[id]) - 1
	match id:
		"potion":
			var m := mon_mine()
			var heal: int = mini(int(Db.ITEMS.potion.heal), int(m.stats.maxhp) - int(m.hp))
			m.hp = int(m.hp) + heal
			var tw := create_tween()
			tw.tween_property(my_hp_bar, "value", int(m.hp), 0.4)
			await tw.finished
			_refresh_panels()
			await _msg("%s 恢复了 %d 点 HP！" % [m.name, heal])
		"pokeball":
			await _throw_ball()
			if result.get("caught", false):
				return
	# 道具消耗回合：敌方行动
	await _use_move(enemy, mon_mine(), _enemy_move_idx(), en_spr, my_spr)
	if await _check_faints():
		return
	busy = false
	_show_menu(Menu.COMMAND)

func _throw_ball() -> void:
	await _msg("你扔出了精灵球！")
	var ball := TextureRect.new()
	ball.texture = Util.load_tex("res://assets/ui/pokeball.png", Vector2i(48, 48), Color(0.9, 0.25, 0.25))
	ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ball.size = Vector2(44, 44)
	ball.position = Vector2(300, 420)
	add_child(ball)
	var target := en_spr.position + en_spr.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ball, "position", target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ball, "rotation", TAU * 2, 0.45)
	await tw.finished
	en_spr.modulate = Color(1, 1, 1, 0.25)
	# 摇晃
	for i in 3:
		var tws := create_tween()
		tws.tween_property(ball, "rotation", 0.35, 0.12)
		tws.tween_property(ball, "rotation", -0.35, 0.12)
		tws.tween_property(ball, "rotation", 0.0, 0.08)
		await tws.finished
		await get_tree().create_timer(0.15).timeout
	var ratio := float(enemy.hp) / float(enemy.stats.maxhp)
	var chance: float = clampf((1.0 - 0.65 * ratio) * float(Db.species(str(enemy.species)).get("catch", 0.5)) * 1.6, 0.08, 0.95)
	if randf() < chance:
		ball.modulate = Color(0.8, 1.0, 0.8)
		await _msg("太好了！%s 被收服了！" % enemy.name)
		var mon: Dictionary = enemy.duplicate(true)
		if Game.add_to_party(mon):
			await _msg("%s 加入了你的队伍！" % mon.name)
		else:
			await _msg("队伍已满，%s 被送去了博士那里。" % mon.name)
		result["caught"] = true
		_end()
	else:
		ball.queue_free()
		en_spr.modulate = Color(1, 1, 1, 1)
		await _msg("噢，差一点就抓住了！")

# ============== 宝可梦切换 ==============
func _on_party() -> void:
	for c in sub_box.get_children():
		c.queue_free()
	for i in Game.party.size():
		var p: Dictionary = Game.party[i]
		var b := Button.new()
		b.text = "%s Lv.%d  HP %d/%d" % [p.name, int(p.level), int(p.hp), int(p.stats.maxhp)]
		b.custom_minimum_size = Vector2(310, 40)
		b.disabled = i == my_idx or int(p.hp) <= 0
		var idx := i
		b.pressed.connect(func() -> void: _switch_to(idx))
		sub_box.add_child(b)
	var back := Button.new()
	back.text = "返回"
	back.custom_minimum_size = Vector2(310, 40)
	back.pressed.connect(func() -> void: _show_menu(Menu.COMMAND))
	sub_box.add_child(back)
	_show_menu(Menu.PARTY)
	_msg_silent("换上哪只宝可梦？")
	(sub_box.get_child(sub_box.get_child_count() - 1) as Button).grab_focus()

func _switch_to(idx: int) -> void:
	if busy: return
	_show_menu(Menu.NONE)
	busy = true
	await _fade_out(my_spr)
	await _msg("回来吧，%s！" % mon_mine().name)
	my_idx = idx
	_refresh_panels()
	await _msg("就决定是你了，%s！" % mon_mine().name)
	await _fade_in(my_spr)
	# 切换消耗回合
	await _use_move(enemy, mon_mine(), _enemy_move_idx(), en_spr, my_spr)
	if await _check_faints():
		return
	busy = false
	_show_menu(Menu.COMMAND)

# ============== 逃跑 ==============
func _on_run() -> void:
	if busy: return
	if is_trainer:
		_show_menu(Menu.NONE)
		busy = true
		await _msg("不能从训练家对战中逃走！")
		busy = false
		_show_menu(Menu.COMMAND)
		return
	_show_menu(Menu.NONE)
	busy = true
	var chance: float = clampf(0.55 + float(int(mon_mine().stats.spd) - int(enemy.stats.spd)) / 150.0, 0.25, 0.95)
	if randf() < chance:
		await _msg("成功逃走了！")
		_end()
	else:
		await _msg("没能逃掉！")
		await _use_move(enemy, mon_mine(), _enemy_move_idx(), en_spr, my_spr)
		if await _check_faints():
			return
		busy = false
		_show_menu(Menu.COMMAND)

func _end() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	await tw.finished
	finished.emit(result)
