extends BaseTool

var cel: Cel3D
var can_start_timer := true
var _hovering: Cel3DObject = null
var _dragging := false
var _has_been_dragged := false
var _prev_mouse_pos := Vector2.ZERO

onready var object_option_button := $"%ObjectOptionButton" as OptionButton
onready var new_object_menu_button := $"%NewObjectMenuButton" as MenuButton
onready var remove_object := $"%RemoveObject" as Button
onready var layer_options := $"%LayerOptions" as Container
onready var object_options := $"%ObjectOptions" as Container
onready var mesh_options := $"%MeshOptions" as VBoxContainer
onready var light_options := $"%LightOptions" as VBoxContainer
onready var undo_redo_timer := $UndoRedoTimer as Timer
onready var load_model_dialog := $LoadModelDialog as FileDialog

onready var layer_properties := {
	"camera:projection": $"%ProjectionOptionButton",
	"camera:rotation_degrees": $"%CameraRotation",
	"viewport:world:environment:ambient_light_color": $"%AmbientColorPickerButton",
	"viewport:world:environment:ambient_light_energy": $"%AmbientEnergy",
}

onready var object_properties := {
	"translation": $"%ObjectPosition",
	"rotation_degrees": $"%ObjectRotation",
	"scale": $"%ObjectScale",
	"node3d_type:mesh:size": $"%MeshSize",
	"node3d_type:mesh:sizev2": $"%MeshSizeV2",
	"node3d_type:mesh:center_offset": $"%MeshCenterOffset",
	"node3d_type:mesh:left_to_right": $"%MeshLeftToRight",
	"node3d_type:mesh:radius": $"%MeshRadius",
	"node3d_type:mesh:height": $"%MeshHeight",
	"node3d_type:mesh:radial_segments": $"%MeshRadialSegments",
	"node3d_type:mesh:rings": $"%MeshRings",
	"node3d_type:mesh:is_hemisphere": $"%MeshIsHemisphere",
	"node3d_type:mesh:mid_height": $"%MeshMidHeight",
	"node3d_type:mesh:top_radius": $"%MeshTopRadius",
	"node3d_type:mesh:bottom_radius": $"%MeshBottomRadius",
	"node3d_type:mesh:text": $"%MeshText",
	"node3d_type:mesh:pixel_size": $"%MeshPixelSize",
	"node3d_type:mesh:curve_step": $"%MeshCurveStep",
	"node3d_type:mesh:horizontal_alignment": $"%MeshHorizontalAlignment",
	"node3d_type:light_color": $"%LightColor",
	"node3d_type:light_energy": $"%LightEnergy",
	"node3d_type:light_negative": $"%LightNegative",
	"node3d_type:shadow_enabled": $"%ShadowEnabled",
	"node3d_type:shadow_color": $"%ShadowColor",
	"node3d_type:omni_range": $"%OmniRange",
	"node3d_type:spot_range": $"%SpotRange",
	"node3d_type:spot_angle": $"%SpotAngle",
}


func _ready() -> void:
	Global.connect("cel_changed", self, "_cel_changed")
	_cel_changed()
	var new_object_popup := new_object_menu_button.get_popup()
	new_object_popup.add_item("Box")
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
		if node is ValueSliderV3:
			node.connect("value_changed", self, "_layer_property_vector3_changed", [prop])
		elif node is Range:
			node.connect("value_changed", self, "_layer_property_value_changed", [prop])
		elif node is OptionButton:
			node.connect("item_selected", self, "_layer_property_item_selected", [prop])
		elif node is ColorPickerButton:
			node.connect("color_changed", self, "_layer_property_color_changed", [prop])
	for prop in object_properties:
		var node: Control = object_properties[prop]
		if node is ValueSliderV3:
			node.connect("value_changed", self, "_object_property_vector3_changed", [prop])
		elif node is ValueSliderV2:
			var property_path: String = prop
			if property_path.ends_with("v2"):
				property_path = property_path.replace("v2", "")
			node.connect("value_changed", self, "_object_property_vector2_changed", [property_path])
		elif node is Range:
			node.connect("value_changed", self, "_object_property_value_changed", [prop])
		elif node is OptionButton:
			node.connect("item_selected", self, "_object_property_item_selected", [prop])
		elif node is ColorPickerButton:
			node.connect("color_changed", self, "_object_property_color_changed", [prop])
		elif node is CheckBox:
			node.connect("toggled", self, "_object_property_toggled", [prop])
		elif node is LineEdit:
			node.connect("text_changed", self, "_object_property_text_changed", [prop])


func draw_start(position: Vector2) -> void:
	if not cel.layer.can_layer_get_drawn():
		return
	var found_cel := false
	for frame_layer in Global.current_project.selected_cels:
		if cel == Global.current_project.frames[frame_layer[0]].cels[frame_layer[1]]:
			found_cel = true
	if not found_cel:
		return

	if is_instance_valid(_hovering):
		cel.selected = _hovering
		_dragging = true
		_prev_mouse_pos = position
	else:
		# We're not hovering
		if is_instance_valid(cel.selected):
			# If we're not clicking on a gizmo, unselect
			if cel.selected.applying_gizmos == Cel3DObject.Gizmos.NONE:
				cel.selected = null
			else:
				_dragging = true
				_prev_mouse_pos = position


func draw_move(position: Vector2) -> void:
	var camera: Camera = cel.camera
	if _dragging:
		_has_been_dragged = true
		var proj_mouse_pos := camera.project_position(position, camera.translation.z)
		var proj_prev_mouse_pos := camera.project_position(_prev_mouse_pos, camera.translation.z)
		cel.selected.change_transform(proj_mouse_pos, proj_prev_mouse_pos)
		_prev_mouse_pos = position


func draw_end(_position: Vector2) -> void:
	_dragging = false
	if is_instance_valid(cel.selected) and _has_been_dragged:
		cel.selected.finish_changing_property()
	_has_been_dragged = false


func cursor_move(position: Vector2) -> void:
	.cursor_move(position)
	# Hover logic
	var camera: Camera = cel.camera
	var ray_from := camera.project_ray_origin(position)
	var ray_to := ray_from + camera.project_ray_normal(position) * 20
	var space_state := camera.get_world().direct_space_state
	var selection := space_state.intersect_ray(ray_from, ray_to)
	if selection.empty():
		if is_instance_valid(_hovering):
			_hovering.unhover()
			_hovering = null
	else:
		if is_instance_valid(_hovering):
			_hovering.unhover()
		_hovering = selection["collider"].get_parent()
		_hovering.hover()


func _on_ObjectOptionButton_item_selected(index: int) -> void:
	if not cel is Cel3D:
		return
	var id := object_option_button.get_item_id(index) - 1
	var object := cel.get_object_from_id(id)
	if not is_instance_valid(object):
		cel.selected = null
		return
	cel.selected = object


func _cel_changed() -> void:
	if not Global.current_project.get_current_cel() is Cel3D:
		get_child(0).visible = false  # Just to ensure that the content of the tool is hidden
		return
	get_child(0).visible = true
	cel = Global.current_project.get_current_cel()
	cel.selected = null
	var layer: Layer3D = cel.layer
	if not layer.is_connected("property_changed", self, "_set_layer_node_values"):
		layer.connect("property_changed", self, "_set_layer_node_values")
		layer.connect("objects_changed", self, "_fill_object_option_button")
	if not cel.is_connected("selected_object", self, "_selected_object"):
		cel.connect("selected_object", self, "_selected_object")
	layer_options.visible = true
	object_options.visible = false
	_set_layer_node_values()
	_fill_object_option_button()


func _add_new_object(id: int) -> void:
	if id == Cel3DObject.Type.IMPORTED:
		load_model_dialog.popup_centered()
		Global.dialog_open(true)
	else:
		cel.layer.add_object(id)


func _on_RemoveObject_pressed() -> void:
	if is_instance_valid(cel.selected):
		cel.selected.delete()
		cel.selected = null


func _selected_object(object: Cel3DObject) -> void:
	if is_instance_valid(object):
		layer_options.visible = false
		object_options.visible = true
		remove_object.disabled = false
		for prop in object_properties:  # Hide irrelevant nodes
			var node: Control = object_properties[prop]
			var property_path: String = prop
			if property_path.ends_with("v2"):
				property_path = property_path.replace("v2", "")
			var prev_node: Control = node.get_parent().get_child(node.get_index() - 1)
			var property = object.get_indexed(property_path)
			var property_exists: bool = property != null
			# Differentiate between the mesh size of a box/prism (Vector3) and a plane (Vector2)
			if node is ValueSliderV3 and typeof(property) != TYPE_VECTOR3:
				property_exists = false
			elif node is ValueSliderV2 and typeof(property) != TYPE_VECTOR2:
				property_exists = false
			prev_node.visible = property_exists
			node.visible = property_exists
		mesh_options.visible = object.node3d_type is MeshInstance
		light_options.visible = object.node3d_type is Light
		_set_object_node_values()
		if not object.is_connected("property_changed", self, "_set_object_node_values"):
			object.connect("property_changed", self, "_set_object_node_values")
		object_option_button.select(object_option_button.get_item_index(object.id + 1))
	else:
		layer_options.visible = true
		object_options.visible = false
		remove_object.disabled = true
		object_option_button.select(0)


func _set_layer_node_values() -> void:
	can_start_timer = false
	_set_node_values(cel, layer_properties)
	can_start_timer = true


func _set_object_node_values() -> void:
	var object: Cel3DObject = cel.selected
	if not is_instance_valid(object):
		return
	can_start_timer = false
	_set_node_values(object, object_properties)
	can_start_timer = true


func _set_node_values(to_edit: Object, properties: Dictionary) -> void:
	for prop in properties:
		var property_path: String = prop
		if property_path.ends_with("v2"):
			property_path = property_path.replace("v2", "")
		var value = to_edit.get_indexed(property_path)
		if value == null:
			continue
		if "scale" in prop:
			value *= 100
		var node: Control = properties[prop]
		if node is Range or node is ValueSliderV3 or node is ValueSliderV2:
			if typeof(node.value) != typeof(value) and typeof(value) != TYPE_INT:
				continue
			node.value = value
		elif node is OptionButton:
			node.selected = value
		elif node is ColorPickerButton:
			node.color = value
		elif node is CheckBox:
			node.pressed = value
		elif node is LineEdit:
			node.text = value


func _set_value_from_node(to_edit: Object, value, prop: String) -> void:
	if "mesh_" in prop:
		prop = prop.replace("mesh_", "")
		to_edit = to_edit.node3d_type.mesh
	if "scale" in prop:
		value /= 100
	to_edit.set_indexed(prop, value)


func _layer_property_vector3_changed(value: Vector3, prop: String) -> void:
	_set_value_from_node(cel, value, prop)
	_value_handle_change()
	Global.canvas.gizmos_3d.update()


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


func _object_property_vector3_changed(value: Vector3, prop: String) -> void:
	_set_value_from_node(cel.selected, value, prop)
	_value_handle_change()


func _object_property_vector2_changed(value: Vector2, prop: String) -> void:
	_set_value_from_node(cel.selected, value, prop)
	_value_handle_change()


func _object_property_value_changed(value: float, prop: String) -> void:
	_set_value_from_node(cel.selected, value, prop)
	_value_handle_change()


func _object_property_item_selected(value: int, prop: String) -> void:
	_set_value_from_node(cel.selected, value, prop)
	_value_handle_change()


func _object_property_color_changed(value: Color, prop: String) -> void:
	_set_value_from_node(cel.selected, value, prop)
	_value_handle_change()


func _object_property_toggled(value: bool, prop: String) -> void:
	_set_value_from_node(cel.selected, value, prop)
	_value_handle_change()


func _object_property_text_changed(value: String, prop: String) -> void:
	_set_value_from_node(cel.selected, value, prop)
	_value_handle_change()


func _value_handle_change() -> void:
	if can_start_timer:
		undo_redo_timer.start()


func _fill_object_option_button() -> void:
	if not cel is Cel3D:
		return
	var layer: Layer3D = cel.layer
	object_option_button.clear()
	object_option_button.add_item("None", 0)
	for id in layer.objects:
		var item_name: String = Cel3DObject.Type.keys()[layer.objects[id]]
		object_option_button.add_item(item_name, id + 1)


func _on_UndoRedoTimer_timeout() -> void:
	if is_instance_valid(cel.selected):
		cel.selected.finish_changing_property()
	else:
		var new_properties := cel.serialize_layer_properties()
		cel.layer.change_properties(new_properties)


func _on_LoadModelDialog_files_selected(paths: PoolStringArray) -> void:
	for path in paths:
		cel.layer.add_object(Cel3DObject.Type.IMPORTED, true, path)


func _on_LoadModelDialog_popup_hide() -> void:
	Global.dialog_open(false)