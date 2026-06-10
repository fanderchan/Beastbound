extends Node
# 截图/调试启动参数（autoload: Shot）
# 用法: godot --path . -- --shot /tmp/out.png --frames 40 --start world --pick 1

var shot_path := ""
var frames_left := -1
var start_screen := ""   # title / world / battle / rival
var pick_starter := -1   # 0/1/2 自动领取御三家
var start_map := ""
var start_cell := Vector2i(-1, -1)

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
		i += 1

func _process(_delta: float) -> void:
	if shot_path == "" or frames_left < 0:
		return
	frames_left -= 1
	if frames_left <= 0:
		var img := get_viewport().get_texture().get_image()
		var err := img.save_png(shot_path)
		print("[Shot] 保存截图 %s err=%d" % [shot_path, err])
		shot_path = ""
		get_tree().quit()
