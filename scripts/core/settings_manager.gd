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
func set_sound(enabled: bool) -> void:
	if sound_enabled() == enabled: return
	progress.set_sound(enabled)
	changed.emit("sound")
func set_touch_diagnostics(enabled: bool) -> void:
	touch_diagnostics_enabled = enabled and OS.is_debug_build()
	changed.emit("touch_diagnostics")
