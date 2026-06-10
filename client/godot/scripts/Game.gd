extends Node
# 全局游戏状态（autoload: Game）

var party: Array = []            # 队伍中的宝可梦实例
var bag := {"pokeball": 5, "potion": 3}
var flags := {"got_starter": false, "beat_rival": false}

var map_id := "town"
var pending_spawn := Vector2i(10, 13)
var pending_facing := "down"
var heal_map := "town"
var heal_cell := Vector2i(10, 13)

const MAX_PARTY := 6

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
	for mid in sp.get("moves", []):
		moves.append({"id": mid, "pp": Db.move(mid).get("pp", 10)})
	return {
		"species": species_id,
		"name": sp.get("name", "???"),
		"level": level,
		"exp": 0,
		"hp": stats.maxhp,
		"stats": stats,
		"moves": moves,
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
		for mv in mon.moves:
			mv.pp = Db.move(mv.id).get("pp", 10)

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
	return msgs

func reset_new_game() -> void:
	party.clear()
	bag = {"pokeball": 5, "potion": 3}
	flags = {"got_starter": false, "beat_rival": false}
	map_id = "town"
	pending_spawn = Vector2i(10, 13)
	pending_facing = "down"
