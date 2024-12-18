extends PanelContainer

const VALUE_ARROW := preload("res://assets/graphics/misc/value_arrow.svg")
const VALUE_ARROW_RIGHT := preload("res://assets/graphics/misc/value_arrow_right.svg")

var slot_colors := PackedColorArray(
	[
		Color(0.55, 0.55, 0.55),  # Scalar
		Color(0.55, 0.55, 0.55),  # Scalar int
		Color(0.55, 0.55, 0.55),  # Scalar uint
		Color(0.44, 0.43, 0.64),  # Vector2
		Color(0.337, 0.314, 0.71),  # Vector3
		Color(0.7, 0.65, 0.147),  # Vector4/Color
		Color(0.243, 0.612, 0.349),  # Boolean
		Color(0.71, 0.357, 0.64),  # Transform
		Color(0.659, 0.4, 0.137)  # Sampler
	]
)
var add_options: Array[AddOption]
var visual_shader: VisualShader:
	set(value):
		if visual_shader == value:
			return
		visual_shader = value
		add_node_button.disabled = not is_instance_valid(visual_shader)
		for child in graph_edit.get_children():
			if child.name != "_connection_layer":
				graph_edit.remove_child(child)
				child.queue_free()
		if is_instance_valid(visual_shader):
			var node_list := visual_shader.get_node_list(VisualShader.Type.TYPE_FRAGMENT)
			for id in node_list:
				var node := visual_shader.get_node(VisualShader.TYPE_FRAGMENT, id)
				add_node(node, id)
			for connection in visual_shader.get_node_connections(VisualShader.TYPE_FRAGMENT):
				var from_node_name := str(connection.from_node)
				var to_node_name := str(connection.to_node)
				graph_edit.connect_node(from_node_name, connection.from_port, to_node_name, connection.to_port)

var effects_button: MenuButton
var add_node_button: Button

@onready var graph_edit := $GraphEdit as GraphEdit
@onready var node_list_tree: Tree = %NodeListTree
@onready var effect_name_line_edit: LineEdit = %EffectNameLineEdit


class AddOption:
	var option_name := ""
	var category := ""
	var type := ""
	var description := ""
	var ops := []
	#Ref<Script> script
	## TODO: Probably remove.
	var mode: int
	var return_type: VisualShaderNode.PortType
	#int func = 0
	#bool highend = false
	#bool is_custom = false
	#bool is_native = false
	#int temp_idx = 0

	func _init(_option_name: String, _category: String, _type: String, _description: String, _ops: Array, _return_type := VisualShaderNode.PORT_TYPE_SCALAR, _mode := -1) -> void:
		option_name = _option_name
		type = _type
		category = _category
		description = _description
		ops = _ops
		return_type = _return_type
		mode = _mode


func _ready() -> void:
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR, VisualShaderNode.PortType.PORT_TYPE_SCALAR_INT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR, VisualShaderNode.PortType.PORT_TYPE_SCALAR_UINT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR_INT, VisualShaderNode.PortType.PORT_TYPE_SCALAR)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR_INT, VisualShaderNode.PortType.PORT_TYPE_SCALAR_UINT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR_UINT, VisualShaderNode.PortType.PORT_TYPE_SCALAR)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR_UINT, VisualShaderNode.PortType.PORT_TYPE_SCALAR_INT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_VECTOR_2D, VisualShaderNode.PortType.PORT_TYPE_VECTOR_3D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_VECTOR_2D, VisualShaderNode.PortType.PORT_TYPE_VECTOR_4D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_VECTOR_3D, VisualShaderNode.PortType.PORT_TYPE_VECTOR_4D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_VECTOR_3D, VisualShaderNode.PortType.PORT_TYPE_VECTOR_2D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_VECTOR_4D, VisualShaderNode.PortType.PORT_TYPE_VECTOR_2D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_VECTOR_4D, VisualShaderNode.PortType.PORT_TYPE_VECTOR_3D)
	#graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_3D, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	#graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_3D, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	#graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_4D, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	#graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_4D, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	node_list_tree.get_window().get_ok_button().set_disabled(true)
	effect_name_line_edit.get_window().get_ok_button().set_disabled(true)
	effects_button = MenuButton.new()
	effects_button.text = "Effects"
	effects_button.flat = false
	effects_button.get_popup().add_item("New")
	effects_button.get_popup().id_pressed.connect(_on_effects_button_id_pressed)
	_find_loaded_effects()
	OpenSave.shader_copied.connect(_load_shader_file)
	add_node_button = Button.new()
	add_node_button.text = "Add node"
	add_node_button.disabled = true
	add_node_button.pressed.connect(func(): node_list_tree.get_window().popup_centered())
	var menu_hbox := graph_edit.get_menu_hbox()
	menu_hbox.add_child(add_node_button)
	menu_hbox.move_child(add_node_button, 0)
	menu_hbox.add_child(effects_button)
	menu_hbox.move_child(effects_button, 0)


func _on_effect_changed() -> void:
	ResourceSaver.save(visual_shader)
	Global.canvas.queue_redraw()


func _find_loaded_effects() -> void:
	if not DirAccess.dir_exists_absolute(OpenSave.SHADERS_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(OpenSave.SHADERS_DIRECTORY)
	var shader_files := DirAccess.get_files_at(OpenSave.SHADERS_DIRECTORY)
	if shader_files.size() == 0:
		return
	for shader_file in shader_files:
		_load_shader_file(OpenSave.SHADERS_DIRECTORY.path_join(shader_file))


func _load_shader_file(file_path: String) -> void:
	var file := load(file_path)
	if file is not VisualShader:
		return
	var effect_name := file_path.get_file().get_basename()
	var popup_menu := effects_button.get_popup()
	popup_menu.add_item(effect_name)
	var effect_index := popup_menu.item_count - 1
	popup_menu.set_item_metadata(effect_index, file)


func _on_effects_button_id_pressed(id: int) -> void:
	if id == 0:
		effect_name_line_edit.get_window().popup_centered()
	else:
		visual_shader = effects_button.get_popup().get_item_metadata(id)


func new_effect(effect_name: String) -> void:
	visual_shader = VisualShader.new()
	visual_shader.set_mode(Shader.MODE_CANVAS_ITEM)
	var file_name := effect_name + ".tres"
	var file_path := OpenSave.SHADERS_DIRECTORY.path_join(file_name)
	while FileAccess.file_exists(file_path):
		effect_name += " (copy)"
		file_name = effect_name + ".tres"
		file_path = OpenSave.SHADERS_DIRECTORY.path_join(file_name)
	ResourceSaver.save(visual_shader, file_path)
	OpenSave.shader_copied.emit(file_path)


func _on_visibility_changed() -> void:
	# Only fill the options when the panel first becomes visible.
	if visible and add_options.size() == 0:
		fill_add_options()
		update_options_menu()


func get_color_type(type: int) -> Color:
	if type <= -1 or type >= VisualShaderNode.PortType.PORT_TYPE_MAX:
		return Color.TRANSPARENT
	return slot_colors[type]


func add_new_node(index: int) -> void:
	var option := add_options[index]
	if not option.type.is_empty():
		var vsn := ClassDB.instantiate(option.type) as VisualShaderNode
		var id := visual_shader.get_valid_node_id(VisualShader.TYPE_FRAGMENT)
		visual_shader.add_node(VisualShader.TYPE_FRAGMENT, vsn, Vector2.ZERO, id)
		add_node(vsn, id, option.ops)


func add_node(vsn: VisualShaderNode, id: int, ops := []) -> void:
	if not is_instance_valid(vsn):
		return
	var parameter_list := vsn.get_default_input_values()
	print(vsn, " ", parameter_list)
	var graph_node := GraphNode.new()
	graph_node.title = vsn.get_class().replace("VisualShaderNode", "")
	if vsn is VisualShaderNodeOutput:
		var color_label := Label.new()
		color_label.text = "Color"
		graph_node.add_child(color_label)
		var alpha_label := Label.new()
		alpha_label.text = "Alpha"
		graph_node.add_child(alpha_label)
		graph_node.set_slot(0, true, VisualShaderNode.PORT_TYPE_VECTOR_3D, slot_colors[VisualShaderNode.PORT_TYPE_VECTOR_3D], false, -1, Color.TRANSPARENT)
		graph_node.set_slot(1, true, VisualShaderNode.PORT_TYPE_SCALAR, slot_colors[VisualShaderNode.PORT_TYPE_SCALAR], false, -1, Color.TRANSPARENT)
	elif vsn is VisualShaderNodeParameter:
		var parameter_type := _get_parameter_type(vsn)
		if vsn.parameter_name.begins_with("PXO_"):
			_create_label(vsn.parameter_name, graph_node, -1, parameter_type)
		else:
			var line_edit := LineEdit.new()
			line_edit.text = vsn.parameter_name
			line_edit.text_changed.connect(func(text: String): vsn.parameter_name = text; _on_effect_changed())
			graph_node.add_child(line_edit)
			graph_node.set_slot(0, false, -1, Color.TRANSPARENT, true, parameter_type, slot_colors[parameter_type])
	#region Constants
	elif vsn is VisualShaderNodeBooleanConstant:
		var button := CheckBox.new()
		button.text = "On"
		button.button_pressed = vsn.constant
		button.toggled.connect(func(toggled_on: bool): vsn.constant = toggled_on; _on_effect_changed())
		graph_node.add_child(button)
		graph_node.set_slot(0, false, -1, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_BOOLEAN, slot_colors[VisualShaderNode.PORT_TYPE_BOOLEAN])
	elif vsn is VisualShaderNodeIntConstant or vsn is VisualShaderNodeUIntConstant:
		var slider := ValueSlider.new()
		slider.custom_minimum_size = Vector2(32, 32)
		slider.value = vsn.constant
		slider.value_changed.connect(func(value: int): vsn.constant = value; _on_effect_changed())
		graph_node.add_child(slider)
		graph_node.set_slot(0, false, -1, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_SCALAR, slot_colors[VisualShaderNode.PORT_TYPE_SCALAR])
	elif vsn is VisualShaderNodeFloatConstant:
		var slider := ValueSlider.new()
		slider.custom_minimum_size = Vector2(32, 32)
		slider.step = 0.001
		slider.value = vsn.constant
		slider.value_changed.connect(func(value: float): vsn.constant = value; _on_effect_changed())
		graph_node.add_child(slider)
		graph_node.set_slot(0, false, -1, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_SCALAR, slot_colors[VisualShaderNode.PORT_TYPE_SCALAR])
	elif vsn is VisualShaderNodeVec2Constant:
		var slider := ShaderLoader.VALUE_SLIDER_V2_TSCN.instantiate() as ValueSliderV2
		slider.value = vsn.constant
		slider.value_changed.connect(func(value: Vector2): vsn.constant = value; _on_effect_changed())
		graph_node.add_child(slider)
		graph_node.set_slot(0, false, -1, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_VECTOR_2D, slot_colors[VisualShaderNode.PORT_TYPE_VECTOR_2D])
	elif vsn is VisualShaderNodeVec3Constant:
		var slider := ShaderLoader.VALUE_SLIDER_V3_TSCN.instantiate() as ValueSliderV3
		slider.value = vsn.constant
		slider.value_changed.connect(func(value: Vector3): vsn.constant = value; _on_effect_changed())
		graph_node.add_child(slider)
		graph_node.set_slot(0, false, -1, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_VECTOR_3D, slot_colors[VisualShaderNode.PORT_TYPE_VECTOR_3D])
	elif vsn is VisualShaderNodeColorConstant or vsn is VisualShaderNodeVec4Constant:
		var color_picker_button := ColorPickerButton.new()
		color_picker_button.custom_minimum_size = Vector2(20, 20)
		color_picker_button.color = vsn.constant
		color_picker_button.color_changed.connect(func(color: Color): vsn.constant = color; _on_effect_changed())
		graph_node.add_child(color_picker_button)
		graph_node.set_slot(0, false, -1, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_VECTOR_4D, slot_colors[VisualShaderNode.PORT_TYPE_VECTOR_4D])
	#endregion
	elif vsn is VisualShaderNodeTexture:
		# TODO: Add texture changing logic
		var texture_rect := TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(20, 20)
		texture_rect.texture = vsn.texture
		graph_node.add_child(texture_rect)
		_create_label("uv", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D, -1)
		_create_label("lod", graph_node, VisualShaderNode.PORT_TYPE_SCALAR, -1)
		_create_label("sampler2D", graph_node, VisualShaderNode.PORT_TYPE_SAMPLER, -1)
		_create_multi_output("color", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	#region Colors
	elif vsn is VisualShaderNodeColorOp:
		if not ops.is_empty():
			vsn.operator = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Screen", VisualShaderNodeColorOp.OP_SCREEN)
		option_button.add_item("Difference", VisualShaderNodeColorOp.OP_DIFFERENCE)
		option_button.add_item("Darken", VisualShaderNodeColorOp.OP_DARKEN)
		option_button.add_item("Lighten", VisualShaderNodeColorOp.OP_LIGHTEN)
		option_button.add_item("Overlay", VisualShaderNodeColorOp.OP_OVERLAY)
		option_button.add_item("Dodge", VisualShaderNodeColorOp.OP_DODGE)
		option_button.add_item("Burn", VisualShaderNodeColorOp.OP_BURN)
		option_button.add_item("Soft light", VisualShaderNodeColorOp.OP_SOFT_LIGHT)
		option_button.add_item("Hard light", VisualShaderNodeColorOp.OP_HARD_LIGHT)
		option_button.select(vsn.operator)
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeColorOp.Operator): vsn.operator = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_label("a", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D, -1)
		_create_label("b", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D, -1)
		_create_multi_output("op", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif vsn is VisualShaderNodeColorFunc:
		if not ops.is_empty():
			vsn.function = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Grayscale", VisualShaderNodeColorFunc.FUNC_GRAYSCALE)
		option_button.add_item("HSV to RGB", VisualShaderNodeColorFunc.FUNC_HSV2RGB)
		option_button.add_item("RGB to HSV", VisualShaderNodeColorFunc.FUNC_RGB2HSV)
		option_button.add_item("Sepia", VisualShaderNodeColorFunc.FUNC_SEPIA)
		option_button.select(vsn.function)
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeColorOp.Operator): vsn.function = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_label("input", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D, -1)
		_create_multi_output("output", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	#endregion
	elif vsn is VisualShaderNodeInput:
		if not ops.is_empty():
			vsn.input_name = ops[0]
		_create_label("output", graph_node, -1, VisualShaderNode.PORT_TYPE_VECTOR_2D)

	elif vsn is VisualShaderNodeMix:
		var op_type := (vsn as VisualShaderNodeMix).op_type
		var option_button := OptionButton.new()
		option_button.add_item("Scalar", VisualShaderNodeMix.OP_TYPE_SCALAR)
		option_button.add_item("Vector2", VisualShaderNodeMix.OP_TYPE_VECTOR_2D)
		option_button.add_item("Vector2Scalar", VisualShaderNodeMix.OP_TYPE_VECTOR_2D_SCALAR)
		option_button.add_item("Vector3", VisualShaderNodeMix.OP_TYPE_VECTOR_3D)
		option_button.add_item("Vector3Scalar", VisualShaderNodeMix.OP_TYPE_VECTOR_3D_SCALAR)
		option_button.add_item("Vector4", VisualShaderNodeMix.OP_TYPE_VECTOR_4D)
		option_button.add_item("Vector4Scalar", VisualShaderNodeMix.OP_TYPE_VECTOR_4D_SCALAR)
		option_button.select(op_type)
		# TODO: Add logic for what happens when changing the op type
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeMix.OpType): vsn.op_type = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		if op_type == VisualShaderNodeMix.OP_TYPE_SCALAR:
			_create_label("a", graph_node, VisualShaderNode.PORT_TYPE_SCALAR, -1)
			_create_label("b", graph_node, VisualShaderNode.PORT_TYPE_SCALAR, -1)
			_create_label("weight", graph_node, VisualShaderNode.PORT_TYPE_SCALAR, -1)
			_create_label("mix", graph_node, -1, VisualShaderNode.PORT_TYPE_SCALAR)
		elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_2D:
			_create_label("a", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D, -1)
			_create_label("b", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D, -1)
			_create_label("weight", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D, -1)
			_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
		elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_2D_SCALAR:
			_create_label("a", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D, -1)
			_create_label("b", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D, -1)
			_create_label("weight", graph_node, VisualShaderNode.PORT_TYPE_SCALAR, -1)
			_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
		elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_3D:
			_create_label("a", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D, -1)
			_create_label("b", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D, -1)
			_create_label("weight", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D, -1)
			_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
		elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_3D_SCALAR:
			_create_label("a", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D, -1)
			_create_label("b", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D, -1)
			_create_label("weight", graph_node, VisualShaderNode.PORT_TYPE_SCALAR, -1)
			_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
		elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_4D:
			_create_label("a", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D, -1)
			_create_label("b", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D, -1)
			_create_label("weight", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D, -1)
			_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)
		elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_4D_SCALAR:
			_create_label("a", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D, -1)
			_create_label("b", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D, -1)
			_create_label("weight", graph_node, VisualShaderNode.PORT_TYPE_SCALAR, -1)
			_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	elif vsn is VisualShaderNodeUVFunc:
		_create_label("uv", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D, -1)
		var scale_hbox := HBoxContainer.new()
		var scale_v2 := ShaderLoader.VALUE_SLIDER_V2_TSCN.instantiate() as ValueSliderV2
		scale_v2.value = Vector2.ONE
		scale_v2.grid_columns = 2
		scale_hbox.add_child(scale_v2)
		var scale_label := Label.new()
		scale_label.text = "scale"
		scale_hbox.add_child(scale_label)
		graph_node.add_child(scale_hbox)
		graph_node.set_slot(1, true, VisualShaderNode.PORT_TYPE_VECTOR_2D, slot_colors[VisualShaderNode.PORT_TYPE_VECTOR_2D], false, -1, Color.TRANSPARENT)
		_create_label("offset", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D, -1)
		_create_label("uv", graph_node, -1, VisualShaderNode.PORT_TYPE_VECTOR_2D)

	graph_node.set_meta("visual_shader_node", vsn)
	graph_node.name = str(id)
	graph_node.position_offset = visual_shader.get_node_position(VisualShader.TYPE_FRAGMENT, id)
	graph_edit.add_child(graph_node)


func _create_label(text: String, graph_node: GraphNode, left_slot: VisualShaderNode.PortType, right_slot: VisualShaderNode.PortType) -> Label:
	var label := Label.new()
	label.text = text
	graph_node.add_child(label)
	var slot_index := graph_node.get_child_count() - 1
	graph_node.set_slot(slot_index, left_slot != -1, left_slot, get_color_type(left_slot), right_slot != -1, right_slot, get_color_type(right_slot))
	return label


func _create_multi_output(text: String, graph_node: GraphNode, right_slot: VisualShaderNode.PortType) -> void:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	hbox.add_child(label)
	var expand_button := TextureButton.new()
	expand_button.toggle_mode = true
	expand_button.texture_normal = VALUE_ARROW_RIGHT
	expand_button.texture_pressed = VALUE_ARROW
	hbox.add_child(expand_button)
	graph_node.add_child(hbox)
	var slot_index := graph_node.get_child_count() - 1
	graph_node.set_slot(slot_index, false, -1, get_color_type(-1), right_slot != -1, right_slot, get_color_type(right_slot))
	var labels: Array[Control]
	var red := _create_label("red", graph_node, -1, VisualShaderNode.PORT_TYPE_SCALAR)
	labels.append(red)
	var green := _create_label("green", graph_node, -1, VisualShaderNode.PORT_TYPE_SCALAR)
	labels.append(green)
	if right_slot > VisualShaderNode.PORT_TYPE_VECTOR_2D:
		var blue := _create_label("blue", graph_node, -1, VisualShaderNode.PORT_TYPE_SCALAR)
		labels.append(blue)
		if right_slot > VisualShaderNode.PORT_TYPE_VECTOR_3D:
			var alpha := _create_label("alpha", graph_node, -1, VisualShaderNode.PORT_TYPE_SCALAR)
			labels.append(alpha)
	expand_button.toggled.connect(_handle_extra_control_visibility.bind(labels))
	_handle_extra_control_visibility(expand_button.button_pressed, labels)


func _handle_extra_control_visibility(toggled_on: bool, controls: Array[Control]) -> void:
	for control in controls:
		control.visible = toggled_on


func _get_parameter_type(vsn: VisualShaderNodeParameter) -> VisualShaderNode.PortType:
	if vsn is VisualShaderNodeBooleanParameter:
		return VisualShaderNode.PORT_TYPE_BOOLEAN
	elif vsn is VisualShaderNodeIntParameter or vsn is VisualShaderNodeUIntParameter or vsn is VisualShaderNodeFloatParameter:
		return VisualShaderNode.PORT_TYPE_SCALAR
	elif vsn is VisualShaderNodeVec2Parameter:
		return VisualShaderNode.PORT_TYPE_VECTOR_2D
	elif vsn is VisualShaderNodeVec3Parameter:
		return VisualShaderNode.PORT_TYPE_VECTOR_3D
	elif vsn is VisualShaderNodeVec4Parameter or vsn is VisualShaderNodeColorParameter:
		return VisualShaderNode.PORT_TYPE_VECTOR_4D
	elif vsn is VisualShaderNodeTransformParameter:
		return VisualShaderNode.PORT_TYPE_TRANSFORM
	elif vsn is VisualShaderNodeTextureParameter:
		return VisualShaderNode.PORT_TYPE_SAMPLER
	return -1


func fill_add_options() -> void:
	#region Color
	add_options.push_back(AddOption.new("ColorFunc", "Color/Common", "VisualShaderNodeColorFunc", "Color function.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("ColorOp", "Color/Common", "VisualShaderNodeColorOp", "Color operator.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D))

	add_options.push_back(AddOption.new("Grayscale", "Color/Functions", "VisualShaderNodeColorFunc", "Grayscale function.", [ VisualShaderNodeColorFunc.FUNC_GRAYSCALE ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("HSV2RGB", "Color/Functions", "VisualShaderNodeColorFunc", "Converts HSV vector to RGB equivalent.", [ VisualShaderNodeColorFunc.FUNC_HSV2RGB, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("RGB2HSV", "Color/Functions", "VisualShaderNodeColorFunc", "Converts RGB vector to HSV equivalent.", [ VisualShaderNodeColorFunc.FUNC_RGB2HSV, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("Sepia", "Color/Functions", "VisualShaderNodeColorFunc", "Sepia function.", [ VisualShaderNodeColorFunc.FUNC_SEPIA ], VisualShaderNode.PORT_TYPE_VECTOR_3D))

	add_options.push_back(AddOption.new("Burn", "Color/Operators", "VisualShaderNodeColorOp", "Burn operator.", [ VisualShaderNodeColorOp.OP_BURN ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("Darken", "Color/Operators", "VisualShaderNodeColorOp", "Darken operator.", [ VisualShaderNodeColorOp.OP_DARKEN ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("Difference", "Color/Operators", "VisualShaderNodeColorOp", "Difference operator.", [ VisualShaderNodeColorOp.OP_DIFFERENCE ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("Dodge", "Color/Operators", "VisualShaderNodeColorOp", "Dodge operator.", [ VisualShaderNodeColorOp.OP_DODGE ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("HardLight", "Color/Operators", "VisualShaderNodeColorOp", "HardLight operator.", [ VisualShaderNodeColorOp.OP_HARD_LIGHT ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("Lighten", "Color/Operators", "VisualShaderNodeColorOp", "Lighten operator.", [ VisualShaderNodeColorOp.OP_LIGHTEN ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("Overlay", "Color/Operators", "VisualShaderNodeColorOp", "Overlay operator.", [ VisualShaderNodeColorOp.OP_OVERLAY ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("Screen", "Color/Operators", "VisualShaderNodeColorOp", "Screen operator.", [ VisualShaderNodeColorOp.OP_SCREEN ], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	add_options.push_back(AddOption.new("SoftLight", "Color/Operators", "VisualShaderNodeColorOp", "SoftLight operator.", [ VisualShaderNodeColorOp.OP_SOFT_LIGHT ], VisualShaderNode.PORT_TYPE_VECTOR_3D))

	add_options.push_back(AddOption.new("ColorConstant", "Color/Variables", "VisualShaderNodeColorConstant", "Color constant.", [], VisualShaderNode.PORT_TYPE_VECTOR_4D))
	add_options.push_back(AddOption.new("ColorParameter", "Color/Variables", "VisualShaderNodeColorParameter", "Color parameter.", [], VisualShaderNode.PORT_TYPE_VECTOR_4D))
	#endregion
	#region Input
	add_options.push_back(AddOption.new("Color", "Input/All", "VisualShaderNodeInput", "", [ "color" ], VisualShaderNode.PORT_TYPE_VECTOR_4D, -1))
	add_options.push_back(AddOption.new("TexturePixelSize", "Input/All", "VisualShaderNodeInput", "", [ "texture_pixel_size" ], VisualShaderNode.PORT_TYPE_VECTOR_2D, -1))
	add_options.push_back(AddOption.new("UV", "Input/All", "VisualShaderNodeInput", "", [ "uv" ], VisualShaderNode.PORT_TYPE_VECTOR_2D, -1))
	add_options.push_back(AddOption.new("Texture", "Input/All", "VisualShaderNodeInput", "", [ "texture" ], VisualShaderNode.PORT_TYPE_SAMPLER, -1))
	#endregion


func update_options_menu() -> void:
	var root := node_list_tree.create_item()
	var folders := {}  # String, TreeItem
	for i in add_options.size():
		var option := add_options[i]
		var path := option.category
		var subfolders := path.split("/")
		var category: TreeItem
		if not folders.has(path):
			category = root
			var path_temp := ""
			for j in subfolders.size():
				path_temp += subfolders[j]
				if not folders.has(path_temp):
					category = node_list_tree.create_item(category)
					category.set_selectable(0, false)
					#category.set_collapsed(!use_filter)
					category.set_text(0, subfolders[j])
					folders[path_temp] = category
				else:
					category = folders[path_temp]
		else:
			category = folders[path]
		var item := node_list_tree.create_item(category)
		#if (options[i].highend && low_driver) {
			#item->set_custom_color(0, unsupported_color)
		#} else if (options[i].highend) {
			#item->set_custom_color(0, supported_color)
		#}
		item.set_text(0, option.option_name)
		item.set_metadata(0, i)
		#if (is_first_item && use_filter):
			#item.select(0)
			#node_desc.set_text(options[i].description)
			#is_first_item = false
#
			#node_list_tree.get_window().get_ok_button().set_disabled(false)


func _on_node_list_tree_item_selected() -> void:
	node_list_tree.get_window().get_ok_button().set_disabled(false)


func _on_node_list_tree_nothing_selected() -> void:
	node_list_tree.get_window().get_ok_button().set_disabled(true)


func _on_effect_name_line_edit_text_changed(new_text: String) -> void:
	effect_name_line_edit.get_window().get_ok_button().set_disabled(new_text.is_empty())


func _on_create_effect_dialog_confirmed() -> void:
	new_effect(effect_name_line_edit.text)


func _on_create_node_dialog_confirmed() -> void:
	add_new_node(node_list_tree.get_selected().get_metadata(0))


func _on_graph_edit_connection_request(from_node_name: String, from_port: int, to_node_name: String, to_port: int) -> void:
	#var from_node := graph_edit.get_node(from_node_name) as GraphNode
	#var to_node := graph_edit.get_node(to_node_name) as GraphNode
	graph_edit.connect_node(from_node_name, from_port, to_node_name, to_port)
	#var vs_from_node := from_node.get_meta("visual_shader_node") as VisualShaderNode
	#var vs_to_node := to_node.get_meta("visual_shader_node") as VisualShaderNode
	var vs_from_node_id := int(from_node_name)
	var vs_to_node_id := int(to_node_name)
	visual_shader.connect_nodes(VisualShader.TYPE_FRAGMENT, vs_from_node_id, from_port, vs_to_node_id, to_port)
	_on_effect_changed()


func _on_graph_edit_disconnection_request(from_node_name: String, from_port: int, to_node_name: String, to_port: int) -> void:
	graph_edit.disconnect_node(from_node_name, from_port, to_node_name, to_port)
	var vs_from_node_id := int(from_node_name)
	var vs_to_node_id := int(to_node_name)
	visual_shader.disconnect_nodes(VisualShader.TYPE_FRAGMENT, vs_from_node_id, from_port, vs_to_node_id, to_port)
	_on_effect_changed()
