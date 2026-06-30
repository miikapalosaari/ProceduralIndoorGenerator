extends Node
class_name IndoorGenerator

@export var roomTemplates: Array[PackedScene]
@export var startRoom: PackedScene

@onready var grid: Grid = $"../Grid"
@onready var root: Node3D = $"../IndoorRoot"

@export var roomCount: int = 10
@export var placementRadius: int = 40
@export var maxPlacementAttempts: int = 100

var rooms: Array[Room] = []
var openDoorways: Array[Doorway] = []

func _ready() -> void:
	call_deferred("generate")

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
		var template: PackedScene = roomTemplates[randi() % roomTemplates.size()]
		var newRoom: Room = template.instantiate()
		
		root.call_deferred("add_child", newRoom)
		await newRoom.ready

		if not placeRoomRandom(newRoom):
			newRoom.queue_free()
			print("Failed to place room.")
			continue

		registerRoom(newRoom)

func placeRoomRandom(room: Room) -> bool:
	for i in range(maxPlacementAttempts):
		var origin: Vector2i = Vector2i(
			randi_range(-placementRadius, placementRadius),
			randi_range(-placementRadius, placementRadius)
		)
		var cells = offsetCells(room.getCells(), origin)

		if grid.canPlace(cells):
			room.global_position = grid.gridToWorld(origin)
			return true
	return false

func registerRoom(room: Room) -> void:
	rooms.append(room)

	var origin: Vector2i = grid.worldToGrid(room.global_position)
	var cells: Array[Vector2i] = offsetCells(room.getCells(), origin)

	grid.occupy(cells, room)

func offsetCells(cells: Array[Vector2i], offset: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in cells:
		result.append(c + offset)
	return result
