class_name MainMenu
extends Control
signal continued
signal chapters_requested
const Reaction = preload("res://scripts/ui/menu_reaction.gd")
const Catalog = preload("res://scripts/core/chapter_catalog.gd")
const Icons = preload("res://scripts/ui/icon_library.gd")
const CYAN: Color = Color("4de6f5")
const MUTED: Color = Color("92a7c2")
var inset: MarginContainer
var reaction: Control
var continue_button: Button
var chapters_button: Button
var chapter_label: Label
var status_label: Label
var progress_label: Label
var stars_label: Label
var progress_bar: ProgressBar
var active: bool = false
var suspended: bool = false
var backdrop: GradientTexture2D
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	backdrop = GradientTexture2D.new()
	backdrop.width = 2
	backdrop.height = 256
	backdrop.fill_from = Vector2(0,0)
	backdrop.fill_to = Vector2(0,1)
	backdrop.gradient = Gradient.new()
	backdrop.gradient.offsets = PackedFloat32Array([0,.5,1])
	backdrop.gradient.colors = PackedColorArray([Color("070d1d"),Color("0c1428"),Color("070d1d")])
	inset = MarginContainer.new()
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inset)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",24)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.add_child(column)
	# Reserve the same safe header row occupied by Info + Settings.
	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 144
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	var emblem := _label("◈",70,CYAN)
	top.add_child(emblem)
	var brand := _label("CHAIN REACT",108,Color("ecf9ff"))
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(brand)
	var subtitle := _label("O N E   T A P   P U Z Z L E",28,CYAN)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	reaction = Reaction.new()
	reaction.custom_minimum_size.y = 420
	reaction.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(reaction)
	continue_button = _action("Продолжить", "play",true)
	continue_button.pressed.connect(func(): continued.emit())
	column.add_child(continue_button)
	chapters_button = _action("Выбор глав", "chapters",false)
	chapters_button.pressed.connect(func(): chapters_requested.emit())
	column.add_child(chapters_button)
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0c1729")
	box.border_color = Color("223952")
	box.set_border_width_all(1)
	box.set_corner_radius_all(26)
	box.content_margin_left = 32
	box.content_margin_right = 32
	box.content_margin_top = 26
	box.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel",box)
	column.add_child(panel)
	var progress := VBoxContainer.new()
	progress.add_theme_constant_override("separation",16)
	panel.add_child(progress)
	status_label = _label("КАМПАНИЯ",26,MUTED)
	progress.add_child(status_label)
	chapter_label = _label("",36)
	progress.add_child(chapter_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	progress.add_child(row)
	row.add_child(_label("Пройдено",30,MUTED))
	progress_label = _label("",34)
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(progress_label)
	row.add_child(_label("★",34,Color("c5b3ff")))
	stars_label = _label("",34,Color("c5b3ff"))
	row.add_child(stars_label)
	progress_bar = ProgressBar.new()
	progress_bar.max_value = 50
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size.y = 10
	for part in ["background","fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = CYAN if part == "fill" else Color("1b2b43")
		style.set_corner_radius_all(5)
		progress_bar.add_theme_stylebox_override(part,style)
	progress.add_child(progress_bar)
	set_active(false)
func _label(text: String,font_size: int,color: Color = Color("eaf5ff")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
func _action(text: String,symbol: String,primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = Icons.icon(symbol)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width",48)
	button.add_theme_constant_override("h_separation",24)
	button.custom_minimum_size.y = 160 if primary else 144
	button.add_theme_font_size_override("font_size",44 if primary else 38)
	button.add_theme_color_override("font_color",Color("d9fcff") if primary else Color("c8d8ed"))
	for state in ["normal","hover","pressed","focus","disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("123746") if primary else Color("101e33")
		if state == "pressed": box.bg_color = Color("24556b")
		box.border_color = CYAN if primary or state in ["focus","hover"] else Color("334761")
		box.set_border_width_all(2)
		box.set_corner_radius_all(26)
		box.content_margin_left = 32
		box.content_margin_right = 32
		if primary:
			box.shadow_color = Color(CYAN,.07)
			box.shadow_size = 12
		button.add_theme_stylebox_override(state,box)
	return button
func update_progress(data: Dictionary,total_stars: int) -> void:
	var completed: int = data.completed.size()
	var chapter: Dictionary = Catalog.CHAPTERS[Catalog.chapter_for_level(int(data.last_level))-1]
	chapter_label.text = "%s · %s" % [chapter.number,chapter.name]
	chapter_label.add_theme_color_override("font_color",Color(chapter.color))
	status_label.text = "Кампания завершена" if completed == 50 else "КАМПАНИЯ"
	progress_label.text = "%d / 50" % completed
	stars_label.text = "%d / 150" % total_stars
	progress_bar.value = completed
	continue_button.tooltip_text = "Продолжить уровень %02d" % int(data.last_level)
func apply_insets(left: int,top: int,right: int,bottom: int) -> void:
	for pair in [["left",left],["top",top],["right",right],["bottom",bottom]]:
		inset.add_theme_constant_override("margin_"+pair[0],pair[1])
func set_active(value: bool) -> void:
	active = value
	visible = value
	if reaction: reaction.set_active(active and not suspended)
func set_suspended(value: bool) -> void:
	suspended = value
	if reaction: reaction.set_active(active and not suspended)
func _draw() -> void:
	# Static backdrop redraws only on resize/visibility; all shapes are own vectors.
	if backdrop: draw_texture_rect(backdrop,Rect2(Vector2.ZERO,size),false)
	var stars := PackedVector2Array()
	for i in range(36):
		var p := Vector2(fposmod(i*173.3+49,size.x),fposmod(i*291.7+83,size.y))
		stars.append(p)
		stars.append(p+Vector2(1.5 if i%3 else 3,0))
	draw_multiline(stars,Color("80b9db",.15),1,true)
	for side in [0,1]:
		var x: float = 22 if side == 0 else size.x-22
		draw_line(Vector2(x,size.y*.24),Vector2(x,size.y*.67),Color(CYAN,.13),1,true)
		for i in range(5):
			draw_line(Vector2(x-4,size.y*.3+i*24),Vector2(x+4,size.y*.3+i*24),Color(CYAN,.28),1,true)
