class_name HUD
extends Control

var game: Node
var quickbar: HBoxContainer
var minimal := false

func _ready() -> void:
	UIStyle.fill(self)
	mouse_filter=MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	quickbar=HBoxContainer.new()
	quickbar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	quickbar.position=Vector2(12,-42)
	quickbar.add_theme_constant_override("separation",4)
	add_child(quickbar)
	for item in [["人物 C","character"],["空窍 Q","aperture"],["身体 B","body"],["背包 I","inventory"],["地图 M","map"],["蛊术 V","elements"]]:
		var button:=UIStyle.button(item[0],func(): game.open_journal(item[1]))
		button.custom_minimum_size=Vector2(58,28)
		button.add_theme_font_size_override("font_size",12)
		for state in ["normal","hover","pressed","focus"]:
			var style:=UIStyle.box(Color(0.055,0.12,0.115,0.78),Color("465b50"),4)
			style.set_content_margin_all(5)
			button.add_theme_stylebox_override(state,style)
		quickbar.add_child(button)

func unobstructed() -> bool:
	return game!=null and game.running and not game.paused and not game.journal.visible and not game.village_ui.visible

func _process(_delta: float) -> void:
	# Paused screenshot fixtures keep the same HUD as normal play.
	quickbar.visible=game!=null and game.running and not minimal and not game.journal.visible and not game.village_ui.visible and not game.pause_layer.visible and not game.refine_layer.visible and not game.compendium_ui.visible and not game.settings_ui.visible
	queue_redraw()

func _text(pos: Vector2,text: String,font_size: int=13,color: Color=UIStyle.INK,width: float=-1,align: int=HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ThemeDB.fallback_font,pos,text,align,int(width),font_size,color)

func _panel(rect: Rect2) -> void:
	draw_style_box(UIStyle.box(Color(0.035,0.095,0.09,0.82),Color("465b50"),5),rect)

func _bar(pos: Vector2,width: float,ratio: float,color: Color) -> void:
	draw_rect(Rect2(pos,Vector2(width,5)),Color("0b1c1a"))
	draw_rect(Rect2(pos,Vector2(width*clampf(ratio,0,1),5)),color)

func _draw() -> void:
	if game==null or not game.running or game.player==null: return
	if game.journal.visible or game.village_ui.visible or game.pause_layer.visible or game.refine_layer.visible or game.compendium_ui.visible or game.settings_ui.visible: return
	var p:Player=game.player
	var vp:=get_viewport_rect().size
	if not minimal:
		_panel(Rect2(12,12,230,76))
		_text(Vector2(23,32),p.aperture.realm(),14,UIStyle.GOLD)
		_text(Vector2(23,51),"气血",12,UIStyle.DIM)
		_bar(Vector2(55,45),114,p.hp/p.max_hp,UIStyle.RED)
		_text(Vector2(173,51),"%d/%d"%[ceili(p.hp),int(p.max_hp)],12,UIStyle.INK,58,HORIZONTAL_ALIGNMENT_RIGHT)
		_text(Vector2(23,71),"真元",12,UIStyle.DIM)
		_bar(Vector2(55,65),114,p.yuan/p.max_yuan,UIStyle.JADE)
		_text(Vector2(173,71),"%.0f%%"%p.yuan,12,UIStyle.INK,58,HORIZONTAL_ALIGNMENT_RIGHT)
		var location:String=game.current_house_name if game.world.in_interior else game.world.zone_name(game.world.zone_at(p.position))
		_text(Vector2(0,30),location,15,UIStyle.GOLD,vp.x,HORIZONTAL_ALIGNMENT_CENTER)
		var map_rect:=Rect2(vp.x-156,12,144,108)
		_panel(map_rect.grow(2))
		draw_texture_rect(game.world.minimap_texture,map_rect,false)
		draw_texture_rect(game.fog.overlay,map_rect,false)
		var extent:=Vector2(GameData.MAP_W,GameData.MAP_H)*GameData.TILE
		var player_pos:Vector2=game.outdoor_return if game.world.in_interior else p.position
		for house in World.HOUSE_DATA:
			if house.id in ["flower_cave","spring_cave"] and not game.fog.discovered(house.pos): continue
			draw_circle(map_rect.position+house.pos/extent*map_rect.size,1.8,UIStyle.GOLD)
		draw_circle(map_rect.position+player_pos/extent*map_rect.size,2.5,Color.WHITE)
		_text(Vector2(vp.x-158,136),"M 山志 · 缩放 %.0f%%"%(game.zoom_level*100),11,UIStyle.DIM)
		if game.waypoint!=Vector2.ZERO:
			var d:Vector2=game.waypoint-player_pos
			_text(Vector2(vp.x-240,157),"%s · %.0f 步"%[game.waypoint_name,d.length()/32],12,UIStyle.GOLD,226,HORIZONTAL_ALIGNMENT_RIGHT)
			var point:=Vector2(vp.x-26,178)
			draw_line(point,point+d.normalized()*10,UIStyle.GOLD,2,true)
			draw_circle(point+d.normalized()*12,2,UIStyle.GOLD)
		var start:=Vector2(vp.x-174,vp.y-64)
		for i in 3:
			var rect:=Rect2(start+Vector2(i*54,0),Vector2(48,48))
			_panel(rect)
			var gu:GuVirtual=game.equipped_gu(i)
			if gu!=null:
				draw_texture_rect(GuArt.texture(gu.template_id),Rect2(rect.position+Vector2(5,5),Vector2(38,38)),false)
				if p.cast_cds[i]>0:
					draw_rect(rect,Color(0.02,0.06,0.07,0.7))
					_text(rect.position+Vector2(2,29),"%.1f"%p.cast_cds[i],14,UIStyle.GOLD,44,HORIZONTAL_ALIGNMENT_CENTER)
			else: _text(rect.position+Vector2(3,29),"空",12,UIStyle.DIM,42,HORIZONTAL_ALIGNMENT_CENTER)
			_text(rect.position+Vector2(4,12),str(i+1),11,UIStyle.GOLD)
		_text(Vector2(vp.x-174,vp.y-70),"催蛊 · Q 管理",11,UIStyle.DIM)
		_text(Vector2(vp.x*0.5-180,vp.y-19),"E 交互 · R 炼化 · J 打坐 · F1 隐藏界面",11,UIStyle.DIM,360,HORIZONTAL_ALIGNMENT_CENTER)
		var line:=0
		for i in mini(2,game.logs.size()):
			var entry:Dictionary=game.logs[game.logs.size()-1-i]
			if Time.get_ticks_msec()-int(entry.get("time",0))>6500: continue
			_text(Vector2(14,vp.y-57-line*17),String(entry.text).left(44),12,UIStyle.INK,540)
			line+=1
	if p.body.total_bleed_rate()>0 or p.body.destroyed_count()>0:
		_panel(Rect2(12,97,230,31))
		_text(Vector2(22,117),"伤势 · 失血 %.1f/s · 毁损 %d · B"%[p.body.total_bleed_rate(),p.body.destroyed_count()],12,UIStyle.RED)
	var statuses:=ElementUI.status_text(p.status)
	if statuses!="": _text(Vector2(14,147),statuses,12,UIStyle.RED)
	if game.meditating:
		var rect:=Rect2(vp.x*0.5-167,42,334,43)
		_panel(rect)
		_text(rect.position+Vector2(10,18),"打坐温养 %.1f%% · 真元 %.1f%% · J 收功"%[p.xiuwei,p.yuan],13,UIStyle.JADE)
		_bar(rect.position+Vector2(10,28),314,p.xiuwei/p.xp_next,UIStyle.GOLD)
	var hint:String=game.world.interaction_prompt(p.position)
	if hint=="" and not game.world.in_interior and not game.npc.dead and not game.npc.hostile and p.position.distance_to(game.npc.position)<80: hint="E  与寨中蛊师交谈"
	if hint!="":
		var rect:=Rect2(vp.x*0.5-196,vp.y-103,392,30)
		_panel(rect)
		_text(rect.position+Vector2(8,20),hint,13,UIStyle.GOLD,376,HORIZONTAL_ALIGNMENT_CENTER)
	elif game.target_hint!=null and not game.world.in_interior and game.fog.can_see(game.target_hint.position):
		var target:Enemy=game.target_hint
		var rect:=Rect2(vp.x*0.5-125,vp.y-113,250,38)
		_panel(rect)
		_text(rect.position+Vector2(8,17),target.display_name,13,UIStyle.GOLD)
		_bar(rect.position+Vector2(8,25),234,target.hp/target.max_hp,UIStyle.RED)
	if minimal: _text(Vector2(12,vp.y-16),"F1 显示界面",11,UIStyle.DIM)
