extends Node
class_name Grid

@export var cellSize: float = 2.0
var occupied: Dictionary = {}   # cell -> {"room": Room, "type": "shape" or "door"}

@export var gridWidth: int = 80
@export var gridHeight: int = 80

func isOccupied(cell: Vector2i) -> bool:
	return occupied.has(cell)

func canPlace(shapeCells: Array[Vector2i], doorCells: Array[Vector2i]) -> bool:
	for c in shapeCells:
		if not inBounds(c):
			return false
		if occupied.has(c):
			return false

	for c in doorCells:
		if not inBounds(c):
			return false
		if occupied.has(c):
			if occupied[c]["type"] == "shape":
				return false
	return true

func occupyShape(cells: Array[Vector2i], room: Room) -> void:
	for c in cells:
		occupied[c] = {"room": room, "type": "shape"}

func occupyDoor(cells: Array[Vector2i], room: Room) -> void:
	for c in cells:
		occupied[c] = {"room": room, "type": "door"}

func gridToWorld(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * cellSize, 0, cell.y * cellSize)

func worldToGrid(pos: Vector3) -> Vector2i:
	return Vector2i(roundi(pos.x / cellSize), roundi(pos.z / cellSize))

func inBounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < gridWidth and cell.y >= 0 and cell.y < gridHeight

func getUnoccupiedCells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in gridWidth:
		for y in gridHeight:
			var c = Vector2i(x, y)
			if not occupied.has(c):
				result.append(c)
	return result

func getOccupiedCount() -> int:
	return occupied.size()

func getUnoccupiedCount() -> int:
	return gridWidth * gridHeight - occupied.size()

func largestEmptyRectangle() -> Vector2i:
	var heights := []
	for x in gridWidth:
		heights.append(0)

	var best = Vector2i(0, 0)

	for y in gridHeight:
		for x in gridWidth:
			var c = Vector2i(x, y)
			if not occupied.has(c):
				heights[x] += 1
			else:
				heights[x] = 0

		var w_h = largestRectangleInHistogram(heights)
		if w_h.x * w_h.y > best.x * best.y:
			best = w_h
	return best

func largestRectangleInHistogram(h: Array) -> Vector2i:
	var stack: Array = []
	var best := Vector2i(0, 0)
	var i := 0

	while i <= h.size():
		var cur: int
		if i == h.size():
			cur = 0
		else:
			cur = h[i]
			
		if stack.is_empty():
			stack.append(i)
			i += 1
		else:
			var last_index = stack.back()
			var last_height = h[last_index]

			if cur >= last_height:
				stack.append(i)
				i += 1
			else:
				stack.pop_back()
				var height = last_height

				var width: int
				if stack.is_empty():
					width = i
				else:
					width = i - stack.back() - 1

				if width * height > best.x * best.y:
					best = Vector2i(width, height)
	return best
