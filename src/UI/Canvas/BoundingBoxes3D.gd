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
			var right :Vector3= object.translation+Vector3.RIGHT.rotated(Vector3.BACK, object.rotation.z).rotated(Vector3.UP, object.rotation.y)
			var up :Vector3= object.translation+Vector3.UP.rotated(Vector3.BACK, object.rotation.z).rotated(Vector3.RIGHT, object.rotation.x)
			var back :Vector3= object.translation+Vector3.BACK.rotated(Vector3.UP, object.rotation.y).rotated(Vector3.RIGHT, object.rotation.x)
			var proj_right :Vector2= object.camera.unproject_position(right)
			var proj_up :Vector2= object.camera.unproject_position(up)
			var proj_back :Vector2= object.camera.unproject_position(back)
			var proj_right_diff := proj_right - gizmos.rect_position
			var proj_up_diff := proj_up - gizmos.rect_position
			var proj_back_diff := proj_back - gizmos.rect_position
#			print((object.camera.unproject_position(right)- gizmos.rect_position).angle())

			$Gizmos/XArrow.rect_scale.x = (proj_right_diff).length() / 15
			$Gizmos/XArrow.rect_scale.y = (proj_right_diff).length() / 15
			$Gizmos/XArrow.rect_rotation = rad2deg((proj_right_diff).angle()) + 90

			$Gizmos/YArrow.rect_scale.x = (proj_up_diff).length() / 15
			$Gizmos/YArrow.rect_scale.y = (proj_up_diff).length() / 15
			$Gizmos/YArrow.rect_rotation = rad2deg((proj_up_diff).angle()) + 90

			$Gizmos/ZArrow.rect_scale.x = (proj_back_diff).length() / 15
			$Gizmos/ZArrow.rect_scale.y = (proj_back_diff).length() / 15
			$Gizmos/ZArrow.rect_rotation = rad2deg((proj_back_diff).angle()) + 90
#			$Gizmos/YArrow.rect_scale = object.camera.unproject_position(up) - gizmos.rect_position
#			$Gizmos/ZArrow.rect_scale = object.camera.unproject_position(back) - gizmos.rect_position

			draw_line(gizmos.rect_position, proj_right, Color.red)
			draw_line(gizmos.rect_position, proj_up, Color.green)
			draw_line(gizmos.rect_position, proj_back, Color.blue)
#			draw_line(gizmos.rect_position, object.camera.unproject_position(Vector3.FORWARD), Color.green)
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
