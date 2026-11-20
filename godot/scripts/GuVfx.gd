class_name GuVfx
extends RefCounted

## Presentation only. Reads actual Gu state; never changes damage, resources or collision.
const COLORS := {
	"moon_glow":Color("6aa9ff"), "white_jade":Color("fff5d8"), "moon_raiment":Color("a3d8ff"),
	"jade_skin":Color("9de8c1"), "copper_skin":Color("e6a35f"),
	"iron_skin":Color("b5c4d0"), "stone_skin":Color("bcb8a3"),
	"beast_skin":Color("d6a06d"), "brute_longhorn":Color("e67d52"),
	"yellow_camel":Color("e6c96b"), "dragon_cricket":Color("9ce2bf"),
	"little_light":Color("fff2bd"), "white_boar":Color("efe7ca"),
	"black_boar":Color("a99bcc"), "jiu_chong":Color("9bdbc3"),
	"moon_blade":Color("98daee"),
}
const MAX_EVENTS := 80
const CAST_HEIGHT := Vector2(0,-20) # World positions are ground anchors; art projects the hand/chest height.
var events: Array[Dictionary] = []
var active: Dictionary = {}
var clock := 0.0
var low_quality := false
var _last_pos := Vector2.ZERO
var _step_time := 0.0

static func tint(id: String) -> Color:
	return COLORS.get(id,Color("e8dfbc"))

func emit(kind: String, pos: Vector2, id: String, duration: float, extra: Dictionary = {}) -> void:
	var e:Dictionary={"kind":kind,"pos":pos,"id":id,"life":duration,"max":duration}
	e.merge(extra,true)
	events.append(e)
	while events.size()>(32 if low_quality else MAX_EVENTS): events.pop_front()

func clear(pos: Vector2 = Vector2.ZERO) -> void:
	events.clear()
	active.clear()
	_last_pos=pos
	_step_time=0

func snapshot(game: Node) -> Dictionary:
	var p:Player=game.player
	if not game.running or p==null or p.dead: return {}
	var gus:GuManager=game.get_node("/root/Gus")
	var result:Dictionary={}
	if p.jade_guard:
		for gu in gus.owned_gus:
			if gu.template_id=="jade_skin" and not gu.dead and gu.location!="bag":
				result.guard="jade_skin"
				break
	var skin:=p.gu_effects.usable(gus,p.gu_effects.guard_id)
	if skin!=null: result.guard=skin.template_id
	if game.active_light_gu()!=null: result.light="little_light"
	if p.gu_effects.brute_left>0 and p.gu_effects.usable(gus,p.gu_effects.brute_id)!=null: result.brute="brute_longhorn"
	if p.gu_effects.endurance_left>0 and p.gu_effects.usable(gus,p.gu_effects.endurance_id)!=null: result.endurance="yellow_camel"
	var train:=p.gu_effects.usable(gus,p.boar_cultivation.active_id)
	if train!=null: result.training=train.template_id
	return result

func advance(delta: float, game: Node) -> void:
	low_quality=game.low_quality
	var next:=snapshot(game)
	if next!=active: game.player.queue_redraw()
	if game.player.dead:
		clear(game.player.position)
		return
	# State is reconciled even while a menu is open (taking a Gu out must hide its aura).
	for key in active:
		if active.get(key,"")!=next.get(key,""):
			for i in range(events.size()-1,-1,-1):
				if events[i].kind=="awaken" and events[i].id==active[key]: events.remove_at(i)
	if game.paused:
		active=next
		_last_pos=game.player.position
		return
	clock+=delta
	for i in range(events.size()-1,-1,-1):
		events[i].life-=delta
		if events[i].life<=0: events.remove_at(i)
	for key in next:
		if next[key]!=active.get(key,""):
			emit("awaken",game.player.position,next[key],0.45)
	active=next
	_step_time+=delta
	var p:Player=game.player
	if p.dash_t>0 and _step_time>=0.035 and _last_pos!=Vector2.ZERO and p.position.distance_to(_last_pos)>2:
		emit("step",p.position,"yellow_camel" if active.has("endurance") else "dragon_cricket",0.28,{"from":_last_pos})
		_step_time=0
	_last_pos=p.position

func guard_hit(pos: Vector2, id: String, reduced: float, broken: bool) -> void:
	emit("guard_break" if broken else "guard_hit",pos,id,0.45 if broken else 0.32,{"reduced":reduced})

func impact(pr: Dictionary, surface: bool = false) -> void:
	if pr.get("gu_id","") not in ["moon_blade","moon_glow"]: return
	emit("moon_hit",pr.pos,pr.gu_id,0.34,{"angle":Vector2(pr.vel).angle(),"strong":float(pr.r)>6,"surface":surface})

static func _star(c:CanvasItem,pos:Vector2,r:float,color:Color,rotation:float=0) -> void:
	var pts:=PackedVector2Array()
	for i in 10: pts.append(pos+Vector2.from_angle(rotation-PI/2+i*PI/5)*(r if i%2==0 else r*0.42))
	c.draw_colored_polygon(pts,color)

static func _line(c:CanvasItem,points:Array,color:Color,width:float=1.0) -> void:
	c.draw_polyline(PackedVector2Array(points),color,width,true)

static func _plate(c:CanvasItem,pos:Vector2,size:Vector2,col:Color,shape:int=0) -> void:
	var pts:=PackedVector2Array()
	if shape==0:
		pts=PackedVector2Array([pos+Vector2(0,-size.y),pos+Vector2(size.x,0),pos+Vector2(0,size.y),pos+Vector2(-size.x,0)])
	else:
		pts=PackedVector2Array([pos+Vector2(-size.x,-size.y*0.7),pos+Vector2(size.x*0.6,-size.y),pos+size,pos+Vector2(-size.x*0.8,size.y*0.8)])
	c.draw_colored_polygon(pts,Color(col,0.20))
	pts.append(pts[0])
	c.draw_polyline(pts,Color(col,0.8),1.2,true)

func draw_player(c:CanvasItem,game:Node,front:bool) -> void:
	var p:Player=game.player
	if p.dead: return
	# Read truth at draw time too, so UI mutations cannot leave a one-frame phantom guard.
	var state:=snapshot(game)
	var pulse:=0.7+sin(clock*3.4)*0.15
	if not front:
		if state.has("training"):
			var col:=tint(state.training)
			c.draw_set_transform(Vector2(0,6),0,Vector2(1,0.35))
			c.draw_arc(Vector2.ZERO,25,clock*0.7,clock*0.7+PI*1.5,32,Color(col,0.65),2,true)
			c.draw_arc(Vector2.ZERO,31,-clock*0.5,-clock*0.5+PI,24,Color(col,0.3),1.5,true)
			c.draw_set_transform(Vector2.ZERO)
		if state.has("guard"):
			var col:=tint(state.guard)
			var hull:=PackedVector2Array([Vector2(-12,5),Vector2(-23,-8),Vector2(-21,-31),Vector2(-10,-47),Vector2(10,-47),Vector2(21,-31),Vector2(23,-8),Vector2(12,5)])
			c.draw_colored_polygon(hull,Color(col,0.08*pulse))
			hull.append(hull[0])
			c.draw_polyline(hull,Color(col,0.22*pulse),3,true)
		return
	if state.has("guard"):
		var id:String=state.guard
		var col:=tint(id)
		for side in [-1,1]:
			for j in 3:
				var pos:=Vector2(side*(19-j*2),-30+j*13)
				match id:
					"jade_skin": _plate(c,pos,Vector2(4,7),col)
					"white_jade":
						_plate(c,pos,Vector2(6,9),col)
						c.draw_circle(pos,2,Color(col,0.65))
					"moon_raiment":
						c.draw_arc(pos,8+sin(clock*3+j)*2,clock+j,clock+j+PI,18,Color(col,0.8),3,true)
					"copper_skin":
						_line(c,[pos+Vector2(-4,-4),pos+Vector2(4,-2),pos+Vector2(4,4),pos+Vector2(-4,3)],col,2)
						c.draw_circle(pos,1.2,Color("fff0cb"))
					"iron_skin":
						_plate(c,pos,Vector2(5,5),col,1)
						c.draw_line(pos+Vector2(-3,-3),pos+Vector2(3,-3),Color("f1f6ff"),1,true)
					"stone_skin":
						_plate(c,pos,Vector2(5,6),col,1)
						_line(c,[pos+Vector2(-3,-1),pos+Vector2(1,1),pos+Vector2(-1,4)],Color(col,0.7))
					"beast_skin":
						for k in 3:
							c.draw_line(pos+Vector2(side*k*2,-4),pos+Vector2(side*(k*2+3),3),Color(col,0.8-k*0.12),1.6,true)
		c.draw_arc(Vector2(0,-24),21,PI*1.15,PI*1.85,24,Color(col,pulse*0.6),1.5,true)
	if state.has("brute"):
		for side in [-1,1]:
			var center:=Vector2(side*15,-19)
			c.draw_arc(center,7+sin(clock*9)*1.2,-PI*0.8,PI*0.8,16,Color(tint("brute_longhorn"),0.8),2.5,true)
			_line(c,[center+Vector2(-3,7),center+Vector2(side*7,1),center+Vector2(side*4,-9)],Color("ffcd8d"),1.4)
	if state.has("endurance"):
		for side in [-1,1]:
			var pos:=Vector2(side*10,1)
			c.draw_arc(pos,7,-clock*2+side,-clock*2+side+PI*1.3,18,Color(tint("yellow_camel"),0.8),1.8,true)
		for i in (2 if low_quality else 4):
			var f:=fposmod(clock*0.65+i*0.25,1.0)
			c.draw_circle(Vector2(sin(i*2+clock)*16,6-f*23),1.4,Color(tint("yellow_camel"),(1-f)*0.65))
	if state.has("light"):
		var palm:=Vector2(14 if cos(p.dir)>=0 else -14,-19)
		c.draw_circle(palm,8,Color(tint("little_light"),0.09))
		_star(c,palm,5.2+sin(clock*4)*0.7,tint("little_light"),clock*0.2)
		if not low_quality:
			for i in 3:
				var mote:=palm+Vector2.from_angle(clock+i*TAU/3)*10
				c.draw_circle(mote,1,Color(tint("little_light"),0.7))
	if state.has("training"):
		var col:=tint(state.training)
		for i in (3 if low_quality else 6):
			var f:=fposmod(clock*0.45+i/6.0,1.0)
			var pos:=Vector2(sin(i*2.4+clock*1.5)*(17-7*f),5-f*43)
			c.draw_line(pos,pos+Vector2(0,5),Color(col,sin(f*PI)*0.65),2,true)
		# Two converging streams signify bodily training, rather than an attack aura.
		for side in [-1,1]:
			c.draw_arc(Vector2(side*7,-17),12,-PI/2 if side>0 else PI/2,PI/2 if side>0 else PI*1.5,20,Color(col,0.5*pulse),1.3,true)

static func draw_moon(c:CanvasItem,pr:Dictionary,low:bool=false) -> void:
	var pos:Vector2=pr.pos+CAST_HEIGHT
	var angle:=Vector2(pr.vel).angle()
	var r:float=pr.r
	var col:Color=pr.color
	var trail:Array=pr.get("trail",[])
	if trail.size()>1:
		var ribbon:=PackedVector2Array()
		var colors:=PackedColorArray()
		var normal:=Vector2.from_angle(angle+PI/2)
		for side in [1,-1]:
			for n in trail.size():
				var i:int=n if side==1 else trail.size()-1-n
				var f:=float(i)/trail.size()
				ribbon.append(trail[i]+CAST_HEIGHT+normal*side*r*f*0.4)
				colors.append(Color(col,f*f*0.28))
		c.draw_polygon(ribbon,colors)
	# The visible crescent fits the collision radius; its translucent trail does not deal damage.
	c.draw_set_transform(pos,angle)
	var outer:=PackedVector2Array()
	var shape:=PackedVector2Array()
	var steps:=12 if low else 20
	for i in steps+1:
		var a:=lerpf(-PI/2,PI/2,float(i)/steps)
		var v:=Vector2(cos(a)*r,sin(a)*r)
		outer.append(v)
		shape.append(v)
	for i in range(steps,-1,-1):
		var a:=lerpf(-PI/2,PI/2,float(i)/steps)
		shape.append(Vector2(cos(a)*r*0.18,sin(a)*r))
	c.draw_polyline(outer,Color(col,0.16),5,true)
	c.draw_colored_polygon(shape,Color(col,0.95))
	c.draw_polyline(outer,Color("f0fcff"),1.6,true)
	if r>6:
		c.draw_arc(Vector2(-2,0),r*0.7,-1.2,1.2,16,Color("fff2bd"),1.2,true)
	c.draw_set_transform(Vector2.ZERO)

func draw_world(c:CanvasItem,game:Node) -> void:
	var effects:GuEffects=game.player.gu_effects
	if effects.ward_id!="" and effects.ward_valid(game):
		var center:Vector2=effects.ward_target.position+CAST_HEIGHT
		for i in 3:
			c.draw_arc(center,18+i*5,clock*(1 if i%2==0 else -1)+i,clock*(1 if i%2==0 else -1)+i+PI*1.4,28,Color("a3d8ff",0.65-i*0.15),2.5,true)
		c.draw_line(game.player.position+CAST_HEIGHT,center,Color("a3d8ff",0.18),1.5,true)
	for e in events:
		var t:float=1.0-float(e.life)/float(e.max)
		var fade:=1.0-t
		var col:=tint(e.id)
		var pos:Vector2=e.pos
		match e.kind:
			"moon_cast":
				c.draw_set_transform(pos+CAST_HEIGHT+Vector2.from_angle(e.angle)*13,e.angle)
				c.draw_arc(Vector2.ZERO,8+t*11,-1.3,1.3,20,Color(col,fade),2,true)
				c.draw_line(Vector2(0,0),Vector2(20+t*10,0),Color(col,fade*0.5),3,true)
				c.draw_set_transform(Vector2.ZERO)
			"moon_hit":
				pos+=CAST_HEIGHT
				var scale_factor:=1.4 if e.strong else 1.0
				var count:=5 if low_quality else 9
				for i in count:
					var a:float=e.angle+(float(i)/count-0.5)*TAU
					var dir:=Vector2.from_angle(a)
					var start:=pos+dir*(4+t*18)*scale_factor
					c.draw_line(start,start+dir*(4+fade*7),Color(col,fade),1.5 if i%2 else 2.2,true)
				c.draw_arc(pos,4+t*19,0,TAU,24,Color(col,fade*0.6),1.4,true)
			"melee":
				pos+=CAST_HEIGHT
				var a:float=e.angle
				var radius:=lerpf(24,48,t)
				var start:=a-0.85+t*0.9
				c.draw_arc(pos,radius,start,start+0.9,24,Color(col,fade*0.85),4 if e.strong else 2,true)
				c.draw_arc(pos,radius-5,start+0.1,start+0.75,20,Color(col,fade*0.3),2,true)
			"guard_hit","guard_break":
				var broken:bool=e.kind=="guard_break"
				var center:=pos+Vector2(0,-21)
				for i in (6 if low_quality else 10):
					var a:=i*TAU/10
					var at:=center+Vector2(cos(a)*23,sin(a)*27)*(1+t*(0.8 if broken else 0.2))
					if broken:
						c.draw_line(at,at+Vector2.from_angle(a+0.6)*6,Color(col,fade),2,true)
					else:
						c.draw_arc(at,3+5*t,a-0.6,a+0.6,8,Color(col,fade),2,true)
			"leap":
				var origin:Vector2=e.from
				var destination:Vector2=e.pos
				var count:=3 if low_quality else 5
				for i in count:
					var f:=float(i)/count
					var at:=origin.lerp(destination,f)+Vector2(0,-sin(f*PI)*13)
					c.draw_arc(at+Vector2(0,-12),13,-0.8,1.4,12,Color(col,fade*(0.2+f*0.3)),2,true)
					c.draw_line(at+Vector2(-6,3),at+Vector2(5,3),Color(col,fade*0.4),2,true)
				c.draw_set_transform(destination+Vector2(0,7),0,Vector2(1,0.35))
				c.draw_arc(Vector2.ZERO,8+t*22,0,TAU,24,Color(col,fade*0.7),2,true)
				c.draw_set_transform(Vector2.ZERO)
			"step":
				c.draw_line(e.from+Vector2(0,7),pos+Vector2(0,7),Color(col,fade*0.35),3,true)
			"refine":
				pos=game.player.position+Vector2(0,-17)
				for i in (4 if low_quality else 8):
					var a:=i*TAU/8+t*5
					var at:=pos+Vector2(cos(a),sin(a)*0.7)*(26*(1-t)+3)
					c.draw_circle(at,2+sin(t*PI)*2,Color(col,fade*0.45))
				_star(c,pos,3+sin(t*PI)*5,Color("d5f4c3"),t*2)
			"awaken":
				# Brief accents at the body, never a large opaque screen flash.
				for i in (4 if low_quality else 7):
					var a:=i*TAU/7
					var at:=pos+Vector2(0,-20)+Vector2(cos(a)*20,sin(a)*26)*(0.8+t*0.5)
					c.draw_line(at,at+Vector2.from_angle(a)*5,Color(col,fade*0.6),1.6,true)
