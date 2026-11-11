class_name ChapterCatalog
extends RefCounted
const LEVELS_PER_CHAPTER: int = 10
const LEVEL_COUNT: int = 50
const CHAPTERS: Array = [
	{"number": "I", "name": "Пробуждение", "color": "4de6f5"},
	{"number": "II", "name": "Переплетение", "color": "aa8bfa"},
	{"number": "III", "name": "Перегрузка", "color": "f5c76d"},
	{"number": "IV", "name": "Парадокс", "color": "f58caf"},
	{"number": "V", "name": "Сингулярность", "color": "a5f3a3"}
]
static func chapter_for_level(id: int) -> int:
	return clampi((id - 1) / LEVELS_PER_CHAPTER + 1, 1, CHAPTERS.size())
