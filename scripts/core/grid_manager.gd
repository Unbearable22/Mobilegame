class_name GridManager
extends RefCounted
const Model = preload("res://scripts/core/reaction_engine.gd")
var level: Dictionary = {}
var state: Dictionary = {}
var used: int = 0
var history: Array = []

func load_level(data: Dictionary) -> void:
	level = data.duplicate(true)
	state = Model.initial_state(level)
	used = 0
	history.clear()

func status() -> String:
	if Model.has_won(level, state):
		return "won"
	return "lost" if used >= int(level.launches) else "playing"

func launch(index: int) -> Dictionary:
	if status() != "playing":
		return {"accepted": false}
	var result: Dictionary = Model.new().simulate(level, state, index)
	if result.accepted:
		_snapshot()
		state = result.state
		used += 1
	return result

func rotate(index: int) -> bool:
	if used != 0 or index < 0 or index >= level.nodes.size():
		return false
	if not level.nodes[index].get("rotatable", false):
		return false
	_snapshot()
	state.rotations[index] = (int(state.rotations[index]) + 1) % 4
	return true

func undo() -> bool:
	if history.is_empty():
		return false
	var previous: Dictionary = history.pop_back()
	state = previous.state
	used = previous.used
	return true

func _snapshot() -> void:
	history.append({"state": state.duplicate(true), "used": used})
