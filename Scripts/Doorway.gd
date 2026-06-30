extends Marker3D
class_name Doorway

enum Direction {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@export var cell: Vector2i
@export var direction: Direction
var connected: bool = false
