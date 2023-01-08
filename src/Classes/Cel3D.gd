class_name Cel3D
extends BaseCel

var layer
var size: Vector2
var viewport: Viewport
var parent_node: Cel3DParent
var camera: Camera
# Key = Cel3DObject's name, Value = Dictionary containing the properties of the Cel3DObject
var object_properties := {}


func _init(_layer, _size: Vector2, from_pxo := false) -> void:
	layer = _layer
	size = _size
	opacity = 1.0
	if not from_pxo:
		_add_nodes()


func _add_nodes() -> void:
	viewport = Viewport.new()
	viewport.size = size
	viewport.own_world = true
	viewport.transparent_bg = true
	viewport.render_target_v_flip = true
	var world := World.new()
	var environment := Environment.new()
	world.environment = environment
	viewport.world = world
	parent_node = Cel3DParent.new()
	parent_node.cel = self
	camera = Camera.new()
	camera.current = true
	deserialize_layer_properties()
	viewport.add_child(camera)
	viewport.add_child(parent_node)
	Global.canvas.add_child(viewport)

	if object_properties.empty():
		for id in layer.objects:
			add_object(id)

	else:
		var objects_duplicate := object_properties.duplicate()
		for id in objects_duplicate:
			var properties: Dictionary = object_properties[id]
			Global.convert_dictionary_values(properties)
			var node3d := Cel3DObject.new()
			node3d.cel = self
			node3d.deserialize(properties)
			node3d.connect("property_finished_changing", self, "_object_property_changed", [node3d])
			parent_node.add_child(node3d)
			object_properties.erase(id)
			object_properties[node3d.id] = properties

	image_texture = viewport.get_texture()


func _get_image_texture() -> Texture:
	if not is_instance_valid(viewport):
		_add_nodes()
	return image_texture


func serialize_layer_properties() -> Dictionary:
	if not is_instance_valid(camera):
		return {}
	return {
		"camera_transform": camera.transform,
		"camera_projection": camera.projection,
		"ambient_color": viewport.world.environment.ambient_light_color
	}


func deserialize_layer_properties() -> void:
	print(layer.properties["camera_transform"])
	print(typeof(layer.properties["camera_transform"]))
	camera.transform = layer.properties["camera_transform"]
	camera.projection = layer.properties["camera_projection"]
	viewport.world.environment.ambient_light_color = layer.properties["ambient_color"]


func _object_property_changed(object: Cel3DObject) -> void:
	var undo_redo: UndoRedo = layer.project.undo_redo
	var new_properties := object_properties.duplicate()
	new_properties[object.id] = object.serialize()
	undo_redo.create_action("Change object transform")
	undo_redo.add_do_property(self, "object_properties", new_properties)
	undo_redo.add_undo_property(self, "object_properties", object_properties)
	undo_redo.add_do_method(self, "_update_objects_transform", object.id)
	undo_redo.add_undo_method(self, "_update_objects_transform", object.id)
	undo_redo.add_do_method(Global, "undo_or_redo", false)
	undo_redo.add_undo_method(Global, "undo_or_redo", true)
	undo_redo.commit_action()


func _update_objects_transform(id: int) -> void:  # Called by undo/redo
	var properties: Dictionary = object_properties[id]
	for child in parent_node.get_children():
		if not child is Cel3DObject:
			continue
		if child.id == id:
			child.deserialize(properties)


func size_changed(new_size: Vector2) -> void:
	size = new_size
	viewport.size = size
	image_texture = viewport.get_texture()


func add_object(id: int) -> void:
	var node3d := Cel3DObject.new()
	node3d.id = id
	node3d.cel = self
	node3d.type = layer.objects[id]
	node3d.connect("property_finished_changing", self, "_object_property_changed", [node3d])
	if id == 0:  # Directional light
		node3d.translation = Vector3(-2.5, 0, 0)
		node3d.rotate_y(-PI / 4)
	if object_properties.has(node3d.id) and object_properties[node3d.id].has("id"):
		node3d.deserialize(object_properties[node3d.id])
	else:
		if object_properties.has(node3d.id) and object_properties[node3d.id].has("file_path"):
			node3d.file_path = object_properties[node3d.id]["file_path"]
		object_properties[node3d.id] = node3d.serialize()
	parent_node.add_child(node3d)


func remove_object(id: int) -> void:
	for child in parent_node.get_children():
		if not child is Cel3DObject:
			continue
		if child.id == id:
			child.queue_free()
			break


# Overridden methods


func get_image() -> Image:
	return viewport.get_texture().get_data()


func save_cel_data_to_pxo(file: File) -> void:
	file.store_line(JSON.print(object_properties))


func load_cel_data_from_pxo(file: File, _project_size: Vector2) -> void:
	var dict := JSON.parse(file.get_line())
	if dict.error != OK:
		print("Error while parsing a Cel3D. %s" % dict.error_string)
		return
	object_properties = dict.result
	_add_nodes()


func on_remove() -> void:
	if is_instance_valid(viewport):
		viewport.queue_free()


func instantiate_cel_button() -> Node:
	return Global.pixel_cel_button_node.instance()
