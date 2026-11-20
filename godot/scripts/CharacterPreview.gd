class_name CharacterPreview
extends Control

class Figure extends Node2D:
	var appearance: CharacterAppearance
	var animation:=ActorAnimation.new()
	func _draw() -> void:
		if appearance!=null: animation.draw(self,false,0,false,"",appearance)

var appearance:=CharacterAppearance.new()
var figure: Figure
var facing := 0
var pose := "idle"
var animate := true
var elapsed := 0.0
var bust := false

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	figure=Figure.new()
	figure.appearance=appearance
	add_child(figure)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if figure==null: return
	var factor:=maxf(0.3,minf(size.x/70.0,size.y/66.0))
	if bust:
		clip_contents=true
		factor=maxf(0.3,minf(size.x/32.0,size.y/36.0))
		figure.scale=Vector2.ONE*factor
		figure.position=Vector2(size.x*0.5,size.y*0.5+38*factor)
		return
	figure.scale=Vector2.ONE*factor
	figure.position=Vector2(size.x*0.5,size.y*0.5+20*factor)

func show_appearance(value: Dictionary, folder: String = "", images: Dictionary = {}) -> void:
	appearance.configure(value,folder,images)
	if figure!=null: figure.queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or figure==null: return
	var direction:float=[PI/2,PI,-PI/2,0.0][facing]
	if animate:
		elapsed+=delta
		if pose in ["strike","cast","hurt","death"] and (elapsed>1.5 or figure.animation.action=="idle"):
			figure.animation.restore_dead(false)
			figure.animation.play(pose,direction)
			elapsed=0
		if pose in ["idle","walk"] and figure.animation.action!="idle": figure.animation.restore_dead(false)
		figure.animation.advance(delta,pose=="walk",direction,delta*65)
	else:
		figure.animation.restore_dead(pose=="death")
		figure.animation.direction=direction
	figure.queue_redraw()
