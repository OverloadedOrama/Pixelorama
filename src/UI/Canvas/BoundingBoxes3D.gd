extends Node2D

var points := PoolVector2Array()
var color: Color


func get_points(camera: Camera, object3d: Object3D, _color: Color) -> void:
#	var camera := get_viewport().get_camera()
	color = _color
	var debug_mesh := object3d.box_shape.get_debug_mesh()
	var arrays := debug_mesh.surface_get_arrays(0)
	points = PoolVector2Array()
	for vertex in arrays[ArrayMesh.ARRAY_VERTEX]:
		var x_vertex: Vector3 = object3d.transform.xform(vertex)
#		print(x_vertex)
		points.append(camera.unproject_position(x_vertex))
	update()


func clear_points() -> void:
	points = PoolVector2Array()
	update()


func _draw() -> void:
	draw_polyline(points, color)
