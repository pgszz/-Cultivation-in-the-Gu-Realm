class_name GameSettings
extends RefCounted

const PATH := "user://settings.cfg"
const MODES := ["windowed", "borderless", "fullscreen"]
const MODE_NAMES := ["窗口", "无边框窗口", "全屏"]
const MIN_SIZE := Vector2i(640,360)
const RESOLUTIONS := [Vector2i(640,360),Vector2i(854,480),Vector2i(960,540),Vector2i(1280,720),Vector2i(1366,768),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]
const LEGACY_RESOLUTIONS := [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]

var mode := "windowed"
var last_window_mode := "windowed"
var window_size := Vector2i(1280,720)
var volumes := {"Master":80.0,"Music":70.0,"SFX":80.0}
var applying := false

func load_settings(path: String = PATH) -> bool:
	var config:=ConfigFile.new()
	if config.load(path)!=OK: return false
	for bus in volumes:
		volumes[bus]=clampf(_number(config,"audio",String(bus).to_lower()+"_volume",volumes[bus]),0,100)
	var old_index:=clampi(int(_number(config,"video","resolution_index",0)),0,LEGACY_RESOLUTIONS.size()-1)
	var old_size:Vector2i=LEGACY_RESOLUTIONS[old_index]
	window_size=Vector2i(int(_number(config,"video","window_width",old_size.x)),int(_number(config,"video","window_height",old_size.y)))
	if window_size.x<MIN_SIZE.x or window_size.y<MIN_SIZE.y or window_size.x>16384 or window_size.y>16384:
		window_size=Vector2i(1280,720)
	var value=config.get_value("video","mode","fullscreen" if config.get_value("video","fullscreen",false)==true else "windowed")
	mode=value if value in MODES else "windowed"
	var previous=config.get_value("video","last_window_mode","windowed")
	last_window_mode=previous if previous in ["windowed","borderless"] else "windowed"
	if mode!="fullscreen": last_window_mode=mode
	return true

func save_settings(path: String = PATH) -> Error:
	var config:=ConfigFile.new()
	config.load(path)
	for bus in volumes:
		config.set_value("audio",String(bus).to_lower()+"_volume",volumes[bus])
	config.set_value("video","mode",mode)
	config.set_value("video","last_window_mode",last_window_mode)
	config.set_value("video","window_width",window_size.x)
	config.set_value("video","window_height",window_size.y)
	return config.save(path)

func _number(config: ConfigFile, section: String, key: String, fallback: float) -> float:
	var value=config.get_value(section,key,fallback)
	return float(value) if (value is float or value is int) and is_finite(float(value)) else fallback

func apply_audio() -> void:
	for bus in volumes:
		var index:=AudioServer.get_bus_index(bus)
		if index<0:
			AudioServer.add_bus()
			index=AudioServer.bus_count-1
			AudioServer.set_bus_name(index,bus)
			AudioServer.set_bus_send(index,"Master")
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(float(volumes[bus])/100.0,0.0001)))
		AudioServer.set_bus_mute(index,float(volumes[bus])<=0.0)

func usable_rect() -> Rect2i:
	var rect:=DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	return rect if rect.size.x>0 and rect.size.y>0 else Rect2i(0,0,1280,720)

func maximum_window_size() -> Vector2i:
	var available:=usable_rect().size-(Vector2i(32,64) if mode=="windowed" else Vector2i.ZERO)
	return Vector2i(maxi(MIN_SIZE.x,available.x),maxi(MIN_SIZE.y,available.y))

func fit_window_size(requested: Vector2i) -> Vector2i:
	var limit:=maximum_window_size()
	var ratio:=minf(1.0,minf(float(limit.x)/maxi(1,requested.x),float(limit.y)/maxi(1,requested.y)))
	return Vector2i(maxi(MIN_SIZE.x,int(requested.x*ratio)),maxi(MIN_SIZE.y,int(requested.y*ratio)))

func apply_video(window: Window) -> void:
	if applying or DisplayServer.get_name()=="headless": return
	applying=true
	window.min_size=MIN_SIZE
	# Leave fullscreen before changing decorations or restoring the client size.
	window.mode=Window.MODE_WINDOWED
	await window.get_tree().process_frame
	window.borderless=mode=="borderless"
	if mode=="fullscreen":
		window.mode=Window.MODE_FULLSCREEN
	else:
		last_window_mode=mode
		window_size=fit_window_size(window_size)
		window.size=window_size
		window.position=usable_rect().position+(usable_rect().size-window_size)/2
	await window.get_tree().process_frame
	await window.get_tree().process_frame
	if mode!="fullscreen": window_size=window.size
	applying=false
