extends Node2D

var points_per_object := {}
var selected_color := Color.white
var hovered_color := Color.gray

#var gizmo_used := false
var proj_right_local: Vector2
var proj_up_local: Vector2
var proj_back_local: Vector2
var gizmo_rotation_x := PoolVector2Array()
var gizmo_rotation_y := PoolVector2Array()
var gizmo_rotation_z := PoolVector2Array()

onready var gizmos: Control = $Gizmos


func _ready() -> void:
	for gizmo in gizmos.get_children():
		gizmo.connect("button_up", self, "_on_gizmo_button_up")
		gizmo.connect("button_down", self, "_on_gizmo_button_down", [gizmo.get_index() + 1])


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var pos: Vector2 = Global.canvas.current_pixel - gizmos.rect_position
#	print(pos, " ", gizmo_rotation_z)
	if event.button_index == BUTTON_LEFT:
		if event.pressed:
			if Geometry.is_point_in_polygon(pos, gizmo_rotation_x):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.X_ROT
			elif Geometry.is_point_in_polygon(pos, gizmo_rotation_y):
				for object in points_per_object:
					if object.selected:
						object.applying_gizmos = Object3D.Gizmos.Y_ROT
			elif Geometry.is_point_in_polygon(pos, gizmo_rotation_z):
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
		gizmos.visible = true
		gizmos.rect_position = camera.unproject_position(object3d.translation)

		var right :Vector3= object3d.translation + object3d.transform.basis.x
		var up :Vector3= object3d.translation + object3d.transform.basis.y
		var back :Vector3= object3d.translation + object3d.transform.basis.z

		var proj_right :Vector2= object3d.camera.unproject_position(right)
		var proj_up :Vector2= object3d.camera.unproject_position(up)
		var proj_back :Vector2= object3d.camera.unproject_position(back)

		proj_right_local = proj_right - gizmos.rect_position
		proj_up_local = proj_up - gizmos.rect_position
		proj_back_local = proj_back - gizmos.rect_position

		# Calculate rotation gizmos
#		gizmo_rotation_z = Geometry.offset_polygon_2d(_find_curve(proj_right_local, proj_up_local), 0)[0]
		gizmo_rotation_z = _find_curve(proj_right_local, proj_up_local)
		gizmo_rotation_y = _find_curve(proj_right_local, proj_back_local)
		gizmo_rotation_x = _find_curve(proj_up_local, proj_back_local)

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

			var width := 1.1
			draw_set_transform($Gizmos.rect_position, 0, Vector2.ONE)
			draw_line(Vector2.ZERO, proj_right_local, Color.red)
			draw_line(Vector2.ZERO, proj_up_local, Color.green)
			draw_line(Vector2.ZERO, proj_back_local, Color.blue)
			draw_polyline(gizmo_rotation_x, Color.red, width)
			draw_polyline(gizmo_rotation_y, Color.green, width)
			draw_polyline(gizmo_rotation_z, Color.blue, width)
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


func _find_curve(a: Vector2, b: Vector2) -> PoolVector2Array:
	var curve2d := Curve2D.new()
	curve2d.bake_interval = 0.5
#	var control := (b.linear_interpolate(a, 0.5) - gizmos.rect_position).limit_length(8)
	var control := (b.linear_interpolate(a, 0.5))
#	print(control.length())
	a = (a.normalized() * 8).limit_length(a.length())
	b = (b.normalized() * 8).limit_length(b.length())
	control = control.normalized() * sqrt(pow(a.length()/4, 2) * 2)
#	print(a.length(), " ", b.length())
	curve2d.add_point(a, Vector2.ZERO, control)
	curve2d.add_point(b, control)
	return curve2d.get_baked_points()


func _scale_gizmo(gizmo: Control, new_scale: Vector2) -> void:
	gizmo.rect_scale.x = max(0.1, new_scale.x) if new_scale.x >= 0 else min(-0.1, new_scale.x)
	gizmo.rect_scale.y = max(0.1, new_scale.y) if new_scale.y >= 0 else min(-0.1, new_scale.y)
