extends Node3D
class_name Room

@export var tags: Array[String] = ["room"]
@export var cellSize: float = 2.0
@export var floorsPath: NodePath

var gridRotation: int = 0
var cachedCells: Array[Vector2i] = []
var cellsCalculated: bool = false

func getCells() -> Array[Vector2i]:
	if cellsCalculated:
		return cachedCells
	
	var floorsNode = get_node_or_null(floorsPath)
	if not floorsNode:
		return []
		
	var meshes = getAllMeshInstances(floorsNode)
	for mi in meshes:
		if not mi.mesh: 
			continue

		var aabb = mi.mesh.get_aabb()
		
		var relativeTransform = getRelativeTransform(self, mi)
		var center = relativeTransform * aabb.get_center()
		var size = relativeTransform.basis.get_scale() * aabb.size

		# Calculate how many grid cells this specific mesh covers
		var cellsX = max(1, roundi(size.x / cellSize))
		var cellsZ = max(1, roundi(size.z / cellSize))

		# Find the starting position (bottom-left-ish local corner)
		var startPos = center - Vector3(size.x / 2.0, 0, size.z / 2.0) + Vector3(cellSize / 2.0, 0, cellSize / 2.0)

		for x in range(cellsX):
			for z in range(cellsZ):
				var pos = startPos + Vector3(x * cellSize, 0, z * cellSize)
				var cx = roundi(pos.x / cellSize)
				var cz = roundi(pos.z / cellSize)
				var cell = Vector2i(cx, cz)
				
				if not cachedCells.has(cell):
					cachedCells.append(cell)

	cellsCalculated = true
	return cachedCells

func getDoorways() -> Array[Doorway]:
	var result: Array[Doorway] = []
	var doorsNode = get_node_or_null("Doorways")
	
	if doorsNode:
		for d in doorsNode.get_children():
			if d is Doorway:
				var relativeTransform = getRelativeTransform(self, d)
				d.cell = Vector2i(roundi(relativeTransform.origin.x / cellSize), roundi(relativeTransform.origin.z / cellSize))
				result.append(d)
	return result

func getDoorCells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for d in getDoorways():
		result.append(d.cell)
	return result

func getAllMeshInstances(node: Node) -> Array[MeshInstance3D]:
	var arr: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		arr.append(node)
	for child in node.get_children():
		arr.append_array(getAllMeshInstances(child))
	return arr

func getRelativeTransform(root: Node3D, target: Node3D) -> Transform3D:
	var trans = Transform3D()
	var current = target
	while current and current != root:
		trans = current.transform * trans
		current = current.get_parent() as Node3D
	return trans

static func rotateCell(c: Vector2i, rot: int) -> Vector2i:
	match rot % 4:
		1: return Vector2i(c.y, -c.x)
		2: return Vector2i(-c.x, -c.y)
		3: return Vector2i(-c.y, c.x)
	return c

func getRotatedCells(rot: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in getCells():
		result.append(rotateCell(c, rot))
	return result

func getRotatedDoorCells(rot: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in getDoorCells():
		result.append(rotateCell(c, rot))
	return result
