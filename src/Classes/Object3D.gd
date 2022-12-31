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
			move_x(Vector3(diff.x, 0, 0))
		Gizmos.Y_POS:
			move_y(Vector3(0, diff.y, 0))
		Gizmos.Z_POS:
			move_z(Vector3(0, 0, diff.x))
		Gizmos.X_ROT:
			change_rotation(Vector3(diff.x, 0, 0))
		Gizmos.Y_ROT:
			change_rotation(Vector3(0, diff.y, 0))
		Gizmos.Z_ROT:
			change_rotation(Vector3(0, 0, diff.x))
		Gizmos.X_SCALE:
			change_scale(Vector3(diff.x, 0, 0))
		Gizmos.Y_SCALE:
			change_scale(Vector3(0, diff.y, 0))
		Gizmos.Z_SCALE:
			change_scale(Vector3(0, 0, diff.x))
		_:
			move(diff)


func move(position: Vector3) -> void:
	translation += position
	select()


func move_x(position: Vector3) -> void:
	translation += position.x * transform.basis.x
	select()


func move_y(position: Vector3) -> void:
	translation += position.y * transform.basis.y
	select()


func move_z(position: Vector3) -> void:
	translation += position.z * transform.basis.z
	select()


func change_rotation(position: Vector3) -> void:
	rotation += position
	rotation.x = wrapf(rotation.x, -PI, PI)
	rotation.y = wrapf(rotation.y, -PI, PI)
	rotation.z = wrapf(rotation.z, -PI, PI)
	select()


func change_scale(position: Vector3) -> void:
	scale += position
	select()

