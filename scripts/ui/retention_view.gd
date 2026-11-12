class_name RetentionView
extends VBoxContainer
const Icons = preload("res://scripts/ui/icon_library.gd")
const Themes = preload("res://scripts/core/theme_catalog.gd")
signal achievement_page_requested(page: int)
signal theme_requested(id: String)
signal export_requested
var achievement_cards: Array = []
var theme_buttons: Dictionary = {}
var next_button: Button
var export_button: Button
var palette: Dictionary
func _init(colors: Dictionary = {}) -> void:
	palette = colors if not colors.is_empty() else Themes.palette("neon")
	add_theme_constant_override("separation",20)
func label(text: String,font_size: int = 32,tone: String = "text") -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",palette[tone])
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item
func action(text: String,callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 144
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",34)
	button.pressed.connect(callback)
	return button
func build_achievements(rows: Array,page: int) -> void:
	for index in range(page*3,mini(rows.size(),page*3+3)):
		var row: Dictionary = rows[index]
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = palette.surface
		style.border_color = palette.accent if row.unlocked else palette.muted.darkened(.6)
		style.set_border_width_all(2)
		style.set_corner_radius_all(22)
		style.set_content_margin_all(22)
		panel.add_theme_stylebox_override("panel",style)
		var body := VBoxContainer.new()
		body.add_theme_constant_override("separation",12)
		panel.add_child(body)
		var heading := HBoxContainer.new()
		heading.add_theme_constant_override("separation",18)
		body.add_child(heading)
		var icon := TextureRect.new()
		icon.texture = Icons.icon(row.icon if Icons.PATHS.has(row.icon) else "trophy")
		icon.modulate = palette.accent if row.unlocked else palette.muted
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(56,56)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heading.add_child(icon)
		var title: Label = label(row.title,34,"accent" if row.unlocked else "text")
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(title)
		body.add_child(label(row.description,30,"muted"))
		body.add_child(label(("✓ Выполнено" if row.unlocked else "В процессе")+"   %d / %d"%[row.current,row.goal],28,"accent" if row.unlocked else "muted"))
		var progress := ProgressBar.new()
		progress.show_percentage = false
		progress.max_value = row.goal
		progress.value = row.current
		progress.custom_minimum_size.y = 8
		for part in ["background","fill"]:
			var track:=StyleBoxFlat.new()
			track.bg_color=palette.accent if part=="fill" else palette.background
			track.set_corner_radius_all(4)
			progress.add_theme_stylebox_override(part,track)
		body.add_child(progress)
		achievement_cards.append(panel)
		add_child(panel)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation",16)
	add_child(navigation)
	var previous := action("‹",func(): achievement_page_requested.emit(page-1))
	previous.disabled = page==0
	navigation.add_child(previous)
	var page_label := label("%d / %d"%[page+1,ceili(rows.size()/3.0)],32,"muted")
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(page_label)
	next_button = action("›",func(): achievement_page_requested.emit(page+1))
	next_button.disabled = (page+1)*3>=rows.size()
	navigation.add_child(next_button)
func build_themes(data: Dictionary,selected: String) -> void:
	for entry in Themes.THEMES:
		var unlocked: bool = Themes.unlocked(entry.id,data)
		var condition: String = "Выбрана" if entry.id==selected else ("Доступна" if unlocked else ("За всю кампанию" if entry.chapter==5 else "За главу "+["","I","II","III"][entry.chapter]))
		var button := action(entry.name+"\n"+condition,func(): theme_requested.emit(entry.id))
		button.disabled = not unlocked
		button.add_theme_color_override("font_color",Themes.palette(entry.id).accent)
		if not unlocked:
			button.icon = Icons.icon("lock")
			button.add_theme_constant_override("icon_max_width",32)
			button.expand_icon = true
		button.set_meta("theme_id",entry.id)
		theme_buttons[entry.id] = button
		add_child(button)
func build_statistics(summary: Dictionary,level_id: int) -> void:
	var totals: Dictionary = {"attempts":0,"restarts":0,"active_seconds":0.0,"launches":0}
	for record in summary.levels.values():
		for key in totals: totals[key] += record[key]
	add_child(label("На этом устройстве",28,"muted"))
	add_child(label("Попытки  %d\nПерезапуски  %d\nЗапуски  %d\nАктивное время  %s"%[totals.attempts,totals.restarts,totals.launches,duration(totals.active_seconds)],34))
	add_child(label("Последний сыгранный: "+("—" if summary.last_played_level==0 else "%02d"%summary.last_played_level),30,"muted"))
	var row: Dictionary = summary.levels.get(str(level_id),{})
	add_child(label("Уровень %02d"%level_id,38,"accent"))
	if row.is_empty():
		add_child(label("Пока нет попыток",30,"muted"))
	else:
		add_child(label("Попытки  %d   ·   Перезапуски  %d\nЗапуски  %d   ·   Время  %s\nЛучший результат  %s"%[row.attempts,row.restarts,row.launches,duration(row.active_seconds),"★".repeat(row.best_stars) if row.best_stars else "—"],32))
		if row.best_stars>0: add_child(label("Лучшее: %d запусков · %s"%[row.best_launches,duration(row.best_seconds)],28,"muted"))
	export_button = action("Экспорт JSON",func(): export_requested.emit())
	add_child(export_button)
static func duration(seconds: float) -> String:
	var value: int = int(seconds)
	return "%d:%02d"%[value/60,value%60]
