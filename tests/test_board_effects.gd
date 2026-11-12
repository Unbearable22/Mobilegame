extends SceneTree
const Board = preload("res://scripts/ui/board.gd")
const Model = preload("res://scripts/core/reaction_engine.gd")
var passed: int = 0
var failed: int = 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func fixture() -> Dictionary:
	return {"width": 3, "height": 2, "nodes": [
		{"x": 0, "y": 0, "type": "source", "dirs": [1, 2]},
		{"x": 1, "y": 0, "type": "normal"},
		{"x": 0, "y": 1, "type": "normal"},
		{"x": 1, "y": 1, "type": "battery"},
		{"x": 2, "y": 1, "type": "target"}]}

func run() -> void:
	var board = Board.new()
	root.add_child(board)
	board.size = Vector2(600, 400)
	await process_frame
	check(board.has_method("configure_visuals"), "Board provides palette/reduced effects configuration")
	if not board.has_method("configure_visuals"):
		board.queue_free()
		finish()
		return
	var data: Dictionary = fixture()
	var before: Dictionary = Model.initial_state(data)
	board.show_state(data, before, false)
	var custom: Dictionary = {"accent": Color.CORAL, "secondary": Color.GOLD,
		"target": Color.LIME_GREEN, "background": Color.MIDNIGHT_BLUE,
		"surface": Color.DARK_SLATE_BLUE, "text": Color.WHITE,
		"muted": Color.SLATE_GRAY, "energy": Color.LIGHT_YELLOW}
	board.configure_visuals(custom, false)
	check(board.palette.accent == Color.CORAL and board.palette.energy == Color.LIGHT_YELLOW,
		"theme colors reach Board drawing palette")
	custom.accent = Color.BLACK
	check(board.palette.accent == Color.CORAL, "Board retains its own palette snapshot")
	check(board.state == before and board.level == data, "theme configuration leaves the game snapshot intact")
	check(not board.is_processing(), "effects require no continuous process callback")

	var partial: Dictionary = before.duplicate(true)
	partial.charges[3] = 1
	var frame: Dictionary = {"state": partial, "nodes": [], "edges": [{"from": 1, "to": 3}]}
	board.show_frame(frame)
	check(board.charge_feedback.get(3) == 1 and board.lit.is_empty(), "first battery hit flashes partial charge even without activation")
	check(board.tween != null and board.animation == 0.0, "normal effects animate the pulse")
	partial.charges[3] = 0
	frame.edges[0].to = 4
	frame.nodes.append(4)
	check(board.state.charges[3] == 1 and board.edges[0].to == 3 and board.lit.is_empty(),
		"render frame owns independent state edges and activation snapshots")
	var full: Dictionary = before.duplicate(true)
	full.charges[3] = 2
	full.active[3] = true
	board.show_frame({"state": full, "nodes": [3], "edges": [{"from": 2, "to": 3}]})
	check(board.charge_feedback.get(3) == 2 and board.lit == [3], "second hit distinguishes full charge and activation")
	check(full.charges[3] == 2 and not before.active[3], "feedback never writes back to model states")
	board.flash_tap(0)
	var old_wave: Tween = board.tween
	var old_tap: Tween = board.tap_tween
	board.configure_visuals(custom, true)
	check(not old_wave.is_valid() and not old_tap.is_valid(), "enabling reduced effects kills in-flight visual tweens")
	check(board.tween == null and board.tap_tween == null and board.animation == 1.0,
		"reduced effects expose final pulse instantly")
	check(board.tapped == -1 and board.tap_glow == 0.0 and board.charge_feedback.is_empty(),
		"reduced effects remove animated tap and charge halos")
	check(board.state == full and board.edges.size() == 1, "reduced effects retain readable state and edges")
	board.flash_tap(0)
	board.show_frame({"state": full, "nodes": [3], "edges": [{"from": 2, "to": 3}]})
	check(board.tween == null and board.tap_tween == null and board.animation == 1.0 and board.tapped == -1,
		"reduced effects never create pulse or tap tweens")
	check(board.state == full, "reduced frames keep model state unchanged")

	board.configure_visuals(custom, false)
	board.show_state(data, before, false)
	var result: Dictionary = Model.new().simulate(data, before, 0)
	var simultaneous_seen: bool = false
	for wave in result.frames:
		board.show_frame(wave)
		if wave.state.charges[3] == 2 and 3 in wave.nodes:
			simultaneous_seen = true
			check(board.charge_feedback.get(3) == 2, "simultaneous battery hits show full charge in the same wave")
			var incoming: int = 0
			for edge in board.edges:
				if edge.to == 3: incoming += 1
			check(incoming == 2 and board.edges.size() == wave.edges.size(), "simultaneous edges are all retained")
	check(simultaneous_seen, "fixture reaches a genuine simultaneous battery wave")
	board.flash_tap(0)
	old_wave = board.tween
	old_tap = board.tap_tween
	board.show_state(data, before, true)
	check(not old_wave.is_valid() and not old_tap.is_valid(), "epoch/reset kills stale pulse and tap callbacks")
	check(board.tween == null and board.tap_tween == null and board.edges.is_empty() and board.lit.is_empty()
		and board.charge_feedback.is_empty() and board.tapped == -1 and board.animation == 1.0,
		"epoch/reset removes every transient effect")
	check(board.locked and board.state == before, "reset preserves requested lock and model snapshot")
	data.nodes[0].x = 99
	before.active[0] = true
	check(board.level.nodes[0].x == 0 and not board.state.active[0], "state restore owns an independent level and state snapshot")
	if DisplayServer.get_name() != "headless":
		custom.accent = Color.CORAL
		await check_rendered_palette(board, custom)
	board.queue_free()
	await process_frame
	finish()

func check_rendered_palette(board: Control, colors: Dictionary) -> void:
	var data: Dictionary = fixture()
	data.nodes.append({"x": 2, "y": 0, "type": "blocker"})
	var snapshot: Dictionary = Model.initial_state(data)
	snapshot.charges[3] = 2
	snapshot.active[3] = true
	board.show_state(data, snapshot, false)
	board.configure_visuals(colors, false)
	board.show_frame({"state": snapshot, "edges": [{"from": 0, "to": 1}], "nodes": []})
	board.tween.pause()
	board._animate(0.6)
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var counts: Dictionary = {}
	for key in colors: counts[key] = 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel: Color = image.get_pixel(x, y)
			for key in colors:
				var wanted: Color = colors[key]
				if absf(pixel.r - wanted.r) + absf(pixel.g - wanted.g) + absf(pixel.b - wanted.b) < 0.02:
					counts[key] += 1
	for key in colors:
		check(counts[key] > 2, "rendered Board uses configured %s color" % key)

func finish() -> void:
	print("Board effects: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
