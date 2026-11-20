class_name CollapseAnimation
extends RefCounted

const DURATION := 1.15

static func draw(canvas: CanvasItem, texture: AtlasTexture, rect: Rect2, progress: float, opacity: float = 1.0, origin: Vector2 = Vector2.ZERO) -> void:
	# Painted roof, walls and beams fall separately, without changing gameplay state.
	for row in 3:
		for col in 4:
			var t:=clampf((progress-float(2-row)*0.045)*1.2,0,1)
			var extent:=rect.size/Vector2(4,3)
			var center:=rect.position+extent*Vector2(col+0.5,row+0.5)
			var drift:=float(col)-1.5
			var drop:=Vector2(drift*t*24,-center.y*t*t)
			canvas.draw_set_transform(origin+center+drop,drift*t*0.32,Vector2(1,1-t*0.4))
			var source:=Rect2(texture.region.position+texture.region.size*Vector2(col/4.0,row/3.0),texture.region.size/Vector2(4,3))
			canvas.draw_texture_rect_region(texture.atlas,Rect2(-extent*0.5,extent),source,Color(1,1,1,(1-smoothstep(0.55,1.0,t))*opacity))
	canvas.draw_set_transform(origin)
	for i in 9:
		var spread:=float(i-4)/4.0
		var t:=clampf((progress-0.14)*1.3,0,1)
		canvas.draw_circle(Vector2(spread*rect.size.x*0.55*t,-8-absf(spread)*t*12),8+t*(13+i%3*4),Color(0.68,0.65,0.49,sin(t*PI)*0.3*opacity))
	canvas.draw_set_transform(Vector2.ZERO)
