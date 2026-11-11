class_name ProgressionManager
extends RefCounted
const Save = preload("res://scripts/core/save_manager.gd")
var save: RefCounted
var data: Dictionary
var last_error: Error = OK
func _init(storage: RefCounted = null) -> void:
	save = storage if storage != null else Save.new()
	data = save.read()
func select_level(id: int) -> void:
	data.last_level = clampi(id, 1, 10)
	last_error = save.write(data)
func complete(id: int, stars: int) -> void:
	data.completed[str(id)] = maxi(int(data.completed.get(str(id), 0)), clampi(stars, 1, 3))
	last_error = save.write(data)
func set_sound(enabled: bool) -> void:
	data.sound = enabled
	last_error = save.write(data)
func total_stars() -> int:
	var total: int = 0
	for value in data.completed.values(): total += int(value)
	return total
