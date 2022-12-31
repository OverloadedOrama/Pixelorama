class_name Object3D
extends MeshInstance

enum Gizmos { NONE, X_POS, Y_POS, Z_POS, X_ROT, Y_ROT, Z_ROT, X_SCALE, Y_SCALE, Z_SCALE }

var selected := false
var hovered := false
var box_shape: BoxShape
var camera: Camera
var applying_gizmos := 0


func _ready() -> void:
	camera = get_viewport().get_camera()
	var static_body := StaticBody.new()
	var collision_shape := CollisionShape.new()
	box_shape = BoxShape.new()
	box_shape.extents = scale
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	add_child(static_body)


func select() -> void:
	selected = true
	Global.canvas.get_node("BoundingBoxes3D").get_points(camera, self)


func unselect() -> void:
	selected = false
	Global.canvas.get_node("BoundingBoxes3D").clear_points(self)


func hover() -> void:
	if hovered:
		return
	hovered = true
	if selected:
		return
	Global.canvas.get_node("BoundingBoxes3D").get_points(camera, self)


func unhover() -> void:
	if not hovered:
		return
	hovered = false
	if selected:
		return
	Global.canvas.get_node("BoundingBoxes3D").clear_points(self)


func change_transform(diff: Vector3) -> void:
	match applying_gizmos:
		Gizmos.X_POS:
			move_axis(diff, transform.basis.x)
		Gizmos.Y_POS:
			move_axis(diff, transform.basis.y)
		Gizmos.Z_POS:
			move_axis(diff, transform.basis.z)
		Gizmos.X_ROT:
			change_rotation(Vector3(diff.x, 0, 0))
		Gizmos.Y_ROT:
			change_rotation(Vector3(0, diff.y, 0))
		Gizmos.Z_ROT:
			change_rotation(Vector3(0, 0, diff.x))
		Gizmos.X_SCALE:
			change_scale(diff, transform.basis.x, Vector3.RIGHT)
		Gizmos.Y_SCALE:
			change_scale(diff, transform.basis.y, Vector3.UP)
		Gizmos.Z_SCALE:
			change_scale(diff, transform.basis.z, Vector3.BACK)
		_:
			move(diff)


func move(position: Vector3) -> void:
	translation += position
	select()


func move_axis(diff: Vector3, axis: Vector3) -> void:
	# Move the object in the direction it is facing, and restrict mouse movement in that axis
	var trans_proj := Vector2(axis.x, axis.y).normalized()
	var diff_v2 := Vector2(diff.x, diff.y).normalized()
	translation += axis * trans_proj.dot(diff_v2) * diff.length()
	select()


func change_rotation(position: Vector3) -> void:
	rotation += position
	rotation.x = wrapf(rotation.x, -PI, PI)
	rotation.y = wrapf(rotation.y, -PI, PI)
	rotation.z = wrapf(rotation.z, -PI, PI)
	select()


func change_scale(diff: Vector3, axis: Vector3, dir: Vector3) -> void:
	# Scale the object in the direction it is facing, and restrict mouse movement in that axis
	var trans_proj := Vector2(axis.x, axis.y).normalized()
	var diff_v2 := Vector2(diff.x, diff.y).normalized()
	scale += dir * trans_proj.dot(diff_v2) * diff.length()
	select()

	select()
