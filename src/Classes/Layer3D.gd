class_name Layer3D
extends BaseLayer

# Overridden Methods:


func _init(_project, _name := "") -> void:
	project = _project
	name = _name


func serialize() -> Dictionary:
	var dict = .serialize()
	dict["type"] = Global.LayerTypes.THREE_D
#	dict["new_cels_linked"] = new_cels_linked
	return dict


#func deserialize(dict: Dictionary) -> void:
#	.deserialize(dict)
#	new_cels_linked = dict.new_cels_linked


func new_empty_cel() -> BaseCel:
	return Cel3D.new(project.size)


func instantiate_layer_button() -> Node:
	return Global.pixel_layer_button_node.instance()
