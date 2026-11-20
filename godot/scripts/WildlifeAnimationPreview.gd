class_name WildlifeAnimationPreview
extends Node2D

## Isolated visual fixture, never part of the normal game or player save.
var actors:Array[Enemy]=[]
var labels:Array[String]=[]
var elapsed:=0.0
var current_stage:=-1

func capture(game: Node) -> void:
	game.set_process(false)
	game.camera.enabled=false
	for child in game.get_children():
		if child is CanvasItem or child is CanvasLayer: child.visible=false
	var layer:=CanvasLayer.new()
	layer.layer=100
	game.add_child(layer)
	layer.add_child(self)
	var index:=0
	for id in WildlifeSystem.SPECIES:
		var actor:Enemy=game._make_host(id,Vector2(224+(index%3)*410,235+int(index/3)*204))
		actor.age_seconds=float(actor.data.mature)
		actor.refresh_growth()
		actor.radius=31 if id not in ["rabbit","pheasant","fox"] else 27
		actor.player_pos=Vector2(-10000,-10000)
		add_child(actor)
		actors.append(actor)
		labels.append(actor.display_name+(" · 妖兽" if actor.is_monster else " · 动物"))
		index+=1
	DirAccess.make_dir_recursive_absolute("res://motion_frames")
	for frame in 90:
		step(1.0/15.0)
		await RenderingServer.frame_post_draw
		var snapshot:=get_viewport().get_texture().get_image()
		snapshot.save_png("res://motion_frames/frame_%03d.png"%frame)
		if frame==30: snapshot.save_png("res://shot_wildlifemotion.png")
	print("SHOT wildlife motion: 90 rendered frames, 15 fps, six seconds")
	game.get_tree().quit()

func step(delta: float) -> void:
	elapsed+=delta
	var stage:=0 if elapsed<0.8 else (1 if elapsed<3.0 else (2 if elapsed<4.1 else (3 if elapsed<4.8 else 4)))
	for actor in actors:
		var animation:=actor.wildlife_animation
		var timid:bool=actor.data.temper=="timid"
		if stage!=current_stage:
			if stage==2 and not timid: animation.play_attack(Vector2.LEFT)
			if stage==3: animation.play_hurt(Vector2.RIGHT)
			if stage==4:
				actor.dead=true
				animation.play_death()
		animation.advance(delta)
		var moving:=stage==1 or (stage==2 and timid)
		var direction:=0.0 if elapsed<1.9 else PI
		animation.locomotion(delta,Vector2.from_angle(direction)*actor.spd*delta if moving else Vector2.ZERO,actor.radius,actor.spd,direction,false)
		animation.sync_pose(actor.radius)
		actor._t+=delta
	current_stage=stage
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("0b1715"))
	draw_string(ThemeDB.fallback_font,Vector2(28,35),"山野生灵 · 动物与妖兽动作",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("e6d9b8"))
	var title:String=["待机 · 呼吸与耳尾轻动","奔跑 · 跳跃 / 迈步 / 振翅","攻击 · 蓄势与出招；胆小动物继续逃跑","受伤 · 缩身后仰与僵直","死亡 · 倒伏后淡出"][maxi(0,current_stage)]
	draw_string(ThemeDB.fallback_font,Vector2(28,62),title,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("90b8a6"))
	for i in actors.size():
		var pos:=Vector2(22+(i%3)*410,80+int(i/3)*204)
		draw_style_box(_card(),Rect2(pos,Vector2(394,194)))
		draw_string(ThemeDB.fallback_font,pos+Vector2(16,26),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("ebaa8b") if actors[i].is_monster else Color("d7c89f"))
		draw_line(pos+Vector2(20,170),pos+Vector2(374,170),Color(0.5,0.64,0.55,0.16),1)
	draw_string(ThemeDB.fallback_font,Vector2(28,712),"动作演示夹具 · 复用游戏动画；真实攻击由距离、朝向、遮挡与命中时刻判定",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("718e81"))

func _card() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("162b25")
	style.border_color=Color("365046")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
