extends VBoxContainer

var cel: Cel3D
var can_start_timer := true

onready var new_object_menu_button: MenuButton = $NewObjectMenuButton
onready var layer_options: Container = $LayerOptions
onready var object_options: Container = $ObjectOptions

onready var projection_option_button: OptionButton = $LayerOptions/ProjectionOptionButton
onready var camera_rotation_x: ValueSlider = $LayerOptions/RotationContainer/CameraRotationX
onready var camera_rotation_y: ValueSlider = $LayerOptions/RotationContainer/CameraRotationY
onready var camera_rotation_z: ValueSlider = $LayerOptions/RotationContainer/CameraRotationZ

onready var object_position_x: ValueSlider = $ObjectOptions/PositionContainer/ObjectPositionX
onready var object_position_y: ValueSlider = $ObjectOptions/PositionContainer/ObjectPositionY
onready var object_position_z: ValueSlider = $ObjectOptions/PositionContainer/ObjectPositionZ
onready var object_rotation_x: ValueSlider = $ObjectOptions/RotationContainer/ObjectRotationX
onready var object_rotation_y: ValueSlider = $ObjectOptions/RotationContainer/ObjectRotationY
onready var object_rotation_z: ValueSlider = $ObjectOptions/RotationContainer/ObjectRotationZ
onready var object_scale_x: ValueSlider = $ObjectOptions/ScaleContainer/ObjectScaleX
onready var object_scale_y: ValueSlider = $ObjectOptions/ScaleContainer/ObjectScaleY
onready var object_scale_z: ValueSlider = $ObjectOptions/ScaleContainer/ObjectScaleZ
onready var undo_redo_timer: Timer = $UndoRedoTimer


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
	new_object_popup.connect("id_pressed", self, "_add_new_object")


func _cel_changed() -> void:
	if not Global.current_project.get_current_cel() is Cel3D:
		return
	cel = Global.current_project.get_current_cel()
	var layer: Layer3D = cel.layer
	if not layer.is_connected("property_changed", self, "_set_cel_settings_values"):
		layer.connect("property_changed", self, "_set_cel_settings_values")
	var parent: Cel3DParent = cel.parent_node
	if not is_instance_valid(parent):
		print("Parent not found")
		return
	if not parent.is_connected("selected_object", self, "_selected_object"):
		parent.connect("selected_object", self, "_selected_object")
	layer_options.visible = true
	object_options.visible = false
	_set_cel_settings_values()


func _add_new_object(id: int) -> void:
	cel.layer.add_object(id, true)


func _selected_object(object: Cel3DObject) -> void:
	if is_instance_valid(object):
		layer_options.visible = false
		object_options.visible = true
		_set_object_settings_values()
		if not object.is_connected("property_changed", self, "_set_object_settings_values"):
			object.connect("property_changed", self, "_set_object_settings_values")
	else:
		layer_options.visible = true
		object_options.visible = false


func _set_cel_settings_values() -> void:
	can_start_timer = false
	var camera: Camera = cel.camera
	projection_option_button.selected = camera.projection
	camera_rotation_x.value = camera.rotation_degrees.x
	camera_rotation_y.value = camera.rotation_degrees.y
	camera_rotation_z.value = camera.rotation_degrees.z
	can_start_timer = true


func _set_object_settings_values() -> void:
	var object: Cel3DObject = cel.parent_node.selected
	if not is_instance_valid(object):
		return
	can_start_timer = false
	object_position_x.value = object.translation.x
	object_position_y.value = object.translation.y
	object_position_z.value = object.translation.z
	object_rotation_x.value = object.rotation_degrees.x
	object_rotation_y.value = object.rotation_degrees.y
	object_rotation_z.value = object.rotation_degrees.z
	object_scale_x.value = object.scale.x * 100
	object_scale_y.value = object.scale.y * 100
	object_scale_z.value = object.scale.z * 100
	can_start_timer = true


func _on_ProjectionOptionButton_item_selected(index: int) -> void:
	cel.camera.projection = index
	_value_handle_change()
	Global.canvas.gizmos_3d.update()


func _on_CameraRotationX_value_changed(value: float) -> void:
	cel.camera.rotation_degrees.x = value
	_value_handle_change()
	Global.canvas.gizmos_3d.update()


func _on_CameraRotationY_value_changed(value: float) -> void:
	cel.camera.rotation_degrees.y = value
	_value_handle_change()
	Global.canvas.gizmos_3d.update()


func _on_CameraRotationZ_value_changed(value: float) -> void:
	cel.camera.rotation_degrees.z = value
	_value_handle_change()
	Global.canvas.gizmos_3d.update()


# Object specific code


func _on_ObjectPositionX_value_changed(value: float) -> void:
	if is_equal_approx(cel.parent_node.selected.translation.x, value):
		return
	cel.parent_node.selected.translation.x = value
	_value_handle_change()


func _on_ObjectPositionY_value_changed(value: float) -> void:
	if is_equal_approx(cel.parent_node.selected.translation.y, value):
		return
	cel.parent_node.selected.translation.y = value
	_value_handle_change()


func _on_ObjectPositionZ_value_changed(value: float) -> void:
	cel.parent_node.selected.translation.z = value
	_value_handle_change()


func _on_ObjectRotationX_value_changed(value: float) -> void:
	cel.parent_node.selected.rotation_degrees.x = value
	_value_handle_change()


func _on_ObjectRotationY_value_changed(value: float) -> void:
	cel.parent_node.selected.rotation_degrees.y = value
	_value_handle_change()


func _on_ObjectRotationZ_value_changed(value: float) -> void:
	cel.parent_node.selected.rotation_degrees.z = value
	_value_handle_change()


func _on_ObjectScaleX_value_changed(value: float) -> void:
	cel.parent_node.selected.scale.x = value / 100
	_value_handle_change()


func _on_ObjectScaleY_value_changed(value: float) -> void:
	cel.parent_node.selected.scale.y = value / 100
	_value_handle_change()


func _on_ObjectScaleZ_value_changed(value: float) -> void:
	cel.parent_node.selected.scale.z = value / 100
	_value_handle_change()


func _value_handle_change() -> void:
	if can_start_timer:
		undo_redo_timer.start()


func _on_UndoRedoTimer_timeout() -> void:
	if is_instance_valid(cel.parent_node.selected):
		cel.parent_node.selected.finish_changing_property()
	else:
		var new_properties := cel.serialize_camera()
		cel.layer.change_camera_properties(new_properties)
