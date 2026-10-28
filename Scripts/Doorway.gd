extends Marker3D
class_name Doorway

enum Direction { NORTH, EAST, SOUTH, WEST }
var connected: bool = false
var cell: Vector2i
var worldCell: Vector2i
var worldDir: int
var attachedRoomTags: Array[String] = []

@export var direction: Direction
@export var requiredTags: Array[String] = ["corridor"]

static func getDirVector(dir: int) -> Vector2i:
	match dir % 4:
		0: return Vector2i(0, -1)
		1: return Vector2i(1, 0)
		2: return Vector2i(0, 1)
		3: return Vector2i(-1, 0)
	return Vector2i.ZERO
	
func getForwardCell() -> Vector2i:
	return worldCell + getDirVector(worldDir)
