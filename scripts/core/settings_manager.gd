class_name SettingsManager
extends RefCounted
## Typed preference API; persistence remains owned by ProgressionManager/SaveManager.
## Keep v1 sound storage compatible: there is no second sound variable.
signal changed(key: String)
var progress: RefCounted
var touch_diagnostics_enabled: bool = false
func _init(progression: RefCounted) -> void:
	progress = progression
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
	if not preload("res://scripts/core/theme_catalog.gd").unlocked(id,progress.data):
		progress.last_error = ERR_INVALID_PARAMETER
		return false
	if theme_id() == id:
		progress.last_error = OK
		return true
	progress.data.theme = id
	progress.last_error = progress.save.write(progress.data)
	changed.emit("theme")
	return progress.last_error == OK
