class_name DailyCatalog
extends RefCounted
## Offline authored pool. Every entry is checked by the campaign acceptance suite.
## The local date is deliberately not presented as tamper-proof.
const POOL:Array[int]=[4,8,12,15,19,25,32,35,40,45,50,56,62,68,75,80,85,90,95,100]
const MAX_RECORDS:int=366
const MAX_RUNS:int=32
const MAX_ACTIONS:int=256
static var _validated_runs:Dictionary={}
const Validator=preload("res://scripts/core/level_validator.gd")
const Grid=preload("res://scripts/core/grid_manager.gd")
static func valid_date(date:String)->bool:
	var pattern:=RegEx.new()
	pattern.compile("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")
	if pattern.search(date)==null: return false
	var year:int=int(date.substr(0,4))
	var month:int=int(date.substr(5,2))
	var day:int=int(date.substr(8,2))
	if year<2000 or year>9999 or month<1 or month>12: return false
	var days:Array[int]=[31,29 if year%400==0 or (year%4==0 and year%100!=0) else 28,31,30,31,30,31,31,30,31,30,31]
	return day>=1 and day<=days[month-1]
static func level_for_date(date:String)->int:
	if not valid_date(date): return 0
	return POOL[date.sha256_text().substr(0,8).hex_to_int()%POOL.size()]
static func sanitize(raw:Variant)->Dictionary:
	var clean:Dictionary={}
	if not raw is Dictionary: return clean
	var dates:Array=raw.keys()
	dates.sort()
	for key in dates:
		var date:String=str(key)
		if not valid_date(date) or not raw[key] is Dictionary: continue
		var row:Dictionary=raw[key]
		var stars:Variant=row.get("stars",0)
		var launches:Variant=row.get("launches",0)
		if not (stars is float or stars is int) or not is_finite(float(stars)) or stars!=floor(stars) or stars<1 or stars>3: continue
		if not (launches is float or launches is int) or not is_finite(float(launches)) or launches!=floor(launches) or launches<1 or launches>8: continue
		if row.get("level",0)!=level_for_date(date): continue
		clean[date]={"level":level_for_date(date),"stars":int(stars),"launches":int(launches)}
	while clean.size()>MAX_RECORDS: clean.erase(clean.keys()[0])
	return clean
static func record(progress:RefCounted,date:String,level:int,stars:int,launches:int)->bool:
	if level!=level_for_date(date) or level==0 or stars<1 or stars>3 or launches<1 or launches>8: return false
	var candidate:Dictionary=progress.data.duplicate(true)
	var previous:Dictionary=candidate.daily.get(date,{})
	if previous.is_empty() or stars>int(previous.stars) or (stars==int(previous.stars) and launches<int(previous.launches)):
		candidate.daily[date]={"level":level,"stars":stars,"launches":launches}
	candidate.daily=sanitize(candidate.daily)
	candidate.daily_runs.erase(date)
	progress.last_error=progress.save.write(candidate)
	if progress.last_error!=OK: return false
	progress.data.daily=candidate.daily
	progress.data.daily_runs=candidate.daily_runs
	return true

static func replay(date:String,actions:Variant,snapshot:Dictionary={})->RefCounted:
	if not valid_date(date) or not actions is Array or actions.size()>MAX_ACTIONS: return null
	var data:Variant=snapshot.duplicate(true) if not snapshot.is_empty() else JSON.parse_string(FileAccess.get_file_as_string("res://levels/%02d.json"%level_for_date(date)))
	if not data is Dictionary or data.get("id",0)!=level_for_date(date) or JSON.stringify(data).length()>65536 or not Validator.new().validate(data).valid: return null
	var grid=Grid.new()
	grid.load_level(data)
	for action in actions:
		if not action is Dictionary or not action.get("type") in ["rotate","launch"]: return null
		var index:Variant=action.get("index",-1)
		if not (index is float or index is int) or not is_finite(float(index)) or index!=floor(index) or index<0 or index>=data.nodes.size(): return null
		if action.type=="rotate":
			if not grid.rotate(int(index)): return null
		elif not grid.launch(int(index)).get("accepted",false): return null
	return grid
static func sanitize_runs(raw:Variant)->Dictionary:
	var clean:Dictionary={}
	if not raw is Dictionary: return clean
	var dates:Array=raw.keys()
	dates.sort()
	for key in dates:
		var date:String=str(key)
		if not raw[key] is Dictionary or raw[key].get("level",0)!=level_for_date(date): continue
		# Compare full immutable input, not a lossy hash. Untouched checkpoints
		# do not re-run hundreds of old actions on every unrelated save.
		var cache_key:String=date
		if _validated_runs.has(cache_key) and (raw[key]==_validated_runs[cache_key].input or raw[key]==_validated_runs[cache_key].clean):
			clean[date]=_validated_runs[cache_key].clean.duplicate(true)
			continue
		var actions:Variant=raw[key].get("actions")
		var snapshot:Variant=raw[key].get("snapshot",{})
		if not snapshot is Dictionary: continue
		var grid= replay(date,actions,snapshot)
		if grid==null: continue
		var fingerprint:String=JSON.stringify(grid.level).sha256_text()
		if raw[key].has("content_sha256") and raw[key].content_sha256!=fingerprint: continue
		var canonical:Array=[]
		for action in actions: canonical.append({"type":str(action.type),"index":int(action.index)})
		clean[date]={"level":level_for_date(date),"actions":canonical,"snapshot":grid.level.duplicate(true),"content_sha256":fingerprint,"pool_version":1}
		_validated_runs[cache_key]={"input":raw[key].duplicate(true),"clean":clean[date].duplicate(true)}
		while _validated_runs.size()>MAX_RUNS: _validated_runs.erase(_validated_runs.keys()[0])
	while clean.size()>MAX_RUNS: clean.erase(clean.keys()[0])
	return clean
static func save_run(progress:RefCounted,date:String,actions:Array)->bool:
	var snapshot:Dictionary=progress.data.daily_runs.get(date,{}).get("snapshot",{})
	var grid=replay(date,actions,snapshot)
	if grid==null: return false
	var candidate:Dictionary=progress.data.duplicate(true)
	if actions.is_empty(): candidate.daily_runs.erase(date)
	else: candidate.daily_runs[date]={"level":level_for_date(date),"actions":actions.duplicate(true),"snapshot":grid.level.duplicate(true),"content_sha256":JSON.stringify(grid.level).sha256_text(),"pool_version":1}
	candidate.daily_runs=sanitize_runs(candidate.daily_runs)
	progress.last_error=progress.save.write(candidate)
	if progress.last_error!=OK: return false
	progress.data.daily_runs=candidate.daily_runs
	return true
