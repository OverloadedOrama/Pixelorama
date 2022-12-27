class_name Object3D
extends MeshInstance

var selected := false
var hovered := false
var box_shape: BoxShape
var camera: Camera


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
