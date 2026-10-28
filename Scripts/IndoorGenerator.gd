extends Node
class_name IndoorGenerator

@export var roomDefinitions: Array[RoomDefinition]
@export var startRoomDef: RoomDefinition
@export var maxAttemptsPerDoor: int = 15

@onready var grid: Grid = $"../Grid"
@onready var root: Node3D = $"../IndoorRoot"
@export var maxStitchDistance: int = 8
@export var stitchTileScene: PackedScene

@export var roomCount: int = 15
@export var maxPlacementAttempts: int = 10

var rooms: Array[Room] = []
var openDoorways: Array[Doorway] = []
var doorFailures: Dictionary = {}

const CARDINAL_DIRS = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0)
]

func _ready() -> void:
	call_deferred("generate")

func generate() -> void:
	for def in roomDefinitions:
		if def:
			def.currentCount = 0
	if startRoomDef:
		startRoomDef.currentCount = 0

	var startDef = startRoomDef if startRoomDef else roomDefinitions.pick_random()
	var start: Room = startDef.scene.instantiate()
	root.add_child(start)

	start.global_position = Vector3.ZERO
	start.rotation_degrees.y = 0
	startDef.currentCount += 1
	registerRoom(start, 0, Vector2i.ZERO)
	
	expand()
	stitchNearbyDoors()
	sealUnconnectedDoors()
	
	await get_tree().process_frame
	grid.debugDrawOccupiedLines(6.0)

func expand() -> void:
	var maxTotalLoops: int = 10000
	var loopCount: int = 0
	while rooms.size() < roomCount and not openDoorways.is_empty():
		loopCount += 1
		if loopCount > maxTotalLoops:
			break
		
		var targetDoor: Doorway = openDoorways.pick_random()
		var chosenDef: RoomDefinition = pickDefinitionForDoor(targetDoor)
		
		if chosenDef == null:
			openDoorways.erase(targetDoor)
			continue
				
		var newRoom: Room = chosenDef.scene.instantiate()
 		
		if tryPlaceRoom(newRoom, targetDoor):
			chosenDef.currentCount += 1
			doorFailures.clear() 
		else:
			newRoom.queue_free()
			doorFailures[targetDoor] = doorFailures.get(targetDoor, 0) + 1
			if doorFailures[targetDoor] >= maxAttemptsPerDoor:
				openDoorways.erase(targetDoor)
				doorFailures.erase(targetDoor)

func pickDefinitionForDoor(door: Doorway) -> RoomDefinition:
	var validDefs: Array[RoomDefinition] = []
	var totalWeight: int = 0

	for def in roomDefinitions:
		if not def or not def.canPlace():
			continue
		if def.matchesRequiredTags(door.requiredTags):
			validDefs.append(def)
			totalWeight += def.weight
 
	if validDefs.is_empty():
		return null
	
	var roll = randi_range(1, totalWeight)
	var accum = 0
	for def in validDefs:
		accum += def.weight
		if roll <= accum:
			return def
	return validDefs[0]

func tryPlaceRoom(newRoom: Room, targetDoor: Doorway) -> bool:
	var newDoorways = newRoom.getDoorways()
	newDoorways.shuffle()

	for newDoor in newDoorways:
		var rot: int = (int(newDoor.direction) - targetDoor.worldDir + 6) % 4
		var offset = targetDoor.getForwardCell() - Room.rotateCell(newDoor.cell, rot)
		
		var shapeCells = offsetCells(newRoom.getRotatedCells(rot), offset)
		var doorCells = offsetCells(newRoom.getRotatedDoorCells(rot), offset)
		
		if not grid.canPlace(shapeCells, doorCells): continue
		if not doorsAreValid(newRoom, rot, offset, targetDoor, newDoor, shapeCells, doorCells): 
			continue

		root.add_child(newRoom)
		newRoom.global_position = grid.gridToWorld(offset)
		newRoom.rotation_degrees.y = rot * 90
		
		targetDoor.connected = true
		newDoor.connected = true
		openDoorways.erase(targetDoor)
		
		autoConnectAlignedDoors(newRoom, rot, offset)
		registerRoom(newRoom, rot, offset)
		return true
	return false

func doorsAreValid(newRoom: Room, rot: int, offset: Vector2i, targetDoor: Doorway, connectingDoor: Doorway, newShapes: Array, newDoors: Array) -> bool:
	for extDoor in openDoorways:
		if extDoor == targetDoor: 
			continue
		var extForward = extDoor.getForwardCell()
		if extForward in newShapes or extForward in newDoors:
			var aligns = false
			for nDoor in newRoom.getDoorways():
				if nDoor == connectingDoor: 
					continue
				var nWorld = offset + Room.rotateCell(nDoor.cell, rot)
				var nDir = (int(nDoor.direction) - rot + 4) % 4
				
				if nWorld == extForward and (nDir + 2) % 4 == extDoor.worldDir:
					if tagsAreCompatible(newRoom.tags, extDoor.requiredTags):
						aligns = true
						break
			if not aligns: 
				return false

	for nDoor in newRoom.getDoorways():
		if nDoor == connectingDoor: continue
		var nForward = getNewDoorForwardCell(nDoor, rot, offset)
		if not grid.inBounds(nForward): return false
			
		if grid.isOccupied(nForward):
			var aligns = false
			for extDoor in openDoorways:
				if extDoor == targetDoor: continue
				if extDoor.worldCell == nForward:
					var nDir = (int(nDoor.direction) - rot + 4) % 4
					if extDoor.worldDir == (nDir + 2) % 4:
						if tagsAreCompatible(newRoom.tags, extDoor.requiredTags):
							aligns = true
							break
			if not aligns: 
				return false
	return true

func tagsAreCompatible(roomTags: Array[String], doorRequiredTags: Array[String]) -> bool:
	if doorRequiredTags.is_empty():
		return true
	for t in doorRequiredTags:
		if t in roomTags:
			return true
	return false
 
func autoConnectAlignedDoors(room: Room, rot: int, offset: Vector2i) -> void:
	for d in room.getDoorways():
		if d.connected: continue
		
		var forwardCell = getNewDoorForwardCell(d, rot, offset)
		var worldDir = (int(d.direction) - rot + 4) % 4
		
		for i in range(openDoorways.size() - 1, -1, -1):
			var other = openDoorways[i]
			if other.worldCell == forwardCell and other.worldDir == (worldDir + 2) % 4:
				if tagsAreCompatible(room.tags, other.requiredTags):
					d.connected = true
					other.connected = true
					openDoorways.remove_at(i)
					doorFailures.erase(other)
					break

func getNewDoorForwardCell(d: Doorway, rot: int, offset: Vector2i) -> Vector2i:
	var worldCell = offset + Room.rotateCell(d.cell, rot)
	var worldDir = (int(d.direction) - rot + 4) % 4
	return worldCell + Doorway.getDirVector(worldDir)

func registerRoom(room: Room, rot: int, origin: Vector2i) -> void:
	rooms.append(room)
	room.gridRotation = rot
	grid.occupyShape(offsetCells(room.getRotatedCells(rot), origin), room)
	grid.occupyDoor(offsetCells(room.getRotatedDoorCells(rot), origin), room)

	for d in room.getDoorways():
		if not d.connected:
			d.worldCell = origin + Room.rotateCell(d.cell, rot)
			d.worldDir = (int(d.direction) - rot + 4) % 4
			d.attachedRoomTags = room.tags
			openDoorways.append(d)
 
func offsetCells(cells: Array[Vector2i], offset: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in cells:
		result.append(c + offset)
	return result
 
func stitchNearbyDoors() -> void:
	if stitchTileScene == null:
		push_warning("No stitchTileScene assigned in IndoorGenerator!")
		return

	var doorCandidates: Array[Doorway] = openDoorways.duplicate()

	for i in range(doorCandidates.size()):
		var doorA = doorCandidates[i]
		if doorA.connected: continue

		for j in range(i + 1, doorCandidates.size()):
			var doorB = doorCandidates[j]
			if doorB.connected: continue

			var startCell = doorA.getForwardCell()
			var endCell = doorB.getForwardCell()
			var dist = abs(startCell.x - endCell.x) + abs(startCell.y - endCell.y)

			if dist <= maxStitchDistance:
				var path = findTilePath(startCell, endCell)
				if not path.is_empty():
					buildStitchingCorridor(path, doorA, doorB)
					break

func findTilePath(start: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var astar = AStar2D.new()
	var pointMap: Dictionary = {}
	var idCounter = 0

	var minX = min(start.x, target.x) - 2
	var maxX = max(start.x, target.x) + 2
	var minY = min(start.y, target.y) - 2
	var maxY = max(start.y, target.y) + 2

	for x in range(minX, maxX + 1):
		for y in range(minY, maxY + 1):
			var cell = Vector2i(x, y)
			if cell == start or cell == target or not grid.isOccupied(cell):
				if grid.inBounds(cell):
					pointMap[cell] = idCounter
					astar.add_point(idCounter, Vector2(cell.x, cell.y))
					idCounter += 1

	for cell in pointMap.keys():
		var currentId = pointMap[cell]
		for d in CARDINAL_DIRS:
			var neighbor = cell + d
			if pointMap.has(neighbor):
				astar.connect_points(currentId, pointMap[neighbor])

	if not pointMap.has(start) or not pointMap.has(target):
		return []

	var rawPath = astar.get_point_path(pointMap[start], pointMap[target])
	var result: Array[Vector2i] = []
	for p in rawPath:
		result.append(Vector2i(roundi(p.x), roundi(p.y)))
	return result
 
func buildStitchingCorridor(path: Array[Vector2i], doorA: Doorway, doorB: Doorway) -> void:
	var placedStitchTiles: Dictionary = {}
	for cell in path:
		if not grid.isOccupied(cell):
			var tileInstance = stitchTileScene.instantiate() as StitchTile
			root.add_child(tileInstance)
			tileInstance.global_position = grid.gridToWorld(cell)
 
			grid.occupyTileBlock(cell, Vector2i(1, 1), tileInstance, "corridor_tile")
			placedStitchTiles[cell] = tileInstance
 
	for cell in placedStitchTiles.keys():
		var tile: StitchTile = placedStitchTiles[cell]
		var neighborMask: Dictionary = {}
 
		for dir in CARDINAL_DIRS:
			var neighborCell = cell + dir
			neighborMask[dir] = grid.isSolidFloor(neighborCell)

		tile.updateWalls(neighborMask)
 
	doorA.connected = true
	doorB.connected = true
	openDoorways.erase(doorA)
	openDoorways.erase(doorB)

func sealUnconnectedDoors() -> void:
	if stitchTileScene == null: 
		return

	var remainingDoors: Array[Doorway] = openDoorways.duplicate()

	for door in remainingDoors:
		if door.connected: 
			continue

		var forwardCell = door.getForwardCell()
		if grid.inBounds(forwardCell) and not grid.isOccupied(forwardCell):
			var capTile = stitchTileScene.instantiate() as StitchTile
			root.add_child(capTile)
			capTile.global_position = grid.gridToWorld(forwardCell)

			grid.occupyTileBlock(forwardCell, Vector2i(1, 1), capTile, "door_cap_tile")
			var neighborMask: Dictionary = {}
			for dir in CARDINAL_DIRS:
				var neighborCell = forwardCell + dir
				neighborMask[dir] = grid.isSolidFloor(neighborCell)

			capTile.updateWalls(neighborMask)
			door.connected = true
			openDoorways.erase(door)
