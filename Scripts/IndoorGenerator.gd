extends Node
class_name IndoorGenerator

@export var roomTemplates: Array[PackedScene]
@export var startRoom: PackedScene

@onready var grid: Grid = $"../Grid"
@onready var root: Node3D = $"../IndoorRoot"

@export var roomCount: int = 10
@export var maxPlacementAttempts: int = 10

var templateSizes: Dictionary = {}

var rooms: Array[Room] = []
var openDoorways: Array[Doorway] = []

func _ready() -> void:
	for t in roomTemplates:
		templateSizes[t] = getTemplateTileCount(t)
	call_deferred("generate")

func getTemplateTileCount(scene: PackedScene) -> int:
	var inst = scene.instantiate()
	var count = inst.getTileCount()
	inst.queue_free()
	return count


func generate() -> void:
	print("Starting generation")

	var start: Room = startRoom.instantiate()
	root.call_deferred("add_child", start)
	await start.ready

	start.global_position = Vector3.ZERO
	registerRoom(start)

	for d in start.getDoorways():
		openDoorways.append(d)
	expand()

func expand() -> void:
	var attempts: int = 0
	while rooms.size() < roomCount:
		if attempts >= maxPlacementAttempts:
			print("Stopping generation because too many placements failed.")
			break
		if not canAnyTemplateFit():
			print("No templates can fit remaining space. Stopping early.")
			break
		var template: PackedScene = roomTemplates[randi() % roomTemplates.size()]
		var newRoom: Room = template.instantiate()
		
		root.call_deferred("add_child", newRoom)
		await newRoom.ready

		if not placeRoomRandom(newRoom):
			newRoom.queue_free()
			attempts += 1
			continue

		registerRoom(newRoom)

func placeRoomRandom(room: Room) -> bool:
	var cellsLocal = normalizeCells(room.getCells())
	var bounds = getRoomBounds(cellsLocal) 
	
	var min_x = bounds["min_x"]
	var max_x = bounds["max_x"]
	var min_y = bounds["min_y"]
	var max_y = bounds["max_y"]

	var origin_min_x = -min_x
	var origin_max_x = grid.gridWidth - 1 - max_x
	var origin_min_y = -min_y
	var origin_max_y = grid.gridHeight - 1 - max_y

	if origin_min_x > origin_max_x or origin_min_y > origin_max_y:
		return false
	
	for i in range(maxPlacementAttempts):
		var origin: Vector2i = Vector2i(
			randi_range(origin_min_x, origin_max_x),
			randi_range(origin_min_y, origin_max_y)
		)
		var cells = offsetCells(cellsLocal, origin)

		if grid.canPlace(cells):
			room.global_position = grid.gridToWorld(origin)
			return true
	return false

func registerRoom(room: Room) -> void:
	rooms.append(room)

	var origin: Vector2i = grid.worldToGrid(room.global_position)
	
	var cellsLocal = normalizeCells(room.getCells())
	var cells: Array[Vector2i] = offsetCells(cellsLocal, origin)

	grid.occupy(cells, room)

func offsetCells(cells: Array[Vector2i], offset: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in cells:
		result.append(c + offset)
	return result

func canAnyTemplateFit() -> bool:
	var rect = grid.largestEmptyRectangle()
	var maxArea = rect.x * rect.y

	for t in roomTemplates:
		if templateSizes[t] <= maxArea:
			return true

	return false


func normalizeCells(cells: Array[Vector2i]) -> Array[Vector2i]:
	var min_x := 999999
	var min_y := 999999

	for c in cells:
		if c.x < min_x:
			min_x = c.x
		if c.y < min_y:
			min_y = c.y

	var result: Array[Vector2i] = []
	for c in cells:
		result.append(Vector2i(c.x - min_x, c.y - min_y))
	return result

func getRoomBounds(cells: Array[Vector2i]) -> Dictionary:
	var min_x := 999999
	var max_x := -999999
	var min_y := 999999
	var max_y := -999999

	for c in cells:
		if c.x < min_x:
			min_x = c.x
		if c.x > max_x:
			max_x = c.x
		if c.y < min_y:
			min_y = c.y
		if c.y > max_y:
			max_y = c.y

	return {
		"min_x": min_x,
		"max_x": max_x,
		"min_y": min_y,
		"max_y": max_y
	}
