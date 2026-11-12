class_name SaveManager
extends RefCounted
const Catalog = preload("res://scripts/core/chapter_catalog.gd")
const Achievements = preload("res://scripts/core/achievement_catalog.gd")
const Themes = preload("res://scripts/core/theme_catalog.gd")
const Statistics = preload("res://scripts/core/statistics_manager.gd")
const Daily=preload("res://scripts/core/daily_catalog.gd")
const Reactor=preload("res://scripts/core/reactor_catalog.gd")
const VERSION: int = 4
var path: String
var last_error: Error = OK
var warning: String = ""
func _init(file_path: String = "user://progress.json") -> void:
	path = file_path
static func defaults() -> Dictionary:
	return {"version": VERSION, "last_level": 1, "completed": {}, "sound": true, "unlocked_chapters": [1], "achievements": {}, "theme": "neon", "reduced_effects": false, "daily":{},"daily_runs":{},"reactor":{"sectors":[],"pulse_style":"standard","reactor_style":"orbital","rewards":{"legacy_themes":false,"solar_gold":false,"braided":false,"prismatic":false}}, "statistics": {"levels":{}, "last_played_level":0}}
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
	if not parsed is Dictionary or (parsed.get("version", -1) != 1 and parsed.get("version", -1) != 2 and parsed.get("version", -1) != 3 and parsed.get("version", -1) != VERSION):
		warning = "Сохранение повреждено или имеет другую версию. Создан новый прогресс."
		var backup_error: Error = DirAccess.copy_absolute(path, path + ".corrupt")
		if backup_error != OK: warning += " Резервная копия недоступна."
		return defaults()
	var backup_suffix: String = ".v%d.bak" % int(parsed.get("version"))
	if int(parsed.get("version")) in [1,2,3] and not FileAccess.file_exists(path + backup_suffix):
		var backup_result: Error = DirAccess.copy_absolute(path,path + backup_suffix)
		if backup_result != OK: warning = "Не удалось создать резервную копию старого прогресса."
	return sanitize(parsed)
static func sanitize(raw: Dictionary) -> Dictionary:
	var clean: Dictionary = defaults()
	var selected: Variant = raw.get("last_level", 1)
	if (selected is float or selected is int) and is_finite(float(selected)) and selected >= 1 and selected <= Catalog.LEVEL_COUNT and selected == floor(selected):
		clean.last_level = int(selected)
	if raw.get("sound") is bool: clean.sound = raw.sound
	if raw.get("completed") is Dictionary:
		for key in raw.completed:
			var id: String = str(key)
			var stars: Variant = raw.completed[key]
			if id.is_valid_int() and int(id) >= 1 and int(id) <= Catalog.LEVEL_COUNT and str(int(id)) == id:
				if (stars is float or stars is int) and is_finite(float(stars)) and stars >= 1 and stars <= 3 and stars == floor(stars):
					clean.completed[id] = int(stars)
	var unlocked: Array = [1]
	var legacy: bool=int(raw.get("version",VERSION))<4
	if raw.get("unlocked_chapters") is Array:
		for value in raw.unlocked_chapters:
			if not (value is int or value is float) or not is_finite(float(value)) or value!=floor(value): continue
			var chapter: int=int(value)
			if legacy:
				if chapter<1 or chapter>5: continue
				for id in range((chapter-1)*10+1,chapter*10+1):
					var mapped: int=Catalog.chapter_for_level(id)
					if not mapped in unlocked: unlocked.append(mapped)
			elif Catalog.available(chapter) and not chapter in unlocked: unlocked.append(chapter)
	var visited: int = Catalog.chapter_for_level(int(clean.last_level))
	if Catalog.available(visited) and not visited in unlocked: unlocked.append(visited)
	for key in clean.completed:
		var chapter: int=Catalog.chapter_for_level(int(key))
		if not chapter in unlocked: unlocked.append(chapter)
	for chapter in range(1,Catalog.AVAILABLE_CHAPTERS):
		var finished: bool=true
		for id in range((chapter-1)*25+1,chapter*25+1):
			if not clean.completed.has(str(id)): finished=false
		if finished and not chapter+1 in unlocked: unlocked.append(chapter+1)
	unlocked.sort()
	clean.unlocked_chapters=unlocked
	if raw.get("achievements") is Dictionary:
		for entry in Achievements.ACHIEVEMENTS:
			if raw.achievements.get(entry.id) is bool and raw.achievements.get(entry.id) == true:
				clean.achievements[entry.id] = true
	if raw.get("reduced_effects") is bool: clean.reduced_effects = raw.reduced_effects
	if raw.get("theme") is String and Themes.unlocked(raw.theme,clean): clean.theme = raw.theme
	clean.statistics = Statistics.sanitize(raw.get("statistics", {}))
	clean.daily=Daily.sanitize(raw.get("daily",{}))
	clean.daily_runs=Daily.sanitize_runs(raw.get("daily_runs",{}))
	clean.reactor=Reactor.sanitize(raw.get("reactor",{}),clean)
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
