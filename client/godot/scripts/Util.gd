class_name Util
extends RefCounted

# 容错加载贴图：缺失时返回纯色占位，保证开发期可运行
static func load_tex(path: String, placeholder_size := Vector2i(64, 64), color := Color(0.8, 0.3, 0.8)) -> Texture2D:
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t != null:
			return t
	var img := Image.create(placeholder_size.x, placeholder_size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("缺少数据文件: " + path)
		return {}
	var txt := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(txt)
	if data is Dictionary:
		return data
	push_error("JSON 解析失败: " + path)
	return {}
