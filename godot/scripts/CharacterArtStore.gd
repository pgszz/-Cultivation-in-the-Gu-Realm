class_name CharacterArtStore
extends RefCounted

var error := ""

func install(folder: String, value: Dictionary, images: Dictionary) -> Dictionary:
	error=""
	var data:=CharacterAppearance.normalize(value)
	for key in ["actor_asset","outfit_asset"]:
		if not images.has(key): continue
		if not images[key] is Image:
			error="导入图片无效，请重新选择。"
			return {}
		var bytes:PackedByteArray=images[key].save_png_to_buffer()
		var hash:=HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(bytes)
		var filename:=hash.finish().hex_encode()+".png"
		if DirAccess.make_dir_recursive_absolute(folder)!=OK:
			error="无法创建角色外观目录。"
			return {}
		var path:=folder.path_join(filename)
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=filename.trim_suffix(".png"):
			var file:=FileAccess.open(path,FileAccess.WRITE)
			if file==null:
				error="无法保存导入图片，请检查磁盘与权限。"
				return {}
			file.store_buffer(bytes)
			file.flush()
			var ok:=file.get_error()==OK
			file.close()
			if not ok:
				error="图片保存失败，原外观已保留。"
				return {}
		var validation:=CharacterAppearance.read_png(path)
		if not validation.has("image"):
			error=str(validation.error)
			return {}
		data[key]=filename
	for key in ["actor_asset","outfit_asset"]:
		if data[key]!="" and not FileAccess.file_exists(folder.path_join(data[key])):
			error="此角色没有对应的导入图片，请重新导入或移除图片。"
			return {}
	return data

func clean(folder: String, keep: Dictionary = {}) -> bool:
	if not DirAccess.dir_exists_absolute(folder): return true
	for file in DirAccess.get_files_at(folder):
		# Only this feature's content-addressed assets belong to us.
		if CharacterAppearance.asset_name(file) and file not in [keep.get("actor_asset",""),keep.get("outfit_asset","")]:
			if DirAccess.remove_absolute(folder.path_join(file))!=OK: return false
	if DirAccess.get_files_at(folder).is_empty() and DirAccess.get_directories_at(folder).is_empty():
		return DirAccess.remove_absolute(folder)==OK
	return true
