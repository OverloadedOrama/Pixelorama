extends VBoxContainer

var cel: Cel3D

onready var new_object_menu_button: MenuButton = $NewObjectMenuButton
onready var cel_options: Container = $CelOptions
onready var object_options: Container = $ObjectOptions

onready var projection_option_button: OptionButton = $CelOptions/ProjectionOptionButton
onready var camera_rotation_x: ValueSlider = $CelOptions/RotationContainer/CameraRotationX
onready var camera_rotation_y: ValueSlider = $CelOptions/RotationContainer/CameraRotationY
onready var camera_rotation_z: ValueSlider = $CelOptions/RotationContainer/CameraRotationZ

onready var object_position_x: ValueSlider = $ObjectOptions/PositionContainer/ObjectPositionX
onready var object_position_y: ValueSlider = $ObjectOptions/PositionContainer/ObjectPositionY
onready var object_position_z: ValueSlider = $ObjectOptions/PositionContainer/ObjectPositionZ
onready var object_rotation_x: ValueSlider = $ObjectOptions/RotationContainer/ObjectRotationX
onready var object_rotation_y: ValueSlider = $ObjectOptions/RotationContainer/ObjectRotationY
onready var object_rotation_z: ValueSlider = $ObjectOptions/RotationContainer/ObjectRotationZ
onready var object_scale_x: ValueSlider = $ObjectOptions/ScaleContainer/ObjectScaleX
onready var object_scale_y: ValueSlider = $ObjectOptions/ScaleContainer/ObjectScaleY
onready var object_scale_z: ValueSlider = $ObjectOptions/ScaleContainer/ObjectScaleZ


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
	new_object_popup.add_item("Omnilight")
	new_object_popup.connect("id_pressed", self, "_add_new_object")


func _cel_changed() -> void:
	if not Global.current_project.get_current_cel() is Cel3D:
		return
	cel = Global.current_project.get_current_cel()
	var parent: Cel3DParent = cel.parent_node
	if not is_instance_valid(parent):
		print("Parent not found")
		return
	if not parent.is_connected("selected_object", self, "_selected_object"):
		parent.connect("selected_object", self, "_selected_object")
	cel_options.visible = true
	object_options.visible = false
	_set_cel_settings_values()


func _add_new_object(id: int) -> void:
	cel.layer.add_object(id, true)


func _selected_object(object: Cel3DObject) -> void:
	if is_instance_valid(object):
		cel_options.visible = false
		object_options.visible = true
		_set_object_settings_values()
		if not object.is_connected("property_changed", self, "_set_object_settings_values"):
			object.connect("property_changed", self, "_set_object_settings_values")
	else:
		cel_options.visible = true
		object_options.visible = false


func _set_cel_settings_values() -> void:
	var camera: Camera = cel.camera
	projection_option_button.selected = camera.projection
	camera_rotation_x.value = camera.rotation_degrees.x
	camera_rotation_y.value = camera.rotation_degrees.y
	camera_rotation_z.value = camera.rotation_degrees.z


func _set_object_settings_values() -> void:
	var object: Cel3DObject = cel.parent_node.selected
	object_position_x.value = object.translation.x
	object_position_y.value = object.translation.y
	object_position_z.value = object.translation.z
	object_rotation_x.value = object.rotation_degrees.x
	object_rotation_y.value = object.rotation_degrees.y
	object_rotation_z.value = object.rotation_degrees.z
	object_scale_x.value = object.scale.x * 100
	object_scale_y.value = object.scale.y * 100
	object_scale_z.value = object.scale.z * 100


func _on_ProjectionOptionButton_item_selected(index: int) -> void:
	cel.camera.projection = index
	cel.serialize_camera()
	Global.canvas.gizmos_3d.update()


func _on_CameraRotationX_value_changed(value: float) -> void:
	cel.camera.rotation_degrees.x = value
	cel.serialize_camera()
	Global.canvas.gizmos_3d.update()


func _on_CameraRotationY_value_changed(value: float) -> void:
	cel.camera.rotation_degrees.y = value
	cel.serialize_camera()
	Global.canvas.gizmos_3d.update()


func _on_CameraRotationZ_value_changed(value: float) -> void:
	cel.camera.rotation_degrees.z = value
	cel.serialize_camera()
	Global.canvas.gizmos_3d.update()


func _on_ObjectPositionX_value_changed(value: float) -> void:
#	if cel.parent_node.selected.translation.x == value:
#		return
	cel.parent_node.selected.translation.x = value
	cel.parent_node.selected.change_property()


func _on_ObjectPositionY_value_changed(value: float) -> void:
	cel.parent_node.selected.translation.y = value
	cel.parent_node.selected.change_property()


func _on_ObjectPositionZ_value_changed(value: float) -> void:
	cel.parent_node.selected.translation.z = value
	cel.parent_node.selected.change_property()


func _on_ObjectRotationX_value_changed(value: float) -> void:
	cel.parent_node.selected.rotation_degrees.x = value
	cel.parent_node.selected.change_property()


func _on_ObjectRotationY_value_changed(value: float) -> void:
	cel.parent_node.selected.rotation_degrees.y = value
	cel.parent_node.selected.change_property()


func _on_ObjectRotationZ_value_changed(value: float) -> void:
	cel.parent_node.selected.rotation_degrees.z = value
	cel.parent_node.selected.change_property()


func _on_ObjectScaleX_value_changed(value: float) -> void:
	cel.parent_node.selected.scale.x = value / 100
	cel.parent_node.selected.change_property()


func _on_ObjectScaleY_value_changed(value: float) -> void:
	cel.parent_node.selected.scale.y = value / 100
	cel.parent_node.selected.change_property()


func _on_ObjectScaleZ_value_changed(value: float) -> void:
	cel.parent_node.selected.scale.z = value / 100
	cel.parent_node.selected.change_property()


func _on_object_slider_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
		cel.parent_node.selected.finish_changing_property()
