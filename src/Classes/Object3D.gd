class_name Object3D
extends MeshInstance

enum Gizmos {
	NONE,
	X_TRANS,
	Y_TRANS,
	Z_TRANS,
	X_ROT,
	Y_ROT,
	Z_ROT,
}

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


func move(position: Vector3) -> void:
	translation += position
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
