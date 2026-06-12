extends Node
# 截图/调试启动参数（autoload: Shot）
# 用法: godot --path . -- --shot /tmp/out.png --frames 40 --start world --pick 1

var shot_path := ""
var frames_left := -1
var start_screen := ""   # title / world / battle / rival / trainer / credits
var pick_starter := -1   # 0/1/2 自动领取御三家
var start_map := ""
var start_cell := Vector2i(-1, -1)
var start_lv := 0                       # 测试用：拔高首发等级
var start_flags: PackedStringArray = [] # 测试用：预置 flags（逗号分隔）
var start_trainer := ""                 # 测试用：直接挑战训练家 id
var auto_confirm := false
var walk := ""           # 自动走路方向序列，如 "uuuulldd"
var presses: Array = []  # [[frame, action], ...] 测试用：指定帧触发按键
var do_save_at := -1     # 测试用：指定帧调用存档
var _ac_t := 0
var _walk_t := 0
var _walk_i := 0
var _press_t := 0
var _cur_act := ""
const DIR_ACTIONS := {"u": "move_up", "d": "move_down", "l": "move_left", "r": "move_right"}

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--shot":
				if i + 1 < args.size(): shot_path = args[i + 1]; i += 1
			"--frames":
				if i + 1 < args.size(): frames_left = int(args[i + 1]); i += 1
			"--start":
				if i + 1 < args.size(): start_screen = args[i + 1]; i += 1
			"--pick":
				if i + 1 < args.size(): pick_starter = int(args[i + 1]); i += 1
			"--map":
				if i + 1 < args.size(): start_map = args[i + 1]; i += 1
			"--cell":
				if i + 1 < args.size():
					var parts: PackedStringArray = args[i + 1].split(",")
					if parts.size() == 2:
						start_cell = Vector2i(int(parts[0]), int(parts[1]))
					i += 1
			"--auto-confirm":
				auto_confirm = true
			"--walk":
				if i + 1 < args.size(): walk = args[i + 1]; i += 1
			"--lv":
				if i + 1 < args.size(): start_lv = int(args[i + 1]); i += 1
			"--flags":
				if i + 1 < args.size(): start_flags = args[i + 1].split(","); i += 1
			"--trainer":
				if i + 1 < args.size(): start_trainer = args[i + 1]; i += 1
			"--press":
				if i + 1 < args.size():
					for part in args[i + 1].split(","):
						var kv: PackedStringArray = part.split("@")
						if kv.size() == 2:
							presses.append([int(kv[1]), kv[0]])
					i += 1
			"--do-save":
				if i + 1 < args.size(): do_save_at = int(args[i + 1]); i += 1
		i += 1

func _process(_delta: float) -> void:
	if walk != "":
		_walk_t += 1
		if _walk_t % 14 == 1 and _walk_i < walk.length():
			var c := walk[_walk_i]
			_walk_i += 1
			if DIR_ACTIONS.has(c):
				_cur_act = DIR_ACTIONS[c]
				Input.action_press(_cur_act)
		elif _walk_t % 14 == 8 and _cur_act != "":
			Input.action_release(_cur_act)
			_cur_act = ""
	if not presses.is_empty() or do_save_at >= 0:
		_press_t += 1
		for p in presses:
			if int(p[0]) == _press_t:
				_tap_action(str(p[1]))
		if _press_t == do_save_at:
			var w := get_tree().get_first_node_in_group("world")
			if w != null:
				Game.save_game(w.cell)
				print("[Shot] 已存档 map=%s cell=%s" % [Game.map_id, w.cell])
	if auto_confirm:
		_ac_t += 1
		# 错开节拍：confirm 推进对话，ui_accept 按下聚焦的按钮
		if _ac_t % 22 == 0:
			_tap_action("confirm")
		elif _ac_t % 22 == 11:
			_tap_action("ui_accept")
	if shot_path == "" or frames_left < 0:
		return
	_take_shot_countdown()

func _tap_action(act: String) -> void:
	var ev := InputEventAction.new()
	ev.action = act
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventAction.new()
	ev2.action = act
	ev2.pressed = false
	Input.parse_input_event(ev2)

func _take_shot_countdown() -> void:
	frames_left -= 1
	if frames_left <= 0:
		var img := get_viewport().get_texture().get_image()
		var err := img.save_png(shot_path)
		print("[Shot] 保存截图 %s err=%d" % [shot_path, err])
		shot_path = ""
		get_tree().quit()
