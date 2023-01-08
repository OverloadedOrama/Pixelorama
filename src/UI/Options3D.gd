extends PanelContainer

var cel: Cel3D
var can_start_timer := true

onready var new_object_menu_button: MenuButton = $VBoxContainer/NewObjectMenuButton
onready var layer_options: Container = $"%LayerOptions"
onready var object_options: Container = $"%ObjectOptions"
onready var undo_redo_timer: Timer = $UndoRedoTimer
onready var load_model_dialog: FileDialog = $LoadModelDialog

onready var layer_properties := {
	"camera.projection": layer_options.get_node("ProjectionOptionButton"),
	"camera.rotation_degrees.x": layer_options.get_node("RotationContainer/CameraRotationX"),
	"camera.rotation_degrees.y": layer_options.get_node("RotationContainer/CameraRotationY"),
	"camera.rotation_degrees.z": layer_options.get_node("RotationContainer/CameraRotationZ"),
	"viewport.world.environment.ambient_light_color":
	layer_options.get_node("AmbientColorPickerButton"),
}

onready var object_properties := {
	"translation.x": object_options.get_node("PositionContainer/ObjectPositionX"),
	"translation.y": object_options.get_node("PositionContainer/ObjectPositionY"),
	"translation.z": object_options.get_node("PositionContainer/ObjectPositionZ"),
	"rotation_degrees.x": object_options.get_node("RotationContainer/ObjectRotationX"),
	"rotation_degrees.y": object_options.get_node("RotationContainer/ObjectRotationY"),
	"rotation_degrees.z": object_options.get_node("RotationContainer/ObjectRotationZ"),
	"scale.x": object_options.get_node("ScaleContainer/ObjectScaleX"),
	"scale.y": object_options.get_node("ScaleContainer/ObjectScaleY"),
	"scale.z": object_options.get_node("ScaleContainer/ObjectScaleZ"),
}


func _ready() -> void:
	Global.connect("cel_changed", self, "_cel_changed")
	var new_object_popup := new_object_menu_button.get_popup()
	new_object_popup.add_item("Cube")
	new_object_popup.add_item("Sphere")
	new_object_popup.add_item("Capsule")
	new_object_popup.add_item("Cylinder")
	new_object_popup.add_item("Prism")
	new_object_popup.add_item("Plane")
	new_object_popup.add_item("Text")
	new_object_popup.add_item("Directional light")
	new_object_popup.add_item("Spotlight")
	new_object_popup.add_item("Omnidirectional (point) light")
	new_object_popup.add_item("Load model from file")
	new_object_popup.connect("id_pressed", self, "_add_new_object")
	for prop in layer_properties:
		var node: Control = layer_properties[prop]
		if node is Range:
			node.connect("value_changed", self, "_layer_property_value_changed", [prop])
		elif node is OptionButton:
			node.connect("item_selected", self, "_layer_property_item_selected", [prop])
		elif node is ColorPickerButton:
			node.connect("color_changed", self, "_layer_property_color_changed", [prop])
	for prop in object_properties:
		var node: Control = object_properties[prop]
		if node is Range:
			node.connect("value_changed", self, "_object_property_value_changed", [prop])
		elif node is OptionButton:
			node.connect("item_selected", self, "_object_property_item_selected", [prop])
		elif node is ColorPickerButton:
			node.connect("color_changed", self, "_object_property_color_changed", [prop])


func _cel_changed() -> void:
	if not Global.current_project.get_current_cel() is Cel3D:
		return
	cel = Global.current_project.get_current_cel()
	var layer: Layer3D = cel.layer
	if not layer.is_connected("property_changed", self, "_set_layer_node_values"):
		layer.connect("property_changed", self, "_set_layer_node_values")
	var parent: Cel3DParent = cel.parent_node
	if not is_instance_valid(parent):
		print("Parent not found")
		return
	if not parent.is_connected("selected_object", self, "_selected_object"):
		parent.connect("selected_object", self, "_selected_object")
	layer_options.visible = true
	object_options.visible = false
	_set_layer_node_values()


func _add_new_object(id: int) -> void:
	if id == Cel3DObject.Type.IMPORTED:
		load_model_dialog.popup_centered()
		Global.dialog_open(true)
	else:
		cel.layer.add_object(id)


func _selected_object(object: Cel3DObject) -> void:
	if is_instance_valid(object):
		layer_options.visible = false
		object_options.visible = true
		_set_object_node_values()
		if not object.is_connected("property_changed", self, "_set_object_node_values"):
			object.connect("property_changed", self, "_set_object_node_values")
	else:
		layer_options.visible = true
		object_options.visible = false


func _set_layer_node_values() -> void:
	can_start_timer = false
	_set_node_values(cel, layer_properties)
	can_start_timer = true


func _set_object_node_values() -> void:
	var object: Cel3DObject = cel.parent_node.selected
	if not is_instance_valid(object):
		return
	can_start_timer = false
	_set_node_values(object, object_properties)
	can_start_timer = true


func _set_node_values(to_edit: Object, properties: Dictionary) -> void:
	for prop in properties:
		var path: PoolStringArray = prop.split(".")
		var value = to_edit.get(path[0])
		for i in range(1, path.size()):
			if typeof(value) == TYPE_VECTOR3:
				match path[i]:
					"x":
						value = value.x
					"y":
						value = value.y
					"z":
						value = value.z
			else:
				value = value.get(path[i])
		if "scale" in prop:
			value *= 100
		var node: Control = properties[prop]
		if node is Range:
			node.value = value
		elif node is OptionButton:
			node.selected = value
		elif node is ColorPickerButton:
			node.color = value


func _set_value_from_node(to_edit: Object, value, prop: String) -> void:
	var path: PoolStringArray = prop.split(".")
	var property = to_edit.get(path[0])
	var prev_property = to_edit
	for i in range(1, path.size() - 1):
		property = property.get(path[i])
		prev_property = prev_property.get(path[i - 1])
	if "scale" in prop:
		value /= 100
	if typeof(property) == TYPE_VECTOR3:
		match path[-1]:
			"x":
				property.x = value
			"y":
				property.y = value
			"z":
				property.z = value
		prev_property.set(path[-2], property)
	else:
		property.set(path[-1], value)


func _layer_property_value_changed(value: float, prop: String) -> void:
	_set_value_from_node(cel, value, prop)
	_value_handle_change()
	Global.canvas.gizmos_3d.update()


func _layer_property_item_selected(value: int, prop: String) -> void:
	_set_value_from_node(cel, value, prop)
	_value_handle_change()
	Global.canvas.gizmos_3d.update()


func _layer_property_color_changed(value: Color, prop: String) -> void:
	_set_value_from_node(cel, value, prop)
	_value_handle_change()
	Global.canvas.gizmos_3d.update()


func _object_property_value_changed(value: float, prop: String) -> void:
	_set_value_from_node(cel.parent_node.selected, value, prop)
	_value_handle_change()


func _object_property_item_selected(value: int, prop: String) -> void:
	_set_value_from_node(cel.parent_node.selected, value, prop)
	_value_handle_change()


func _object_property_color_changed(value: Color, prop: String) -> void:
	_set_value_from_node(cel.parent_node.selected, value, prop)
	_value_handle_change()


func _value_handle_change() -> void:
	if can_start_timer:
		undo_redo_timer.start()


func _on_UndoRedoTimer_timeout() -> void:
	if is_instance_valid(cel.parent_node.selected):
		cel.parent_node.selected.finish_changing_property()
	else:
		var new_properties := cel.serialize_layer_properties()
		cel.layer.change_properties(new_properties)


func _on_LoadModelDialog_files_selected(paths: PoolStringArray) -> void:
	for path in paths:
		cel.layer.add_object(Cel3DObject.Type.IMPORTED, true, path)


func _on_LoadModelDialog_popup_hide() -> void:
	Global.dialog_open(false)
