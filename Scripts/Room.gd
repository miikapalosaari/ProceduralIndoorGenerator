extends Node3D
class_name Room

#var shapeNode: Node
#var doorwaysNode: Node
@export var tags: Array[String] = ["room"]
var gridRotation: int = 0

func getCells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var shapeNode = get_node_or_null("Shape")
	
	if shapeNode:
		for c in shapeNode.get_children():
			var cell = c.cell
			result.append(cell)
	return result

func getDoorways() -> Array[Doorway]:
	var result: Array[Doorway] = []
	var doorsNode = get_node_or_null("Doorways")
	
	if doorsNode:
		for d in doorsNode.get_children():
			if d is Doorway:
				result.append(d)
	return result

func getDoorCells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for d in getDoorways():
		result.append(d.cell)
	return result

static func rotateCell(c: Vector2i, rot: int) -> Vector2i:
	match rot % 4:
		1: return Vector2i(c.y, -c.x)
		2: return Vector2i(-c.x, -c.y)
		3: return Vector2i(-c.y, c.x)
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
