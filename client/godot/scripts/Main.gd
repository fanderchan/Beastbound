extends Node
# 顶层流程控制：标题 → 世界 → 战斗

var ui_theme: Theme
var title: TitleScreen
var world: WorldScreen
var battle: BattleScreen
var screen_layer: CanvasLayer   # Control 屏幕的全屏容器

func _ready() -> void:
	ui_theme = UiTheme.build()
	screen_layer = CanvasLayer.new()
	screen_layer.layer = 5
	add_child(screen_layer)
	await get_tree().process_frame
	_route_start()

func _route_start() -> void:
	if Shot.pick_starter >= 0:
		_give_starter(Shot.pick_starter)
	if Shot.start_lv > 0 and not Game.party.is_empty():
		var mon: Dictionary = Game.party[0]
		mon.level = Shot.start_lv
		mon.stats = Game.calc_stats(str(mon.species), Shot.start_lv)
		mon.hp = mon.stats.maxhp
		mon.moves.clear()
		for mid in Db.moves_at_level(str(mon.species), Shot.start_lv):
			mon.moves.append({"id": mid, "pp": Db.move(mid).get("pp", 10)})
	for f in Shot.start_flags:
		Game.flags[f] = true
	if Shot.start_map != "":
		Game.map_id = Shot.start_map
		if Shot.start_cell.x >= 0:
			Game.pending_spawn = Shot.start_cell
	match Shot.start_screen:
		"world":
			_enter_world()
		"battle":
			if Game.party.is_empty():
				_give_starter(0)
			_enter_world()
			start_battle({"kind": "wild", "species": "fluffrat", "level": 3})
		"rival":
			if Game.party.is_empty():
				_give_starter(0)
			_enter_world()
			start_battle(rival_cfg())
		"trainer":
			if Game.party.is_empty():
				_give_starter(0)
			_enter_world()
			start_battle(trainer_cfg(Shot.start_trainer))
		"credits":
			_show_credits()
		_:
			_show_title()

func _give_starter(idx: int) -> void:
	var ids := ["leafdra", "flarefox", "aquaturt"]
	var sid: String = ids[clampi(idx, 0, 2)]
	var mon: Dictionary = Game.make_monster(sid, 5)
	Game.add_to_party(mon)
	Game.mark_caught(sid)
	Game.flags["got_starter"] = true

# 玩家初始御三家（含进化后）判定
func _starter_line() -> String:
	for mon in Game.party:
		var sid := str(mon.species)
		if sid in ["leafdra", "verdhound"]: return "grass"
		if sid in ["flarefox", "blazefox"]: return "fire"
		if sid in ["aquaturt", "tidesal"]: return "water"
	return "grass"

func rival_cfg() -> Dictionary:
	var counter := {"grass": "flarefox", "fire": "aquaturt", "water": "leafdra"}
	return {
		"kind": "trainer", "trainer_id": "rival1",
		"trainer_name": "劲敌·小烈",
		"team": [{"species": counter[_starter_line()], "level": 5}],
		"intro": ["小烈：哼，让你见识一下\n真正的训练家！"],
		"win_lines": ["小烈：可恶……你变强了。", "小烈：我要去联盟特训，\n山顶的冠军之座是我的！"],
		"reward": 500,
	}

func champion_cfg() -> Dictionary:
	var counter_evo := {"grass": "blazefox", "fire": "tidesal", "water": "verdhound"}
	return {
		"kind": "trainer", "trainer_id": "champion",
		"trainer_name": "冠军·小烈",
		"team": [
			{"species": "nightowl", "level": 21},
			{"species": "boulderturt", "level": 22},
			{"species": "thunderhawk", "level": 23},
			{"species": counter_evo[_starter_line()], "level": 24},
		],
		"intro": [
			"小烈：……你终于来了。",
			"小烈：我说过吧，山顶见。\n现在我是青峰联盟的冠军！",
			"小烈：让这场对决，\n为我们的旅程画上句号吧！",
		],
		"win_lines": [
			"小烈：……哈哈，痛快！",
			"小烈：从今天起，你就是\n青峰联盟新的冠军！",
		],
		"reward": 5000,
	}

func trainer_cfg(tid: String) -> Dictionary:
	if tid == "champion":
		return champion_cfg()
	var t := Db.trainer(tid)
	var team: Array = []
	for m in t.get("team", []):
		team.append({"species": str(m[0]), "level": int(m[1])})
	return {
		"kind": "trainer", "trainer_id": tid,
		"trainer_name": str(t.get("name", "训练家")),
		"team": team,
		"intro": t.get("intro", []),
		"win_lines": t.get("win_lines", []),
		"reward": int(t.get("reward", 0)),
	}

func _show_title() -> void:
	title = TitleScreen.new()
	title.start_game.connect(_on_start_game)
	screen_layer.add_child(title)

func _on_start_game(continue_save: bool) -> void:
	if is_instance_valid(title):
		title.queue_free()
	if continue_save and Game.load_game():
		pass
	else:
		Game.reset_new_game()
	_enter_world()

func _enter_world() -> void:
	if is_instance_valid(world):
		world.queue_free()
	world = WorldScreen.new()
	world.request_battle.connect(start_battle)
	add_child(world)

func start_battle(cfg: Dictionary) -> void:
	if is_instance_valid(battle):
		return
	world.set_active(false)
	battle = BattleScreen.new(cfg, ui_theme)
	battle.finished.connect(_on_battle_end)
	screen_layer.add_child(battle)

func _on_battle_end(result: Dictionary) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
		battle = null
	if result.get("whiteout", false):
		Game.heal_party()
		Game.map_id = Game.heal_map
		Game.pending_spawn = Game.heal_cell
		Game.pending_facing = "down"
		_enter_world()
		world.show_lines(["你眼前一黑……", "等回过神来，宝可梦\n已经恢复了精神。"])
		return

	world.set_active(true)
	var lines: Array = []

	# 训练家战胜利：落旗 + 徽章
	var tid := str(result.get("trainer_id", ""))
	if result.get("won", false) and tid != "":
		Game.flags["beaten_%s" % tid] = true
		var t := Db.trainer(tid)
		if t.has("badge"):
			Game.flags[str(t.badge)] = true
			lines.append("获得了「%s」！" % str(t.badge_name))

	# 进化检查
	for ev in Game.check_evolutions():
		lines.append("咦？%s 的样子……" % ev.from_name)
		lines.append("%s 进化成了 %s！" % [ev.from_name, ev.to_name])

	# 冠军通关
	if result.get("won", false) and tid == "champion":
		Game.flags["game_clear"] = true
		Game.save_game(world.cell)
		_show_credits()
		return

	if not lines.is_empty():
		world.show_lines(lines)

func _show_credits() -> void:
	if is_instance_valid(world):
		world.queue_free()
	var credits := CreditsScreen.new()
	screen_layer.add_child(credits)
	credits.finished.connect(func() -> void:
		credits.queue_free()
		_show_title())
