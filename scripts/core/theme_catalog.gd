class_name ThemeCatalog
extends RefCounted
const THEMES: Array = [
	{"id":"neon", "name":"Neon", "chapter":0},
	{"id":"electric_blue", "name":"Electric Blue", "chapter":1},
	{"id":"violet_pulse", "name":"Violet Pulse", "chapter":2},
	{"id":"emerald_circuit", "name":"Emerald Circuit", "chapter":3},
	{"id":"solar_gold", "name":"Solar Gold", "chapter":5}
]
static func unlocked(id: String, data: Dictionary) -> bool:
	if id == "neon": return true
	var chapter: int = -1
	for row in THEMES:
		if row.id == id: chapter = row.chapter
	if chapter < 0: return false
	var completed: Dictionary = data.get("completed", {})
	var first: int = 1 if id == "solar_gold" else (chapter-1)*10+1
	var last: int = 50 if id == "solar_gold" else chapter*10
	for level in range(first,last+1):
		if not completed.has(str(level)): return false
	return true
static func palette(id: String) -> Dictionary:
	# Color roles are supplied once by SettingsManager; renderers consume them.
	var rows: Dictionary = {
		"neon":["080f1e","142137","4de6f5","aa8bfa","a5f3a3"],
		"electric_blue":["060f2c","112951","439bff","91caff","78efce"],
		"violet_pulse":["180b2b","312044","d29aff","ff9bdd","a5e6ff"],
		"emerald_circuit":["061d19","123b32","54edb4","8bdcff","e1efa0"],
		"solar_gold":["211607","3c2c15","ffce62","ffa883","c2f3a3"]
	}
	var row: Array = rows.get(id,rows.neon)
	var accent: Color = Color(row[2])
	return {"background":Color(row[0]),"surface":Color(row[1]),
		"accent":accent,"secondary":Color(row[3]),"border":accent.darkened(.42),
		"energy":accent.lightened(.3),"active_node":accent,"inactive_node":accent.darkened(.2),
		"target":Color(row[4]),"battery":Color(row[3]),"text":Color("f0f5ff"),"muted":Color("a5b7ce")}
