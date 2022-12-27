class_name Object3D
extends Spatial

var selected := false
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
	Global.canvas.get_node("BoundingBoxes3D").get_points(camera, self, Color.blue)


func unselect() -> void:
	selected = false
	Global.canvas.get_node("BoundingBoxes3D").clear_points()


func hover() -> void:
	if selected:
		return
	Global.canvas.get_node("BoundingBoxes3D").get_points(camera, self, Color.cyan)


func unhover() -> void:
	if selected:
		return
	Global.canvas.get_node("BoundingBoxes3D").clear_points()
