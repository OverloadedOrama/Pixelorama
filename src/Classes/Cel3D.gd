class_name Cel3D
extends BaseCel

var viewport: Viewport


func _init(_viewport: Viewport) -> void:
	viewport = _viewport
	image_texture = viewport.get_texture()
	opacity = 1.0


func get_image() -> Image:
	return viewport.get_texture().get_data()


func instantiate_cel_button() -> Node:
	return Global.pixel_cel_button_node.instance()
