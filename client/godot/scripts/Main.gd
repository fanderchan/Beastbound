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
			start_battle(_rival_cfg())
		_:
			_show_title()

func _give_starter(idx: int) -> void:
	var ids := ["leafdra", "flarefox", "aquaturt"]
	var mon: Dictionary = Game.make_monster(ids[clampi(idx, 0, 2)], 5)
	Game.add_to_party(mon)
	Game.flags.got_starter = true

func _rival_cfg() -> Dictionary:
	var counter := {"leafdra": "flarefox", "flarefox": "aquaturt", "aquaturt": "leafdra"}
	var my: String = Game.party[0].species if not Game.party.is_empty() else "leafdra"
	return {
		"kind": "trainer",
		"trainer_name": "劲敌·小烈",
		"team": [{"species": counter.get(my, "flarefox"), "level": 5}],
		"intro": ["小烈：哼，让你见识一下\n真正的训练家！"],
		"win_lines": ["小烈：可恶……你变强了。", "小烈：下次我一定不会输！"],
	}

func _show_title() -> void:
	title = TitleScreen.new()
	title.start_game.connect(_on_start_game)
	screen_layer.add_child(title)

func _on_start_game() -> void:
	if is_instance_valid(title):
		title.queue_free()
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
		world.show_lines(["你眼前一黑……", "等回过神来，已经躺在家门口了。\n宝可梦也都恢复了精神。"])
	else:
		world.set_active(true)
		if result.get("beat_rival", false):
			Game.flags.beat_rival = true
			world.show_lines(["恭喜！你击败了劲敌小烈！", "青叶镇的冒险暂告一段落，\n但训练家之路才刚刚开始……"])
