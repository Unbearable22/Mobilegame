class_name SaveManager
extends RefCounted
const VERSION: int = 1
var path: String
var last_error: Error = OK
var warning: String = ""
func _init(file_path: String = "user://progress.json") -> void:
	path = file_path
static func defaults() -> Dictionary:
	return {"version": VERSION, "last_level": 1, "completed": {}, "sound": true}
func read() -> Dictionary:
	warning = ""
	if not FileAccess.file_exists(path): return defaults()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		warning = "Не удалось прочитать сохранение."
		return defaults()
	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	var parsed: Variant = parser.data if parse_error == OK else null
	file.close()
	if not parsed is Dictionary or parsed.get("version", -1) != VERSION:
		warning = "Сохранение повреждено или имеет другую версию. Создан новый прогресс."
		var backup_error: Error = DirAccess.copy_absolute(path, path + ".corrupt")
		if backup_error != OK: warning += " Резервная копия недоступна."
		return defaults()
	return sanitize(parsed)
static func sanitize(raw: Dictionary) -> Dictionary:
	var clean: Dictionary = defaults()
	var selected: Variant = raw.get("last_level", 1)
	if (selected is float or selected is int) and selected >= 1 and selected <= 10 and selected == floor(selected):
		clean.last_level = int(selected)
	if raw.get("sound") is bool: clean.sound = raw.sound
	if raw.get("completed") is Dictionary:
		for key in raw.completed:
			var id: String = str(key)
			var stars: Variant = raw.completed[key]
			if id.is_valid_int() and int(id) >= 1 and int(id) <= 10 and str(int(id)) == id:
				if (stars is float or stars is int) and stars >= 1 and stars <= 3 and stars == floor(stars):
					clean.completed[id] = int(stars)
	return clean
func write(data: Dictionary) -> Error:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = FileAccess.get_open_error()
		return last_error
	file.store_string(JSON.stringify(sanitize(data)))
	file.flush()
	last_error = file.get_error()
	file.close()
	if last_error != OK: return last_error
	last_error = DirAccess.rename_absolute(path + ".tmp", path)
	return last_error
