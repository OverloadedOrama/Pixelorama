class_name Cel3D
extends BaseCel

var node_3d_parent := preload("res://src/Classes/Node3DParent.gd")
var object_3d_script := preload("res://src/Classes/Object3D.gd")
var viewport: Viewport
var camera: Camera
var objects := []


func _init(size: Vector2) -> void:
	opacity = 1.0
	viewport = Viewport.new()
	viewport.size = size
	viewport.own_world = true
	viewport.transparent_bg = true
	viewport.render_target_v_flip = true

	var node_3d := Spatial.new()
	node_3d.set_script(node_3d_parent)
	camera = Camera.new()
	var light := DirectionalLight.new()
	var cube := CSGBox.new()
	cube.set_script(object_3d_script)
	camera.current = true
	light.rotate_y(-PI/4)
	cube.translation = Vector3(0, 0, -4)
	cube.rotation_degrees = Vector3(20, -50, -20)
	node_3d.add_child(camera)
	node_3d.add_child(light)
	node_3d.add_child(cube)
	viewport.add_child(node_3d)
	Global.canvas.add_child(viewport)
	image_texture = viewport.get_texture()
	objects.append(light)
	objects.append(cube)


func get_image() -> Image:
	return viewport.get_texture().get_data()


func on_remove() -> void:
	viewport.queue_free()


func instantiate_cel_button() -> Node:
	return Global.pixel_cel_button_node.instance()
