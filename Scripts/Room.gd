extends Node3D
class_name Room

var shapeNode: Node
var doorwaysNode: Node
var gridRotation: int = 0

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

func rotateCell(c: Vector2i, rot: int) -> Vector2i:
	match rot:
		0:
			return c
		1:
			return Vector2i(c.y, -c.x)
		2:
			return Vector2i(-c.x, -c.y)
		3:
			return Vector2i(-c.y, c.x)
	return c

func getRotatedCells(rot: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in getCells():
		result.append(rotateCell(c, rot))
	return result

func getRotatedDoorCells(rot: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in getDoorCells():
		result.append(rotateCell(c, rot))
	return result
