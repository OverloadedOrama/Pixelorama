class_name Cel3D
extends BaseCel

var object_3d_script := preload("res://src/Classes/Object3D.gd")
var viewport: Viewport
var camera: Camera


func _init(size: Vector2) -> void:
	opacity = 1.0
	viewport = Viewport.new()
	var spatial := Spatial.new()
	camera = Camera.new()
	var light := DirectionalLight.new()
	var cube := CSGBox.new()
	cube.set_script(object_3d_script)
	camera.current = true
	light.rotate_y(-PI/4)
	cube.translation = Vector3(0, 0, -3)
	cube.rotation_degrees = Vector3(20, -50, -20)
	spatial.add_child(camera)
	spatial.add_child(light)
	spatial.add_child(cube)
	viewport.add_child(spatial)
	Global.canvas.add_child(viewport)
	viewport.size = size
	viewport.own_world = true
	viewport.transparent_bg = true
	viewport.render_target_v_flip = true
	image_texture = viewport.get_texture()


func get_image() -> Image:
	return viewport.get_texture().get_data()


func on_remove() -> void:
	viewport.queue_free()


func instantiate_cel_button() -> Node:
	return Global.pixel_cel_button_node.instance()
