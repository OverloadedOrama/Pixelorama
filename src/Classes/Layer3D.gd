class_name Layer3D
extends BaseLayer

var objects := {}  # Key = id, Value = Cel3DObject.Type
var objects_id := 0  # This number is used as the id of the objects, its value never decreases

# Overridden Methods:


func _init(_project, _name := "") -> void:
	project = _project
	name = _name
	add_object(Cel3DObject.Type.DIR_LIGHT)
	add_object(Cel3DObject.Type.CUBE)


func add_object(type: int) -> void:
	objects[objects_id] = type
	objects_id += 1


func remove_object(id: int) -> void:
	for frame in project.frames:
		var cel: Cel3D = frame.cels[index]
		cel.remove_object(id)
	objects.erase(id)


func serialize() -> Dictionary:
	var dict = .serialize()
	dict["type"] = Global.LayerTypes.THREE_D
#	dict["new_cels_linked"] = new_cels_linked
	return dict


#func deserialize(dict: Dictionary) -> void:
#	.deserialize(dict)
#	new_cels_linked = dict.new_cels_linked


func new_empty_cel() -> BaseCel:
	return Cel3D.new(self, project.size, objects)


func instantiate_layer_button() -> Node:
	return Global.pixel_layer_button_node.instance()
