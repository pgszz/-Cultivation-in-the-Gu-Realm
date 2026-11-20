class_name ItemArt
extends RefCounted

# Original transparent item paintings; prompts and provenance in assets/items/painted/SOURCE.json.
const PORTRAITS := {
	"currency":preload("res://assets/items/painted/primeval_stone.png"),
	"timber":preload("res://assets/items/painted/timber.png"),
	"rubble":preload("res://assets/items/painted/rubble.png"),
	"bandage":preload("res://assets/items/painted/bandage.png"),
	"moon_petals":preload("res://assets/items/painted/moon_petals.png"),
	"bamboo_wine":preload("res://assets/items/painted/bamboo_wine.png"),
	"jade":preload("res://assets/items/painted/jade.png"),
	"rabbit_meat":preload("res://assets/items/painted/rabbit_meat.png"),
	"deer_meat":preload("res://assets/items/painted/deer_meat.png"),
	"wolf_meat":preload("res://assets/items/painted/wolf_meat.png"),
	"bear_meat":preload("res://assets/items/painted/bear_meat.png"),
	"boar_meat":preload("res://assets/items/painted/boar_meat.png"),
	"pheasant_meat":preload("res://assets/items/painted/pheasant_meat.png"),
	"pork_ration":preload("res://assets/items/painted/pork_ration.png"),
}

static func texture(id: String) -> Texture2D:
	return PORTRAITS.get(id)

static func decorate(button: Button, id: String, side: int = 32) -> void:
	button.icon=texture(id)
	button.expand_icon=true
	button.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	button.add_theme_constant_override("icon_max_width",side)
	button.add_theme_constant_override("h_separation",8)
