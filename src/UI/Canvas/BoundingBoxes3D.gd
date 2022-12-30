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
#			var pixel_diff: float = (object.camera.unproject_position(Vector3.RIGHT) - object.camera.unproject_position(Vector3.ZERO)).length()

			var right :Vector3= object.translation + object.transform.basis.x
			var up :Vector3= object.translation + object.transform.basis.y
			var back :Vector3= object.translation + object.transform.basis.z

			var proj_right :Vector2= object.camera.unproject_position(right)
			var proj_up :Vector2= object.camera.unproject_position(up)
			var proj_back :Vector2= object.camera.unproject_position(back)

			var proj_right_diff := proj_right - gizmos.rect_position
			var proj_up_diff := proj_up - gizmos.rect_position
			var proj_back_diff := proj_back - gizmos.rect_position

#			$Gizmos/XArrow.rect_scale.x = (proj_right_diff).length() / pixel_diff
#			$Gizmos/XArrow.rect_scale.y = (proj_right_diff).length() / pixel_diff
#			$Gizmos/XArrow.rect_rotation = rad2deg((proj_right_diff).angle()) + 90
#
#			$Gizmos/YArrow.rect_scale.x = (proj_up_diff).length() / pixel_diff
#			$Gizmos/YArrow.rect_scale.y = (proj_up_diff).length() / pixel_diff
#			$Gizmos/YArrow.rect_rotation = rad2deg((proj_up_diff).angle()) + 90
#
#			$Gizmos/ZArrow.rect_scale.x = (proj_back_diff).length() / pixel_diff
#			$Gizmos/ZArrow.rect_scale.y = (proj_back_diff).length() / pixel_diff
#			$Gizmos/ZArrow.rect_rotation = rad2deg(proj_back_diff.angle()) + 90
#			var z_transform := Transform2D(object.transform)
#			z_transform.origin = $Gizmos.rect_position

			var width := 1.1
			draw_line(gizmos.rect_position, proj_right, Color.red)
			draw_line(gizmos.rect_position, proj_up, Color.green)
			draw_line(gizmos.rect_position, proj_back, Color.blue)
#			var p := PoolVector2Array()
#			p.append(proj_right - Vector2.ONE * width)
#			p.append(proj_right)
#			p.append(proj_right + Vector2.ONE * width)
#			p.append(proj_up + Vector2.ONE * width)
#			p.append(proj_up)
#			p.append(proj_up - Vector2.ONE * width)
#			p.append(proj_right - Vector2.ONE * width)

#			draw_line(proj_right, proj_up, Color.blue, width)
#			draw_line(proj_right, proj_back, Color.green, width)
#			draw_line(proj_back, proj_up, Color.red, width)
#			draw_polyline(p, Color.orange)

			var curve2d := Curve2D.new()
			curve2d.bake_interval = 3.5
			var start := proj_right_diff
			var end := proj_up_diff
#			var control := (end.linear_interpolate(start, 0.5) - gizmos.rect_position).limit_length(8)
			var control := (end.linear_interpolate(start, 0.5))
			print(control.length())
			start = start.normalized() * control.length()
			end = end.normalized() * control.length()
			control = control.normalized() * sqrt(pow(start.length()/4, 2) * 2)
			print(start.length(), " ", end.length())
			curve2d.add_point(start, Vector2.ZERO, control)
			curve2d.add_point(end, control)
			var baked := curve2d.get_baked_points()
			draw_set_transform($Gizmos.rect_position, 0, Vector2.ONE)
			draw_polyline(baked, Color.blue, 1.1)
			draw_line(Vector2.ZERO, start, Color.orange)
			draw_line(Vector2.ZERO, control, Color.yellow, 1.0)
			draw_set_transform_matrix(Transform2D())
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


func _scale_gizmo(gizmo: Control, new_scale: Vector2) -> void:
	gizmo.rect_scale.x = max(0.1, new_scale.x) if new_scale.x >= 0 else min(-0.1, new_scale.x)
	gizmo.rect_scale.y = max(0.1, new_scale.y) if new_scale.y >= 0 else min(-0.1, new_scale.y)
