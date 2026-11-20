class_name AwakeningView
extends Control

## 只读的开窍表现；角色状态在完整仪式后由 AwakeningUI 结算。
var game: Node
var elapsed := 0.0
var preview: CharacterPreview
var completed := false

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	preview=CharacterPreview.new()
	preview.animate=false
	add_child(preview)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if preview==null: return
	preview.size=Vector2(size.x*0.22,size.y*0.72)
	preview.position=Vector2(size.x*0.22,size.y*0.10)

func sync() -> void:
	preview.appearance.texture=game.player.appearance.texture
	preview.appearance.data=game.player.appearance.data
	queue_redraw()

func _draw() -> void:
	if game==null: return
	var scale_x:=size.x/900.0
	var scale_y:=size.y/300.0
	draw_set_transform(Vector2.ZERO,0,Vector2(scale_x,scale_y))
	var t:=elapsed
	var center:=Vector2(660,140)
	var heart:=Vector2(297,167)
	draw_style_box(UIStyle.box(Color("0b1b1d"),Color("29463e"),12),Rect2(0,0,900,300))
	for i in 34:
		var x:=32.0+float(i)*24.5
		var y:=246.0+sin(float(i)*1.8)*17.0
		draw_line(Vector2(x,y+22),Vector2(x,y),Color("3b6352"),1.5,true)
		for petal in 5:
			var spot:=Vector2(x,y)+Vector2.from_angle(float(petal)*TAU/5)*4.0
			draw_circle(spot,3.5,Color("8da2b5",0.42))
	# 希望蛊没有可辨认的虫体，以生成的白色光点画出花海汇流。
	var texture:=GuArt.texture("hope_gu")
	for i in 48:
		var seed_value:=float(i)
		var source:=Vector2(38+fmod(seed_value*101,813),238+sin(seed_value*3.4)*18)
		var phase:=fmod(t*0.17+seed_value*0.137,1.0)
		var target:=heart if t<6.0 else center
		var converge:=smoothstep(0.0,1.0,phase)
		var point:=source.lerp(target,converge)
		point.y-=sin(phase*PI)*(58+fmod(seed_value*29,90))
		var alpha:=sin(phase*PI)*clampf(7.5-t,0,1)
		if t<=0: alpha=0.18+0.12*sin(seed_value)
		if t<=0: point=source-Vector2(0,12+fmod(seed_value*7,36))
		var mote_size:=10.0+fmod(seed_value*3.1,11)
		draw_texture_rect(texture,Rect2(point-Vector2.ONE*mote_size/2,Vector2.ONE*mote_size),false,Color(1,1,1,alpha))
	if t>2 and t<7:
		var light_size:=30.0+35.0*sin(clampf((t-2)/5,0,1)*PI)
		draw_texture_rect(texture,Rect2(heart-Vector2.ONE*light_size/2,Vector2.ONE*light_size),false)
	var membrane:=smoothstep(5.5,8.0,t)
	if membrane>0:
		var radius:=89.0*membrane
		draw_circle(center,radius,Color("102a2b"))
		var fill:float=smoothstep(8.0,12.0,t)*game.player.aperture.potential/100.0
		if completed: fill=game.player.aperture.capacity/100.0
		var surface:=center.y+radius-fill*radius*2
		for y in range(int(ceil(surface)),int(center.y+radius)):
			var half:=sqrt(maxf(0,radius*radius-pow(float(y)-center.y,2)))
			draw_line(Vector2(center.x-half,y),Vector2(center.x+half,y),Color("4f8b71"),1)
		if fill>0:
			var half:=sqrt(maxf(0,radius*radius-pow(surface-center.y,2)))
			draw_line(Vector2(center.x-half,surface),Vector2(center.x+half,surface),Color("9ac7a1"),2,true)
		draw_arc(center,radius+2,0,TAU,96,Color("e2e8d6",membrane),2.6,true)
		draw_arc(center,radius+7,0,TAU,96,Color("dbe5d6",0.13*membrane),4,true)
		if t<8:
			for i in 18:
				var angle:=float(i)*TAU/18+t*0.12
				var point:=center+Vector2.from_angle(angle)*radius
				draw_texture_rect(texture,Rect2(point-Vector2(10,10),Vector2(20,20)),false,Color(1,1,1,1-membrane*0.7))
	var font:=ThemeDB.fallback_font
	draw_string(font,Vector2(190,285),"凡人之身" if not completed else "一转初阶",HORIZONTAL_ALIGNMENT_CENTER,220,15,UIStyle.GOLD)
	draw_string(font,Vector2(530,272),"空窍尚未开辟" if t<5.5 else "光膜凝成" if t<8 else "青铜元海",HORIZONTAL_ALIGNMENT_CENTER,260,17,UIStyle.GOLD)
	if completed:
		draw_string(font,Vector2(530,294),"%s资质 · 元海 %.0f%%"%[game.player.aperture.aptitude(),game.player.aperture.capacity],HORIZONTAL_ALIGNMENT_CENTER,260,15,UIStyle.INK)
	draw_set_transform(Vector2.ZERO)
