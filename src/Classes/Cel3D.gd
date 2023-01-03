class_name Cel3D
extends BaseCel

var size: Vector2
var viewport: Viewport
var parent_node: Cel3DParent
var camera: Camera
var camera_properties := {}  # Key = property name, Value = property
# Key = Cel3DObject's name, Value = Dictionary containing the properties of the Cel3DObject
var objects := {}


func _init(_size: Vector2) -> void:
	size = _size
	opacity = 1.0
	_add_nodes()


func _add_nodes() -> void:
	viewport = Viewport.new()
	viewport.size = size
	viewport.own_world = true
	viewport.transparent_bg = true
	viewport.render_target_v_flip = true
#	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS

	parent_node = Cel3DParent.new()
	parent_node.cel = self
	camera = Camera.new()
	camera.current = true
	if camera_properties.empty():
		camera.translation = Vector3(0, 0, 3)
		serialize_camera()
	else:
		_deserialize_camera()
	viewport.add_child(camera)
	viewport.add_child(parent_node)
	Global.canvas.add_child(viewport)

	if objects.empty():
		var light := Cel3DObject.new()
		light.cel = self
		light.type = Cel3DObject.Type.DIR_LIGHT
		light.connect("property_changed", self, "_object_property_changed", [light])
		light.rotate_y(-PI / 4)
		var cube := Cel3DObject.new()
		cube.cel = self
		var cube_mesh := CubeMesh.new()
		cube.mesh = cube_mesh
		cube.connect("property_changed", self, "_object_property_changed", [cube])
		parent_node.add_child(light)
		parent_node.add_child(cube)
		objects[light.name] = light.serialize()
		objects[cube.name] = cube.serialize()
	else:
		var objects_duplicate := objects.duplicate(true)
		for object_name in objects_duplicate:
			var properties: Dictionary = objects[object_name]
			var object_node := Cel3DObject.new()
			object_node.cel = self
			object_node.type = properties["type"]
			if properties["mesh"]:
				object_node.mesh = properties["mesh"]
			object_node.transform = properties["transform"]
			object_node.connect("property_changed", self, "_object_property_changed", [object_node])
			parent_node.add_child(object_node)
			objects.erase(object_name)
			objects[object_node.name] = properties

	image_texture = viewport.get_texture()


func _get_image_texture() -> Texture:
	if not is_instance_valid(viewport):
		_add_nodes()
	return image_texture


func serialize_camera() -> void:
	if not is_instance_valid(camera):
		return
	camera_properties = {"transform": camera.transform, "projection": camera.projection}


func _deserialize_camera() -> void:
	camera.transform = camera_properties["transform"]
	camera.projection = camera_properties["projection"]


func _object_property_changed(object: Cel3DObject) -> void:
	objects[object.name] = object.serialize()


func get_image() -> Image:
	return viewport.get_texture().get_data()


func size_changed(new_size: Vector2) -> void:
	size = new_size
	viewport.size = size
	image_texture = viewport.get_texture()


func add_object(object: Cel3DObject) -> void:
	_object_property_changed(object)


func remove_object(object: Cel3DObject) -> void:
	objects.erase(object.name)


func on_remove() -> void:
	if is_instance_valid(viewport):
		viewport.queue_free()


func instantiate_cel_button() -> Node:
	return Global.pixel_cel_button_node.instance()
