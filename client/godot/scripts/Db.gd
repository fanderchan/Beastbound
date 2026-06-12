class_name Db
extends RefCounted

# ===== 属性 =====
const TYPE_COLORS := {
	"普": Color(0.62, 0.63, 0.58),
	"草": Color(0.38, 0.74, 0.36),
	"火": Color(0.93, 0.45, 0.25),
	"水": Color(0.32, 0.56, 0.93),
	"虫": Color(0.62, 0.72, 0.22),
	"飞": Color(0.55, 0.62, 0.90),
	"岩": Color(0.72, 0.63, 0.38),
	"电": Color(0.95, 0.80, 0.20),
}

# 攻击属性 -> 防守属性 -> 倍率（未列出默认 1.0）
const CHART := {
	"火": {"草": 2.0, "虫": 2.0, "火": 0.5, "水": 0.5, "岩": 0.5},
	"水": {"火": 2.0, "岩": 2.0, "水": 0.5, "草": 0.5},
	"草": {"水": 2.0, "岩": 2.0, "草": 0.5, "火": 0.5, "虫": 0.5, "飞": 0.5},
	"虫": {"草": 2.0, "火": 0.5, "飞": 0.5},
	"飞": {"虫": 2.0, "草": 2.0, "电": 0.5, "岩": 0.5},
	"岩": {"火": 2.0, "飞": 2.0, "虫": 2.0},
	"电": {"水": 2.0, "飞": 2.0, "草": 0.5, "电": 0.5},
	"普": {"岩": 0.5},
}

static func effectiveness(move_type: String, def_types: Array) -> float:
	var mult := 1.0
	var row: Dictionary = CHART.get(move_type, {})
	for t in def_types:
		mult *= float(row.get(t, 1.0))
	return mult

# ===== 异常状态 =====
const STATUS_NAMES := {"psn": "中毒", "brn": "灼伤", "par": "麻痹"}
const STATUS_COLORS := {"psn": Color(0.65, 0.35, 0.75), "brn": Color(0.92, 0.45, 0.2), "par": Color(0.85, 0.75, 0.2)}

# ===== 技能 =====
# effect: {kind:"status", status:"psn/brn/par", chance:百分比, target:"enemy"}
#         {kind:"stage", stat:"atk/def/spd", delta:±1, chance:100, target:"enemy/self"}
# power 0 = 变化技
const MOVES := {
	"zhuangji":   {"name": "撞击",     "type": "普", "power": 40, "acc": 100, "pp": 35},
	"mengzhuang": {"name": "猛撞",     "type": "普", "power": 70, "acc": 90,  "pp": 15},
	"zhongji":    {"name": "重击",     "type": "普", "power": 85, "acc": 85,  "pp": 10},
	"dianguang":  {"name": "电光一闪", "type": "普", "power": 40, "acc": 100, "pp": 30},
	"zhuo":       {"name": "啄",       "type": "飞", "power": 35, "acc": 100, "pp": 35},
	"jiaosheng":  {"name": "叫声",     "type": "普", "power": 0,  "acc": 100, "pp": 30, "effect": {"kind": "stage", "stat": "atk", "delta": -1, "chance": 100, "target": "enemy"}},
	"ciya":       {"name": "龇牙",     "type": "普", "power": 0,  "acc": 100, "pp": 30, "effect": {"kind": "stage", "stat": "def", "delta": -1, "chance": 100, "target": "enemy"}},
	"yinghua":    {"name": "硬化",     "type": "普", "power": 0,  "acc": 100, "pp": 25, "effect": {"kind": "stage", "stat": "def", "delta": 1, "chance": 100, "target": "self"}},
	"tengbian":   {"name": "藤鞭",     "type": "草", "power": 45, "acc": 100, "pp": 25},
	"yeren":      {"name": "叶刃",     "type": "草", "power": 55, "acc": 95,  "pp": 25},
	"xiqu":       {"name": "吸取",     "type": "草", "power": 20, "acc": 100, "pp": 25, "drain": true},
	"guanghe":    {"name": "光合吸取", "type": "草", "power": 65, "acc": 100, "pp": 12, "drain": true},
	"baozifen":   {"name": "孢子粉",   "type": "草", "power": 0,  "acc": 75,  "pp": 20, "effect": {"kind": "status", "status": "psn", "chance": 100, "target": "enemy"}},
	"huohua":     {"name": "火花",     "type": "火", "power": 40, "acc": 100, "pp": 25},
	"zhuoshao":   {"name": "灼热吐息", "type": "火", "power": 60, "acc": 100, "pp": 15, "effect": {"kind": "status", "status": "brn", "chance": 15, "target": "enemy"}},
	"huoyanya":   {"name": "火焰牙",   "type": "火", "power": 65, "acc": 95,  "pp": 15, "effect": {"kind": "status", "status": "brn", "chance": 10, "target": "enemy"}},
	"lieyan":     {"name": "烈焰冲撞", "type": "火", "power": 85, "acc": 90,  "pp": 10, "effect": {"kind": "status", "status": "brn", "chance": 10, "target": "enemy"}},
	"shuiqiang":  {"name": "水枪",     "type": "水", "power": 40, "acc": 100, "pp": 25},
	"shuibo":     {"name": "水波",     "type": "水", "power": 60, "acc": 100, "pp": 18},
	"paomo":      {"name": "泡沫光线", "type": "水", "power": 65, "acc": 100, "pp": 20},
	"jiliu":      {"name": "激流喷射", "type": "水", "power": 85, "acc": 90,  "pp": 10},
	"duci":       {"name": "毒刺",     "type": "虫", "power": 25, "acc": 100, "pp": 30, "effect": {"kind": "status", "status": "psn", "chance": 25, "target": "enemy"}},
	"fengren":    {"name": "风刃",     "type": "飞", "power": 55, "acc": 100, "pp": 22},
	"fenglie":    {"name": "烈风",     "type": "飞", "power": 75, "acc": 95,  "pp": 12},
	"luoshi":     {"name": "落石",     "type": "岩", "power": 50, "acc": 95,  "pp": 22},
	"yanbeng":    {"name": "岩崩",     "type": "岩", "power": 75, "acc": 90,  "pp": 12},
	"dianji":     {"name": "电击",     "type": "电", "power": 40, "acc": 100, "pp": 28, "effect": {"kind": "status", "status": "par", "chance": 10, "target": "enemy"}},
	"luolei":     {"name": "落雷",     "type": "电", "power": 75, "acc": 95,  "pp": 12, "effect": {"kind": "status", "status": "par", "chance": 10, "target": "enemy"}},
	"mabifen":    {"name": "麻痹粉",   "type": "草", "power": 0,  "acc": 75,  "pp": 20, "effect": {"kind": "status", "status": "par", "chance": 100, "target": "enemy"}},
}

# ===== 宝可梦图鉴（原创设计） =====
# learnset: 按等级学会的技能；实例自动取等级最近的 4 个
const SPECIES := {
	"leafdra": {
		"dex": 1, "name": "叶芽犬", "types": ["草"],
		"base": {"hp": 45, "atk": 49, "def": 49, "spd": 45},
		"learnset": [[1, "zhuangji"], [1, "jiaosheng"], [5, "tengbian"], [9, "yeren"], [13, "yinghua"], [18, "guanghe"], [22, "mengzhuang"]],
		"evolve": {"to": "verdhound", "level": 16},
		"catch": 0.45, "base_exp": 64,
		"sprite": "res://assets/monsters/starter_grass.png",
		"desc": "头顶嫩芽、围着叶片披肩的小狗，晒太阳时嫩芽会微微发光。",
	},
	"verdhound": {
		"dex": 2, "name": "叶冠犬", "types": ["草"],
		"base": {"hp": 62, "atk": 73, "def": 70, "spd": 64},
		"learnset": [[1, "zhuangji"], [1, "jiaosheng"], [5, "tengbian"], [9, "yeren"], [13, "yinghua"], [18, "guanghe"], [22, "mengzhuang"], [26, "zhongji"]],
		"catch": 0.22, "base_exp": 142,
		"sprite": "res://assets/monsters/verdhound.png",
		"desc": "叶芽犬的进化形。头顶的嫩芽绽放成翠绿叶冠，奔跑时洒下点点花粉。",
	},
	"flarefox": {
		"dex": 3, "name": "炎尾狐", "types": ["火"],
		"base": {"hp": 39, "atk": 52, "def": 43, "spd": 65},
		"learnset": [[1, "zhuangji"], [1, "ciya"], [5, "huohua"], [9, "zhuoshao"], [13, "dianguang"], [18, "huoyanya"], [22, "lieyan"]],
		"evolve": {"to": "blazefox", "level": 16},
		"catch": 0.45, "base_exp": 62,
		"sprite": "res://assets/monsters/starter_fire.png",
		"desc": "尾巴尖上燃着小小的火苗，心情越好火苗越旺。",
	},
	"blazefox": {
		"dex": 4, "name": "炎魄狐", "types": ["火"],
		"base": {"hp": 56, "atk": 76, "def": 58, "spd": 82},
		"learnset": [[1, "zhuangji"], [1, "ciya"], [5, "huohua"], [9, "zhuoshao"], [13, "dianguang"], [18, "huoyanya"], [22, "lieyan"], [26, "zhongji"]],
		"catch": 0.22, "base_exp": 145,
		"sprite": "res://assets/monsters/blazefox.png",
		"desc": "炎尾狐的进化形。三条火焰尾如流星拖曳，怒时周身腾起赤红烈焰。",
	},
	"aquaturt": {
		"dex": 5, "name": "水灵螈", "types": ["水"],
		"base": {"hp": 44, "atk": 48, "def": 65, "spd": 43},
		"learnset": [[1, "zhuangji"], [1, "yinghua"], [5, "shuiqiang"], [9, "shuibo"], [13, "paomo"], [18, "jiliu"], [22, "mengzhuang"]],
		"evolve": {"to": "tidesal", "level": 16},
		"catch": 0.45, "base_exp": 63,
		"sprite": "res://assets/monsters/starter_water.png",
		"desc": "头顶水滴饰角的小水螈，腮边绒毛会随心情轻轻摆动。",
	},
	"tidesal": {
		"dex": 6, "name": "澜尾螈", "types": ["水"],
		"base": {"hp": 64, "atk": 66, "def": 84, "spd": 56},
		"learnset": [[1, "zhuangji"], [1, "yinghua"], [5, "shuiqiang"], [9, "shuibo"], [13, "paomo"], [18, "jiliu"], [22, "mengzhuang"], [26, "zhongji"]],
		"catch": 0.22, "base_exp": 144,
		"sprite": "res://assets/monsters/tidesal.png",
		"desc": "水灵螈的进化形。背鳍如海浪般起伏，能在湍流中稳稳立住身形。",
	},
	"fluffrat": {
		"dex": 7, "name": "绒绒鼠", "types": ["普"],
		"base": {"hp": 38, "atk": 50, "def": 35, "spd": 60},
		"learnset": [[1, "zhuangji"], [4, "ciya"], [8, "dianguang"], [13, "mengzhuang"]],
		"catch": 0.70, "base_exp": 51,
		"sprite": "res://assets/monsters/rat.png",
		"desc": "脸颊毛茸茸的小老鼠，最喜欢收集亮晶晶的小石子。",
	},
	"chirpie": {
		"dex": 8, "name": "啾啾雀", "types": ["飞"],
		"base": {"hp": 40, "atk": 45, "def": 40, "spd": 56},
		"learnset": [[1, "zhuo"], [4, "jiaosheng"], [9, "fengren"], [15, "fenglie"]],
		"catch": 0.70, "base_exp": 50,
		"sprite": "res://assets/monsters/bird.png",
		"desc": "清晨在青叶镇上空盘旋，叫声清脆悦耳。",
	},
	"shroomite": {
		"dex": 9, "name": "菇菇虫", "types": ["虫", "草"],
		"base": {"hp": 50, "atk": 42, "def": 50, "spd": 30},
		"learnset": [[1, "zhuangji"], [5, "xiqu"], [9, "baozifen"], [13, "duci"]],
		"catch": 0.60, "base_exp": 54,
		"sprite": "res://assets/monsters/bugshroom.png",
		"desc": "背上长着小蘑菇的幼虫，雨后会成群出现在草丛里。",
	},
	"rockrab": {
		"dex": 10, "name": "石拳蟹", "types": ["岩"],
		"base": {"hp": 48, "atk": 60, "def": 70, "spd": 28},
		"learnset": [[1, "zhuangji"], [6, "luoshi"], [11, "yinghua"], [16, "yanbeng"]],
		"catch": 0.50, "base_exp": 72,
		"sprite": "res://assets/monsters/rockrab.png",
		"desc": "钳子由坚硬的岩石构成，挥拳时能击碎挡路的大石。",
	},
	"voltweasel": {
		"dex": 11, "name": "电光鼬", "types": ["电"],
		"base": {"hp": 40, "atk": 56, "def": 40, "spd": 72},
		"learnset": [[1, "zhuangji"], [6, "dianji"], [11, "dianguang"], [16, "luolei"]],
		"catch": 0.50, "base_exp": 70,
		"sprite": "res://assets/monsters/voltweasel.png",
		"desc": "奔跑时浑身迸发蓝白色电花，尾巴是天然的避雷针。",
	},
	"bubblefrog": {
		"dex": 12, "name": "波纹蛙", "types": ["水"],
		"base": {"hp": 46, "atk": 50, "def": 48, "spd": 58},
		"learnset": [[1, "zhuangji"], [6, "shuiqiang"], [11, "shuibo"], [16, "jiliu"]],
		"catch": 0.50, "base_exp": 68,
		"sprite": "res://assets/monsters/bubblefrog.png",
		"desc": "鼓起腮帮吹出的泡泡又圆又亮，雨天心情格外好。",
	},
	"nightowl": {
		"dex": 13, "name": "夜翎枭", "types": ["飞"],
		"base": {"hp": 52, "atk": 55, "def": 50, "spd": 62},
		"learnset": [[1, "zhuo"], [6, "fengren"], [12, "jiaosheng"], [16, "fenglie"]],
		"catch": 0.45, "base_exp": 75,
		"sprite": "res://assets/monsters/nightowl.png",
		"desc": "暮色降临时无声滑翔，月白色的羽环在夜里微微发亮。",
	},
	"magmander": {
		"dex": 14, "name": "熔岩蜥", "types": ["火"],
		"base": {"hp": 50, "atk": 64, "def": 52, "spd": 55},
		"learnset": [[1, "zhuangji"], [6, "huohua"], [11, "zhuoshao"], [17, "lieyan"]],
		"catch": 0.40, "base_exp": 80,
		"sprite": "res://assets/monsters/magmander.png",
		"desc": "背脊的纹路像缓缓流动的岩浆，生气时体温会骤然升高。",
	},
	"boulderturt": {
		"dex": 15, "name": "岩盾龟", "types": ["岩"],
		"base": {"hp": 66, "atk": 55, "def": 88, "spd": 20},
		"learnset": [[1, "zhuangji"], [6, "luoshi"], [11, "yinghua"], [17, "yanbeng"]],
		"catch": 0.40, "base_exp": 82,
		"sprite": "res://assets/monsters/boulderturt.png",
		"desc": "龟壳是由古老山岩长成的天然要塞，认定的地方绝不后退。",
	},
	"thunderhawk": {
		"dex": 16, "name": "雷鸣鹰", "types": ["电", "飞"],
		"base": {"hp": 56, "atk": 72, "def": 55, "spd": 88},
		"learnset": [[1, "zhuo"], [8, "dianji"], [14, "fengren"], [20, "luolei"]],
		"catch": 0.30, "base_exp": 95,
		"sprite": "res://assets/monsters/thunderhawk.png",
		"desc": "俯冲时羽翼劈开空气发出雷鸣般的轰响，是胜利之路的霸主。",
	},
}

const DEX_ORDER := ["leafdra", "verdhound", "flarefox", "blazefox", "aquaturt", "tidesal",
	"fluffrat", "chirpie", "shroomite", "rockrab", "voltweasel", "bubblefrog",
	"nightowl", "magmander", "boulderturt", "thunderhawk"]

# ===== 道具 =====
const ITEMS := {
	"pokeball":     {"name": "精灵球",   "desc": "用于捕捉野生宝可梦。", "price": 200},
	"potion":       {"name": "伤药",     "desc": "恢复 20 点 HP。", "heal": 20, "price": 300},
	"super_potion": {"name": "好伤药",   "desc": "恢复 60 点 HP。", "heal": 60, "price": 700},
	"full_heal":    {"name": "万能药",   "desc": "治愈全部异常状态。", "cure": true, "price": 600},
}
const SHOP_STOCK := ["pokeball", "potion", "super_potion", "full_heal"]

# ===== 训练家 =====
const TRAINERS := {
	"t_route2_a": {
		"name": "短裤小子·阿树", "team": [["fluffrat", 8], ["chirpie", 8]], "reward": 320,
		"intro": ["阿树：短裤穿起来\n跑步可快了！来比一场吧！"],
		"win_lines": ["阿树：呜哇，输啦！"],
		"after": ["阿树：你的宝可梦跑得比我还快……"],
	},
	"t_route2_b": {
		"name": "捕虫少年·小绿", "team": [["shroomite", 9], ["shroomite", 10]], "reward": 360,
		"intro": ["小绿：我的菇菇虫\n可是精心培育的！"],
		"win_lines": ["小绿：菇菇虫，对不起……"],
		"after": ["小绿：等菇菇虫再长大一点，\n我就去挑战道馆！"],
	},
	"gym1": {
		"name": "道馆主·磐石", "team": [["rockrab", 12], ["boulderturt", 13]], "reward": 1500,
		"badge": "badge1", "badge_name": "岩岸徽章",
		"intro": ["磐石：我是岩岸道馆的馆主——磐石！", "磐石：让我看看你的意志\n是否如岩石般坚定！"],
		"win_lines": ["磐石：好一场酣畅淋漓的对战！", "磐石：这枚「岩岸徽章」是你应得的！"],
		"after": ["磐石：往东走就是 2 号道路，\n去会一会临波市的澜心吧！"],
	},
	"t_route3_a": {
		"name": "泳气少女·小波", "team": [["bubblefrog", 14], ["bubblefrog", 15]], "reward": 560,
		"intro": ["小波：海边长大的孩子\n可不会轻易认输哦！"],
		"win_lines": ["小波：哇，被冲垮啦！"],
		"after": ["小波：临波市的馆主澜心姐姐\n超级温柔又超级强！"],
	},
	"t_route3_b": {
		"name": "飞鸟使·风羽", "team": [["chirpie", 15], ["nightowl", 15]], "reward": 600,
		"intro": ["风羽：我的伙伴们\n是天空的主人！"],
		"win_lines": ["风羽：竟然连夜翎枭都……"],
		"after": ["风羽：夜翎枭只在黄昏出没，\n你见过它滑翔的样子吗？"],
	},
	"gym2": {
		"name": "道馆主·澜心", "team": [["bubblefrog", 17], ["tidesal", 18]], "reward": 2100,
		"badge": "badge2", "badge_name": "临波徽章",
		"intro": ["澜心：欢迎来到临波市～", "澜心：那么，让海浪来检验\n你们的羁绊吧！"],
		"win_lines": ["澜心：好厉害……完全被你的气势压过了呢。", "澜心：「临波徽章」请收下吧～"],
		"after": ["澜心：北边的 3 号道路通往烬原镇，\n焰罗前辈的火焰可不好对付哦～"],
	},
	"t_route4_a": {
		"name": "登山客·岩生", "team": [["boulderturt", 19], ["rockrab", 19]], "reward": 760,
		"intro": ["岩生：能爬到这里，\n你已经很了不起了！"],
		"win_lines": ["岩生：连我的岩盾龟都挡不住！"],
		"after": ["岩生：胜利之路的尽头就是青峰联盟，\n加油啊，年轻人！"],
	},
	"t_route4_b": {
		"name": "精英学员·雷娜", "team": [["voltweasel", 20], ["thunderhawk", 20]], "reward": 800,
		"intro": ["雷娜：联盟挑战者？\n先过我这一关再说！"],
		"win_lines": ["雷娜：好快的攻势……完败。"],
		"after": ["雷娜：冠军大人就在前面的联盟殿堂，\n他还从来没输过呢。"],
	},
	"gym3": {
		"name": "道馆主·焰罗", "team": [["magmander", 21], ["blazefox", 22]], "reward": 2800,
		"badge": "badge3", "badge_name": "烬原徽章",
		"intro": ["焰罗：呵，又一个想要徽章的年轻人。", "焰罗：那就让烈焰\n烧尽你的天真吧！"],
		"win_lines": ["焰罗：……火焰熄灭了。痛快！", "焰罗：拿着「烬原徽章」，\n去胜利之路证明自己吧！"],
		"after": ["焰罗：东边就是胜利之路。\n冠军在联盟殿堂等着你。"],
	},
}

static func species(id: String) -> Dictionary:
	return SPECIES.get(id, {})

static func move(id: String) -> Dictionary:
	return MOVES.get(id, {})

static func trainer(id: String) -> Dictionary:
	return TRAINERS.get(id, {})

# 按等级返回最近学会的至多 4 个技能 id
static func moves_at_level(species_id: String, level: int) -> Array:
	var learned: Array = []
	for entry in species(species_id).get("learnset", []):
		if int(entry[0]) <= level:
			var mid: String = str(entry[1])
			learned.erase(mid)
			learned.append(mid)
	if learned.size() > 4:
		learned = learned.slice(learned.size() - 4)
	if learned.is_empty():
		learned = ["zhuangji"]
	return learned
