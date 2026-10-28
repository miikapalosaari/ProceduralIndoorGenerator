# StitchTile.gd
extends Node3D
class_name StitchTile

# References to the StaticBody3D nodes
@export var wallNorth: StaticBody3D
@export var wallEast:  StaticBody3D
@export var wallSouth: StaticBody3D
@export var wallWest:  StaticBody3D

func updateWalls(neighborMask: Dictionary) -> void:
	# Check if a neighbor exists in each direction
	var hasNorth = neighborMask.get(Vector2i(0, -1), false)
	var hasEast  = neighborMask.get(Vector2i(1, 0),  false)
	var hasSouth = neighborMask.get(Vector2i(0, 1),  false)
	var hasWest  = neighborMask.get(Vector2i(-1, 0), false)

	# Set wall state (Active when NO neighbor exists)
	setWallActive(wallNorth, not hasNorth)
	setWallActive(wallEast,  not hasEast)
	setWallActive(wallSouth, not hasSouth)
	setWallActive(wallWest,  not hasWest)

func setWallActive(wall: StaticBody3D, active: bool) -> void:
	wall.visible = active
	wall.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED
