extends Node2D

const ARROW_LENGTH := 14
const SCALE_CIRCLE_LENGTH := 8
const SCALE_CIRCLE_RADIUS := 1

var points_per_object := {}
var selected_color := Color.white
var hovered_color := Color.gray

var gizmos_origin: Vector2
var proj_right_local: Vector2
var proj_up_local: Vector2
var proj_back_local: Vector2
# Same vectors as `proj_x_local`, but with a smaller length, for the rotation & scale gizmos
var proj_right_local_scale: Vector2
var proj_up_local_scale: Vector2
var proj_back_local_scale: Vector2
var gizmo_position_x := PoolVector2Array()
var gizmo_position_y := PoolVector2Array()
var gizmo_position_z := PoolVector2Array()
var gizmo_rotation_x := PoolVector2Array()
var gizmo_rotation_y := PoolVector2Array()
var gizmo_rotation_z := PoolVector2Array()


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if gizmo_rotation_x.empty():
		return
	var pos: Vector2 = Global.canvas.current_pixel - gizmos_origin
	if event.button_index == BUTTON_LEFT:
		if event.pressed:
			var draw_scale := Global.camera.zoom * 10
			pos /= draw_scale
			var gizmo_rotation_x_poly: PoolVector2Array = Geometry.offset_polyline_2d(gizmo_rotation_x, 1)[0]
			var gizmo_rotation_y_poly: PoolVector2Array = Geometry.offset_polyline_2d(gizmo_rotation_y, 1)[0]
			var gizmo_rotation_z_poly: PoolVector2Array = Geometry.offset_polyline_2d(gizmo_rotation_z, 1)[0]
			if Geometry.point_is_inside_triangle(pos, gizmo_position_x[0], gizmo_position_x[1], gizmo_position_x[2]):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.X_TRANS
			elif Geometry.point_is_inside_triangle(pos, gizmo_position_y[0], gizmo_position_y[1], gizmo_position_y[2]):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.Y_TRANS
			elif Geometry.point_is_inside_triangle(pos, gizmo_position_z[0], gizmo_position_z[1], gizmo_position_z[2]):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.Z_TRANS
			elif Geometry.is_point_in_circle(pos, proj_right_local_scale, SCALE_CIRCLE_RADIUS):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.X_SCALE
			elif Geometry.is_point_in_circle(pos, proj_up_local_scale, SCALE_CIRCLE_RADIUS):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.Y_SCALE
			elif Geometry.is_point_in_circle(pos, proj_back_local_scale, SCALE_CIRCLE_RADIUS):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.Z_SCALE
			elif Geometry.is_point_in_polygon(pos, gizmo_rotation_x_poly):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.X_ROT
			elif Geometry.is_point_in_polygon(pos, gizmo_rotation_y_poly):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.Y_ROT
			elif Geometry.is_point_in_polygon(pos, gizmo_rotation_z_poly):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.Z_ROT
		else:
			for object in points_per_object:
				if object.selected:
					object.applying_gizmos = Object3D.Gizmos.NONE


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
		gizmos_origin = camera.unproject_position(object3d.translation)

		var right: Vector3 = object3d.translation + object3d.transform.basis.x
		var up: Vector3 = object3d.translation + object3d.transform.basis.y
		var back: Vector3 = object3d.translation + object3d.transform.basis.z

		var proj_right: Vector2 = object3d.camera.unproject_position(right)
		var proj_up: Vector2 = object3d.camera.unproject_position(up)
		var proj_back: Vector2 = object3d.camera.unproject_position(back)

		proj_right_local = proj_right - gizmos_origin
		proj_up_local = proj_up - gizmos_origin
		proj_back_local = proj_back - gizmos_origin

		proj_right_local = _resize_vector(proj_right_local, ARROW_LENGTH)
		proj_up_local = _resize_vector(proj_up_local, ARROW_LENGTH)
		proj_back_local = _resize_vector(proj_back_local, ARROW_LENGTH)

		proj_right_local_scale = _resize_vector(proj_right_local, SCALE_CIRCLE_LENGTH)
		proj_up_local_scale = _resize_vector(proj_up_local, SCALE_CIRCLE_LENGTH)
		proj_back_local_scale = _resize_vector(proj_back_local, SCALE_CIRCLE_LENGTH)

		# Calculate position gizmos (arrows)
		gizmo_position_x = _find_arrow(proj_right_local)
		gizmo_position_y = _find_arrow(proj_up_local)
		gizmo_position_z = _find_arrow(proj_back_local)
		# Calculate rotation gizmos
		gizmo_rotation_x = _find_curve(proj_up_local, proj_back_local)
		gizmo_rotation_y = _find_curve(proj_right_local, proj_back_local)
		gizmo_rotation_z = _find_curve(proj_right_local, proj_up_local)

	update()


func clear_points(object3d: Object3D) -> void:
	points_per_object.erase(object3d)
#	if not object3d.selected:
#		gizmos.visible = false
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
			var width := 1.1
#			var draw_scale := Vector2.ONE
			var draw_scale := Global.camera.zoom * 10
			draw_set_transform(gizmos_origin, 0, draw_scale)
			draw_line(Vector2.ZERO, proj_right_local, Color.red)
			draw_line(Vector2.ZERO, proj_up_local, Color.green)
			draw_line(Vector2.ZERO, proj_back_local, Color.blue)
			_draw_arrow(gizmo_position_x, Color.red)
			_draw_arrow(gizmo_position_y, Color.green)
			_draw_arrow(gizmo_position_z, Color.blue)
			draw_polyline(gizmo_rotation_x, Color.red, width)
			draw_polyline(gizmo_rotation_y, Color.green, width)
			draw_polyline(gizmo_rotation_z, Color.blue, width)
			draw_circle(proj_right_local_scale, SCALE_CIRCLE_RADIUS, Color.red)
			draw_circle(proj_up_local_scale, SCALE_CIRCLE_RADIUS, Color.green)
			draw_circle(proj_back_local_scale, SCALE_CIRCLE_RADIUS, Color.blue)
#			draw_set_transform(gizmos_origin, 0, Vector2.ONE)
#			for i in gizmo_rotation_x.size():
#				gizmo_rotation_x[i] *= draw_scale
#			draw_polygon(Geometry.offset_polyline_2d(gizmo_rotation_x, 1)[0], [Color.red])
#			draw_polygon(gizmo_rotation_x, [Color.red])
#			draw_polygon(gizmo_rotation_y, [Color.green])
#			draw_polygon(gizmo_rotation_z, [Color.blue])
			var font: Font = Global.control.theme.default_font
			var font_height := font.get_height()
			var char_scale := 0.16
			draw_set_transform(gizmos_origin + Vector2(-font_height, font_height) * char_scale / 4 * draw_scale, 0, draw_scale * char_scale)
			draw_char(font, proj_right_local_scale / char_scale, 'X', '')
			draw_char(font, proj_up_local_scale / char_scale, "Y", '')
			draw_char(font, proj_back_local_scale / char_scale, "Z", '')
			draw_set_transform_matrix(Transform2D())
		elif object.hovered:
			draw_multiline(points, hovered_color, 1.0, true)


func _resize_vector(v: Vector2, l: float) -> Vector2:
	return (v.normalized() * l).limit_length(v.length())


func _find_curve(a: Vector2, b: Vector2) -> PoolVector2Array:
	var curve2d := Curve2D.new()
	curve2d.bake_interval = 0.5
	var control := (b.linear_interpolate(a, 0.5))
	a = _resize_vector(a, SCALE_CIRCLE_LENGTH)
	b = _resize_vector(b, SCALE_CIRCLE_LENGTH)
	control = control.normalized() * sqrt(pow(a.length() / 4, 2) * 2)  # Thank you Pythagoras
	curve2d.add_point(a, Vector2.ZERO, control)
	curve2d.add_point(b, control)
	return curve2d.get_baked_points()


func _find_arrow(a: Vector2, tilt := 0.5) -> PoolVector2Array:
	var b := (a + Vector2(-tilt, 1).rotated(a.angle() + PI / 2) * 2)
	var c := (a + Vector2(tilt, 1).rotated(a.angle() + PI / 2) * 2)
	return PoolVector2Array([a, b, c])


func _draw_arrow(triangle: PoolVector2Array, color: Color) -> void:
	draw_primitive(triangle, [color, color, color], [])


func _scale_gizmo(gizmo: Control, new_scale: Vector2) -> void:
	gizmo.rect_scale.x = max(0.1, new_scale.x) if new_scale.x >= 0 else min(-0.1, new_scale.x)
	gizmo.rect_scale.y = max(0.1, new_scale.y) if new_scale.y >= 0 else min(-0.1, new_scale.y)
