extends Node2D

var points := PoolVector2Array()
var color: Color


func get_points(camera: Camera, object3d: Object3D, _color: Color) -> void:
	color = _color
	var debug_mesh := object3d.box_shape.get_debug_mesh()
	var arrays := debug_mesh.surface_get_arrays(0)
	points = PoolVector2Array()
	for vertex in arrays[ArrayMesh.ARRAY_VERTEX]:
		var x_vertex: Vector3 = object3d.transform.xform(vertex)
		var point := camera.unproject_position(x_vertex)
		points.append(point)
	update()


func clear_points() -> void:
	points = PoolVector2Array()
	update()


func _draw() -> void:
	if points.empty():
		return
	draw_multiline(points, color, 1.0, true)
