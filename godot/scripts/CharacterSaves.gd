class_name CharacterSaves
extends RefCounted

## One independent world per character. Death/deletion markers always win over snapshots.
const ROOT := "user://characters"
const LEGACY := "user://canon_save.json"
var directory := ROOT
var last_error := ""
static var session_dead := {}

func _init(folder: String = ROOT) -> void:
	directory=folder.trim_suffix("/")

func valid_id(id: String) -> bool:
	if id=="legacy": return true
	if not id.begins_with("c_") or id.length()<10 or id.length()>50: return false
	for c in id.substr(2):
		if not c in "0123456789abcdef": return false
	return true

func path_for(id: String) -> String:
	return directory.path_join(id+".json") if valid_id(id) else ""

func _marker(id: String, suffix: String) -> String:
	return directory.path_join(id+suffix) if valid_id(id) else ""

func _read(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path): return {}
	var json:=JSON.new()
	if json.parse(FileAccess.get_file_as_string(path))!=OK: return {}
	var value=json.data
	return value if value is Dictionary else {}

func _ensure_directory() -> bool:
	var error:=DirAccess.make_dir_recursive_absolute(directory)
	if error!=OK:
		last_error="无法创建角色存档目录："+error_string(error)
	return error==OK

func _write(path: String, data: Dictionary) -> bool:
	if not _ensure_directory(): return false
	var temp:=path+".tmp"
	var file:=FileAccess.open(temp,FileAccess.WRITE)
	if file==null:
		last_error="无法写入角色存档："+error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error:=file.get_error()
	file.close()
	if error==OK: error=DirAccess.rename_absolute(temp,path)
	if error!=OK:
		last_error="角色存档未能保存："+error_string(error)
		return false
	return true

func _lock(id: String, suffix: String, data: Dictionary) -> bool:
	if not valid_id(id) or not _ensure_directory(): return false
	# Existence is sufficient: even an interrupted write cannot restore an older live snapshot.
	var file:=FileAccess.open(_marker(id,suffix),FileAccess.WRITE)
	if file==null:
		last_error="无法写入角色状态："+error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var result:=file.get_error()==OK
	if not result: last_error="角色状态写入失败，请检查磁盘空间和权限。"
	file.close()
	return result

func _dead_data(data: Dictionary) -> bool:
	var profile:Dictionary=data.get("profile",{}) if data.get("profile",{}) is Dictionary else {}
	var body:Dictionary=data.get("body",{}) if data.get("body",{}) is Dictionary else {}
	return profile.get("status","")=="dead" or bool(body.get("dead",false)) or ((data.get("hp",1) is float or data.get("hp",1) is int) and float(data.get("hp",1))<=0)

func is_dead(id: String) -> bool:
	if not valid_id(id): return false
	return session_dead.has(path_for(id)) or FileAccess.file_exists(_marker(id,".dead")) or _dead_data(_read(path_for(id)))

func _valid_snapshot(data: Dictionary) -> bool:
	if data.has("shang_city") and not ShangCityData.valid_save(data.shang_city): return false
	if data.is_empty() or not _number(data.get("version")): return false
	if int(data.version)<4 or int(data.version)>8: return false
	if float(data.version)!=float(int(data.version)): return false
	if int(data.version)==8:
		if not data.get("profile") is Dictionary: return false
		if not data.profile.get("id") is String or not data.profile.get("name") is String: return false
		if not bool(data.get("fresh",false)):
			for key in ["hp","aperture","body","inventory","gus"]:
				if not data.has(key): return false
	for key in ["profile","aperture","body","inventory","hunger","world_damage","visited_sites","claimed_camps","commissions","poi_cd","npcs","gu_physical","boar_cultivation","gu_shop_purchased","population","wildlife","terrain_layers","layer_explored"]:
		if data.has(key) and not data[key] is Dictionary: return false
	for key in ["gus","skill_slots","captured","owned","discovered","explored","position","waypoint","world_salvaged"]:
		if data.has(key) and not data[key] is Array: return false
	for key in ["hp","rank","crystals","materials","play_time","day_time","social_time","map_version","map_width","camera_zoom","captures","refined","kills","npc_quest","world_layer","waypoint_layer"]:
		if data.has(key) and not _number(data[key]): return false
	for key in ["position","waypoint"]:
		if data.has(key):
			if data[key].size()!=2: return false
			for value in data[key]:
				if not _number(value): return false
	for key in ["aperture","inventory","world_damage","poi_cd"]:
		for value in data.get(key,{}).values():
			if not _number(value): return false
	for key in ["owned","discovered","skill_slots","world_salvaged"]:
		for value in data.get(key,[]):
			if not value is String: return false
	for key in ["gus","captured"]:
		for value in data.get(key,[]):
			if not value is Dictionary: return false
			if key=="gus" and (not value.get("id") is String or not value.get("template_id") is String): return false
			for field in ["id","template_id","quality","location","preferred_food"]:
				if value.has(field) and not value[field] is String: return false
			for field in ["rank","progress","level","exp","hunger","last_fed_time"]:
				if value.has(field) and not _number(value[field]): return false
	var body:Dictionary=data.get("body",{})
	if body.has("parts") and not body.parts is Dictionary: return false
	for value in body.get("parts",{}).values():
		if not value is Dictionary or not _number(value.get("hp",1)): return false
	for key in ["blood","pain","consciousness","neck_timer","unconscious_timer"]:
		if body.has(key) and not _number(body[key]): return false
	for key in ["hunger","npcs","commissions"]:
		for value in data.get(key,{}).values():
			if not value is Dictionary: return false
	var profile:Dictionary=data.get("profile",{})
	for key in ["id","name","status","created_at","updated_at","death_at","death_reason"]:
		if profile.has(key) and not profile[key] is String: return false
	if profile.has("status") and profile.status not in ["alive","dead"]: return false
	if data.has("fresh") and not data.fresh is bool: return false
	if bool(data.get("fresh",false)) and (int(data.version)!=8 or not profile.has("name")): return false
	return true

func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func entries() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if not DirAccess.dir_exists_absolute(directory): return result
	var ids:={}
	for file in DirAccess.get_files_at(directory):
		if file.ends_with(".json") or file.ends_with(".dead"):
			var id:=String(file).get_basename()
			if valid_id(id): ids[id]=true
	for id in ids:
		var data:=_read(path_for(id))
		var profile:Dictionary=data.get("profile",{}) if data.get("profile",{}) is Dictionary else {}
		var state:="alive"
		if FileAccess.file_exists(_marker(id,".deleted")): state="deleting"
		elif is_dead(id): state="dead"
		elif not _valid_snapshot(data) or profile.get("id",id)!=id: state="corrupt"
		var aperture:Dictionary=data.get("aperture",{}) if data.get("aperture",{}) is Dictionary else {}
		result.append({"id":id,"name":str(profile.get("name","旧角色" if id=="legacy" else "未命名角色")),"status":state,
			"rank":int(data.get("rank",1)) if data.get("rank",1) is float or data.get("rank",1) is int else 1,
			"stage":int(aperture.get("stage",0)) if _number(aperture.get("stage",0)) else 0,"play_time":float(data.get("play_time",0)) if _number(data.get("play_time",0)) else 0,
			"updated_at":str(profile.get("updated_at",profile.get("created_at",""))),"death_reason":str(profile.get("death_reason","此次生命已经结束。")),"fresh":bool(data.get("fresh",false))})
	result.sort_custom(func(a: Dictionary,b: Dictionary): return a.updated_at>b.updated_at if a.updated_at!=b.updated_at else a.id<b.id)
	return result

func create_character(display_name: String, appearance: Dictionary = {}, images: Dictionary = {}) -> String:
	last_error=""
	var title:=display_name.strip_edges()
	var pattern:=RegEx.new()
	pattern.compile("^[\\p{L}\\p{N} _·-]{1,16}$")
	if pattern.search(title)==null:
		last_error="名字需为 1–16 个中英文字、数字、空格或 · _ -。"
		return ""
	for entry in entries():
		if entry.name.nocasecmp_to(title)==0:
			last_error="此名字已有角色，请更换名字或先删除旧角色。"
			return ""
	var id:="c_"+Crypto.new().generate_random_bytes(12).hex_encode()
	while FileAccess.file_exists(path_for(id)) or FileAccess.file_exists(_marker(id,".deleted")):
		id="c_"+Crypto.new().generate_random_bytes(12).hex_encode()
	var now:=Time.get_datetime_string_from_system()
	var data:={"version":8,"fresh":true,"rank":0,"aperture":{"rank":0,"potential":randi_range(20,99)},"profile":{"id":id,"name":title,"status":"alive","created_at":now,"updated_at":now}}
	var art:=CharacterArtStore.new()
	data.appearance=art.install(art_directory(id),appearance,images)
	if data.appearance.is_empty():
		last_error=art.error
		art.clean(art_directory(id))
		return ""
	if not _write(path_for(id),data):
		art.clean(art_directory(id))
		return ""
	remember_selection(id)
	return id

func art_directory(id: String) -> String:
	return directory.path_join(id+"_art") if valid_id(id) else ""

func appearance_for(id: String) -> Dictionary:
	if not valid_id(id): return CharacterAppearance.normalize({})
	return CharacterAppearance.normalize(_read(path_for(id)).get("appearance",{}))

func update_appearance(id: String, value: Dictionary, images: Dictionary = {}) -> bool:
	var data:=load_character(id)
	if data.is_empty(): return false
	var previous:=CharacterAppearance.normalize(data.get("appearance",{}))
	var art:=CharacterArtStore.new()
	var next:=art.install(art_directory(id),value,images)
	if next.is_empty():
		last_error=art.error
		art.clean(art_directory(id),previous)
		return false
	data.appearance=next
	data.profile.updated_at=Time.get_datetime_string_from_system()
	if not _write(path_for(id),data):
		art.clean(art_directory(id),previous)
		return false
	art.clean(art_directory(id),next)
	return true

func load_character(id: String) -> Dictionary:
	last_error=""
	if not valid_id(id) or FileAccess.file_exists(_marker(id,".deleted")):
		last_error="此角色已删除或不存在。"
		return {}
	if is_dead(id):
		last_error="此角色已陨落，无法继续游历。"
		return {}
	var data:=_read(path_for(id))
	if not _valid_snapshot(data) or data.get("profile",{}).get("id",id)!=id:
		last_error="角色存档损坏或版本不受支持，无法读取。"
		return {}
	return data

func save_character(id: String, snapshot: Dictionary) -> bool:
	var previous:=load_character(id)
	if previous.is_empty(): return false
	var profile:Dictionary=previous.get("profile",{}).duplicate(true)
	profile.id=id
	profile.updated_at=Time.get_datetime_string_from_system()
	profile.status="alive"
	var data:=snapshot.duplicate(true)
	data.version=8
	data.profile=profile
	data.appearance=CharacterAppearance.normalize(data.get("appearance",previous.get("appearance",{})))
	data.erase("fresh")
	if not _valid_snapshot(data):
		last_error="角色状态不完整，未覆盖原存档。"
		return false
	if _dead_data(data):
		last_error="死亡状态不能保存为可继续的角色。"
		return false
	return _write(path_for(id),data)

func mark_dead(id: String, snapshot: Dictionary, reason: String) -> bool:
	last_error=""
	if not valid_id(id) or FileAccess.file_exists(_marker(id,".deleted")): return false
	session_dead[path_for(id)]=true
	var now:=Time.get_datetime_string_from_system()
	var locked:=_lock(id,".dead",{"id":id,"at":now,"reason":reason})
	var previous:=_read(path_for(id))
	var profile:Dictionary=previous.get("profile",{}).duplicate(true) if previous.get("profile",{}) is Dictionary else {}
	profile.merge({"id":id,"status":"dead","updated_at":now,"death_at":now,"death_reason":reason},true)
	var data:=snapshot.duplicate(true)
	data.version=8
	data.profile=profile
	data.hp=0
	data.erase("fresh")
	var saved:=_write(path_for(id),data)
	return locked or saved

func delete_character(id: String) -> bool:
	last_error=""
	if not valid_id(id):
		last_error="无效角色。"
		return false
	if not _lock(id,".deleted",{"id":id}): return false
	if not CharacterArtStore.new().clean(art_directory(id)):
		last_error="角色图片未能全部删除，请重试。"
		return false
	for path in [path_for(id),path_for(id)+".tmp",_marker(id,".dead")]:
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path)!=OK:
			last_error="部分角色文件未能删除，请重试。"
			return false
	return true

func remember_selection(id: String) -> void:
	var config:=ConfigFile.new()
	config.set_value("selection","id",id)
	config.save(directory.path_join("selection.cfg"))

func last_selection() -> String:
	var config:=ConfigFile.new()
	config.load(directory.path_join("selection.cfg"))
	return str(config.get_value("selection","id",""))

func import_legacy(path: String = LEGACY) -> bool:
	last_error=""
	if FileAccess.file_exists(path_for("legacy")) or FileAccess.file_exists(_marker("legacy",".dead")) or FileAccess.file_exists(_marker("legacy",".deleted")): return true
	if not FileAccess.file_exists(path): return true
	var data:=_read(path)
	if not _valid_snapshot(data):
		last_error="旧存档无法读取，原文件已保留；可新建角色。"
		return false
	var dead:=_dead_data(data)
	var now:=Time.get_datetime_string_from_system()
	data.profile={"id":"legacy","name":"旧角色","status":"dead" if dead else "alive","created_at":now,"updated_at":now}
	data.version=8
	if not _write(path_for("legacy"),data): return false
	if dead: _lock("legacy",".dead",{"id":"legacy","at":now})
	return true
