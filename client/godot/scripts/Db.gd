class_name Db
extends RefCounted

# ===== 属性 =====
const TYPE_COLORS := {
	"普": Color(0.62, 0.63, 0.58),
	"草": Color(0.38, 0.74, 0.36),
	"火": Color(0.93, 0.45, 0.25),
	"水": Color(0.32, 0.56, 0.93),
	"虫": Color(0.62, 0.72, 0.22),
}

# 攻击属性 -> 防守属性 -> 倍率（未列出默认 1.0）
const CHART := {
	"火": {"草": 2.0, "虫": 2.0, "火": 0.5, "水": 0.5},
	"水": {"火": 2.0, "水": 0.5, "草": 0.5},
	"草": {"水": 2.0, "草": 0.5, "火": 0.5, "虫": 0.5},
	"虫": {"草": 2.0, "火": 0.5},
	"普": {},
}

static func effectiveness(move_type: String, def_types: Array) -> float:
	var mult := 1.0
	var row: Dictionary = CHART.get(move_type, {})
	for t in def_types:
		mult *= float(row.get(t, 1.0))
	return mult

# ===== 技能 =====
const MOVES := {
	"zhuangji":  {"name": "撞击",     "type": "普", "power": 40, "acc": 100, "pp": 35},
	"mengzhuang":{"name": "猛撞",     "type": "普", "power": 70, "acc": 90,  "pp": 15},
	"dianguang": {"name": "电光一闪", "type": "普", "power": 40, "acc": 100, "pp": 30},
	"zhuo":      {"name": "啄",       "type": "普", "power": 35, "acc": 100, "pp": 35},
	"tengbian":  {"name": "藤鞭",     "type": "草", "power": 45, "acc": 100, "pp": 25},
	"yeren":     {"name": "叶刃",     "type": "草", "power": 55, "acc": 95,  "pp": 25},
	"xiqu":      {"name": "吸取",     "type": "草", "power": 20, "acc": 100, "pp": 25, "drain": true},
	"huohua":    {"name": "火花",     "type": "火", "power": 40, "acc": 100, "pp": 25},
	"huoyanya":  {"name": "火焰牙",   "type": "火", "power": 65, "acc": 95,  "pp": 15},
	"shuiqiang": {"name": "水枪",     "type": "水", "power": 40, "acc": 100, "pp": 25},
	"paomo":     {"name": "泡沫光线", "type": "水", "power": 65, "acc": 100, "pp": 20},
}

# ===== 宝可梦图鉴（原创设计） =====
const SPECIES := {
	"leafdra": {
		"name": "叶芽龙", "types": ["草"],
		"base": {"hp": 45, "atk": 49, "def": 49, "spd": 45},
		"moves": ["zhuangji", "tengbian", "yeren", "mengzhuang"],
		"catch": 0.45, "base_exp": 64,
		"sprite": "res://assets/monsters/starter_grass.png",
		"desc": "背上驮着一颗嫩芽的小龙，晒太阳时嫩芽会微微发光。",
	},
	"flarefox": {
		"name": "炎尾狐", "types": ["火"],
		"base": {"hp": 39, "atk": 52, "def": 43, "spd": 65},
		"moves": ["zhuangji", "huohua", "huoyanya", "mengzhuang"],
		"catch": 0.45, "base_exp": 62,
		"sprite": "res://assets/monsters/starter_fire.png",
		"desc": "尾巴尖上燃着小小的火苗，心情越好火苗越旺。",
	},
	"aquaturt": {
		"name": "水灵龟", "types": ["水"],
		"base": {"hp": 44, "atk": 48, "def": 65, "spd": 43},
		"moves": ["zhuangji", "shuiqiang", "paomo", "mengzhuang"],
		"catch": 0.45, "base_exp": 63,
		"sprite": "res://assets/monsters/starter_water.png",
		"desc": "壳里储存着清泉水，遇到危险会喷出水柱防身。",
	},
	"chirpie": {
		"name": "啾啾雀", "types": ["普"],
		"base": {"hp": 40, "atk": 45, "def": 40, "spd": 56},
		"moves": ["zhuo", "dianguang"],
		"catch": 0.70, "base_exp": 50,
		"sprite": "res://assets/monsters/bird.png",
		"desc": "清晨在青叶镇上空盘旋，叫声清脆悦耳。",
	},
	"fluffrat": {
		"name": "绒绒鼠", "types": ["普"],
		"base": {"hp": 38, "atk": 50, "def": 35, "spd": 60},
		"moves": ["zhuangji", "dianguang"],
		"catch": 0.70, "base_exp": 51,
		"sprite": "res://assets/monsters/rat.png",
		"desc": "脸颊毛茸茸的小老鼠，最喜欢收集亮晶晶的小石子。",
	},
	"shroomite": {
		"name": "菇菇虫", "types": ["虫", "草"],
		"base": {"hp": 50, "atk": 42, "def": 50, "spd": 30},
		"moves": ["zhuangji", "xiqu"],
		"catch": 0.60, "base_exp": 54,
		"sprite": "res://assets/monsters/bugshroom.png",
		"desc": "背上长着小蘑菇的幼虫，雨后会成群出现在草丛里。",
	},
}

# ===== 道具 =====
const ITEMS := {
	"pokeball": {"name": "精灵球", "desc": "用于捕捉野生宝可梦。"},
	"potion":   {"name": "伤药",   "desc": "恢复 20 点 HP。", "heal": 20},
}

static func species(id: String) -> Dictionary:
	return SPECIES.get(id, {})

static func move(id: String) -> Dictionary:
	return MOVES.get(id, {})
