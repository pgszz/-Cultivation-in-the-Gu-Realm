class_name GuArt
extends RefCounted

# Original generated transparent Gu paintings; creation record in assets/gu/painted/SOURCE.json.
const PORTRAITS := {
	"moon_blade":preload("res://assets/gu/painted/moon_blade.png"),
	"jiu_chong":preload("res://assets/gu/painted/jiu_chong.png"),
	"jade_skin":preload("res://assets/gu/painted/jade_skin.png"),
}

static func texture(id: String) -> Texture2D:
	return PORTRAITS.get(id)

static func portrait(side: float = 96) -> TextureRect:
	var view:=TextureRect.new()
	view.custom_minimum_size=Vector2(side,side)
	view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return view

static func decorate(button: Button, id: String, side: int = 32) -> void:
	button.icon=texture(id)
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",side)
	button.add_theme_constant_override("h_separation",6)
