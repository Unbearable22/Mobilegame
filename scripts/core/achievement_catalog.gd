class_name AchievementCatalog
extends RefCounted
## Milestones use best campaign results, never attempts or chapter visibility.
const ACHIEVEMENTS: Array = [
	{"id":"first_light", "title":"Первая искра", "description":"Пройдите уровень 1", "icon":"spark", "goal":1, "metric":"level1"},
	{"id":"chapter_one", "title":"Инженер", "description":"Пройдите уровни 1–10", "icon":"trophy", "goal":10, "metric":"chapter1"},
	{"id":"chapter_two", "title":"Переплетение", "description":"Пройдите уровни 11–20", "icon":"trophy", "goal":10, "metric":"chapter2"},
	{"id":"three_chapters", "title":"Мастер цепей", "description":"Пройдите три старые коллекции по 10 уровней", "icon":"chapters", "goal":3, "metric":"chapters"},
	{"id":"chapter_four", "title":"Парадокс", "description":"Пройдите уровни 31–40", "icon":"trophy", "goal":10, "metric":"chapter4"},
	{"id":"perfect_chapter", "title":"Идеальная глава", "description":"Соберите 30 звёзд в одной старой коллекции из 10 уровней", "icon":"star", "goal":30, "metric":"chapter_stars"},
	{"id":"fifty_stars", "title":"Созвездие", "description":"Соберите 50 звёзд", "icon":"star", "goal":50, "metric":"stars"},
	{"id":"hundred_stars", "title":"Коллекционер", "description":"Соберите 100 звёзд", "icon":"star", "goal":100, "metric":"stars"},
	{"id":"all_levels", "title":"Сингулярность", "description":"Пройдите все 50 уровней", "icon":"circuit", "goal":50, "metric":"levels"},
	{"id":"all_stars", "title":"Абсолютное совершенство", "description":"Соберите все 150 звёзд", "icon":"star", "goal":150, "metric":"stars"},
	{"id":"reactor_pair","title":"Два сектора","description":"Завершите две главы по 25 уровней","icon":"circuit","goal":2,"metric":"sectors"},
	{"id":"hundred_levels","title":"Новый горизонт","description":"Пройдите все 100 доступных уровней","icon":"trophy","goal":100,"metric":"campaign_levels"},
	{"id":"three_hundred_stars","title":"Сверхновая","description":"Соберите 300 звёзд","icon":"star","goal":300,"metric":"campaign_stars"}
]
static func metrics(data: Dictionary) -> Dictionary:
	var completed: Dictionary = data.get("completed", {})
	var result: Dictionary = {"level1":int(completed.has("1")), "chapters":0, "chapter_stars":0, "stars":0, "levels":0,"campaign_levels":completed.size(),"campaign_stars":0,"sectors":preload("res://scripts/core/reactor_catalog.gd").sectors(data).size()}
	for value in completed.values(): result.campaign_stars+=int(value)
	for id in range(1,51):
		if completed.has(str(id)): result.levels+=1
	for chapter in range(1,6):
		var won: int = 0
		var stars: int = 0
		for id in range((chapter-1)*10+1, chapter*10+1):
			if completed.has(str(id)):
				won += 1
				stars += int(completed[str(id)])
		result["chapter%d" % chapter] = won
		result.stars += stars
		result.chapter_stars = maxi(result.chapter_stars, stars)
		if won == 10: result.chapters += 1
	return result
static func status(data: Dictionary) -> Array:
	var counts: Dictionary = metrics(data)
	var rows: Array = []
	for entry in ACHIEVEMENTS:
		var row: Dictionary = entry.duplicate()
		row.erase("metric")
		row.current = mini(int(counts[entry.metric]), int(entry.goal))
		row.unlocked = data.get("achievements", {}).get(entry.id, false) == true
		rows.append(row)
	return rows
