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
			var pixel_diff: float = (object.camera.unproject_position(Vector3.RIGHT) - object.camera.unproject_position(Vector3.ZERO)).length()
#			var right :Vector3= object.translation+Vector3.RIGHT.rotated(Vector3.BACK, object.rotation.z).rotated(Vector3.UP, object.rotation.y)
#			var up :Vector3= object.translation+Vector3.UP.rotated(Vector3.BACK, object.rotation.z).rotated(Vector3.RIGHT, object.rotation.x)
#			var back :Vector3= object.translation+Vector3.BACK.rotated(Vector3.UP, object.rotation.y).rotated(Vector3.RIGHT, object.rotation.x)
			var right :Vector3= object.translation + object.transform.basis.x
			var up :Vector3= object.translation + object.transform.basis.y
			var back :Vector3= object.translation + object.transform.basis.z

			var proj_right :Vector2= object.camera.unproject_position(right)
			var proj_up :Vector2= object.camera.unproject_position(up)
			var proj_back :Vector2= object.camera.unproject_position(back)

			var proj_right_diff := proj_right - gizmos.rect_position
			var proj_up_diff := proj_up - gizmos.rect_position
			var proj_back_diff := proj_back - gizmos.rect_position
#			print((object.camera.unproject_position(right)- gizmos.rect_position).angle())

			$Gizmos/XArrow.rect_scale.x = (proj_right_diff).length() / pixel_diff
#			print(object.transform.basis.x)
#			print((proj_right_diff).length())
#			print((proj_right.x - gizmos.rect_position.x))
#			print((proj_right.y - gizmos.rect_position.y))
			$Gizmos/XArrow.rect_scale.y = (proj_right_diff).length() / pixel_diff
			$Gizmos/XArrow.rect_rotation = rad2deg((proj_right_diff).angle()) + 90

			$Gizmos/YArrow.rect_scale.x = (proj_up_diff).length() / pixel_diff
			$Gizmos/YArrow.rect_scale.y = (proj_up_diff).length() / pixel_diff
			$Gizmos/YArrow.rect_rotation = rad2deg((proj_up_diff).angle()) + 90

			$Gizmos/ZArrow.rect_scale.x = (proj_back_diff).length() / pixel_diff
			$Gizmos/ZArrow.rect_scale.y = (proj_back_diff).length() / pixel_diff
			$Gizmos/ZArrow.rect_rotation = rad2deg(proj_back_diff.angle()) + 90

#			_scale_gizmo($Gizmos/XRot, Vector2($Gizmos/ZArrow.rect_scale.x, $Gizmos/YArrow.rect_scale.y))
#			_scale_gizmo($Gizmos/YRot, Vector2($Gizmos/XArrow.rect_scale.x, $Gizmos/ZArrow.rect_scale.y))
#			_scale_gizmo($Gizmos/ZRot, Vector2($Gizmos/XArrow.rect_scale.x, $Gizmos/YArrow.rect_scale.y))

#			$Gizmos/XRot.rect_rotation = rad2deg(-object.rotation.x)
#			$Gizmos/YRot.rect_rotation = rad2deg(-object.rotation.y) + 180
#			$Gizmos/ZRot.rect_rotation = rad2deg(-object.rotation.z) + 90
#			$Gizmos/ZRot.rect_rotation = $Gizmos/XArrow.rect_rotation

#			_scale_gizmo($Gizmos/XRot, Vector2.ONE - $Gizmos/XArrow.rect_scale)
#			_scale_gizmo($Gizmos/YRot, Vector2.ONE - $Gizmos/YArrow.rect_scale)
#			_scale_gizmo($Gizmos/ZRot, Vector2.ONE - $Gizmos/ZArrow.rect_scale)

#			_scale_gizmo($Gizmos/XRot, Vector2(object.transform.basis.x.dot(object.camera.transform.basis.x), object.transform.basis.x.dot(object.camera.transform.basis.x)))
#			_scale_gizmo($Gizmos/YRot, Vector2(object.transform.basis.y.dot(object.camera.transform.basis.y), object.transform.basis.y.dot(object.camera.transform.basis.y)))
#			_scale_gizmo($Gizmos/ZRot, Vector2(object.transform.basis.z.dot(object.camera.transform.basis.z), object.transform.basis.z.dot(object.camera.transform.basis.z)))

#			_scale_gizmo($Gizmos/XRot, Vector2(cos(object.rotation.x), sin(object.rotation.x)))
#			_scale_gizmo($Gizmos/YRot, Vector2(cos(object.rotation.y), sin(object.rotation.y)))
#			_scale_gizmo($Gizmos/ZRot, Vector2(cos(object.rotation.z), sin(object.rotation.z)))

#			_scale_gizmo($Gizmos/XRot, Vector2(proj_back_diff.length() * proj_back_diff.sign().x, proj_up_diff.length() * proj_up_diff.sign().y) / 15)
#			_scale_gizmo($Gizmos/YRot, Vector2(proj_back_diff.length() * proj_back_diff.sign().x, proj_right_diff.length() * proj_right_diff.sign().y) / 15)
#			_scale_gizmo($Gizmos/ZRot, Vector2(proj_right_diff.length() * proj_right_diff.sign().x, proj_up_diff.length() * proj_up_diff.sign().y) / 15)

			var z_transform := Transform2D(object.transform)
			z_transform.origin = $Gizmos.rect_position
#			z_transform = z_transform.rotated(-TAU)
#			z_transform = z_transform.inverse()
#			print(z_transform)
#			$Gizmos/ZRot.rect_rotation = -rad2deg(z_transform.get_rotation()) + 90
#			$Gizmos/ZRot.rect_scale = z_transform.get_scale()
#			draw_set_transform($Gizmos.rect_position, -z_transform.get_rotation(), z_transform.get_scale())
#			var xx = ($Gizmos/XArrow.rect_position + (Vector2($Gizmos/XArrow.rect_size.x/2, 0) * $Gizmos/XArrow.rect_scale)).rotated(deg2rad($Gizmos/XArrow.rect_rotation))
#			var yy = ($Gizmos/YArrow.rect_position + (Vector2($Gizmos/YArrow.rect_size.x/2, 0) * $Gizmos/YArrow.rect_scale)).rotated(deg2rad($Gizmos/YArrow.rect_rotation))
#			draw_set_transform($Gizmos.rect_position, 0, $Gizmos.rect_scale)
#			draw_line(xx, yy, Color.blue)
#			draw_set_transform_matrix(z_transform)
#			draw_circle(Vector2.ZERO, 4, Color.blue)
#			draw_arc(Vector2.ZERO, 8, 3*PI/2, TAU, 8, Color.blue)
#			draw_set_transform_matrix(Transform2D())

#			var y_transform := Transform2D(Vector2(object.transform.basis.x.x, object.transform.basis.x.z), Vector2(object.transform.basis.z.x, object.transform.basis.z.z), Vector2.ZERO)
#			var y_transform := Transform2D(object.transform)
#			y_transform.y = y_transform.y * Vector2.RIGHT
#			print(y_transform)
#			$Gizmos/YRot.rect_rotation = -rad2deg(y_transform.get_rotation())
#			$Gizmos/YRot.rect_scale = y_transform.get_scale()

#			var x_transform := Transform2D(Vector2(object.transform.basis.y.y, object.transform.basis.y.z), Vector2(object.transform.basis.z.y, object.transform.basis.z.z), Vector2.ZERO)
#			var x_transform := Transform2D(object.transform)
#			x_transform.x = x_transform.x * Vector2.DOWN
#			print(x_transform)
#			$Gizmos/XRot.rect_rotation = -rad2deg(x_transform.get_rotation())
#			$Gizmos/XRot.rect_scale = x_transform.get_scale()

#			var scl := 1 if abs(object.rotation.y) <= PI / 2 else -1
#			$Gizmos/ZRot.rect_scale.x = (proj_up_diff).length() / 15
#			$Gizmos/ZRot.rect_scale.y = (proj_right_diff).length()*scl / 15
#			$Gizmos/ZRot.rect_scale = Vector2(sin(proj_up.x), cos(proj_right.y))
#			$Gizmos/ZRot.rect_scale.y = (proj_right_diff).length() / 15

#			print((proj_up_diff).length() * proj_up_diff.sign().x / 15)
#			print((proj_right_diff).length() * proj_right_diff.sign().x / 15)
#			print(rad2deg((-object.rotation.z)) + 90)

			var width := 1.1
			draw_line(gizmos.rect_position, proj_right, Color.red)
			draw_line(gizmos.rect_position, proj_up, Color.green)
			draw_line(gizmos.rect_position, proj_back, Color.blue)

#			var curve2d := Curve2D.new()
#			curve2d.bake_interval = 1
#			var start := proj_right
#			var end := proj_up
#			var control := Vector2(start.x, end.y)
#			curve2d.add_point(start, -(end-start), end - start)
#			curve2d.add_point(end, end * Vector2.UP, end * Vector2.DOWN)
#			curve2d.add_point(start, Vector2.ZERO, control)
#			curve2d.add_point(end, control, Vector2.ZERO)
#			curve2d.add_point(start)
#			curve2d.add_point(control)
#			curve2d.add_point(end)
#			var baked := curve2d.get_baked_points()
#			print($"../Path2D".curve.get_point_position(0), " ", $"../Path2D".curve.get_point_in(0), " ", $"../Path2D".curve.get_point_out(0))
#			print($"../Path2D".curve.get_point_position(1), " ", $"../Path2D".curve.get_point_in(1), " ", $"../Path2D".curve.get_point_out(1))
#			print(baked.size())
#			draw_set_transform($Gizmos.rect_position, 0, Vector2.ONE)
#			draw_polyline(baked, Color.blue, 2.0)
#			draw_set_transform_matrix(Transform2D())
#			print(proj_right_diff, " ", proj_up_diff)
#			draw_set_transform($Gizmos.rect_position, 0, Vector2(proj_right_diff.length(), proj_up_diff.length()) / pixel_diff)
#			draw_arc(Vector2.ZERO, pixel_diff, proj_right_diff.angle(), proj_up_diff.angle(), 8, Color.blue, 2.0)
#			draw_set_transform_matrix(Transform2D())
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


func _scale_gizmo(gizmo: Control, new_scale: Vector2) -> void:
	gizmo.rect_scale.x = max(0.1, new_scale.x) if new_scale.x >= 0 else min(-0.1, new_scale.x)
	gizmo.rect_scale.y = max(0.1, new_scale.y) if new_scale.y >= 0 else min(-0.1, new_scale.y)
