extends Node
class_name Grid

@export var cellSize: float = 2.0
var occupied: Dictionary = {}

func isOccupied(cell: Vector2i) -> bool:
	return occupied.has(cell)

func canPlace(cells: Array[Vector2i]) -> bool:
	for c in cells:
		if occupied.has(c):
			return false
	return true

func occupy(cells: Array[Vector2i], room: Room) -> void:
	for c in cells:
		occupied[c] = room

func gridToWorld(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * cellSize, 0, cell.y * cellSize)

func worldToGrid(pos: Vector3) -> Vector2i:
	return Vector2i(roundi(pos.x / cellSize), roundi(pos.z / cellSize))
