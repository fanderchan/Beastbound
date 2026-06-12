extends Node
# 全局游戏状态（autoload: Game）

const SAVE_PATH := "user://save.json"
const MAX_PARTY := 6

var party: Array = []            # 队伍中的宝可梦实例
var bag := {"pokeball": 5, "potion": 3}
var money := 1500
var flags := {}                  # got_starter / beat_rival / badge1-3 / beaten_<id> / game_clear
var dex_seen := {}
var dex_caught := {}

var map_id := "town"
var pending_spawn := Vector2i(10, 13)
var pending_facing := "down"
var heal_map := "town"
var heal_cell := Vector2i(10, 13)

# ===== 宝可梦实例 =====
static func calc_stats(species_id: String, level: int) -> Dictionary:
	var base: Dictionary = Db.species(species_id).get("base", {"hp": 40, "atk": 45, "def": 45, "spd": 45})
	return {
		"maxhp": int(float(base.hp) * 2.0 * level / 50.0) + level + 10,
		"atk": int(float(base.atk) * 2.0 * level / 50.0) + 5,
		"def": int(float(base.def) * 2.0 * level / 50.0) + 5,
		"spd": int(float(base.spd) * 2.0 * level / 50.0) + 5,
	}

static func exp_to_next(level: int) -> int:
	return 12 + level * 8

func make_monster(species_id: String, level: int) -> Dictionary:
	var sp := Db.species(species_id)
	var stats := calc_stats(species_id, level)
	var moves: Array = []
	for mid in Db.moves_at_level(species_id, level):
		moves.append({"id": mid, "pp": Db.move(mid).get("pp", 10)})
	return {
		"species": species_id,
		"name": sp.get("name", "???"),
		"level": level,
		"exp": 0,
		"hp": stats.maxhp,
		"stats": stats,
		"moves": moves,
		"status": "",
	}

func add_to_party(mon: Dictionary) -> bool:
	if party.size() >= MAX_PARTY:
		return false
	party.append(mon)
	return true

func first_alive_index() -> int:
	for i in party.size():
		if int(party[i].hp) > 0:
			return i
	return -1

func party_wiped() -> bool:
	return first_alive_index() < 0

func heal_party() -> void:
	for mon in party:
		mon.hp = mon.stats.maxhp
		mon.status = ""
		for mv in mon.moves:
			mv.pp = Db.move(mv.id).get("pp", 10)

# ===== 图鉴 =====
func mark_seen(species_id: String) -> void:
	dex_seen[species_id] = true

func mark_caught(species_id: String) -> void:
	dex_seen[species_id] = true
	dex_caught[species_id] = true

# ===== 升级 / 进化 =====
# 升级处理：返回升级消息列表
func gain_exp(mon: Dictionary, amount: int) -> Array[String]:
	var msgs: Array[String] = []
	msgs.append("%s 获得了 %d 点经验值！" % [mon.name, amount])
	mon.exp += amount
	while mon.exp >= exp_to_next(mon.level) and mon.level < 100:
		mon.exp -= exp_to_next(mon.level)
		mon.level += 1
		var old_max: int = mon.stats.maxhp
		mon.stats = calc_stats(mon.species, mon.level)
		mon.hp = clampi(int(mon.hp) + (int(mon.stats.maxhp) - old_max), 1, int(mon.stats.maxhp))
		msgs.append("%s 升到了 %d 级！" % [mon.name, mon.level])
		_learn_new_moves(mon, msgs)
	return msgs

func _learn_new_moves(mon: Dictionary, msgs: Array[String]) -> void:
	for entry in Db.species(str(mon.species)).get("learnset", []):
		if int(entry[0]) != int(mon.level):
			continue
		var mid := str(entry[1])
		var has := false
		for mv in mon.moves:
			if str(mv.id) == mid:
				has = true
		if has:
			continue
		if mon.moves.size() >= 4:
			mon.moves.pop_front()
		mon.moves.append({"id": mid, "pp": Db.move(mid).get("pp", 10)})
		msgs.append("%s 学会了 %s！" % [mon.name, Db.move(mid).name])

# 战斗后调用：返回进化事件列表 [{mon, from_name, to_name}]
func check_evolutions() -> Array:
	var events: Array = []
	for mon in party:
		var evo: Dictionary = Db.species(str(mon.species)).get("evolve", {})
		if evo.is_empty() or int(mon.level) < int(evo.level):
			continue
		var from_name := str(mon.name)
		var to_id := str(evo.to)
		mon.species = to_id
		mon.name = Db.species(to_id).get("name", "???")
		var old_max: int = mon.stats.maxhp
		mon.stats = calc_stats(to_id, int(mon.level))
		mon.hp = clampi(int(mon.hp) + (int(mon.stats.maxhp) - old_max), 1, int(mon.stats.maxhp))
		mark_caught(to_id)
		events.append({"from_name": from_name, "to_name": mon.name})
	return events

# ===== 存档 =====
func save_game(world_cell: Vector2i) -> bool:
	var data := {
		"party": party, "bag": bag, "money": money, "flags": flags,
		"dex_seen": dex_seen, "dex_caught": dex_caught,
		"map_id": map_id, "cell": [world_cell.x, world_cell.y],
		"heal_map": heal_map, "heal_cell": [heal_cell.x, heal_cell.y],
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary:
		return false
	party = data.get("party", [])
	bag = data.get("bag", {"pokeball": 5, "potion": 3})
	money = int(data.get("money", 1500))
	flags = data.get("flags", {})
	dex_seen = data.get("dex_seen", {})
	dex_caught = data.get("dex_caught", {})
	map_id = str(data.get("map_id", "town"))
	var c: Array = data.get("cell", [10, 13])
	pending_spawn = Vector2i(int(c[0]), int(c[1]))
	pending_facing = "down"
	heal_map = str(data.get("heal_map", "town"))
	var hc: Array = data.get("heal_cell", [10, 13])
	heal_cell = Vector2i(int(hc[0]), int(hc[1]))
	return true

func reset_new_game() -> void:
	party.clear()
	bag = {"pokeball": 5, "potion": 3}
	money = 1500
	flags = {}
	dex_seen.clear()
	dex_caught.clear()
	map_id = "town"
	pending_spawn = Vector2i(10, 13)
	pending_facing = "down"
	heal_map = "town"
	heal_cell = Vector2i(10, 13)
