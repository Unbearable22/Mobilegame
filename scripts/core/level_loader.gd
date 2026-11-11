class_name LevelLoader
extends RefCounted
const Catalog = preload("res://scripts/core/chapter_catalog.gd")
const Validator = preload("res://scripts/core/level_validator.gd")
var errors: Array[String] = []

func load_all() -> Array:
	errors.clear()
	var result: Array = []
	for id in range(1, Catalog.LEVEL_COUNT + 1):
		var path: String = "res://levels/%02d.json" % id
		if not FileAccess.file_exists(path):
			errors.append("Missing " + path)
			continue
		var parser := JSON.new()
		var parsed: Error = parser.parse(FileAccess.get_file_as_string(path))
		var value: Variant = parser.data if parsed == OK else null
		if not value is Dictionary:
			errors.append("Invalid JSON: " + path)
			continue
		var report: Dictionary = Validator.new().validate(value)
		if not report.valid:
			errors.append(path + ": " + report.error)
			continue
		if int(value.id) != id:
			errors.append(path + ": id does not match catalogue position")
			continue
		result.append(value)
	return result
