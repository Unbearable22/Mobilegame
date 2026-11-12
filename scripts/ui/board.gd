extends Control
signal node_pressed(index: int)
signal pointer_observed(point: Vector2, index: int, device: int)
const Model = preload("res://scripts/core/reaction_engine.gd")
const CYAN: Color = Color("4de6f5")
const PURPLE: Color = Color("aa8bfa")
const GREEN: Color = Color("a5f3a3")
var DEFAULT_PALETTE: Dictionary = preload("res://scripts/core/theme_catalog.gd").palette("neon")
var palette: Dictionary = DEFAULT_PALETTE
var reduced_effects: bool = false
# Charge increases can occur without an activation in frame.nodes.
var charge_feedback: Dictionary = {}
var level: Dictionary = {}
var state: Dictionary = {}
var edges: Array = []
var lit: Array = []
var locked: bool = false
var rotation_available: bool = true
var animation: float = 1.0
var tween: Tween
var tap_tween: Tween
var tapped: int = -1
var tap_glow: float = 0.0

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	set_process(false)

func configure_visuals(colors: Dictionary, reduced: bool) -> void:
	palette = DEFAULT_PALETTE.duplicate()
	for key in palette:
		if colors.get(key) is Color: palette[key]=colors[key]
	# Compatibility for external previews using the original eight-role API.
	for pair in [["border","accent"],["active_node","accent"],["inactive_node","accent"],["battery","secondary"]]:
		if not colors.has(pair[0]): palette[pair[0]]=palette[pair[1]]
	reduced_effects = reduced
	if reduced_effects:
		_clear_effects()
	queue_redraw()

func _clear_effects() -> void:
	if tween:
		tween.kill()
		tween = null
	if tap_tween:
		tap_tween.kill()
		tap_tween = null
	tapped = -1
	tap_glow = 0.0
	animation = 1.0
	charge_feedback = {}

func show_state(data: Dictionary, snapshot: Dictionary, is_locked: bool) -> void:
	_clear_effects()
	level = data.duplicate(true)
	state = snapshot.duplicate(true)
	locked = is_locked
	edges = []
	lit = []
	queue_redraw()

func show_frame(frame: Dictionary) -> void:
	charge_feedback = {}
	if not reduced_effects:
		for index in range(level.nodes.size()):
			if level.nodes[index].type == "battery" and int(frame.state.charges[index]) > int(state.charges[index]):
				charge_feedback[index] = int(frame.state.charges[index])
	state = frame.state.duplicate(true)
	edges = frame.edges.duplicate(true)
	lit = frame.nodes.duplicate(true)
	if tween:
		tween.kill()
		tween = null
	animation = 1.0 if reduced_effects else 0.0
	if not reduced_effects:
		tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_method(_animate, 0.0, 1.0, 0.15)
	queue_redraw()

func _animate(value: float) -> void:
	animation = value
	queue_redraw()

func geometry() -> Dictionary:
	var width: int = int(level.get("width", 5))
	var height: int = int(level.get("height", 5))
	var cell: float = minf((size.x - 16.0) / width, (size.y - 16.0) / height)
	var extent := Vector2(width, height) * cell
	return {"origin": (size - extent) * 0.5, "cell": cell, "extent": extent}

func center(index: int) -> Vector2:
	var g: Dictionary = geometry()
	var n: Dictionary = level.nodes[index]
	return g.origin + Vector2(n.x + 0.5, n.y + 0.5) * g.cell

func _gui_input(event: InputEvent) -> void:
	if level.is_empty(): return
	# One canonical GUI action path. Godot synthesizes mouse from native touch.
	# Never decide event origin from the global mouse-to-touch preference.
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var point: Vector2 = event.position
	var g: Dictionary = geometry()
	for i in range(level.nodes.size()):
		if point.distance_to(center(i)) < g.cell * 0.43:
			pointer_observed.emit(point, i, event.device)
			if locked: return
			flash_tap(i)
			node_pressed.emit(i)
			accept_event()
			return
	pointer_observed.emit(point, -1, event.device)

func _draw() -> void:
	if level.is_empty(): return
	var g: Dictionary = geometry()
	var cell: float = g.cell
	var origin: Vector2 = g.origin
	var outer := StyleBoxFlat.new()
	outer.bg_color = palette.background
	outer.border_color = palette.border
	outer.set_border_width_all(2)
	outer.set_corner_radius_all(36)
	draw_style_box(outer, Rect2(origin, g.extent))
	for x in range(int(level.width)):
		for y in range(int(level.height)):
			var p: Vector2 = origin + Vector2(x + 0.5, y + 0.5) * cell
			draw_circle(p, 3.0, palette.muted.lerp(palette.background, 0.7))
	# Physical adjacency links give a stable map of the network.
	for i in range(level.nodes.size()):
		for j in range(i + 1, level.nodes.size()):
			var a: Dictionary = level.nodes[i]
			var b: Dictionary = level.nodes[j]
			if absi(int(a.x - b.x)) + absi(int(a.y - b.y)) == 1:
				draw_line(center(i), center(j), palette.muted.lerp(palette.background, 0.72), 5, true)
	for edge in edges:
		var a: Vector2 = center(edge.from)
		var b: Vector2 = center(edge.to)
		_draw_pulse(a, b)
	for i in range(level.nodes.size()):
		_draw_node(i, cell)

func _draw_pulse(a: Vector2, b: Vector2) -> void:
	if reduced_effects:
		draw_line(a, b, Color(palette.accent, 0.9), 7, true)
		return
	var head: Vector2 = a.lerp(b, animation)
	draw_line(a, head, Color(palette.accent, 0.32), 5, true)
	# Four short tail segments soften the head without particles or extra tweens.
	for segment in range(4):
		var tail: float = maxf(0.0, animation - 0.30 + segment * 0.075)
		var tip: float = minf(animation, tail + 0.075)
		draw_line(a.lerp(b, tail), a.lerp(b, tip), Color(palette.accent, 0.25 + segment * 0.16), 5 + segment, true)
	var glow: float = 1.0 - animation * 0.65
	draw_circle(head, 15, Color(palette.accent, glow * 0.12))
	draw_circle(head, 9, Color(palette.energy, glow * 0.25))
	draw_circle(head, 5, palette.energy)

func _draw_node(index: int, cell: float) -> void:
	var n: Dictionary = level.nodes[index]
	var p: Vector2 = center(index)
	var r: float = cell * 0.30
	var active: bool = state.active[index]
	if index == tapped and not reduced_effects:
		draw_arc(p, r * (1.1 + (1.0 - tap_glow) * 0.5), 0, TAU, 48, Color(palette.accent, tap_glow), 5, true)
	var color: Color = palette.target if n.type == "target" else (palette.battery if n.type == "battery" else (palette.secondary if n.type == "splitter" else (palette.active_node if active or n.type=="source" else palette.inactive_node)))
	if n.type == "blocker": color = palette.muted
	if active:
		draw_circle(p, r * 1.32, Color(color, 0.09))
		draw_circle(p, r * 1.12, Color(color, 0.13))
	if index in lit and not reduced_effects:
		draw_arc(p, r * (1.15 + animation * 0.35), 0, TAU, 40, Color(color, 1.0 - animation), 4, true)
	if charge_feedback.has(index) and not reduced_effects:
		var full: bool = int(charge_feedback[index]) >= 2
		var charge_color: Color = palette.energy if full else palette.secondary
		draw_arc(p, r * (1.12 + animation * (0.48 if full else 0.25)), 0, TAU, 40,
			Color(charge_color, (1.0 - animation) * 0.9), 6 if full else 4, true)
	draw_circle(p, r, palette.surface)
	if n.type == "target":
		var diamond := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0), p + Vector2(0, -r)])
		draw_colored_polygon(diamond, palette.surface.lerp(palette.target, 0.18 if active else 0.06))
		draw_polyline(diamond, color, 4, true)
		if active:
			draw_line(p + Vector2(-r * 0.4, 0), p + Vector2(-r * 0.05, r * 0.3), color, 6, true)
			draw_line(p + Vector2(-r * 0.05, r * 0.3), p + Vector2(r * 0.45, -r * 0.3), color, 6, true)
		else: draw_circle(p, r * 0.22, color)
	else:
		draw_arc(p, r, 0, TAU, 48, Color(color, 1.0 if active or n.type == "source" else 0.6), 4, true)
		match n.type:
			"source":
				for direction in n.dirs:
					var d: Vector2 = Vector2(Model.DIRECTIONS[int(direction)])
					var tip: Vector2 = p + d * r * 1.20
					draw_line(tip - d.rotated(0.65) * r * 0.25, tip, color, 4, true)
					draw_line(tip - d.rotated(-0.65) * r * 0.25, tip, color, 4, true)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.25, -r * 0.45), p + Vector2(r * 0.45, 0), p + Vector2(-r * 0.25, r * 0.45)]), palette.text)
			"normal":
				draw_circle(p,r*0.22,color)
				for d in Model.DIRECTIONS:
					draw_line(p+Vector2(d)*r*0.60,p+Vector2(d)*r*0.82,color,3,true)
			"blocker":
				for sign_x in [-1, 1]: draw_line(p + Vector2(-r * 0.35, -r * 0.35 * sign_x), p + Vector2(r * 0.35, r * 0.35 * sign_x), color, 6, true)
			"battery":
				for k in range(2):
					var rect := Rect2(p + Vector2(-r * 0.43 + k * r * 0.5, -r * 0.4), Vector2(r * 0.35, r * 0.8))
					draw_rect(rect, color, false, 3)
					if int(state.charges[index]) > k:
						var charge_color: Color = palette.energy if active else color
						draw_rect(rect.grow(-4), charge_color)
			"directional", "splitter":
				for direction in n.dirs:
					var d: Vector2 = Vector2(Model.DIRECTIONS[(int(direction) + int(state.rotations[index])) % 4])
					var end: Vector2 = p + d * r * 0.65
					draw_line(p - d * r * 0.1, end, color, 5, true)
					draw_line(end, end - d.rotated(0.65) * r * 0.35, color, 5, true)
					draw_line(end, end - d.rotated(-0.65) * r * 0.35, color, 5, true)
	if n.get("rotatable", false):
		if rotation_available and not locked:
			draw_arc(p,r*1.23,-0.8,0.4,16,color,4,true)
		else:
			var lock_pos: Vector2 = p + Vector2(r*0.85,r*0.85)
			draw_rect(Rect2(lock_pos-Vector2(9,0),Vector2(18,14)),color,false,3)
			draw_arc(lock_pos+Vector2(0,0),7,PI,TAU,12,color,3,true)


func flash_tap(index: int) -> void:
	if reduced_effects: return
	if tap_tween: tap_tween.kill()
	tapped = index
	tap_glow = 1.0
	tap_tween = create_tween()
	tap_tween.tween_method(func(value: float): tap_glow = value; queue_redraw(), 1.0, 0.0, 0.28)
