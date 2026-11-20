class_name InteriorFixtureVisual
extends Node2D

## Furniture shares the actors' Y sort so residents stand behind their desk.
var interior: HouseInterior
var fixture_id := ""

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	position=HouseInterior.ORIGIN+Vector2(0,HouseInterior.FIXTURES[fixture_id].end.y)

func _process(_delta: float) -> void:
	if not is_instance_valid(interior):
		queue_free()
		return
	visible=interior.visible and not SettlementData.is_cave(interior.house_id)
	if visible: queue_redraw()

func _draw() -> void:
	interior.draw_fixture(fixture_id,self,position-HouseInterior.ORIGIN)
