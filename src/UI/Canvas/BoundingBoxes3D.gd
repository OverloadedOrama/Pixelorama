extends Node2D

var points_per_object := {}
var selected_color := Color.white
var hovered_color := Color.gray

onready var gizmos: Control = $Gizmos


func _ready() -> void:
	for gizmo in gizmos.get_children():
		gizmo.connect("button_up", self, "_on_gizmo_button_up")
		gizmo.connect("button_down", self, "_on_gizmo_button_down", [gizmo.get_index() + 1])


func get_points(camera: Camera, object3d: Object3D) -> void:
	var debug_mesh := object3d.box_shape.get_debug_mesh()
	var arrays := debug_mesh.surface_get_arrays(0)
	var points := PoolVector2Array()
	for vertex in arrays[ArrayMesh.ARRAY_VERTEX]:
		var x_vertex: Vector3 = object3d.transform.xform(vertex)
		var point := camera.unproject_position(x_vertex)
		points.append(point)
	points_per_object[object3d] = points
	if object3d.selected:
		gizmos.visible = true
		gizmos.rect_position = camera.unproject_position(object3d.translation)
	update()


func clear_points(object3d: Object3D) -> void:
	points_per_object.erase(object3d)
	if not object3d.selected:
		gizmos.visible = false
	update()


func _draw() -> void:
	if points_per_object.empty():
		return
	for object in points_per_object:
		var points: PoolVector2Array = points_per_object[object]
		if points.empty():
			continue
		if object.selected:
			draw_multiline(points, selected_color, 1.0, true)
		elif object.hovered:
			draw_multiline(points, hovered_color, 1.0, true)


func _on_gizmo_button_down(index: int) -> void:
	for object in points_per_object:
		if object.selected:
			object.applying_gizmos = index


func _on_gizmo_button_up() -> void:
	for object in points_per_object:
		if object.selected:
			object.applying_gizmos = Object3D.Gizmos.NONE
