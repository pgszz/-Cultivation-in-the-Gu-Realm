class_name WildlifeArt
extends RefCounted

static var cache := {}

static func texture(id: String) -> Texture2D:
	if not WildlifeSystem.SPECIES.has(id): return null
	if not cache.has(id):
		var path:="res://assets/wildlife/painted/"+id+".png"
		if ResourceLoader.exists(path): cache[id]=load(path)
	return cache.get(id)
