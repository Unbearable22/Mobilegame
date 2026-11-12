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
	var accents: Dictionary = {"neon":"4de6f5", "electric_blue":"68bcff", "violet_pulse":"bc9dff", "emerald_circuit":"69edba", "solar_gold":"ffda7b"}
	var accent: Color = Color(accents.get(id, accents.neon))
	var secondary: Dictionary = {"neon":"aa8bfa", "electric_blue":"96a6ff", "violet_pulse":"f6a0d5", "emerald_circuit":"80cbff", "solar_gold":"ffad80"}
	var targets: Dictionary = {"neon":"a5f3a3", "electric_blue":"80efcb", "violet_pulse":"a5e6ff", "emerald_circuit":"e1efa0", "solar_gold":"c2f3a3"}
	return {"accent":accent, "secondary":Color(secondary.get(id,secondary.neon)), "target":Color(targets.get(id,targets.neon)), "background":Color("080f1e"), "surface":Color("142137"), "text":Color("f0f5ff"), "muted":Color("a5b7ce"), "energy":accent.lightened(0.22)}
