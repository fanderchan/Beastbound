class_name WorldScreen
extends Node2D
# 世界探索：网格移动 / 碰撞 / 对话 / 草丛遇敌 / 地图切换

signal request_battle(cfg: Dictionary)

const CELL := 32
const MOVE_TIME := 0.17

var map: Dictionary
var grid_w := 48
var grid_h := 32
var blocked := {}            # Vector2i -> true
var grass := {}              # Vector2i -> true
var exits := {}              # Vector2i -> exit dict
var interactables := {}      # Vector2i -> {kind, data}
var npc_nodes := {}

var player_root: Node2D
var player_spr: Sprite2D
var cam: Camera2D
var ui: CanvasLayer
var dialog: DialogBox
var flash: ColorRect
var toast: Label
var hintbar: Label

var cell := Vector2i(10, 13)
var facing := "down"
var moving := false
var active := true
var anim_t := 0.0
var encounter_lock := false

const DIRS := {"down": Vector2i(0, 1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0), "up": Vector2i(0, -1)}
const ROW := {"down": 0, "left": 1, "right": 2, "up": 3}

func _ready() -> void:
	add_to_group("world")
	y_sort_enabled = false
	_build_ui()
	load_map(Game.map_id)

func set_active(v: bool) -> void:
	active = v
	visible = v
	if is_instance_valid(ui):
		ui.visible = v
	set_process(v)
	set_process_unhandled_input(v)

func show_lines(lines: Array) -> void:
	dialog.show_lines(lines)

# ===================== 地图构建 =====================
func load_map(id: String) -> void:
	Game.map_id = id
	for c in get_children():
		if c != ui:
			c.queue_free()
	blocked.clear(); grass.clear(); exits.clear(); interactables.clear(); npc_nodes.clear()

	map = Util.load_json("res://data/%s.json" % id)
	if map.is_empty():
		return
	grid_w = int(map.grid[0]); grid_h = int(map.grid[1])

	var base := Sprite2D.new()
	base.texture = Util.load_tex(str(map.base), Vector2i(grid_w * CELL, grid_h * CELL), Color(0.3, 0.5, 0.3))
	base.centered = false
	base.scale = Vector2(float(grid_w * CELL) / base.texture.get_width(), float(grid_h * CELL) / base.texture.get_height())
	base.z_index = -10
	add_child(base)

	for r in map.get("blocked_rects", []):
		for x in range(int(r[0]), int(r[0]) + int(r[2])):
			for y in range(int(r[1]), int(r[1]) + int(r[3])):
				blocked[Vector2i(x, y)] = true

	var ground := Node2D.new()   # 草丛/花等贴地装饰
	ground.z_index = -5
	add_child(ground)

	var ysort := Node2D.new()
	ysort.y_sort_enabled = true
	ysort.name = "ysort"
	add_child(ysort)

	var prop_defs: Dictionary = Util.load_json("res://data/props.json")
	for p in map.get("props", []):
		_spawn_prop(p, prop_defs, ysort, ground)

	# 草丛矩形区域：每格生成一片草丛
	for r in map.get("grass_rects", []):
		for x in range(int(r[0]), int(r[0]) + int(r[2])):
			for y in range(int(r[1]), int(r[1]) + int(r[3])):
				_spawn_prop({"type": "tall_grass", "cell": [x, y]}, prop_defs, ysort, ground)

	for n in map.get("npcs", []):
		_spawn_npc(n, ysort)

	for s in map.get("signs", []):
		var c := Vector2i(int(s.cell[0]), int(s.cell[1]))
		interactables[c] = {"kind": "sign", "lines": s.lines}

	for e in map.get("exits", []):
		for ec in e.cells:
			exits[Vector2i(int(ec[0]), int(ec[1]))] = e

	# 玩家
	cell = Game.pending_spawn
	facing = Game.pending_facing
	player_root = Node2D.new()
	player_spr = Sprite2D.new()
	var ptex := Util.load_tex("res://assets/actors/player.png", Vector2i(128, 192), Color(0.9, 0.4, 0.2))
	player_spr.texture = ptex
	player_spr.hframes = 4
	player_spr.vframes = 4
	var fh := float(ptex.get_height()) / 4.0
	var s := 46.0 / fh
	player_spr.scale = Vector2(s, s)
	player_spr.position = Vector2(0, -fh * s * 0.5 + 2)
	player_root.add_child(player_spr)
	player_root.position = _feet_pos(cell)
	ysort.add_child(player_root)
	_update_frame(0)

	# 摄像机
	cam = Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = grid_w * CELL
	cam.limit_bottom = grid_h * CELL
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player_root.add_child(cam)
	cam.make_current()

	_show_toast(str(map.get("name", id)))

func _feet_pos(c: Vector2i) -> Vector2:
	return Vector2(c.x * CELL + CELL * 0.5, (c.y + 1) * CELL - 2)

func _spawn_prop(p: Dictionary, defs: Dictionary, ysort: Node2D, ground: Node2D) -> void:
	var t := str(p.type)
	var d: Dictionary = defs.get(t, {})
	if d.is_empty():
		return
	var c := Vector2i(int(p.cell[0]), int(p.cell[1]))
	var tex := Util.load_tex(str(d.tex), Vector2i(64, 64), Color(0.5, 0.7, 0.4))
	var draw_w := float(d.get("draw_w", 1.0)) * CELL
	var sc := draw_w / tex.get_width()
	var draw_h := tex.get_height() * sc

	var anchor_bl := bool(d.get("anchor_bl", false))
	var root := Node2D.new()
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.scale = Vector2(sc, sc)
	if anchor_bl:
		root.position = Vector2(c.x * CELL + draw_w * 0.5, (c.y + 1) * CELL)
	else:
		root.position = Vector2(c.x * CELL + CELL * 0.5, (c.y + 1) * CELL)
	spr.position = Vector2(0, -draw_h * 0.5 + float(d.get("y_off", 0)))
	root.add_child(spr)

	# 草丛等贴地装饰：随机镜像减弱网格感
	if bool(d.get("encounter", false)):
		spr.flip_h = randi() % 2 == 0

	if bool(d.get("ground", false)):
		ground.add_child(root)
	else:
		ysort.add_child(root)

	# 碰撞脚印
	var bw := int(d.get("block_w", 0))
	var bh := int(d.get("block_h", 0))
	for x in range(c.x, c.x + maxi(bw, 0)):
		for y in range(c.y - maxi(bh, 1) + 1, c.y + 1):
			if bw > 0:
				blocked[Vector2i(x, y)] = true

	if bool(d.get("encounter", false)):
		grass[c] = true
	if d.has("interact_lines"):
		interactables[c] = {"kind": "sign", "lines": d.interact_lines}

func _spawn_npc(n: Dictionary, ysort: Node2D) -> void:
	var c := Vector2i(int(n.cell[0]), int(n.cell[1]))
	var root := Node2D.new()
	var spr := Sprite2D.new()
	var tex := Util.load_tex("res://assets/actors/%s" % str(n.sprite), Vector2i(64, 96), Color(0.4, 0.5, 0.9))
	spr.texture = tex
	var sc := 44.0 / tex.get_height()
	spr.scale = Vector2(sc, sc)
	spr.position = Vector2(0, -tex.get_height() * sc * 0.5 + 2)
	root.add_child(spr)
	root.position = _feet_pos(c)
	ysort.add_child(root)
	blocked[c] = true
	interactables[c] = {"kind": "npc", "id": str(n.id), "data": n}
	npc_nodes[str(n.id)] = root

# ===================== UI =====================
func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var theme_root := Control.new()
	theme_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme_root.size = get_viewport().get_visible_rect().size
	theme_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme_root.theme = UiTheme.build()
	ui.add_child(theme_root)

	dialog = DialogBox.new()
	dialog.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialog.offset_left = 60
	dialog.offset_right = -60
	dialog.offset_top = -170
	dialog.offset_bottom = -24
	theme_root.add_child(dialog)

	toast = Label.new()
	toast.position = Vector2(24, 18)
	toast.add_theme_font_size_override("font_size", 30)
	toast.add_theme_color_override("font_color", Color(1, 1, 1))
	toast.add_theme_constant_override("outline_size", 10)
	toast.add_theme_color_override("font_outline_color", Color(0.1, 0.15, 0.25, 0.9))
	toast.modulate.a = 0.0
	theme_root.add_child(toast)

	hintbar = Label.new()
	hintbar.text = "Z 确认 · C 菜单 · WASD 移动"
	hintbar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hintbar.offset_left = -340
	hintbar.offset_top = -40
	hintbar.offset_right = -16
	hintbar.offset_bottom = -12
	hintbar.add_theme_font_size_override("font_size", 18)
	hintbar.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	hintbar.add_theme_constant_override("outline_size", 6)
	hintbar.add_theme_color_override("font_outline_color", Color(0.1, 0.15, 0.25, 0.7))
	theme_root.add_child(hintbar)

	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme_root.add_child(flash)

func _show_toast(text: String) -> void:
	toast.text = text
	var tw := create_tween()
	toast.modulate.a = 0.0
	tw.tween_property(toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.8)
	tw.tween_property(toast, "modulate:a", 0.0, 0.6)

# ===================== 移动 =====================
func _process(_delta: float) -> void:
	if moving or dialog.is_busy() or encounter_lock or not active:
		return
	for dir in DIRS:
		if Input.is_action_pressed("move_%s" % dir):
			_try_move(dir)
			return

func _try_move(dir: String) -> void:
	facing = dir
	_update_frame(0)
	var target: Vector2i = cell + DIRS[dir]
	if exits.has(target):
		_use_exit(exits[target])
		return
	if target.x < 0 or target.y < 0 or target.x >= grid_w or target.y >= grid_h:
		return
	if blocked.has(target):
		return
	moving = true
	cell = target
	var tw := create_tween()
	tw.tween_property(player_root, "position", _feet_pos(cell), MOVE_TIME)
	tw.parallel().tween_method(_anim_step, 0.0, 1.0, MOVE_TIME)
	tw.tween_callback(_on_step_done)

func _anim_step(t: float) -> void:
	var f := int(floor(t * 4.0)) % 4
	_update_frame(f)

func _update_frame(col: int) -> void:
	if is_instance_valid(player_spr):
		player_spr.frame = ROW[facing] * 4 + col

func _on_step_done() -> void:
	moving = false
	_update_frame(0)
	if grass.has(cell):
		_roll_encounter()

func _roll_encounter() -> void:
	if randf() > 0.12 or Game.party.is_empty():
		return
	var table: Array = map.get("encounters", [])
	if table.is_empty():
		return
	encounter_lock = true
	var roll := randf()
	var acc := 0.0
	var pick: Dictionary = table[0]
	for e in table:
		acc += float(e.weight)
		if roll <= acc:
			pick = e
			break
	var lv := randi_range(int(pick.min_lv), int(pick.max_lv))
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 1.0, 0.18)
	tw.tween_property(flash, "color:a", 0.0, 0.12)
	tw.tween_property(flash, "color:a", 1.0, 0.18)
	tw.tween_callback(func() -> void:
		flash.color.a = 0.0
		encounter_lock = false
		request_battle.emit({"kind": "wild", "species": str(pick.species), "level": lv}))

func _use_exit(e: Dictionary) -> void:
	# 徽章门禁
	if e.has("require_flag") and not Game.flags.get(str(e.require_flag), false):
		dialog.show_lines(e.get("deny_lines", ["前面的路还不能通行。"]))
		return
	moving = true
	Game.pending_spawn = Vector2i(int(e.spawn[0]), int(e.spawn[1]))
	Game.pending_facing = str(e.get("facing", "down"))
	var tw := create_tween()
	flash.color = Color(0, 0, 0, 0)
	tw.tween_property(flash, "color:a", 1.0, 0.25)
	tw.tween_callback(func() -> void:
		load_map(str(e.to))
		moving = false)
	tw.tween_callback(func() -> void:
		var tw2 := create_tween()
		tw2.tween_property(flash, "color:a", 0.0, 0.25)
		tw2.tween_callback(func() -> void: flash.color = Color(1, 1, 1, 0)))

# ===================== 交互 =====================
func _unhandled_input(event: InputEvent) -> void:
	if not active or moving or dialog.is_busy() or encounter_lock:
		return
	if event.is_action_pressed("confirm"):
		var target: Vector2i = cell + DIRS[facing]
		if interactables.has(target):
			_interact(interactables[target], target)
	elif event.is_action_pressed("menu"):
		_open_menu()

func _open_menu() -> void:
	var m := GameMenu.new()
	m.world_cell = cell
	active = false
	m.closed.connect(func() -> void: active = true)
	ui.add_child(m)

func _interact(it: Dictionary, _c: Vector2i) -> void:
	match str(it.kind):
		"sign":
			dialog.show_lines(it.lines)
		"npc":
			_npc_talk(str(it.id), it.get("data", {}))

func _npc_talk(id: String, data: Dictionary) -> void:
	# 数据驱动 NPC
	match str(data.get("kind", "")):
		"nurse":
			_nurse_talk()
			return
		"shop":
			_shop_talk()
			return
		"trainer":
			_trainer_talk(str(data.trainer))
			return
		"dialog":
			dialog.show_lines(data.get("lines", ["……"]))
			return
	# 剧情 NPC
	match id:
		"prof":
			if not Game.flags.get("got_starter", false):
				dialog.show_lines([
					"青木博士：哦哦，你就是隔壁家的孩子吧！",
					"青木博士：来得正好！我这里有三只\n刚出生的宝可梦伙伴。",
					"青木博士：选一只，和它一起踏上冒险吧！",
				])
				await dialog.finished
				_pick_starter()
			elif not Game.flags.get("beaten_rival1", false):
				dialog.show_lines([
					"青木博士：北边的青草小径上\n有很多野生宝可梦。",
					"青木博士：多多锻炼，去会一会\n在那里等你的小烈吧！",
				])
			elif Game.flags.get("game_clear", false):
				dialog.show_lines(["青木博士：冠军！我为你骄傲！\n图鉴的完成也拜托你了！"])
			else:
				dialog.show_lines([
					"青木博士：北方的城镇里有宝可梦道馆。",
					"青木博士：集齐 3 枚徽章就能挑战\n青峰联盟的冠军！加油！",
				])
		"villager":
			dialog.show_lines([
				"村民：走进草丛就可能遇到\n野生宝可梦哦。",
				"村民：每个城镇的宝可梦中心\n都能免费治疗，多多利用吧。",
			])
		"rival":
			if Game.flags.get("beaten_rival1", false):
				dialog.show_lines(["小烈：我去联盟特训了！\n山顶见，到时候我可不会留情！"])
			else:
				dialog.show_lines(["小烈：站住！", "小烈：要通过这里，\n先赢过我的宝可梦再说！"])
				await dialog.finished
				request_battle.emit(get_node("/root/Main").rival_cfg())

func _nurse_talk() -> void:
	dialog.show_lines(["护士：欢迎来到宝可梦中心！\n马上为你的宝可梦恢复体力～"])
	await dialog.finished
	Game.heal_party()
	Game.heal_map = Game.map_id
	Game.heal_cell = cell
	dialog.show_lines(["叮咚♪ 宝可梦们都恢复了精神！", "护士：今后如果输掉对战，\n会回到这里重新出发哦。"])

func _shop_talk() -> void:
	while true:
		var options: Array = []
		for id in Db.SHOP_STOCK:
			var item: Dictionary = Db.ITEMS[id]
			options.append("%s %d元（持有%d）" % [item.name, int(item.price), int(Game.bag.get(id, 0))])
		options.append("离开")
		dialog.show_choice("店员：欢迎光临！（所持金 %d 元）" % Game.money, options)
		var idx: int = await dialog.chosen
		if idx >= Db.SHOP_STOCK.size():
			dialog.show_lines(["店员：欢迎下次再来～"])
			return
		var iid: String = Db.SHOP_STOCK[idx]
		var price := int(Db.ITEMS[iid].price)
		if Game.money < price:
			dialog.show_lines(["店员：哎呀，钱不够呢……"])
			await dialog.finished
			continue
		Game.money -= price
		Game.bag[iid] = int(Game.bag.get(iid, 0)) + 1
		dialog.show_lines(["买下了 %s！（剩余 %d 元）" % [Db.ITEMS[iid].name, Game.money]])
		await dialog.finished

func _trainer_talk(tid: String) -> void:
	var t := Db.trainer(tid)
	if t.is_empty():
		return
	if Game.flags.get("beaten_%s" % tid, false):
		dialog.show_lines(t.get("after", ["……"]))
		return
	dialog.show_lines(t.get("intro", ["来对战吧！"]))
	await dialog.finished
	request_battle.emit(get_node("/root/Main").trainer_cfg(tid))

func _pick_starter() -> void:
	dialog.show_choice("要选择哪一只宝可梦呢？", ["叶芽犬（草）", "炎尾狐（火）", "水灵螈（水）"])
	var idx: int = await dialog.chosen
	var ids := ["leafdra", "flarefox", "aquaturt"]
	var mon: Dictionary = Game.make_monster(ids[idx], 5)
	Game.add_to_party(mon)
	Game.mark_caught(ids[idx])
	Game.flags["got_starter"] = true
	dialog.show_lines([
		"你获得了 %s！" % mon.name,
		"青木博士：再送你 5 个精灵球和 3 瓶伤药。",
		"青木博士：去北边的青草小径锻炼一下吧，\n小烈那家伙已经等不及了！",
	])
