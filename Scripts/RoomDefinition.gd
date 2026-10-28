# RoomDefinition.gd
extends Resource
class_name RoomDefinition

@export var scene: PackedScene
@export var tags: Array[String] = ["room"] # Tags this room satisfies (e.g., ["room", "medium"])
@export var minCount: int = 0
@export var maxCount: int = 999
@export_range(1, 100) var weight: int = 10

var currentCount: int = 0

func canPlace() -> bool:
	return currentCount < maxCount

func matchesRequiredTags(required: Array[String]) -> bool:
	if required.is_empty():
		return true
	for t in required:
		if t in tags:
			return true
	return false
