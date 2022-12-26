class_name Layer3D
extends BaseLayer

var viewport: Viewport

# Overridden Methods:


func _init(_project, _name := "") -> void:
	project = _project
	name = _name
	viewport = Viewport.new()
	var spatial := Spatial.new()
	var camera := Camera.new()
	var light := DirectionalLight.new()
	var cube := CSGBox.new()
	camera.current = true
	light.rotate_y(-PI/4)
	cube.translation = Vector3(0, 0, -3)
	cube.rotation_degrees = Vector3(20, -50, -20)
	spatial.add_child(camera)
	spatial.add_child(light)
	spatial.add_child(cube)
	viewport.add_child(spatial)
	Global.canvas.add_child(viewport)
	viewport.size = project.size
	viewport.own_world = true
	viewport.transparent_bg = true
	viewport.render_target_v_flip = true


func serialize() -> Dictionary:
	var dict = .serialize()
	dict["type"] = Global.LayerTypes.THREE_D
#	dict["new_cels_linked"] = new_cels_linked
	return dict


#func deserialize(dict: Dictionary) -> void:
#	.deserialize(dict)
#	new_cels_linked = dict.new_cels_linked


func new_empty_cel() -> BaseCel:
	return Cel3D.new(viewport)


func on_remove() -> void:
	viewport.queue_free()


func instantiate_layer_button() -> Node:
	return Global.pixel_layer_button_node.instance()
