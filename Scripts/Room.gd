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
