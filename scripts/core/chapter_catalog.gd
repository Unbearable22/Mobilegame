class_name ChapterCatalog
extends RefCounted
const LEVELS_PER_CHAPTER: int=25
const LEVEL_COUNT: int=100
const AVAILABLE_CHAPTERS: int=4
const CHAPTERS: Array=[
	{"number":"I","name":"Пробуждение","color":"4de6f5"},
	{"number":"II","name":"Переплетение","color":"aa8bfa"},
	{"number":"III","name":"Новые маршруты","color":"69edba"},
	{"number":"IV","name":"Синхронизация","color":"f5c76d"},
	{"number":"V","name":"Следующий горизонт","color":"a5b7ce"},
	{"number":"VI","name":"В разработке","color":"a5b7ce"},
	{"number":"VII","name":"В разработке","color":"a5b7ce"},
	{"number":"VIII","name":"В разработке","color":"a5b7ce"},
	{"number":"IX","name":"В разработке","color":"a5b7ce"},
	{"number":"X","name":"В разработке","color":"a5b7ce"},
	{"number":"XI","name":"В разработке","color":"a5b7ce"},
	{"number":"XII","name":"В разработке","color":"a5b7ce"},
	{"number":"XIII","name":"В разработке","color":"a5b7ce"},
	{"number":"XIV","name":"В разработке","color":"a5b7ce"},
	{"number":"XV","name":"В разработке","color":"a5b7ce"},
	{"number":"XVI","name":"В разработке","color":"a5b7ce"},
	{"number":"XVII","name":"В разработке","color":"a5b7ce"},
	{"number":"XVIII","name":"В разработке","color":"a5b7ce"},
	{"number":"XIX","name":"В разработке","color":"a5b7ce"},
	{"number":"XX","name":"В разработке","color":"a5b7ce"}
]
static func chapter_for_level(id:int)->int:
	return clampi((id-1)/LEVELS_PER_CHAPTER+1,1,CHAPTERS.size())
static func available(chapter:int)->bool:
	return chapter>=1 and chapter<=AVAILABLE_CHAPTERS
