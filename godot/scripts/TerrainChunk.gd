class_name TerrainChunk
extends Node2D

var blocks: TerrainLayers
var cells := Rect2i()
var layer := 0

func _draw() -> void:
	draw_set_transform(Vector2.ONE-Vector2(cells.position)*GameData.TILE)
	blocks.draw_cells(self,cells,layer)
