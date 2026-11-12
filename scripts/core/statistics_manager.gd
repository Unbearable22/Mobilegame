class_name StatisticsManager
extends RefCounted
## Local aggregate counters only. A terminal attempt can be resumed via Undo;
## its work/time continues, but its first terminal outcome is counted exactly once.
## Later real wins can improve personal bests without counting another outcome.
const MAX_COUNTER: int = 1000000000
const COUNTERS: Array = ["attempts", "restarts", "wins", "losses", "launches", "rotations", "undos", "best_stars", "best_launches"]
var progress: RefCounted
var data: Dictionary
var dirty: bool = false
var last_export_path: String = ""
var last_error: Error = OK
var level_id: int = 0
var started: bool = false
var active: bool = false
var outcome_recorded: bool = false
var attempt_seconds: float = 0.0
func _init(progression: RefCounted) -> void:
	progress = progression
	data = sanitize(progress.data.get("statistics", {}))
	progress.data.statistics = data
static func empty_level() -> Dictionary:
	return {"attempts":0,"restarts":0,"wins":0,"losses":0,"launches":0,"rotations":0,"undos":0,"active_seconds":0.0,"best_stars":0,"best_launches":0,"best_seconds":0.0}
static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= MAX_COUNTER
static func sanitize(raw: Variant) -> Dictionary:
	var clean: Dictionary = {"levels":{}, "last_played_level":0}
	if not raw is Dictionary: return clean
	var last: Variant = raw.get("last_played_level",0)
	if number(last) and last == floor(last) and last <= 100: clean.last_played_level = int(last)
	if not raw.get("levels") is Dictionary: return clean
	for key in raw.levels:
		var id: String = str(key)
		if not id.is_valid_int() or str(int(id)) != id or int(id) < 1 or int(id) > 100 or not raw.levels[key] is Dictionary: continue
		var source: Dictionary = raw.levels[key]
		var row: Dictionary = empty_level()
		for counter in COUNTERS:
			var value: Variant = source.get(counter,0)
			if number(value) and value == floor(value): row[counter] = int(value)
		row.best_stars = mini(row.best_stars,3)
		for field in ["active_seconds","best_seconds"]:
			if number(source.get(field,0)): row[field] = float(source.get(field,0))
		clean.levels[id] = row
	return clean
func select(id: int) -> void:
	level_id = id
	started = false
	active = false
	outcome_recorded = false
	attempt_seconds = 0.0
func _row() -> Dictionary:
	var key: String = str(level_id)
	if not data.levels.has(key): data.levels[key] = empty_level()
	return data.levels[key]
func action(kind: String) -> void:
	if level_id < 1 or level_id > 100: return
	if not started:
		started = true
		active = true
		data.last_played_level = level_id
		_increment("attempts")
	_increment(kind)
func _increment(field: String) -> void:
	var row: Dictionary = _row()
	row[field] = mini(int(row[field])+1, MAX_COUNTER)
	dirty = true
func restart() -> void:
	if level_id >= 1 and level_id <= 100: _increment("restarts")
func undo() -> void:
	if started:
		active = true
		_increment("undos")
func tick(delta: float) -> void:
	if not started or not active or not is_finite(delta) or delta <= 0: return
	var row: Dictionary = _row()
	attempt_seconds = minf(attempt_seconds+delta,MAX_COUNTER)
	row.active_seconds = minf(float(row.active_seconds)+delta,MAX_COUNTER)
	dirty = true
func finish(won: bool, stars: int, launches: int) -> void:
	if not started: return
	active = false
	var row: Dictionary = _row()
	if not outcome_recorded:
		outcome_recorded = true
		_increment("wins" if won else "losses")
	if won:
		var first_win: bool = int(row.best_stars) == 0
		row.best_stars = maxi(int(row.best_stars),clampi(stars,1,3))
		row.best_launches = launches if first_win else mini(int(row.best_launches),launches)
		row.best_seconds = attempt_seconds if first_win else minf(float(row.best_seconds),attempt_seconds)
func summary() -> Dictionary:
	return sanitize(data)
func flush() -> Error:
	if not dirty: return OK
	progress.data.statistics = summary()
	last_error = progress.save.write(progress.data)
	progress.last_error = last_error
	if last_error == OK: dirty = false
	return last_error
func export_json(path: String) -> Error:
	var file := FileAccess.open(path+".tmp", FileAccess.WRITE)
	if file == null:
		last_error = FileAccess.get_open_error()
		return last_error
	file.store_string(JSON.stringify(summary(), "\t"))
	file.flush()
	last_error = file.get_error()
	file.close()
	if last_error != OK: return last_error
	last_error = DirAccess.rename_absolute(path+".tmp",path)
	if last_error == OK: last_export_path = path
	return last_error
