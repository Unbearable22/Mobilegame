extends SceneTree
const Loader = preload("res://scripts/core/level_loader.gd")
const Auditor = preload("res://scripts/core/level_auditor.gd")
var failed: int = 0
func _initialize() -> void:
	var reports: Array = []
	var total: int = 0
	for data in Loader.new().load_all():
		var report: Dictionary = Auditor.new().audit(data)
		report.id = int(data.id)
		total += int(report.calls)
		reports.append(report)
		if not report.valid:
			failed += 1
			push_error("Audit level %d: %s" % [int(data.id),report])
		print("AUDIT %02d: %s" % [int(data.id),report])
	var file := FileAccess.open("res://build/level-audit.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(reports,"\t"))
	print("Level audit: %d levels, %d simulations, %d failures" % [reports.size(),total,failed])
	quit(1 if failed or reports.size()!=50 else 0)
