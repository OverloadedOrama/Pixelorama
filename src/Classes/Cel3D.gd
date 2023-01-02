class_name Cel3D
extends BaseCel

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

	var node_3d := Cel3DParent.new()
	node_3d.cel = self
	camera = Camera.new()
	camera.translation = Vector3(0, 0, 3)
	var light := Cel3DObject.new()
	light.type = Cel3DObject.Types.DIR_LIGHT
	var cube := Cel3DObject.new()
	var cube_mesh := CubeMesh.new()
	cube.mesh = cube_mesh
	camera.current = true
	light.rotate_y(-PI / 4)
#	cube.translation = Vector3(0, 0, -4)
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
	if is_instance_valid(viewport):
		viewport.queue_free()


func instantiate_cel_button() -> Node:
	return Global.pixel_cel_button_node.instance()
