extends SceneTree
const Save = preload("res://scripts/core/save_manager.gd")
const Progress = preload("res://scripts/core/progression_manager.gd")
const Themes = preload("res://scripts/core/theme_catalog.gd")
const Settings = preload("res://scripts/core/settings_manager.gd")
var failed: int = 0
var passed: int = 0
var notices: Array = []
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)
func put(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
func _initialize() -> void:
	check(Save.VERSION == 4, "schema4 preserves local retention")
	check(Themes.THEMES[0].name == "Neon" and Themes.THEMES[4].name == "Solar Gold", "theme names match requested collection")
	check(Themes.palette("neon").secondary == Color("aa8bfa") and Themes.palette("neon").target == Color("a5f3a3"), "neon preserves original shape colors")
	var save := Save.new("user://test-retention.json")
	for version in [1,2]:
		var original: Dictionary = {"version":version,"last_level":31,"completed":{"1":3,"31":2},"sound":false,"unlocked_chapters":[1,4],"achievements":["bad"],"theme":42,"statistics":"bad","reduced_effects":[]}
		DirAccess.remove_absolute(save.path+".v%d.bak" % version)
		put(save.path,original)
		var clean: Dictionary = save.read()
		check(clean.version == Save.VERSION and clean.last_level == 31 and clean.completed == original.completed and not clean.sound, "v%d migration preserves legitimate campaign despite corrupt optional fields" % version)
		check(clean.theme == "neon" and clean.achievements == {} and not clean.reduced_effects and clean.statistics.levels == {}, "v%d optional corruption defaults independently" % version)
		check(FileAccess.file_exists(save.path+".v%d.bak" % version), "v%d original backup exists" % version)
		var backup := FileAccess.open(save.path+".v%d.bak" % version,FileAccess.READ)
		check(backup.get_as_text() == JSON.stringify(original), "v%d backup retains exact data" % version)
		backup.close()
	var malformed: Dictionary = Save.sanitize({"completed":{"1":3,"2":INF,"03":2},"last_level":NAN,"statistics":{"levels":{"1":{"attempts":INF,"active_seconds":NAN,"device":"secret","wins":-1},"101":{"attempts":9}},"last_played_level":INF,"email":"secret"},"achievements":{"all_stars":"yes","unknown":true},"theme":"missing"})
	check(malformed.completed == {"1":3} and malformed.last_level == 1, "finite canonical campaign allowlist")
	check(malformed.statistics.levels["1"].attempts == 0 and malformed.statistics.levels["1"].active_seconds == 0.0 and malformed.statistics.levels.size() == 1 and malformed.statistics.size() == 2 and malformed.achievements.is_empty(), "bounded optional allowlist removes nonfinite negative unknown fields")
	put(save.path,Save.defaults())
	var p := Progress.new(save)
	p.achievements_unlocked.connect(func(ids: Array) -> void: notices.append_array(ids))
	check(p.achievement_status().size() == 13, "legacy10and3newmilestonesavailable")
	p.complete(1,3)
	check(notices == ["first_light"], "first level milestone awarded once")
	p.complete(1,1)
	check(notices.size() == 1 and p.data.completed["1"] == 3, "replayed poorer result preserves best and never re-awards")
	for id in range(2,11): p.complete(id,3)
	check(Themes.unlocked("electric_blue",p.data) and not Themes.unlocked("violet_pulse",p.data), "chapterI completion unlocks only blue")
	var settings := Settings.new(p)
	check(settings.set_theme("electric_blue") and settings.theme_id() == "electric_blue", "unlocked theme selects")
	check(not settings.set_theme("solar_gold") and settings.theme_id() == "electric_blue", "locked theme rejected preserving selection")
	check(settings.set_theme("electric_blue") and p.last_error == OK, "successful unchanged theme clears previous rejection status")
	check(settings.set_reduced_effects(true) and settings.reduced_effects_enabled(), "reduced effects persists")
	for id in range(11,51): p.complete(id,3)
	check(notices.size() == 11 and p.data.achievements.size() == 11 and p.total_stars() == 150, "legacy10andreactorpairawardonce")
	for row in p.achievement_status():
		if not row.id in ["hundred_levels","three_hundred_stars"]: check(row.unlocked and row.current == row.goal, "achievement progress complete: "+row.id)
	for theme in Themes.THEMES:
		check(Themes.unlocked(theme.id,p.data), "theme complete unlock: "+theme.id)
		var palette: Dictionary = Themes.palette(theme.id)
		check(palette.size() == 12 and palette.accent is Color and palette.background.srgb_to_linear().get_luminance() < 0.05 and palette.text.srgb_to_linear().get_luminance() > 0.8, "readable palette: "+theme.id)
	var all_notice_count: int = notices.size()
	p.complete(50,3)
	check(notices.size() == all_notice_count, "repeated final level has no duplicate achievement")
	var restored := Progress.new(save)
	var restored_settings := Settings.new(restored)
	check(restored.data.achievements.size() == 11 and restored_settings.theme_id() == "electric_blue" and restored_settings.reduced_effects_enabled() and restored.data.sound, "all retention preferences survive recreation")
	var legacy: Dictionary = Save.defaults()
	legacy.completed = {"1":3}
	put(save.path,legacy)
	var retrospective := Progress.new(save)
	check(retrospective.data.achievements == {"first_light":true} and save.read().achievements == retrospective.data.achievements, "legacy milestones silently persisted at startup")
	var again := Progress.new(save)
	check(again.data.achievements == retrospective.data.achievements, "repeated startup retains one-shot IDs")
	var visited: Dictionary = Save.sanitize({"last_level":50,"unlocked_chapters":[1,2,3,4,5],"theme":"solar_gold","completed":{"50":3}})
	check(not Themes.unlocked("electric_blue",visited) and not Themes.unlocked("solar_gold",visited) and visited.theme == "neon", "visited or unlocked chapters never unlock themes")
	var nearly: Dictionary = Save.defaults()
	for id in range(1,51):
		if id != 27: nearly.completed[str(id)] = 1
	check(not Themes.unlocked("emerald_circuit",nearly) and not Themes.unlocked("solar_gold",nearly), "nine chapter wins cannot unlock theme or all chapters theme")
	print("Retention: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
