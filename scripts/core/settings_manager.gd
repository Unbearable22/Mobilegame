class_name SettingsManager
extends RefCounted
## Typed preference API; persistence remains owned by ProgressionManager/SaveManager.
## Keep v1 sound storage compatible: there is no second sound variable.
signal changed(key: String)
signal theme_diagnostic(record: Dictionary)
const Themes=preload("res://scripts/core/theme_catalog.gd")
var active_palette: Dictionary
var progress: RefCounted
var touch_diagnostics_enabled: bool = false
func _init(progression: RefCounted) -> void:
	progress = progression
	active_palette = Themes.palette(theme_id())
func sound_enabled() -> bool:
	return bool(progress.data.sound)
func set_sound(enabled: bool) -> bool:
	if sound_enabled() == enabled:
		progress.last_error = OK
		return true
	progress.set_sound(enabled)
	changed.emit("sound")
	return progress.last_error == OK
func set_touch_diagnostics(enabled: bool) -> void:
	touch_diagnostics_enabled = enabled and OS.is_debug_build()
	changed.emit("touch_diagnostics")

func reduced_effects_enabled() -> bool:
	return bool(progress.data.reduced_effects)
func set_reduced_effects(enabled: bool) -> bool:
	if reduced_effects_enabled() == enabled:
		progress.last_error = OK
		return true
	progress.data.reduced_effects = enabled
	progress.last_error = progress.save.write(progress.data)
	changed.emit("reduced_effects")
	return progress.last_error == OK
func theme_id() -> String:
	var id: String = str(progress.data.theme)
	return id if preload("res://scripts/core/theme_catalog.gd").unlocked(id,progress.data) else "neon"
func set_theme(id: String) -> bool:
	var before: String = theme_id()
	var available: bool = Themes.unlocked(id,progress.data)
	if not available:
		progress.last_error = ERR_INVALID_PARAMETER
		_theme_trace(before,id,available,"locked or unknown theme")
		return false
	if before == id:
		progress.last_error = OK
		_theme_trace(before,id,available,"already selected")
		return true
	# Commit preferences before notifying renderers. Failed persistence rolls back.
	var candidate: Dictionary = progress.data.duplicate(true)
	candidate.theme = id
	progress.last_error = progress.save.write(candidate)
	if progress.last_error != OK:
		_theme_trace(before,id,available,"save failed: %d"%progress.last_error)
		return false
	progress.data.theme = id
	active_palette = Themes.palette(id)
	changed.emit("theme")
	_theme_trace(before,id,available,"")
	return true
func _theme_trace(before: String,requested: String,available: bool,reason: String) -> void:
	if not OS.is_debug_build(): return
	var record: Dictionary = {"stage":"selection","before":before,"requested":requested,
		"after":theme_id(),"available":available,"reason":reason,
		"accent":active_palette.accent.to_html(),"background":active_palette.background.to_html()}
	print("ThemeDebug "+JSON.stringify(record))
	theme_diagnostic.emit(record)
