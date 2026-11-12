class_name ProgressionManager
extends RefCounted
const Catalog = preload("res://scripts/core/chapter_catalog.gd")
const Achievements = preload("res://scripts/core/achievement_catalog.gd")
const Themes = preload("res://scripts/core/theme_catalog.gd")
signal achievements_unlocked(ids: Array)
const Save = preload("res://scripts/core/save_manager.gd")
var save: RefCounted
var data: Dictionary
var last_error: Error = OK
func _init(storage: RefCounted = null) -> void:
	save = storage if storage != null else Save.new()
	data = save.read()
	# Retrospective grants are persisted silently; startup never queues award notices.
	if not _grant_achievements().is_empty(): last_error = save.write(data)
func select_level(id: int) -> void:
	if id < 1 or id > Catalog.LEVEL_COUNT or not chapter_unlocked(Catalog.chapter_for_level(id)): return
	data.last_level = id
	last_error = save.write(data)
func complete(id: int, stars: int) -> void:
	if id < 1 or id > Catalog.LEVEL_COUNT: return
	data.completed[str(id)] = maxi(int(data.completed.get(str(id), 0)), clampi(stars, 1, 3))
	data = Save.sanitize(data)
	var granted: Array = _grant_achievements()
	last_error = save.write(data)
	if not granted.is_empty(): achievements_unlocked.emit(granted)
func set_sound(enabled: bool) -> void:
	data.sound = enabled
	last_error = save.write(data)
func total_stars() -> int:
	var total: int = 0
	for value in data.completed.values(): total += int(value)
	return total

func chapter_unlocked(chapter: int) -> bool:
	return Catalog.available(chapter) and chapter in data.unlocked_chapters
func chapter_progress(chapter: int) -> Dictionary:
	var won: int = 0
	var stars: int = 0
	for id in range((chapter-1)*25+1,chapter*25+1):
		if data.completed.has(str(id)):
			won += 1
			stars += int(data.completed[str(id)])
	return {"completed": won, "stars": stars, "unlocked": chapter_unlocked(chapter)}

func achievement_status() -> Array:
	return Achievements.status(data)
func _grant_achievements() -> Array:
	var granted: Array = []
	for row in achievement_status():
		if row.current >= row.goal and not row.unlocked:
			data.achievements[row.id] = true
			granted.append(row.id)
	return granted
func theme_unlocked(id: String) -> bool:
	return Themes.unlocked(id,data)
