extends Node3D
class_name Room

var shapeNode: Node
var doorwaysNode: Node

func _ready() -> void:
	shapeNode = find_child("Shape", true, false)
	doorwaysNode = find_child("Doorways", true, false)
	
	if shapeNode == null:
		print("Shape node missing in room: " + name)
	
	if doorwaysNode == null:
		print("Doorways node missing in room: " + name)

func getCells() -> Array[Vector2i]:
	if shapeNode == null:
		return []
		
	var result: Array[Vector2i] = []

	for c in shapeNode.get_children():
		if c is ShapeCell:
			var cell = c.cell
			result.append(cell)

	return result

func getDoorways() -> Array[Doorway]:
	if doorwaysNode == null:
		return []
	
	var result: Array[Doorway] = []
	
	for d in doorwaysNode.get_children():
		if d is Doorway:
			result.append(d)
	return result

func getTileCount() -> int:
	return getCells().size()

func getDoorCells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for d in getDoorways():
		result.append(d.cell)
	return result

func getNormalizedDoorCells() -> Array[Vector2i]:
	var cells = getDoorCells()
	if cells.is_empty():
		return []

	var min_x: int = 999999
	var min_y: int = 999999

	for c in cells:
		min_x = min(min_x, c.x)
		min_y = min(min_y, c.y)

	var result: Array[Vector2i] = []
	for c in cells:
		result.append(Vector2i(c.x - min_x, c.y - min_y))
	return result
