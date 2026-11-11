class_name LevelLoader
extends RefCounted
const Validator = preload("res://scripts/core/level_validator.gd")
var errors: Array[String] = []

func load_all() -> Array:
	errors.clear()
	var result: Array = []
	for id in range(1, 11):
		var path: String = "res://levels/%02d.json" % id
		if not FileAccess.file_exists(path):
			errors.append("Missing " + path)
			continue
		var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not value is Dictionary:
			errors.append("Invalid JSON: " + path)
			continue
		var report: Dictionary = Validator.new().validate(value)
		if not report.valid:
			errors.append(path + ": " + report.error)
			continue
		result.append(value)
	return result
