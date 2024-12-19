extends PanelContainer

const VALUE_ARROW := preload("res://assets/graphics/misc/value_arrow.svg")
const VALUE_ARROW_RIGHT := preload("res://assets/graphics/misc/value_arrow_right.svg")
const CLOSE := preload("res://assets/graphics/misc/close.svg")

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
var can_undo := false
var undo_redos := {}  ## Dictionary of [VisualShader] and [UndoRedo].
var undo_redo: UndoRedo:
	get():
		if is_instance_valid(visual_shader) and visual_shader in undo_redos:
			return undo_redos[visual_shader]
		return null
var add_options: Array[AddOption]
var visual_shader: VisualShader:
	set(value):
		if visual_shader == value:
			return
		visual_shader = value
		add_node_button.disabled = not is_instance_valid(visual_shader)
		graph_edit.clear_connections()
		for child in graph_edit.get_children():
			if child.name != "_connection_layer":
				graph_edit.remove_child(child)
				child.queue_free()
		await get_tree().process_frame
		if is_instance_valid(visual_shader):
			var node_list := visual_shader.get_node_list(VisualShader.Type.TYPE_FRAGMENT)
			for id in node_list:
				var vsn := visual_shader.get_node(VisualShader.TYPE_FRAGMENT, id)
				add_node(vsn, id)
			for connection in visual_shader.get_node_connections(VisualShader.TYPE_FRAGMENT):
				var from_node_name := str(connection.from_node)
				var to_node_name := str(connection.to_node)
				var to_port: int = connection.to_port
				graph_edit.connect_node(from_node_name, connection.from_port, to_node_name, to_port)
				var to_node := graph_edit.get_node(to_node_name) as GraphNode
				if to_node.has_meta(&"default_input_button_%s" % to_port):
					to_node.get_meta(&"default_input_button_%s" % to_port).visible = false
			for id in node_list:
				var vsn := visual_shader.get_node(VisualShader.TYPE_FRAGMENT, id)
				if vsn is VisualShaderNodeFrame:
					for attached_node in vsn.attached_nodes:
						graph_edit.attach_graph_element_to_frame(str(attached_node), str(id))
			if not visual_shader in undo_redos:
				undo_redos[visual_shader] = UndoRedo.new()

var effects_button: MenuButton
var add_node_button: Button
var spawn_node_in_position := Vector2.ZERO

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
	## TODO: Probably remove.
	var return_type: VisualShaderNode.PortType
	#int func = 0
	var highend := false
	#bool is_custom = false
	#bool is_native = false
	#int temp_idx = 0

	func _init(_option_name: String, _category: String, _type: String, _description: String, _ops := [], _return_type := VisualShaderNode.PORT_TYPE_SCALAR, _mode := -1, _highend := false) -> void:
		option_name = _option_name
		type = _type
		category = _category
		description = _description
		ops = _ops
		return_type = _return_type
		mode = _mode
		highend = _highend


func _ready() -> void:
	#region add_valid_connection_types
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR, VisualShaderNode.PortType.PORT_TYPE_SCALAR_INT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR, VisualShaderNode.PortType.PORT_TYPE_SCALAR_UINT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR, VisualShaderNode.PORT_TYPE_BOOLEAN)

	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR_INT, VisualShaderNode.PortType.PORT_TYPE_SCALAR)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR_INT, VisualShaderNode.PortType.PORT_TYPE_SCALAR_UINT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR_INT, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR_INT, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR_INT, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR_INT, VisualShaderNode.PORT_TYPE_BOOLEAN)

	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR_UINT, VisualShaderNode.PortType.PORT_TYPE_SCALAR)
	graph_edit.add_valid_connection_type(VisualShaderNode.PortType.PORT_TYPE_SCALAR_UINT, VisualShaderNode.PortType.PORT_TYPE_SCALAR_INT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR_UINT, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR_UINT, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR_UINT, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SCALAR_UINT, VisualShaderNode.PORT_TYPE_BOOLEAN)

	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_2D, VisualShaderNode.PORT_TYPE_SCALAR)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_2D, VisualShaderNode.PORT_TYPE_SCALAR_INT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_2D, VisualShaderNode.PORT_TYPE_SCALAR_UINT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_2D, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_2D, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_2D, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_2D, VisualShaderNode.PORT_TYPE_BOOLEAN)

	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_3D, VisualShaderNode.PORT_TYPE_SCALAR)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_3D, VisualShaderNode.PORT_TYPE_SCALAR_INT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_3D, VisualShaderNode.PORT_TYPE_SCALAR_UINT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_3D, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_3D, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_3D, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_3D, VisualShaderNode.PORT_TYPE_BOOLEAN)

	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_4D, VisualShaderNode.PORT_TYPE_SCALAR)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_4D, VisualShaderNode.PORT_TYPE_SCALAR_INT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_4D, VisualShaderNode.PORT_TYPE_SCALAR_UINT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_4D, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_4D, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_4D, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_VECTOR_4D, VisualShaderNode.PORT_TYPE_BOOLEAN)

	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_BOOLEAN, VisualShaderNode.PORT_TYPE_SCALAR)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_BOOLEAN, VisualShaderNode.PORT_TYPE_SCALAR_INT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_BOOLEAN, VisualShaderNode.PORT_TYPE_SCALAR_UINT)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_BOOLEAN, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_BOOLEAN, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_BOOLEAN, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_BOOLEAN, VisualShaderNode.PORT_TYPE_BOOLEAN)

	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_TRANSFORM, VisualShaderNode.PORT_TYPE_TRANSFORM)
	graph_edit.add_valid_connection_type(VisualShaderNode.PORT_TYPE_SAMPLER, VisualShaderNode.PORT_TYPE_SAMPLER)
	#endregion
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


func _input(event: InputEvent) -> void:
	if can_undo and is_instance_valid(undo_redo):
		if event.is_action_pressed(&"undo", true, true):
			undo_redo.undo()
			get_window().set_input_as_handled()
		if event.is_action_pressed(&"redo", true, true):
			undo_redo.redo()
			get_window().set_input_as_handled()


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
	visual_shader.resource_path = file_path
	ResourceSaver.save(visual_shader)
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
		if not is_instance_valid(vsn):
			return
		var id := visual_shader.get_valid_node_id(VisualShader.TYPE_FRAGMENT)
		undo_redo.create_action("Add node")
		undo_redo.add_do_method(visual_shader.add_node.bind(VisualShader.TYPE_FRAGMENT, vsn, spawn_node_in_position, id))
		undo_redo.add_do_method(add_node.bind(vsn, id, option.ops))
		undo_redo.add_do_method(_on_effect_changed)
		undo_redo.add_undo_method(delete_node.bind(str(id)))
		undo_redo.add_undo_method(_on_effect_changed)
		undo_redo.commit_action()


func add_node(vsn: VisualShaderNode, id: int, ops := []) -> void:
	var graph_node: GraphElement
	if vsn is VisualShaderNodeFrame:
		graph_node = GraphFrame.new()
	else:
		graph_node = GraphNode.new()
	graph_node.name = str(id)
	graph_node.title = vsn.get_class().replace("VisualShaderNode", "")
	graph_node.resizable = true
	graph_node.set_meta("visual_shader_node", vsn)  # TODO: Remove if not needed
	graph_node.position_offset = visual_shader.get_node_position(VisualShader.TYPE_FRAGMENT, id)
	graph_node.dragged.connect(move_node.bind(str(id)))
	if vsn is not VisualShaderNodeOutput:  # Add a close button if the node can be deleted.
		var close_button := TextureButton.new()
		close_button.texture_normal = CLOSE
		close_button.pressed.connect(_on_delete_request.bind((str(id))))
		graph_node.get_titlebar_hbox().add_child(close_button)
	if vsn is VisualShaderNodeOutput:
		_create_input("Color", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D)
		_create_input("Alpha", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D)
		_create_input("Normal", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D)
		_create_input("Normal Map", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D)
		_create_input("Normal Map Depth", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR)
		_create_input("Light Vertex", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D)
		_create_input("Shadow Vertex", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif vsn is VisualShaderNodeInput:
		if not ops.is_empty():
			vsn.input_name = ops[0]
		var port_type := VisualShaderNode.PORT_TYPE_VECTOR_2D
		if vsn.input_name in ["color"]:
			port_type = VisualShaderNode.PORT_TYPE_VECTOR_4D
		elif vsn.input_name in ["texture"]:
			port_type = VisualShaderNode.PORT_TYPE_SAMPLER
		_create_label(vsn.input_name, graph_node, VisualShaderNode.PORT_TYPE_MAX, port_type)
	elif vsn is VisualShaderNodeParameter:
		if not ops.is_empty():
			vsn.parameter_name = ops[0]
		var parameter_type := _get_parameter_type(vsn)
		if vsn.parameter_name.begins_with("PXO_"):
			graph_node.title = "Input"
			_create_label(vsn.parameter_name, graph_node, VisualShaderNode.PORT_TYPE_MAX, parameter_type)
		else:
			var line_edit := LineEdit.new()
			line_edit.text = vsn.parameter_name
			line_edit.text_changed.connect(func(text: String): vsn.parameter_name = text; _on_effect_changed())
			graph_node.add_child(line_edit)
			graph_node.set_slot(0, false, VisualShaderNode.PORT_TYPE_MAX, Color.TRANSPARENT, true, parameter_type, slot_colors[parameter_type])
	#region Constants
	elif vsn is VisualShaderNodeBooleanConstant:
		var button := CheckBox.new()
		button.text = "On"
		button.button_pressed = vsn.constant
		button.toggled.connect(func(toggled_on: bool): vsn.constant = toggled_on; _on_effect_changed())
		graph_node.add_child(button)
		graph_node.set_slot(0, false, VisualShaderNode.PORT_TYPE_MAX, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_BOOLEAN, slot_colors[VisualShaderNode.PORT_TYPE_BOOLEAN])
	elif vsn is VisualShaderNodeIntConstant or vsn is VisualShaderNodeUIntConstant:
		var slider := ValueSlider.new()
		slider.custom_minimum_size = Vector2(32, 32)
		slider.value = vsn.constant
		slider.value_changed.connect(func(value: int): vsn.constant = value; _on_effect_changed())
		graph_node.add_child(slider)
		graph_node.set_slot(0, false, VisualShaderNode.PORT_TYPE_MAX, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_SCALAR, slot_colors[VisualShaderNode.PORT_TYPE_SCALAR])
	elif vsn is VisualShaderNodeFloatConstant:
		var slider := ValueSlider.new()
		slider.custom_minimum_size = Vector2(32, 32)
		slider.step = 0.001
		slider.value = vsn.constant
		slider.value_changed.connect(func(value: float): vsn.constant = value; _on_effect_changed())
		graph_node.add_child(slider)
		graph_node.set_slot(0, false, VisualShaderNode.PORT_TYPE_MAX, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_SCALAR, slot_colors[VisualShaderNode.PORT_TYPE_SCALAR])
	elif vsn is VisualShaderNodeVec2Constant:
		var slider := ShaderLoader.VALUE_SLIDER_V2_TSCN.instantiate() as ValueSliderV2
		slider.value = vsn.constant
		slider.value_changed.connect(func(value: Vector2): vsn.constant = value; _on_effect_changed())
		graph_node.add_child(slider)
		graph_node.set_slot(0, false, VisualShaderNode.PORT_TYPE_MAX, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_VECTOR_2D, slot_colors[VisualShaderNode.PORT_TYPE_VECTOR_2D])
	elif vsn is VisualShaderNodeVec3Constant:
		var slider := ShaderLoader.VALUE_SLIDER_V3_TSCN.instantiate() as ValueSliderV3
		slider.value = vsn.constant
		slider.value_changed.connect(func(value: Vector3): vsn.constant = value; _on_effect_changed())
		graph_node.add_child(slider)
		graph_node.set_slot(0, false, VisualShaderNode.PORT_TYPE_MAX, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_VECTOR_3D, slot_colors[VisualShaderNode.PORT_TYPE_VECTOR_3D])
	elif vsn is VisualShaderNodeColorConstant or vsn is VisualShaderNodeVec4Constant:
		var color_picker_button := ColorPickerButton.new()
		color_picker_button.custom_minimum_size = Vector2(20, 20)
		color_picker_button.color = vsn.constant
		color_picker_button.color_changed.connect(func(color: Color): vsn.constant = color; _on_effect_changed())
		graph_node.add_child(color_picker_button)
		graph_node.set_slot(0, false, VisualShaderNode.PORT_TYPE_MAX, Color.TRANSPARENT, true, VisualShaderNode.PORT_TYPE_VECTOR_4D, slot_colors[VisualShaderNode.PORT_TYPE_VECTOR_4D])
	#endregion
	#region Conditionals
	elif vsn is VisualShaderNodeIs:
		if not ops.is_empty():
			vsn.function = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Infinite", VisualShaderNodeIs.FUNC_IS_INF)
		option_button.add_item("Not A Number", VisualShaderNodeIs.FUNC_IS_NAN)
		option_button.select(option_button.get_item_index(vsn.function))
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeIs.Function):
				vsn.function = id_selected
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
		_create_input("input", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_multi_output("output", graph_node, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif vsn is VisualShaderNodeIf:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("tolerance", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_input("a == b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 3)
		_create_input("a > b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 4)
		_create_input("a < b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 5)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif vsn is VisualShaderNodeSwitch:
		vsn.set("expanded_output_ports", [0])
		if not ops.is_empty():
			vsn.op_type = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Float", VisualShaderNodeSwitch.OP_TYPE_FLOAT)
		option_button.add_item("Int", VisualShaderNodeSwitch.OP_TYPE_INT)
		option_button.add_item("UInt", VisualShaderNodeSwitch.OP_TYPE_UINT)
		option_button.add_item("Vector2", VisualShaderNodeSwitch.OP_TYPE_VECTOR_2D)
		option_button.add_item("Vector3", VisualShaderNodeSwitch.OP_TYPE_VECTOR_3D)
		option_button.add_item("Vector4", VisualShaderNodeSwitch.OP_TYPE_VECTOR_4D)
		option_button.add_item("Boolean", VisualShaderNodeSwitch.OP_TYPE_BOOLEAN)
		option_button.add_item("Transform", VisualShaderNodeSwitch.OP_TYPE_TRANSFORM)
		option_button.select(option_button.get_item_index(vsn.op_type))
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeSwitch.OpType):
				vsn.op_type = id_selected
				_create_switch_node(graph_node, vsn)
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
		_create_switch_node(graph_node, vsn)
	elif vsn is VisualShaderNodeCompare:
		vsn.set("expanded_output_ports", [0])
		if not ops.is_empty():
			vsn.function = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Float", VisualShaderNodeCompare.CTYPE_SCALAR)
		option_button.add_item("Int", VisualShaderNodeCompare.CTYPE_SCALAR_INT)
		option_button.add_item("UInt", VisualShaderNodeCompare.CTYPE_SCALAR_UINT)
		option_button.add_item("Vector2", VisualShaderNodeCompare.CTYPE_VECTOR_2D)
		option_button.add_item("Vector3", VisualShaderNodeCompare.CTYPE_VECTOR_3D)
		option_button.add_item("Vector4", VisualShaderNodeCompare.CTYPE_VECTOR_4D)
		option_button.add_item("Boolean", VisualShaderNodeCompare.CTYPE_BOOLEAN)
		option_button.add_item("Transform", VisualShaderNodeCompare.CTYPE_TRANSFORM)
		option_button.select(option_button.get_item_index(vsn.type))
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeCompare.ComparisonType):
				vsn.type = id_selected
				_create_compare_node(graph_node, vsn)
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
		var comparison_option_button := OptionButton.new()
		comparison_option_button.add_item("Equal (a == b)", VisualShaderNodeCompare.FUNC_EQUAL)
		comparison_option_button.add_item("Not equal (a != b)", VisualShaderNodeCompare.FUNC_NOT_EQUAL)
		comparison_option_button.add_item("Greater than (a > b)", VisualShaderNodeCompare.FUNC_GREATER_THAN)
		comparison_option_button.add_item("Greater than or equal (a >= b)", VisualShaderNodeCompare.FUNC_GREATER_THAN_EQUAL)
		comparison_option_button.add_item("Less than (a < b)", VisualShaderNodeCompare.FUNC_LESS_THAN)
		comparison_option_button.add_item("Less than or equal (a <= b)", VisualShaderNodeCompare.FUNC_LESS_THAN_EQUAL)
		comparison_option_button.select(comparison_option_button.get_item_index(vsn.function))
		comparison_option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeCompare.Function):
				vsn.function = id_selected
				_create_compare_node(graph_node, vsn)
				_on_effect_changed()
		)
		graph_node.add_child(comparison_option_button)
		_create_compare_node(graph_node, vsn)
	#endregion
	#region Integers
	elif vsn is VisualShaderNodeIntOp:
		if not ops.is_empty():
			vsn.operator = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Add", VisualShaderNodeIntOp.OP_ADD)
		option_button.add_item("Subtract", VisualShaderNodeIntOp.OP_SUB)
		option_button.add_item("Multiply", VisualShaderNodeIntOp.OP_MUL)
		option_button.add_item("Divide", VisualShaderNodeIntOp.OP_DIV)
		option_button.add_item("Remainder", VisualShaderNodeIntOp.OP_MOD)
		option_button.add_item("Max", VisualShaderNodeIntOp.OP_MAX)
		option_button.add_item("Min", VisualShaderNodeIntOp.OP_MIN)
		option_button.add_item("Bitwise AND", VisualShaderNodeIntOp.OP_BITWISE_AND)
		option_button.add_item("Bitwise OR", VisualShaderNodeIntOp.OP_BITWISE_OR)
		option_button.add_item("Bitwise XOR", VisualShaderNodeIntOp.OP_BITWISE_XOR)
		option_button.add_item("Bitwise Left Shift", VisualShaderNodeIntOp.OP_BITWISE_LEFT_SHIFT)
		option_button.add_item("Bitwise Right Shift", VisualShaderNodeIntOp.OP_BITWISE_RIGHT_SHIFT)
		option_button.select(option_button.get_item_index(vsn.operator))
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeIntOp.Operator): vsn.operator = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_INT, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_INT, 1)
		_create_multi_output("op", graph_node, VisualShaderNode.PORT_TYPE_SCALAR_INT)
	elif vsn is VisualShaderNodeIntFunc:
		if not ops.is_empty():
			vsn.function = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Abs", VisualShaderNodeIntFunc.FUNC_ABS)
		option_button.add_item("Negate", VisualShaderNodeIntFunc.FUNC_NEGATE)
		option_button.add_item("Sign", VisualShaderNodeIntFunc.FUNC_SIGN)
		option_button.add_item("Bitwise NOT", VisualShaderNodeIntFunc.FUNC_BITWISE_NOT)
		option_button.select(option_button.get_item_index(vsn.function))
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeIntFunc.Function): vsn.function = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_input("input", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_INT, 0)
		_create_multi_output("output", graph_node, VisualShaderNode.PORT_TYPE_SCALAR_INT)
	#endregion
	#region Unsigned integers
	elif vsn is VisualShaderNodeUIntOp:
		if not ops.is_empty():
			vsn.operator = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Add", VisualShaderNodeUIntOp.OP_ADD)
		option_button.add_item("Subtract", VisualShaderNodeUIntOp.OP_SUB)
		option_button.add_item("Multiply", VisualShaderNodeUIntOp.OP_MUL)
		option_button.add_item("Divide", VisualShaderNodeUIntOp.OP_DIV)
		option_button.add_item("Remainder", VisualShaderNodeUIntOp.OP_MOD)
		option_button.add_item("Max", VisualShaderNodeUIntOp.OP_MAX)
		option_button.add_item("Min", VisualShaderNodeUIntOp.OP_MIN)
		option_button.add_item("Bitwise AND", VisualShaderNodeUIntOp.OP_BITWISE_AND)
		option_button.add_item("Bitwise OR", VisualShaderNodeUIntOp.OP_BITWISE_OR)
		option_button.add_item("Bitwise XOR", VisualShaderNodeUIntOp.OP_BITWISE_XOR)
		option_button.add_item("Bitwise Left Shift", VisualShaderNodeUIntOp.OP_BITWISE_LEFT_SHIFT)
		option_button.add_item("Bitwise Right Shift", VisualShaderNodeUIntOp.OP_BITWISE_RIGHT_SHIFT)
		option_button.select(option_button.get_item_index(vsn.operator))
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeUIntOp.Operator): vsn.operator = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_UINT, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_UINT, 1)
		_create_multi_output("op", graph_node, VisualShaderNode.PORT_TYPE_SCALAR_UINT)
	elif vsn is VisualShaderNodeUIntFunc:
		if not ops.is_empty():
			vsn.function = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Negate", VisualShaderNodeUIntFunc.FUNC_NEGATE)
		option_button.add_item("Bitwise NOT", VisualShaderNodeUIntFunc.FUNC_BITWISE_NOT)
		option_button.select(option_button.get_item_index(vsn.function))
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeUIntFunc.Function): vsn.function = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_input("input", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_UINT, 0)
		_create_multi_output("output", graph_node, VisualShaderNode.PORT_TYPE_SCALAR_UINT)
	#endregion
	#region Floats
	elif vsn is VisualShaderNodeFloatOp:
		if not ops.is_empty():
			vsn.operator = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Add", VisualShaderNodeFloatOp.OP_ADD)
		option_button.add_item("Subtract", VisualShaderNodeFloatOp.OP_SUB)
		option_button.add_item("Multiply", VisualShaderNodeFloatOp.OP_MUL)
		option_button.add_item("Divide", VisualShaderNodeFloatOp.OP_DIV)
		option_button.add_item("Remainder", VisualShaderNodeFloatOp.OP_MOD)
		option_button.add_item("Power", VisualShaderNodeFloatOp.OP_POW)
		option_button.add_item("Max", VisualShaderNodeFloatOp.OP_MAX)
		option_button.add_item("Min", VisualShaderNodeFloatOp.OP_MIN)
		option_button.add_item("ATan2", VisualShaderNodeFloatOp.OP_ATAN2)
		option_button.add_item("Step", VisualShaderNodeFloatOp.OP_STEP)
		option_button.select(option_button.get_item_index(vsn.operator))
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeFloatOp.Operator): vsn.operator = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_multi_output("op", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
	elif vsn is VisualShaderNodeFloatFunc:
		if not ops.is_empty():
			vsn.function = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Sin", VisualShaderNodeFloatFunc.FUNC_SIN)
		option_button.add_item("Cos", VisualShaderNodeFloatFunc.FUNC_COS)
		option_button.add_item("Tan", VisualShaderNodeFloatFunc.FUNC_TAN)
		option_button.add_item("ASin", VisualShaderNodeFloatFunc.FUNC_ASIN)
		option_button.add_item("ACos", VisualShaderNodeFloatFunc.FUNC_ACOS)
		option_button.add_item("ATan", VisualShaderNodeFloatFunc.FUNC_ATAN)
		option_button.add_item("SinH", VisualShaderNodeFloatFunc.FUNC_SINH)
		option_button.add_item("CosH", VisualShaderNodeFloatFunc.FUNC_COSH)
		option_button.add_item("TanH", VisualShaderNodeFloatFunc.FUNC_TANH)
		option_button.add_item("Log", VisualShaderNodeFloatFunc.FUNC_LOG)
		option_button.add_item("Exp", VisualShaderNodeFloatFunc.FUNC_EXP)
		option_button.add_item("Square root", VisualShaderNodeFloatFunc.FUNC_SQRT)
		option_button.add_item("Abs", VisualShaderNodeFloatFunc.FUNC_ABS)
		option_button.add_item("Sign", VisualShaderNodeFloatFunc.FUNC_SIGN)
		option_button.add_item("Floor", VisualShaderNodeFloatFunc.FUNC_FLOOR)
		option_button.add_item("Round", VisualShaderNodeFloatFunc.FUNC_ROUND)
		option_button.add_item("Ceil", VisualShaderNodeFloatFunc.FUNC_CEIL)
		option_button.add_item("Fract", VisualShaderNodeFloatFunc.FUNC_FRACT)
		option_button.add_item("Saturate", VisualShaderNodeFloatFunc.FUNC_SATURATE)
		option_button.add_item("Negate", VisualShaderNodeFloatFunc.FUNC_NEGATE)
		option_button.add_item("ASinH", VisualShaderNodeFloatFunc.FUNC_ASINH)
		option_button.add_item("ACosH", VisualShaderNodeFloatFunc.FUNC_ACOSH)
		option_button.add_item("ATanH", VisualShaderNodeFloatFunc.FUNC_ATANH)
		option_button.add_item("Degrees", VisualShaderNodeFloatFunc.FUNC_DEGREES)
		option_button.add_item("Exp2", VisualShaderNodeFloatFunc.FUNC_EXP2)
		option_button.add_item("Inverse square root", VisualShaderNodeFloatFunc.FUNC_INVERSE_SQRT)
		option_button.add_item("Log2", VisualShaderNodeFloatFunc.FUNC_LOG2)
		option_button.add_item("Radians", VisualShaderNodeFloatFunc.FUNC_RADIANS)
		option_button.add_item("Reciprocal", VisualShaderNodeFloatFunc.FUNC_RECIPROCAL)
		option_button.add_item("Roundeven", VisualShaderNodeFloatFunc.FUNC_ROUNDEVEN)
		option_button.add_item("Trunc", VisualShaderNodeFloatFunc.FUNC_TRUNC)
		option_button.add_item("One minus", VisualShaderNodeFloatFunc.FUNC_ONEMINUS)
		option_button.select(option_button.get_item_index(vsn.function))
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeFloatFunc.Function): vsn.function = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_input("input", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_multi_output("output", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
	#endregion
	#region Vectors
	elif vsn is VisualShaderNodeVectorBase:
		vsn.set("expanded_output_ports", [0])
		if ops.size() > 1:
			vsn.op_type = ops[1]
		var option_button := OptionButton.new()
		option_button.add_item("Vector2", VisualShaderNodeVectorBase.OP_TYPE_VECTOR_2D)
		option_button.add_item("Vector3", VisualShaderNodeVectorBase.OP_TYPE_VECTOR_3D)
		option_button.add_item("Vector4", VisualShaderNodeVectorBase.OP_TYPE_VECTOR_4D)
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeVectorBase.OpType):
				vsn.op_type = id_selected
				_create_vector_node(graph_node, vsn)
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
		_create_vector_node(graph_node, vsn, ops)
		option_button.select(option_button.get_item_index(vsn.op_type))
	#endregion
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
		option_button.select(option_button.get_item_index(vsn.operator))
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeColorOp.Operator): vsn.operator = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_multi_output("op", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif vsn is VisualShaderNodeColorFunc:
		if not ops.is_empty():
			vsn.function = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Grayscale", VisualShaderNodeColorFunc.FUNC_GRAYSCALE)
		option_button.add_item("HSV to RGB", VisualShaderNodeColorFunc.FUNC_HSV2RGB)
		option_button.add_item("RGB to HSV", VisualShaderNodeColorFunc.FUNC_RGB2HSV)
		option_button.add_item("Sepia", VisualShaderNodeColorFunc.FUNC_SEPIA)
		option_button.select(option_button.get_item_index(vsn.function))
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeColorFunc.Function): vsn.function = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_input("input", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_multi_output("output", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	#endregion
	#region Extra functions
	elif vsn is VisualShaderNodeDotProduct:
		vsn.set("expanded_output_ports", [0])
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_multi_output("output", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
	elif vsn is VisualShaderNodeClamp:
		vsn.set("expanded_output_ports", [0])
		if not ops.is_empty():
			vsn.op_type = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Float", VisualShaderNodeClamp.OP_TYPE_FLOAT)
		option_button.add_item("Int", VisualShaderNodeClamp.OP_TYPE_INT)
		option_button.add_item("UInt", VisualShaderNodeClamp.OP_TYPE_UINT)
		option_button.add_item("Vector2", VisualShaderNodeClamp.OP_TYPE_VECTOR_2D)
		option_button.add_item("Vector3", VisualShaderNodeClamp.OP_TYPE_VECTOR_3D)
		option_button.add_item("Vector4", VisualShaderNodeClamp.OP_TYPE_VECTOR_4D)
		option_button.select(option_button.get_item_index(vsn.op_type))
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeClamp.OpType):
				vsn.op_type = id_selected
				_create_clamp_node(graph_node, vsn)
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
		_create_clamp_node(graph_node, vsn)
	elif vsn is VisualShaderNodeMultiplyAdd:
		vsn.set("expanded_output_ports", [0])
		if not ops.is_empty():
			vsn.op_type = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Scalar", VisualShaderNodeMultiplyAdd.OP_TYPE_SCALAR)
		option_button.add_item("Vector2", VisualShaderNodeMultiplyAdd.OP_TYPE_VECTOR_2D)
		option_button.add_item("Vector3", VisualShaderNodeMultiplyAdd.OP_TYPE_VECTOR_3D)
		option_button.add_item("Vector4", VisualShaderNodeMultiplyAdd.OP_TYPE_VECTOR_4D)
		option_button.select(option_button.get_item_index(vsn.op_type))
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeMultiplyAdd.OpType):
				vsn.op_type = id_selected
				_create_multiply_add_node(graph_node, vsn)
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
		_create_multiply_add_node(graph_node, vsn)
	elif vsn is VisualShaderNodeMix:
		vsn.set("expanded_output_ports", [0])
		if not ops.is_empty():
			vsn.op_type = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Scalar", VisualShaderNodeMix.OP_TYPE_SCALAR)
		option_button.add_item("Vector2", VisualShaderNodeMix.OP_TYPE_VECTOR_2D)
		option_button.add_item("Vector2Scalar", VisualShaderNodeMix.OP_TYPE_VECTOR_2D_SCALAR)
		option_button.add_item("Vector3", VisualShaderNodeMix.OP_TYPE_VECTOR_3D)
		option_button.add_item("Vector3Scalar", VisualShaderNodeMix.OP_TYPE_VECTOR_3D_SCALAR)
		option_button.add_item("Vector4", VisualShaderNodeMix.OP_TYPE_VECTOR_4D)
		option_button.add_item("Vector4Scalar", VisualShaderNodeMix.OP_TYPE_VECTOR_4D_SCALAR)
		option_button.select(option_button.get_item_index(vsn.op_type))
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeMix.OpType):
				vsn.op_type = id_selected
				_create_mix_node(graph_node, vsn)
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
		_create_mix_node(graph_node, vsn)
	elif vsn is VisualShaderNodeStep:
		vsn.set("expanded_output_ports", [0])
		if not ops.is_empty():
			vsn.op_type = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Scalar", VisualShaderNodeStep.OP_TYPE_SCALAR)
		option_button.add_item("Vector2", VisualShaderNodeStep.OP_TYPE_VECTOR_2D)
		option_button.add_item("Vector2Scalar", VisualShaderNodeStep.OP_TYPE_VECTOR_2D_SCALAR)
		option_button.add_item("Vector3", VisualShaderNodeStep.OP_TYPE_VECTOR_3D)
		option_button.add_item("Vector3Scalar", VisualShaderNodeStep.OP_TYPE_VECTOR_3D_SCALAR)
		option_button.add_item("Vector4", VisualShaderNodeStep.OP_TYPE_VECTOR_4D)
		option_button.add_item("Vector4Scalar", VisualShaderNodeStep.OP_TYPE_VECTOR_4D_SCALAR)
		option_button.select(option_button.get_item_index(vsn.op_type))
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeStep.OpType):
				vsn.op_type = id_selected
				_create_step_node(graph_node, vsn)
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
		_create_step_node(graph_node, vsn)
	elif vsn is VisualShaderNodeSmoothStep:
		vsn.set("expanded_output_ports", [0])
		if not ops.is_empty():
			vsn.op_type = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Scalar", VisualShaderNodeSmoothStep.OP_TYPE_SCALAR)
		option_button.add_item("Vector2", VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_2D)
		option_button.add_item("Vector2Scalar", VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_2D_SCALAR)
		option_button.add_item("Vector3", VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_3D)
		option_button.add_item("Vector3Scalar", VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_3D_SCALAR)
		option_button.add_item("Vector4", VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_4D)
		option_button.add_item("Vector4Scalar", VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_4D_SCALAR)
		option_button.select(option_button.get_item_index(vsn.op_type))
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeSmoothStep.OpType):
				vsn.op_type = id_selected
				_create_smooth_step_node(graph_node, vsn)
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
		_create_smooth_step_node(graph_node, vsn)
	#endregion
	#region Utility
	elif vsn is VisualShaderNodeRandomRange:
		_create_input("seed", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("min", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("max", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_multi_output("value", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
	elif vsn is VisualShaderNodeRotationByAxis:
		_create_input("input", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("angle", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("axis", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 2)
		_create_label("output", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_VECTOR_3D)
		_create_label("rotationMat", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_TRANSFORM)
	#endregion
	#region Textures
	elif vsn is VisualShaderNodeTexture:
		# TODO: Add texture changing logic
		var texture_rect := TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(20, 20)
		texture_rect.texture = vsn.texture
		graph_node.add_child(texture_rect)
		_create_label("uv", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D, VisualShaderNode.PORT_TYPE_MAX)
		_create_label("lod", graph_node, VisualShaderNode.PORT_TYPE_SCALAR, VisualShaderNode.PORT_TYPE_MAX)
		_create_label("sampler2D", graph_node, VisualShaderNode.PORT_TYPE_SAMPLER, VisualShaderNode.PORT_TYPE_MAX)
		_create_multi_output("color", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	elif vsn is VisualShaderNodeUVFunc:
		vsn.set("expanded_output_ports", [0])
		if not ops.is_empty():
			vsn.function = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Panning", VisualShaderNodeUVFunc.FUNC_PANNING)
		option_button.add_item("Scaling", VisualShaderNodeUVFunc.FUNC_SCALING)
		option_button.select(option_button.get_item_index(vsn.function))
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeUVFunc.Function):
				vsn.function = id_selected
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
		_create_input("uv", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 0)
		_create_input("scale", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		var input_text := "offset" if vsn.function == VisualShaderNodeUVFunc.FUNC_PANNING else "pivot"
		_create_input(input_text, graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 2)
		_create_multi_output("uv", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	elif vsn is VisualShaderNodeUVPolarCoord:
		vsn.set("expanded_output_ports", [0])
		_create_input("uv", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 0)
		_create_input("scale", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		_create_input("zoom_strength", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_input("repeat", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 3)
		_create_multi_output("uv", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	#endregion

	graph_edit.add_child(graph_node)


func _on_delete_request(graph_node_name: StringName) -> void:
	var id := int(String(graph_node_name))
	var vsn := visual_shader.get_node(VisualShader.TYPE_FRAGMENT, id)
	undo_redo.create_action("Remove node")
	undo_redo.add_do_method(delete_node.bind(graph_node_name))
	undo_redo.add_do_method(_on_effect_changed)
	undo_redo.add_undo_method(visual_shader.add_node.bind(VisualShader.TYPE_FRAGMENT, vsn, spawn_node_in_position, id))
	undo_redo.add_undo_method(add_node.bind(vsn, id))
	undo_redo.add_undo_method(_on_effect_changed)
	undo_redo.commit_action()


func delete_node(graph_node_name: StringName) -> void:
	var graph_node := graph_edit.get_node(String(graph_node_name))
	visual_shader.remove_node(VisualShader.TYPE_FRAGMENT, int(String(graph_node_name)))
	graph_node.queue_free()


func move_node(from: Vector2, to: Vector2, graph_node_name: StringName) -> void:
	var id := int(String(graph_node_name))
	undo_redo.create_action("Move node")
	undo_redo.add_do_method(
		func():
			var graph_node := graph_edit.get_node(String(graph_node_name))
			graph_node.position_offset = to
	)
	undo_redo.add_do_method(visual_shader.set_node_position.bind(VisualShader.TYPE_FRAGMENT, id, to))
	undo_redo.add_do_method(_on_effect_changed)
	undo_redo.add_undo_method(
		func():
			var graph_node := graph_edit.get_node(String(graph_node_name))
			graph_node.position_offset = from
	)
	undo_redo.add_undo_method(visual_shader.set_node_position.bind(VisualShader.TYPE_FRAGMENT, id, from))
	undo_redo.add_undo_method(_on_effect_changed)
	undo_redo.commit_action()


func _create_label(text: String, graph_node: GraphNode, left_slot: VisualShaderNode.PortType, right_slot: VisualShaderNode.PortType) -> Label:
	var label := Label.new()
	label.text = text
	if right_slot != VisualShaderNode.PORT_TYPE_MAX:
		if left_slot != VisualShaderNode.PORT_TYPE_MAX:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	graph_node.add_child(label)
	var slot_index := graph_node.get_child_count() - 1
	graph_node.set_slot(slot_index, left_slot != VisualShaderNode.PORT_TYPE_MAX, left_slot, get_color_type(left_slot), right_slot != VisualShaderNode.PORT_TYPE_MAX, right_slot, get_color_type(right_slot))
	return label


func _create_input(text: String, graph_node: GraphNode, vsn: VisualShaderNode, left_slot: VisualShaderNode.PortType, port_index := -1) -> void:
	var hbox := HBoxContainer.new()
	graph_node.add_child(hbox)
	var slot_index := graph_node.get_child_count() - 1
	if port_index == -1:
		port_index = slot_index
	var default_parameter = vsn.get_input_port_default_value(port_index)

	if left_slot <= VisualShaderNode.PORT_TYPE_SCALAR_UINT:
		var slider := ValueSlider.new()
		slider.custom_minimum_size = Vector2(100, 32)
		slider.step = 0.001
		slider.allow_greater = true
		slider.allow_lesser = left_slot != VisualShaderNode.PORT_TYPE_SCALAR_UINT
		if default_parameter != null:
			slider.value = default_parameter
		slider.value_changed.connect(func(value: float): vsn.set_input_port_default_value(port_index, value); _on_effect_changed())
		hbox.add_child(slider)
		graph_node.set_meta(&"default_input_button_%s" % port_index, slider)
	elif left_slot == VisualShaderNode.PORT_TYPE_VECTOR_2D:
		var slider := ShaderLoader.VALUE_SLIDER_V2_TSCN.instantiate() as ValueSliderV2
		slider.custom_minimum_size = Vector2(150, 32)
		slider.grid_columns = 2
		slider.step = 0.001
		slider.allow_greater = true
		slider.allow_lesser = true
		if default_parameter != null:
			slider.value = default_parameter
		slider.value_changed.connect(func(value: Vector2): vsn.set_input_port_default_value(port_index, value))
		hbox.add_child(slider)
		graph_node.set_meta(&"default_input_button_%s" % port_index, slider)
	elif left_slot == VisualShaderNode.PORT_TYPE_VECTOR_3D:
		var slider := ShaderLoader.VALUE_SLIDER_V3_TSCN.instantiate() as ValueSliderV3
		slider.custom_minimum_size = Vector2(200, 32)
		slider.grid_columns = 3
		slider.step = 0.001
		slider.allow_greater = true
		slider.allow_lesser = true
		if default_parameter != null:
			slider.value = default_parameter
		slider.value_changed.connect(func(value: Vector3): vsn.set_input_port_default_value(port_index, value))
		hbox.add_child(slider)
		graph_node.set_meta(&"default_input_button_%s" % port_index, slider)
	elif left_slot == VisualShaderNode.PORT_TYPE_VECTOR_4D:
		var cbp := ColorPickerButton.new()
		cbp.custom_minimum_size = Vector2(50, 50)
		if default_parameter != null:
			if default_parameter is Quaternion or default_parameter is Vector4:
				cbp.color = Color(default_parameter.w, default_parameter.x, default_parameter.y, default_parameter.z)
		cbp.color_changed.connect(func(value: Color): vsn.set_input_port_default_value(port_index, value))
		hbox.add_child(cbp)
		graph_node.set_meta(&"default_input_button_%s" % port_index, cbp)
	elif left_slot == VisualShaderNode.PORT_TYPE_BOOLEAN:
		var box := CheckBox.new()
		if default_parameter != null:
			box.button_pressed = default_parameter
		box.toggled.connect(func(value: bool): vsn.set_input_port_default_value(port_index, value))
		hbox.add_child(box)
		graph_node.set_meta(&"default_input_button_%s" % port_index, box)
	var label := Label.new()
	label.text = text
	hbox.add_child(label)
	graph_node.set_slot(slot_index, left_slot != VisualShaderNode.PORT_TYPE_MAX, left_slot, get_color_type(left_slot), false, VisualShaderNode.PORT_TYPE_MAX, get_color_type(VisualShaderNode.PORT_TYPE_MAX))


func _create_multi_output(text: String, graph_node: GraphNode, right_slot: VisualShaderNode.PortType) -> void:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_END
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.text = text
	hbox.add_child(label)
	var expand_button := TextureButton.new()
	expand_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	expand_button.toggle_mode = true
	expand_button.texture_normal = VALUE_ARROW_RIGHT
	expand_button.texture_pressed = VALUE_ARROW
	hbox.add_child(expand_button)
	graph_node.add_child(hbox)
	var slot_index := graph_node.get_child_count() - 1
	graph_node.set_slot(slot_index, false, VisualShaderNode.PORT_TYPE_MAX, get_color_type(VisualShaderNode.PORT_TYPE_MAX), right_slot != VisualShaderNode.PORT_TYPE_MAX, right_slot, get_color_type(right_slot))
	if right_slot >= VisualShaderNode.PORT_TYPE_VECTOR_2D and right_slot <= VisualShaderNode.PORT_TYPE_VECTOR_4D:
		var labels: Array[Control]
		var red := _create_label("red", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_SCALAR)
		labels.append(red)
		var green := _create_label("green", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_SCALAR)
		labels.append(green)
		if right_slot > VisualShaderNode.PORT_TYPE_VECTOR_2D:
			var blue := _create_label("blue", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_SCALAR)
			labels.append(blue)
			if right_slot > VisualShaderNode.PORT_TYPE_VECTOR_3D:
				var alpha := _create_label("alpha", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_SCALAR)
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
	return VisualShaderNode.PORT_TYPE_MAX


func _get_vector_op_type(vsn: VisualShaderNodeVectorBase) -> VisualShaderNode.PortType:
	var op_type := vsn.op_type
	if op_type == VisualShaderNodeVectorBase.OP_TYPE_VECTOR_2D:
		return VisualShaderNode.PORT_TYPE_VECTOR_2D
	elif op_type == VisualShaderNodeVectorBase.OP_TYPE_VECTOR_3D:
		return VisualShaderNode.PORT_TYPE_VECTOR_3D
	elif op_type == VisualShaderNodeVectorBase.OP_TYPE_VECTOR_4D:
		return VisualShaderNode.PORT_TYPE_VECTOR_4D
	return VisualShaderNode.PORT_TYPE_MAX


func _create_clamp_node(graph_node: GraphNode, vsn: VisualShaderNodeClamp) -> void:
	var children := graph_node.get_children(true)
	for i in range(2, children.size()):
		var child := children[i]
		graph_node.remove_child(child)
		child.queue_free()
	var op_type := vsn.op_type
	if op_type == VisualShaderNodeClamp.OP_TYPE_FLOAT:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("min", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("max", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
	elif op_type == VisualShaderNodeClamp.OP_TYPE_INT:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_INT, 0)
		_create_input("min", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_INT, 1)
		_create_input("max", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_INT, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_SCALAR_INT)
	elif op_type == VisualShaderNodeClamp.OP_TYPE_UINT:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_UINT, 0)
		_create_input("min", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_UINT, 1)
		_create_input("max", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_UINT, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_SCALAR_UINT)
	elif op_type == VisualShaderNodeClamp.OP_TYPE_VECTOR_2D:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 0)
		_create_input("min", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		_create_input("max", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	elif op_type == VisualShaderNodeClamp.OP_TYPE_VECTOR_3D:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("min", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_input("max", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif op_type == VisualShaderNodeClamp.OP_TYPE_VECTOR_4D:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 0)
		_create_input("min", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 1)
		_create_input("max", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)

	_check_output_connections_validity(graph_node)


func _create_multiply_add_node(graph_node: GraphNode, vsn: VisualShaderNodeMultiplyAdd) -> void:
	var children := graph_node.get_children(true)
	for i in range(2, children.size()):
		var child := children[i]
		graph_node.remove_child(child)
		child.queue_free()
	var op_type := vsn.op_type
	if op_type == VisualShaderNodeMultiplyAdd.OP_TYPE_SCALAR:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("b(*)", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("c(+)", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
	elif op_type == VisualShaderNodeMultiplyAdd.OP_TYPE_VECTOR_2D:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 0)
		_create_input("b(*)", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		_create_input("c(+)", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	elif op_type == VisualShaderNodeMultiplyAdd.OP_TYPE_VECTOR_3D:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("b(*)", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_input("c(+)", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif op_type == VisualShaderNodeMultiplyAdd.OP_TYPE_VECTOR_4D:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 0)
		_create_input("b(*)", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 1)
		_create_input("c(+)", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)

	_check_output_connections_validity(graph_node)


func _create_mix_node(graph_node: GraphNode, vsn: VisualShaderNodeMix) -> void:
	var children := graph_node.get_children(true)
	for i in range(2, children.size()):
		var child := children[i]
		graph_node.remove_child(child)
		child.queue_free()
	var op_type := vsn.op_type
	if op_type == VisualShaderNodeMix.OP_TYPE_SCALAR:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("weight", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_label("mix", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_SCALAR)
	elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_2D:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		_create_input("weight", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 2)
		_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_2D_SCALAR:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		_create_input("weight", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_3D:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_input("weight", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 2)
		_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_3D_SCALAR:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_input("weight", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_4D:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 1)
		_create_input("weight", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 2)
		_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	elif op_type == VisualShaderNodeMix.OP_TYPE_VECTOR_4D_SCALAR:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 1)
		_create_input("weight", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_multi_output("mix", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)

	_check_output_connections_validity(graph_node)


func _create_step_node(graph_node: GraphNode, vsn: VisualShaderNodeStep) -> void:
	var children := graph_node.get_children(true)
	for i in range(2, children.size()):
		var child := children[i]
		graph_node.remove_child(child)
		child.queue_free()
	var op_type := vsn.op_type
	if op_type == VisualShaderNodeStep.OP_TYPE_SCALAR:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_SCALAR)
	elif op_type == VisualShaderNodeStep.OP_TYPE_VECTOR_2D:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 0)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	elif op_type == VisualShaderNodeStep.OP_TYPE_VECTOR_2D_SCALAR:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	elif op_type == VisualShaderNodeStep.OP_TYPE_VECTOR_3D:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif op_type == VisualShaderNodeStep.OP_TYPE_VECTOR_3D_SCALAR:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif op_type == VisualShaderNodeStep.OP_TYPE_VECTOR_4D:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 0)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 1)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	elif op_type == VisualShaderNodeStep.OP_TYPE_VECTOR_4D_SCALAR:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 1)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)

	_check_output_connections_validity(graph_node)


func _create_smooth_step_node(graph_node: GraphNode, vsn: VisualShaderNodeSmoothStep) -> void:
	var children := graph_node.get_children(true)
	for i in range(2, children.size()):
		var child := children[i]
		graph_node.remove_child(child)
		child.queue_free()
	var op_type := vsn.op_type
	if op_type == VisualShaderNodeSmoothStep.OP_TYPE_SCALAR:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("edge1", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_SCALAR)
	elif op_type == VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_2D:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 0)
		_create_input("edge1", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	elif op_type == VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_2D_SCALAR:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("edge1", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_2D)
	elif op_type == VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_3D:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("edge1", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif op_type == VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_3D_SCALAR:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("edge1", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_3D)
	elif op_type == VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_4D:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 0)
		_create_input("edge1", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 1)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)
	elif op_type == VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_4D_SCALAR:
		_create_input("edge0", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("edge1", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 2)
		_create_multi_output("result", graph_node, VisualShaderNode.PORT_TYPE_VECTOR_4D)

	_check_output_connections_validity(graph_node)


func _create_switch_node(graph_node: GraphNode, vsn: VisualShaderNodeSwitch) -> void:
	var children := graph_node.get_children(true)
	for i in range(2, children.size()):
		var child := children[i]
		graph_node.remove_child(child)
		child.queue_free()
	var op_type := vsn.op_type
	if op_type == VisualShaderNodeSwitch.OP_TYPE_FLOAT:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 0)
		_create_input("true", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		_create_input("false", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeSwitch.OP_TYPE_INT:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 0)
		_create_input("true", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_INT, 1)
		_create_input("false", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_INT, 2)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeSwitch.OP_TYPE_UINT:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 0)
		_create_input("true", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_UINT, 1)
		_create_input("false", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_UINT, 2)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeSwitch.OP_TYPE_VECTOR_2D:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 0)
		_create_input("true", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		_create_input("false", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 2)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeSwitch.OP_TYPE_VECTOR_3D:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 0)
		_create_input("true", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_input("false", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 2)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeSwitch.OP_TYPE_VECTOR_4D:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 0)
		_create_input("true", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 1)
		_create_input("false", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 2)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeSwitch.OP_TYPE_BOOLEAN:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 0)
		_create_input("true", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 1)
		_create_input("false", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 2)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeSwitch.OP_TYPE_TRANSFORM:
		_create_input("value", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 0)
		_create_input("true", graph_node, vsn, VisualShaderNode.PORT_TYPE_TRANSFORM, 1)
		_create_input("false", graph_node, vsn, VisualShaderNode.PORT_TYPE_TRANSFORM, 2)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)

	_check_output_connections_validity(graph_node)


func _create_compare_node(graph_node: GraphNode, vsn: VisualShaderNodeCompare) -> void:
	var children := graph_node.get_children(true)
	for i in range(3, children.size()):
		var child := children[i]
		graph_node.remove_child(child)
		child.queue_free()
	graph_node.clear_all_slots()
	var op_type := vsn.type
	if op_type >= VisualShaderNodeCompare.CTYPE_VECTOR_2D and op_type <= VisualShaderNodeCompare.CTYPE_VECTOR_4D:
		var option_button := OptionButton.new()
		option_button.add_item("All", VisualShaderNodeCompare.COND_ALL)
		option_button.add_item("Any", VisualShaderNodeCompare.COND_ANY)
		option_button.select(option_button.get_item_index(vsn.condition))
		option_button.item_selected.connect(
			func(id_selected: VisualShaderNodeCompare.Condition):
				vsn.condition = id_selected
				_on_effect_changed()
		)
		graph_node.add_child(option_button)
	if op_type == VisualShaderNodeCompare.CTYPE_SCALAR:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
		if vsn.function == VisualShaderNodeCompare.FUNC_EQUAL or vsn.function == VisualShaderNodeCompare.FUNC_NOT_EQUAL:
			_create_input("tolerance", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeCompare.CTYPE_SCALAR_INT:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_INT, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_INT, 1)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeCompare.CTYPE_SCALAR_UINT:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_UINT, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR_UINT, 1)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeCompare.CTYPE_VECTOR_2D:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_2D, 1)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeCompare.CTYPE_VECTOR_3D:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_3D, 1)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeCompare.CTYPE_VECTOR_4D:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_VECTOR_4D, 1)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
	elif op_type == VisualShaderNodeCompare.CTYPE_BOOLEAN:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_BOOLEAN, 1)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
		if vsn.function >= VisualShaderNodeCompare.FUNC_GREATER_THAN:
			var label := Label.new()
			label.text = "Invalid comparison function for that type."
			graph_node.add_child(label)
	elif op_type == VisualShaderNodeCompare.CTYPE_TRANSFORM:
		_create_input("a", graph_node, vsn, VisualShaderNode.PORT_TYPE_TRANSFORM, 0)
		_create_input("b", graph_node, vsn, VisualShaderNode.PORT_TYPE_TRANSFORM, 1)
		_create_label("result", graph_node, VisualShaderNode.PORT_TYPE_MAX, VisualShaderNode.PORT_TYPE_BOOLEAN)
		if vsn.function >= VisualShaderNodeCompare.FUNC_GREATER_THAN:
			var label := Label.new()
			label.text = "Invalid comparison function for that type."
			graph_node.add_child(label)

	_check_output_connections_validity(graph_node)


func _check_output_connections_validity(graph_node: GraphNode) -> void:
	var output_connections := graph_edit.get_connection_list().filter(func(dict: Dictionary): return dict.from_node == graph_node.name)
	for output_connection in output_connections:
		var from_port: int = output_connection.from_port
		if from_port >= graph_node.get_output_port_count():  # The connection is no longer valid
			graph_edit.disconnect_node(output_connection.from_node, from_port, output_connection.to_node, output_connection.to_port)
			var vs_from_node_id := int(String(output_connection.from_node))
			var vs_to_node_id := int(String(output_connection.to_node))
			visual_shader.disconnect_nodes(VisualShader.TYPE_FRAGMENT, vs_from_node_id, from_port, vs_to_node_id, output_connection.to_port)


func _create_vector_node(graph_node: GraphNode, vsn: VisualShaderNodeVectorBase, ops := []) -> void:
	var children := graph_node.get_children(true)
	for i in range(2, children.size()):
		var child := children[i]
		graph_node.remove_child(child)
		child.queue_free()
	if vsn is VisualShaderNodeVectorOp:
		if not ops.is_empty():
			vsn.operator = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Add", VisualShaderNodeVectorOp.OP_ADD)
		option_button.add_item("Subtract", VisualShaderNodeVectorOp.OP_SUB)
		option_button.add_item("Multiply", VisualShaderNodeVectorOp.OP_MUL)
		option_button.add_item("Divide", VisualShaderNodeVectorOp.OP_DIV)
		option_button.add_item("Remainder", VisualShaderNodeVectorOp.OP_MOD)
		option_button.add_item("Power", VisualShaderNodeVectorOp.OP_POW)
		option_button.add_item("Max", VisualShaderNodeVectorOp.OP_MAX)
		option_button.add_item("Min", VisualShaderNodeVectorOp.OP_MIN)
		option_button.add_item("Cross", VisualShaderNodeVectorOp.OP_CROSS)
		option_button.add_item("ATan2", VisualShaderNodeVectorOp.OP_ATAN2)
		option_button.add_item("Reflect", VisualShaderNodeVectorOp.OP_REFLECT)
		option_button.add_item("Step", VisualShaderNodeVectorOp.OP_STEP)
		option_button.select(option_button.get_item_index(vsn.operator))
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeVectorOp.Operator): vsn.operator = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_input("a", graph_node, vsn, _get_vector_op_type(vsn), 0)
		_create_input("b", graph_node, vsn, _get_vector_op_type(vsn), 1)
		_create_multi_output("op", graph_node, _get_vector_op_type(vsn))
	elif vsn is VisualShaderNodeVectorFunc:
		if not ops.is_empty():
			vsn.function = ops[0]
		var option_button := OptionButton.new()
		option_button.add_item("Normalize", VisualShaderNodeVectorFunc.FUNC_NORMALIZE)
		option_button.add_item("Sin", VisualShaderNodeVectorFunc.FUNC_SIN)
		option_button.add_item("Cos", VisualShaderNodeVectorFunc.FUNC_COS)
		option_button.add_item("Tan", VisualShaderNodeVectorFunc.FUNC_TAN)
		option_button.add_item("ASin", VisualShaderNodeVectorFunc.FUNC_ASIN)
		option_button.add_item("ACos", VisualShaderNodeVectorFunc.FUNC_ACOS)
		option_button.add_item("ATan", VisualShaderNodeVectorFunc.FUNC_ATAN)
		option_button.add_item("SinH", VisualShaderNodeVectorFunc.FUNC_SINH)
		option_button.add_item("CosH", VisualShaderNodeVectorFunc.FUNC_COSH)
		option_button.add_item("TanH", VisualShaderNodeVectorFunc.FUNC_TANH)
		option_button.add_item("Log", VisualShaderNodeVectorFunc.FUNC_LOG)
		option_button.add_item("Exp", VisualShaderNodeVectorFunc.FUNC_EXP)
		option_button.add_item("Square root", VisualShaderNodeVectorFunc.FUNC_SQRT)
		option_button.add_item("Abs", VisualShaderNodeVectorFunc.FUNC_ABS)
		option_button.add_item("Sign", VisualShaderNodeVectorFunc.FUNC_SIGN)
		option_button.add_item("Floor", VisualShaderNodeVectorFunc.FUNC_FLOOR)
		option_button.add_item("Round", VisualShaderNodeVectorFunc.FUNC_ROUND)
		option_button.add_item("Ceil", VisualShaderNodeVectorFunc.FUNC_CEIL)
		option_button.add_item("Fract", VisualShaderNodeVectorFunc.FUNC_FRACT)
		option_button.add_item("Saturate", VisualShaderNodeVectorFunc.FUNC_SATURATE)
		option_button.add_item("Negate", VisualShaderNodeVectorFunc.FUNC_NEGATE)
		option_button.add_item("ASinH", VisualShaderNodeVectorFunc.FUNC_ASINH)
		option_button.add_item("ACosH", VisualShaderNodeVectorFunc.FUNC_ACOSH)
		option_button.add_item("ATanH", VisualShaderNodeVectorFunc.FUNC_ATANH)
		option_button.add_item("Degrees", VisualShaderNodeVectorFunc.FUNC_DEGREES)
		option_button.add_item("Exp2", VisualShaderNodeVectorFunc.FUNC_EXP2)
		option_button.add_item("Inverse square root", VisualShaderNodeVectorFunc.FUNC_INVERSE_SQRT)
		option_button.add_item("Log2", VisualShaderNodeVectorFunc.FUNC_LOG2)
		option_button.add_item("Radians", VisualShaderNodeVectorFunc.FUNC_RADIANS)
		option_button.add_item("Reciprocal", VisualShaderNodeVectorFunc.FUNC_RECIPROCAL)
		option_button.add_item("Roundeven", VisualShaderNodeVectorFunc.FUNC_ROUNDEVEN)
		option_button.add_item("Trunc", VisualShaderNodeVectorFunc.FUNC_TRUNC)
		option_button.add_item("One minus", VisualShaderNodeVectorFunc.FUNC_ONEMINUS)
		option_button.select(option_button.get_item_index(vsn.function))
		option_button.item_selected.connect(func(id_selected: VisualShaderNodeFloatFunc.Function): vsn.function = id_selected; _on_effect_changed())
		graph_node.add_child(option_button)
		_create_input("input", graph_node, vsn, _get_vector_op_type(vsn), 0)
		_create_multi_output("output", graph_node, _get_vector_op_type(vsn))
	elif vsn is VisualShaderNodeVectorCompose:
		if not ops.is_empty():
			vsn.op_type = ops[0]
		_create_input("x", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 0)
		if vsn.op_type >= VisualShaderNodeVectorBase.OP_TYPE_VECTOR_2D:
			_create_input("y", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 1)
			if vsn.op_type >= VisualShaderNodeVectorBase.OP_TYPE_VECTOR_3D:
				_create_input("z", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 2)
				if vsn.op_type == VisualShaderNodeVectorBase.OP_TYPE_VECTOR_4D:
					_create_input("w", graph_node, vsn, VisualShaderNode.PORT_TYPE_SCALAR, 3)
		_create_multi_output("vec", graph_node, _get_vector_op_type(vsn))
	elif vsn is VisualShaderNodeVectorDecompose:
		if not ops.is_empty():
			vsn.op_type = ops[0]
		_create_input("vec", graph_node, vsn, _get_vector_op_type(vsn), 0)
		_create_multi_output("x", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
		if vsn.op_type >= VisualShaderNodeVectorBase.OP_TYPE_VECTOR_2D:
			_create_multi_output("y", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
			if vsn.op_type >= VisualShaderNodeVectorBase.OP_TYPE_VECTOR_3D:
				_create_multi_output("z", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
				if vsn.op_type == VisualShaderNodeVectorBase.OP_TYPE_VECTOR_4D:
					_create_multi_output("w", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
	elif vsn is VisualShaderNodeVectorLen:
		if not ops.is_empty():
			vsn.op_type = ops[0]
		_create_input("vec", graph_node, vsn, _get_vector_op_type(vsn), 0)
		_create_multi_output("length", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
	elif vsn is VisualShaderNodeVectorDistance:
		if not ops.is_empty():
			vsn.op_type = ops[0]
		_create_input("a", graph_node, vsn, _get_vector_op_type(vsn), 0)
		_create_input("b", graph_node, vsn, _get_vector_op_type(vsn), 1)
		_create_multi_output("distance", graph_node, VisualShaderNode.PORT_TYPE_SCALAR)
	elif vsn is VisualShaderNodeFaceForward:
		if not ops.is_empty():
			vsn.op_type = ops[0]
		_create_input("N", graph_node, vsn, _get_vector_op_type(vsn), 0)
		_create_input("I", graph_node, vsn, _get_vector_op_type(vsn), 1)
		_create_input("Nref", graph_node, vsn, _get_vector_op_type(vsn), 2)
		_create_multi_output("", graph_node, _get_vector_op_type(vsn))
	elif vsn is VisualShaderNodeVectorRefract:
		if not ops.is_empty():
			vsn.op_type = ops[0]
		_create_input("I", graph_node, vsn, _get_vector_op_type(vsn), 0)
		_create_input("N", graph_node, vsn, _get_vector_op_type(vsn), 1)
		_create_input("eta", graph_node, vsn, _get_vector_op_type(vsn), 2)
		_create_multi_output("", graph_node, _get_vector_op_type(vsn))

	_check_output_connections_validity(graph_node)


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
	#region Conditional
	const compare_func_desc := "Returns the boolean result of the %s comparison between two parameters."

	add_options.push_back(AddOption.new("Equal (==)", "Conditional/Functions", "VisualShaderNodeCompare", compare_func_desc % "Equal (==)", [ VisualShaderNodeCompare.FUNC_EQUAL ], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("GreaterThan (>)", "Conditional/Functions", "VisualShaderNodeCompare", compare_func_desc % "Greater Than (>)", [ VisualShaderNodeCompare.FUNC_GREATER_THAN ], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("GreaterThanEqual (>=)", "Conditional/Functions", "VisualShaderNodeCompare", compare_func_desc %  "Greater Than or Equal (>=)", [ VisualShaderNodeCompare.FUNC_GREATER_THAN_EQUAL ], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("If", "Conditional/Functions", "VisualShaderNodeIf", "Returns an associated vector if the provided scalars are equal, greater or less.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("IsInf", "Conditional/Functions", "VisualShaderNodeIs", "Returns the boolean result of the comparison between INF and a scalar parameter.", [ VisualShaderNodeIs.FUNC_IS_INF ], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("IsNaN", "Conditional/Functions", "VisualShaderNodeIs", "Returns the boolean result of the comparison between NaN and a scalar parameter.", [ VisualShaderNodeIs.FUNC_IS_NAN ], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("LessThan (<)", "Conditional/Functions", "VisualShaderNodeCompare", compare_func_desc %  "Less Than (<)", [ VisualShaderNodeCompare.FUNC_LESS_THAN ], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("LessThanEqual (<=)", "Conditional/Functions", "VisualShaderNodeCompare", compare_func_desc %  "Less Than or Equal (<=)", [ VisualShaderNodeCompare.FUNC_LESS_THAN_EQUAL ], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("NotEqual (!=)", "Conditional/Functions", "VisualShaderNodeCompare", compare_func_desc %  "Not Equal (!=)", [ VisualShaderNodeCompare.FUNC_NOT_EQUAL ], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("SwitchVector2D (==)", "Conditional/Functions", "VisualShaderNodeSwitch", "Returns an associated 2D vector if the provided boolean value is true or false.", [ VisualShaderNodeSwitch.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("SwitchVector3D (==)", "Conditional/Functions", "VisualShaderNodeSwitch", "Returns an associated 3D vector if the provided boolean value is true or false.", [ VisualShaderNodeSwitch.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("SwitchVector4D (==)", "Conditional/Functions", "VisualShaderNodeSwitch", "Returns an associated 4D vector if the provided boolean value is true or false.", [ VisualShaderNodeSwitch.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("SwitchBool (==)", "Conditional/Functions", "VisualShaderNodeSwitch", "Returns an associated boolean if the provided boolean value is true or false.", [ VisualShaderNodeSwitch.OP_TYPE_BOOLEAN ], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("SwitchFloat (==)", "Conditional/Functions", "VisualShaderNodeSwitch", "Returns an associated floating-point scalar if the provided boolean value is true or false.", [ VisualShaderNodeSwitch.OP_TYPE_FLOAT ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("SwitchInt (==)", "Conditional/Functions", "VisualShaderNodeSwitch", "Returns an associated integer scalar if the provided boolean value is true or false.", [ VisualShaderNodeSwitch.OP_TYPE_INT ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("SwitchTransform (==)", "Conditional/Functions", "VisualShaderNodeSwitch", "Returns an associated transform if the provided boolean value is true or false.", [ VisualShaderNodeSwitch.OP_TYPE_TRANSFORM ], VisualShaderNode.PORT_TYPE_TRANSFORM));
	add_options.push_back(AddOption.new("SwitchUInt (==)", "Conditional/Functions", "VisualShaderNodeSwitch", "Returns an associated unsigned integer scalar if the provided boolean value is true or false.", [ VisualShaderNodeSwitch.OP_TYPE_UINT ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));

	add_options.push_back(AddOption.new("Compare (==)", "Conditional/Common", "VisualShaderNodeCompare", "Returns the boolean result of the comparison between two parameters.", [], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("Is", "Conditional/Common", "VisualShaderNodeIs", "Returns the boolean result of the comparison between INF (or NaN) and a scalar parameter.", [], VisualShaderNode.PORT_TYPE_BOOLEAN));

	add_options.push_back(AddOption.new("BooleanConstant", "Conditional/Variables", "VisualShaderNodeBooleanConstant", "Boolean constant.", [], VisualShaderNode.PORT_TYPE_BOOLEAN));
	add_options.push_back(AddOption.new("BooleanParameter", "Conditional/Variables", "VisualShaderNodeBooleanParameter", "Boolean parameter.", [], VisualShaderNode.PORT_TYPE_BOOLEAN));
	#endregion
	#region Input
	add_options.push_back(AddOption.new("Color", "Input/All", "VisualShaderNodeInput", "", [ "color" ], VisualShaderNode.PORT_TYPE_VECTOR_4D, -1))
	add_options.push_back(AddOption.new("TexturePixelSize", "Input/All", "VisualShaderNodeInput", "", [ "texture_pixel_size" ], VisualShaderNode.PORT_TYPE_VECTOR_2D, -1))
	add_options.push_back(AddOption.new("Time", "Input/All", "VisualShaderNodeFloatParameter", "", [ "PXO_time" ], VisualShaderNode.PORT_TYPE_SCALAR, -1))
	add_options.push_back(AddOption.new("UV", "Input/All", "VisualShaderNodeInput", "", [ "uv" ], VisualShaderNode.PORT_TYPE_VECTOR_2D, -1))
	add_options.push_back(AddOption.new("Texture", "Input/Fragment", "VisualShaderNodeInput", "", [ "texture" ], VisualShaderNode.PORT_TYPE_SAMPLER, -1))
	#endregion
	#region Scalar
	add_options.push_back(AddOption.new("FloatFunc", "Scalar/Common", "VisualShaderNodeFloatFunc", ("Float function."), [], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("FloatOp", "Scalar/Common", "VisualShaderNodeFloatOp", ("Float operator."), [], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("IntFunc", "Scalar/Common", "VisualShaderNodeIntFunc", ("Integer function."), [], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("IntOp", "Scalar/Common", "VisualShaderNodeIntOp", ("Integer operator."), [], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("UIntFunc", "Scalar/Common", "VisualShaderNodeUIntFunc", ("Unsigned integer function."), [], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("UIntOp", "Scalar/Common", "VisualShaderNodeUIntOp", ("Unsigned integer operator."), [], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	# FUNCTIONS
	add_options.push_back(AddOption.new("Abs", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the absolute value of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_ABS ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Abs", "Scalar/Functions", "VisualShaderNodeIntFunc", ("Returns the absolute value of the parameter."), [ VisualShaderNodeIntFunc.FUNC_ABS ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("ACos", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the arc-cosine of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_ACOS ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("ACosH", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the inverse hyperbolic cosine of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_ACOSH ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("ASin", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the arc-sine of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_ASIN ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("ASinH", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the inverse hyperbolic sine of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_ASINH ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("ATan", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the arc-tangent of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_ATAN ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("ATan2", "Scalar/Functions", "VisualShaderNodeFloatOp", ("Returns the arc-tangent of the parameters."), [ VisualShaderNodeFloatOp.OP_ATAN2 ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("ATanH", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the inverse hyperbolic tangent of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_ATANH ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("BitwiseNOT", "Scalar/Functions", "VisualShaderNodeIntFunc", ("Returns the result of bitwise NOT (~a) operation on the integer."), [ VisualShaderNodeIntFunc.FUNC_BITWISE_NOT ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("BitwiseNOT", "Scalar/Functions", "VisualShaderNodeUIntFunc", ("Returns the result of bitwise NOT (~a) operation on the unsigned integer."), [ VisualShaderNodeUIntFunc.FUNC_BITWISE_NOT ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("Ceil", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Finds the nearest integer that is greater than or equal to the parameter."), [ VisualShaderNodeFloatFunc.FUNC_CEIL ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Clamp", "Scalar/Functions", "VisualShaderNodeClamp", ("Constrains a value to lie between two further values."), [ VisualShaderNodeClamp.OP_TYPE_FLOAT ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Clamp", "Scalar/Functions", "VisualShaderNodeClamp", ("Constrains a value to lie between two further values."), [ VisualShaderNodeClamp.OP_TYPE_INT ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("Clamp", "Scalar/Functions", "VisualShaderNodeClamp", ("Constrains a value to lie between two further values."), [ VisualShaderNodeClamp.OP_TYPE_UINT ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("Cos", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the cosine of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_COS ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("CosH", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the hyperbolic cosine of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_COSH ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Degrees", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Converts a quantity in radians to degrees."), [ VisualShaderNodeFloatFunc.FUNC_DEGREES ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("DFdX", "Scalar/Functions", "VisualShaderNodeDerivativeFunc", ("(Fragment/Light mode only) (Scalar) Derivative in 'x' using local differencing."), [ VisualShaderNodeDerivativeFunc.FUNC_X, VisualShaderNodeDerivativeFunc.OP_TYPE_SCALAR ], VisualShaderNode.PORT_TYPE_SCALAR, -1, true))
	add_options.push_back(AddOption.new("DFdY", "Scalar/Functions", "VisualShaderNodeDerivativeFunc", ("(Fragment/Light mode only) (Scalar) Derivative in 'y' using local differencing."), [ VisualShaderNodeDerivativeFunc.FUNC_Y, VisualShaderNodeDerivativeFunc.OP_TYPE_SCALAR ], VisualShaderNode.PORT_TYPE_SCALAR, -1, true))
	add_options.push_back(AddOption.new("Exp", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Base-e Exponential."), [ VisualShaderNodeFloatFunc.FUNC_EXP ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Exp2", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Base-2 Exponential."), [ VisualShaderNodeFloatFunc.FUNC_EXP2 ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Floor", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Finds the nearest integer less than or equal to the parameter."), [ VisualShaderNodeFloatFunc.FUNC_FLOOR ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Fract", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Computes the fractional part of the argument."), [ VisualShaderNodeFloatFunc.FUNC_FRACT ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("InverseSqrt", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the inverse of the square root of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_INVERSE_SQRT ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Log", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Natural logarithm."), [ VisualShaderNodeFloatFunc.FUNC_LOG ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Log2", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Base-2 logarithm."), [ VisualShaderNodeFloatFunc.FUNC_LOG2 ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Max", "Scalar/Functions", "VisualShaderNodeFloatOp", ("Returns the greater of two values."), [ VisualShaderNodeFloatOp.OP_MAX ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Min", "Scalar/Functions", "VisualShaderNodeFloatOp", ("Returns the lesser of two values."), [ VisualShaderNodeFloatOp.OP_MIN ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Mix", "Scalar/Functions", "VisualShaderNodeMix", ("Linear interpolation between two scalars."), [ VisualShaderNodeMix.OP_TYPE_SCALAR ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("MultiplyAdd (a * b + c)", "Scalar/Functions", "VisualShaderNodeMultiplyAdd", ("Performs a fused multiply-add operation (a * b + c) on scalars."), [ VisualShaderNodeMultiplyAdd.OP_TYPE_SCALAR ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Negate (*-1)", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the opposite value of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_NEGATE ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Negate (*-1)", "Scalar/Functions", "VisualShaderNodeIntFunc", ("Returns the opposite value of the parameter."), [ VisualShaderNodeIntFunc.FUNC_NEGATE ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("Negate (*-1)", "Scalar/Functions", "VisualShaderNodeUIntFunc", ("Returns the opposite value of the parameter."), [ VisualShaderNodeUIntFunc.FUNC_NEGATE ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("OneMinus (1-)", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("1.0 - scalar"), [ VisualShaderNodeFloatFunc.FUNC_ONEMINUS ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Pow", "Scalar/Functions", "VisualShaderNodeFloatOp", ("Returns the value of the first parameter raised to the power of the second."), [ VisualShaderNodeFloatOp.OP_POW ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Radians", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Converts a quantity in degrees to radians."), [ VisualShaderNodeFloatFunc.FUNC_RADIANS ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Reciprocal", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("1.0 / scalar"), [ VisualShaderNodeFloatFunc.FUNC_RECIPROCAL ], VisualShaderNode.PORT_TYPE_SCALAR));
	#add_options.push_back(AddOption.new("Remap", "Scalar/Functions", "VisualShaderNodeRemap", ("Remaps a value from the input range to the output range."), [ VisualShaderNodeRemap.OP_TYPE_SCALAR ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Round", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Finds the nearest integer to the parameter."), [ VisualShaderNodeFloatFunc.FUNC_ROUND ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("RoundEven", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Finds the nearest even integer to the parameter."), [ VisualShaderNodeFloatFunc.FUNC_ROUNDEVEN ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Saturate", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Clamps the value between 0.0 and 1.0."), [ VisualShaderNodeFloatFunc.FUNC_SATURATE ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Sign", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Extracts the sign of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_SIGN ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Sign", "Scalar/Functions", "VisualShaderNodeIntFunc", ("Extracts the sign of the parameter."), [ VisualShaderNodeIntFunc.FUNC_SIGN ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("Sin", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the sine of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_SIN ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("SinH", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the hyperbolic sine of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_SINH ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Sqrt", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the square root of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_SQRT ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("SmoothStep", "Scalar/Functions", "VisualShaderNodeSmoothStep", ("SmoothStep function( scalar(edge0), scalar(edge1), scalar(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge0' and 1.0 if x is larger than 'edge1'. Otherwise the return value is interpolated between 0.0 and 1.0 using Hermite polynomials."), [ VisualShaderNodeSmoothStep.OP_TYPE_SCALAR ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Step", "Scalar/Functions", "VisualShaderNodeStep", ("Step function( scalar(edge), scalar(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge' and otherwise 1.0."), [ VisualShaderNodeStep.OP_TYPE_SCALAR ], VisualShaderNode.PORT_TYPE_SCALAR))
	add_options.push_back(AddOption.new("Sum", "Scalar/Functions", "VisualShaderNodeDerivativeFunc", ("(Fragment/Light mode only) (Scalar) Sum of absolute derivative in 'x' and 'y'."), [ VisualShaderNodeDerivativeFunc.FUNC_SUM, VisualShaderNodeDerivativeFunc.OP_TYPE_SCALAR ], VisualShaderNode.PORT_TYPE_SCALAR, -1, true))
	add_options.push_back(AddOption.new("Tan", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the tangent of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_TAN ], VisualShaderNode.PORT_TYPE_SCALAR))
	add_options.push_back(AddOption.new("TanH", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Returns the hyperbolic tangent of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_TANH ], VisualShaderNode.PORT_TYPE_SCALAR))
	add_options.push_back(AddOption.new("Trunc", "Scalar/Functions", "VisualShaderNodeFloatFunc", ("Finds the truncated value of the parameter."), [ VisualShaderNodeFloatFunc.FUNC_TRUNC ], VisualShaderNode.PORT_TYPE_SCALAR))

	add_options.push_back(AddOption.new("Add (+)", "Scalar/Operators", "VisualShaderNodeFloatOp", ("Sums two floating-point scalars."), [ VisualShaderNodeFloatOp.OP_ADD ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Add (+)", "Scalar/Operators", "VisualShaderNodeIntOp", ("Sums two integer scalars."), [ VisualShaderNodeIntOp.OP_ADD ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("Add (+)", "Scalar/Operators", "VisualShaderNodeUIntOp", ("Sums two unsigned integer scalars."), [ VisualShaderNodeUIntOp.OP_ADD ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("BitwiseAND (&)", "Scalar/Operators", "VisualShaderNodeIntOp", ("Returns the result of bitwise AND (a & b) operation for two integers."), [ VisualShaderNodeIntOp.OP_BITWISE_AND ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("BitwiseAND (&)", "Scalar/Operators", "VisualShaderNodeUIntOp", ("Returns the result of bitwise AND (a & b) operation for two unsigned integers."), [ VisualShaderNodeUIntOp.OP_BITWISE_AND ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("BitwiseLeftShift (<<)", "Scalar/Operators", "VisualShaderNodeIntOp", ("Returns the result of bitwise left shift (a << b) operation on the integer."), [ VisualShaderNodeIntOp.OP_BITWISE_LEFT_SHIFT ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("BitwiseLeftShift (<<)", "Scalar/Operators", "VisualShaderNodeUIntOp", ("Returns the result of bitwise left shift (a << b) operation on the unsigned integer."), [ VisualShaderNodeUIntOp.OP_BITWISE_LEFT_SHIFT ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("BitwiseOR (|)", "Scalar/Operators", "VisualShaderNodeIntOp", ("Returns the result of bitwise OR (a | b) operation for two integers."), [ VisualShaderNodeIntOp.OP_BITWISE_OR ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("BitwiseOR (|)", "Scalar/Operators", "VisualShaderNodeUIntOp", ("Returns the result of bitwise OR (a | b) operation for two unsigned integers."), [ VisualShaderNodeUIntOp.OP_BITWISE_OR ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("BitwiseRightShift (>>)", "Scalar/Operators", "VisualShaderNodeIntOp", ("Returns the result of bitwise right shift (a >> b) operation on the integer."), [ VisualShaderNodeIntOp.OP_BITWISE_RIGHT_SHIFT ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("BitwiseRightShift (>>)", "Scalar/Operators", "VisualShaderNodeUIntOp", ("Returns the result of bitwise right shift (a >> b) operation on the unsigned integer."), [ VisualShaderNodeIntOp.OP_BITWISE_RIGHT_SHIFT ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("BitwiseXOR (^)", "Scalar/Operators", "VisualShaderNodeIntOp", ("Returns the result of bitwise XOR (a ^ b) operation on the integer."), [ VisualShaderNodeIntOp.OP_BITWISE_XOR ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("BitwiseXOR (^)", "Scalar/Operators", "VisualShaderNodeUIntOp", ("Returns the result of bitwise XOR (a ^ b) operation on the unsigned integer."), [ VisualShaderNodeUIntOp.OP_BITWISE_XOR ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("Divide (/)", "Scalar/Operators", "VisualShaderNodeFloatOp", ("Divides two floating-point scalars."), [ VisualShaderNodeFloatOp.OP_DIV ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Divide (/)", "Scalar/Operators", "VisualShaderNodeIntOp", ("Divides two integer scalars."), [ VisualShaderNodeIntOp.OP_DIV ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("Divide (/)", "Scalar/Operators", "VisualShaderNodeUIntOp", ("Divides two unsigned integer scalars."), [ VisualShaderNodeUIntOp.OP_DIV ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("Multiply (*)", "Scalar/Operators", "VisualShaderNodeFloatOp", ("Multiplies two floating-point scalars."), [ VisualShaderNodeFloatOp.OP_MUL ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Multiply (*)", "Scalar/Operators", "VisualShaderNodeIntOp", ("Multiplies two integer scalars."), [ VisualShaderNodeIntOp.OP_MUL ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("Multiply (*)", "Scalar/Operators", "VisualShaderNodeUIntOp", ("Multiplies two unsigned integer scalars."), [ VisualShaderNodeUIntOp.OP_MUL ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("Remainder (%)", "Scalar/Operators", "VisualShaderNodeFloatOp", ("Returns the remainder of the two floating-point scalars."), [ VisualShaderNodeFloatOp.OP_MOD ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Remainder (%)", "Scalar/Operators", "VisualShaderNodeIntOp", ("Returns the remainder of the two integer scalars."), [ VisualShaderNodeIntOp.OP_MOD ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("Remainder (%)", "Scalar/Operators", "VisualShaderNodeUIntOp", ("Returns the remainder of the two unsigned integer scalars."), [ VisualShaderNodeUIntOp.OP_MOD ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("Subtract (-)", "Scalar/Operators", "VisualShaderNodeFloatOp", ("Subtracts two floating-point scalars."), [ VisualShaderNodeFloatOp.OP_SUB ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Subtract (-)", "Scalar/Operators", "VisualShaderNodeIntOp", ("Subtracts two integer scalars."), [ VisualShaderNodeIntOp.OP_SUB ], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("Subtract (-)", "Scalar/Operators", "VisualShaderNodeUIntOp", ("Subtracts two unsigned integer scalars."), [ VisualShaderNodeUIntOp.OP_SUB ], VisualShaderNode.PORT_TYPE_SCALAR_UINT));

	add_options.push_back(AddOption.new("FloatConstant", "Scalar/Variables", "VisualShaderNodeFloatConstant", ("Scalar floating-point constant."), [], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("IntConstant", "Scalar/Variables", "VisualShaderNodeIntConstant", ("Scalar integer constant."), [], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("UIntConstant", "Scalar/Variables", "VisualShaderNodeUIntConstant", ("Scalar unsigned integer constant."), [], VisualShaderNode.PORT_TYPE_SCALAR_UINT));
	add_options.push_back(AddOption.new("FloatParameter", "Scalar/Variables", "VisualShaderNodeFloatParameter", ("Scalar floating-point parameter."), [], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("IntParameter", "Scalar/Variables", "VisualShaderNodeIntParameter", ("Scalar integer parameter."), [], VisualShaderNode.PORT_TYPE_SCALAR_INT));
	add_options.push_back(AddOption.new("UIntParameter", "Scalar/Variables", "VisualShaderNodeUIntParameter", ("Scalar unsigned integer parameter."), [], VisualShaderNode.PORT_TYPE_SCALAR_UINT));

	#endregion
	#region Textures
	add_options.push_back(AddOption.new("UVFunc", "Textures/Common", "VisualShaderNodeUVFunc", "Function to be applied on texture coordinates.", [], VisualShaderNode.PORT_TYPE_VECTOR_2D))
	add_options.push_back(AddOption.new("UVPolarCoord", "Textures/Common", "VisualShaderNodeUVPolarCoord", "Polar coordinates conversion applied on texture coordinates.", [], VisualShaderNode.PORT_TYPE_VECTOR_2D))
	add_options.push_back(AddOption.new("UVPanning", "Textures/Functions", "VisualShaderNodeUVFunc", "Apply panning function on texture coordinates.", [ VisualShaderNodeUVFunc.FUNC_PANNING ], VisualShaderNode.PORT_TYPE_VECTOR_2D))
	add_options.push_back(AddOption.new("UVScaling", "Textures/Functions", "VisualShaderNodeUVFunc", "Apply scaling function on texture coordinates.", [ VisualShaderNodeUVFunc.FUNC_SCALING ], VisualShaderNode.PORT_TYPE_VECTOR_2D))
	#endregion
	#region Utility
	add_options.push_back(AddOption.new("RandomRange", "Utility", "VisualShaderNodeRandomRange", "Returns a random value between the minimum and maximum input values.", [], VisualShaderNode.PORT_TYPE_SCALAR))
	add_options.push_back(AddOption.new("RotationByAxis", "Utility", "VisualShaderNodeRotationByAxis", "Builds a rotation matrix from the given axis and angle, multiply the input vector by it and returns both this vector and a matrix.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D))
	#endregion
	#region Vector
	add_options.push_back(AddOption.new("VectorFunc", "Vector/Common", "VisualShaderNodeVectorFunc", "Vector function.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("VectorOp", "Vector/Common", "VisualShaderNodeVectorOp", "Vector operator.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("VectorCompose", "Vector/Common", "VisualShaderNodeVectorCompose", "Composes vector from scalars."));
	add_options.push_back(AddOption.new("VectorDecompose", "Vector/Common", "VisualShaderNodeVectorDecompose", "Decomposes vector to scalars."));

	add_options.push_back(AddOption.new("Vector2Compose", "Vector/Composition", "VisualShaderNodeVectorCompose", "Composes 2D vector from two scalars.", [ VisualShaderNodeVectorCompose.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Vector2Decompose", "Vector/Composition", "VisualShaderNodeVectorDecompose", "Decomposes 2D vector to two scalars.", [ VisualShaderNodeVectorDecompose.OP_TYPE_VECTOR_2D ]));
	add_options.push_back(AddOption.new("Vector3Compose", "Vector/Composition", "VisualShaderNodeVectorCompose", "Composes 3D vector from three scalars.", [ VisualShaderNodeVectorCompose.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Vector3Decompose", "Vector/Composition", "VisualShaderNodeVectorDecompose", "Decomposes 3D vector to three scalars.", [ VisualShaderNodeVectorDecompose.OP_TYPE_VECTOR_3D ]));
	add_options.push_back(AddOption.new("Vector4Compose", "Vector/Composition", "VisualShaderNodeVectorCompose", "Composes 4D vector from four scalars.", [ VisualShaderNodeVectorCompose.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Vector4Decompose", "Vector/Composition", "VisualShaderNodeVectorDecompose", "Decomposes 4D vector to four scalars.", [ VisualShaderNodeVectorDecompose.OP_TYPE_VECTOR_4D ]));

	add_options.push_back(AddOption.new("Abs", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the absolute value of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ABS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Abs", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the absolute value of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ABS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Abs", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the absolute value of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ABS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("ACos", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the arc-cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ACOS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("ACos", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the arc-cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ACOS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("ACos", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the arc-cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ACOS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("ACosH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse hyperbolic cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ACOSH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("ACosH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse hyperbolic cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ACOSH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("ACosH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse hyperbolic cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ACOSH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("ASin", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the arc-sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ASIN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("ASin", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the arc-sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ASIN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("ASin", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the arc-sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ASIN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("ASinH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse hyperbolic sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ASINH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("ASinH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse hyperbolic sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ASINH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("ASinH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse hyperbolic sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ASINH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("ATan", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the arc-tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ATAN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("ATan", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the arc-tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ATAN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("ATan", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the arc-tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ATAN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("ATan2", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the arc-tangent of the parameters.", [ VisualShaderNodeVectorOp.OP_ATAN2, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("ATan2", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the arc-tangent of the parameters.", [ VisualShaderNodeVectorOp.OP_ATAN2, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("ATan2", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the arc-tangent of the parameters.", [ VisualShaderNodeVectorOp.OP_ATAN2, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("ATanH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse hyperbolic tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ATANH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("ATanH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse hyperbolic tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ATANH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("ATanH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse hyperbolic tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ATANH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Ceil", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest integer that is greater than or equal to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_CEIL, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Ceil", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest integer that is greater than or equal to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_CEIL, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Ceil", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest integer that is greater than or equal to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_CEIL, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Clamp", "Vector/Functions", "VisualShaderNodeClamp", "Constrains a value to lie between two further values.", [ VisualShaderNodeClamp.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Clamp", "Vector/Functions", "VisualShaderNodeClamp", "Constrains a value to lie between two further values.", [ VisualShaderNodeClamp.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Clamp", "Vector/Functions", "VisualShaderNodeClamp", "Constrains a value to lie between two further values.", [ VisualShaderNodeClamp.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Cos", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_COS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Cos", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_COS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Cos", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_COS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("CosH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the hyperbolic cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_COSH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("CosH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the hyperbolic cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_COSH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("CosH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the hyperbolic cosine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_COSH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Cross", "Vector/Functions", "VisualShaderNodeVectorOp", "Calculates the cross product of two vectors.", [ VisualShaderNodeVectorOp.OP_CROSS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Degrees", "Vector/Functions", "VisualShaderNodeVectorFunc", "Converts a quantity in radians to degrees.", [ VisualShaderNodeVectorFunc.FUNC_DEGREES, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Degrees", "Vector/Functions", "VisualShaderNodeVectorFunc", "Converts a quantity in radians to degrees.", [ VisualShaderNodeVectorFunc.FUNC_DEGREES, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Degrees", "Vector/Functions", "VisualShaderNodeVectorFunc", "Converts a quantity in radians to degrees.", [ VisualShaderNodeVectorFunc.FUNC_DEGREES, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("DFdX", "Vector/Functions", "VisualShaderNodeDerivativeFunc", "(Fragment/Light mode only) (Vector) Derivative in 'x' using local differencing.", [ VisualShaderNodeDerivativeFunc.FUNC_X, VisualShaderNodeDerivativeFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D, -1, true))
	add_options.push_back(AddOption.new("DFdX", "Vector/Functions", "VisualShaderNodeDerivativeFunc", "(Fragment/Light mode only) (Vector) Derivative in 'x' using local differencing.", [ VisualShaderNodeDerivativeFunc.FUNC_X, VisualShaderNodeDerivativeFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D, -1, true))
	add_options.push_back(AddOption.new("DFdX", "Vector/Functions", "VisualShaderNodeDerivativeFunc", "(Fragment/Light mode only) (Vector) Derivative in 'x' using local differencing.", [ VisualShaderNodeDerivativeFunc.FUNC_X, VisualShaderNodeDerivativeFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D, -1, true))
	add_options.push_back(AddOption.new("DFdY", "Vector/Functions", "VisualShaderNodeDerivativeFunc", "(Fragment/Light mode only) (Vector) Derivative in 'y' using local differencing.", [ VisualShaderNodeDerivativeFunc.FUNC_Y, VisualShaderNodeDerivativeFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D, -1, true))
	add_options.push_back(AddOption.new("DFdY", "Vector/Functions", "VisualShaderNodeDerivativeFunc", "(Fragment/Light mode only) (Vector) Derivative in 'y' using local differencing.", [ VisualShaderNodeDerivativeFunc.FUNC_Y, VisualShaderNodeDerivativeFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D, -1, true))
	add_options.push_back(AddOption.new("DFdY", "Vector/Functions", "VisualShaderNodeDerivativeFunc", "(Fragment/Light mode only) (Vector) Derivative in 'y' using local differencing.", [ VisualShaderNodeDerivativeFunc.FUNC_Y, VisualShaderNodeDerivativeFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D, -1, true))
	add_options.push_back(AddOption.new("Distance2D", "Vector/Functions", "VisualShaderNodeVectorDistance", "Returns the distance between two points.", [ VisualShaderNodeVectorDistance.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Distance3D", "Vector/Functions", "VisualShaderNodeVectorDistance", "Returns the distance between two points.", [ VisualShaderNodeVectorDistance.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Distance4D", "Vector/Functions", "VisualShaderNodeVectorDistance", "Returns the distance between two points.", [ VisualShaderNodeVectorDistance.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Dot", "Vector/Functions", "VisualShaderNodeDotProduct", "Calculates the dot product of two vectors.", [], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Exp", "Vector/Functions", "VisualShaderNodeVectorFunc", "Base-e Exponential.", [ VisualShaderNodeVectorFunc.FUNC_EXP, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Exp", "Vector/Functions", "VisualShaderNodeVectorFunc", "Base-e Exponential.", [ VisualShaderNodeVectorFunc.FUNC_EXP, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Exp", "Vector/Functions", "VisualShaderNodeVectorFunc", "Base-e Exponential.", [ VisualShaderNodeVectorFunc.FUNC_EXP, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Exp2", "Vector/Functions", "VisualShaderNodeVectorFunc", "Base-2 Exponential.", [ VisualShaderNodeVectorFunc.FUNC_EXP2, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Exp2", "Vector/Functions", "VisualShaderNodeVectorFunc", "Base-2 Exponential.", [ VisualShaderNodeVectorFunc.FUNC_EXP2, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Exp2", "Vector/Functions", "VisualShaderNodeVectorFunc", "Base-2 Exponential.", [ VisualShaderNodeVectorFunc.FUNC_EXP2, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("FaceForward", "Vector/Functions", "VisualShaderNodeFaceForward", "Returns the vector that points in the same direction as a reference vector. The function has three vector parameters : N, the vector to orient, I, the incident vector, and Nref, the reference vector. If the dot product of I and Nref is smaller than zero the return value is N. Otherwise -N is returned.", [ VisualShaderNodeFaceForward.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("FaceForward", "Vector/Functions", "VisualShaderNodeFaceForward", "Returns the vector that points in the same direction as a reference vector. The function has three vector parameters : N, the vector to orient, I, the incident vector, and Nref, the reference vector. If the dot product of I and Nref is smaller than zero the return value is N. Otherwise -N is returned.", [ VisualShaderNodeFaceForward.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("FaceForward", "Vector/Functions", "VisualShaderNodeFaceForward", "Returns the vector that points in the same direction as a reference vector. The function has three vector parameters : N, the vector to orient, I, the incident vector, and Nref, the reference vector. If the dot product of I and Nref is smaller than zero the return value is N. Otherwise -N is returned.", [ VisualShaderNodeFaceForward.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Floor", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest integer less than or equal to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_FLOOR, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Floor", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest integer less than or equal to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_FLOOR, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Floor", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest integer less than or equal to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_FLOOR, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Fract", "Vector/Functions", "VisualShaderNodeVectorFunc", "Computes the fractional part of the argument.", [ VisualShaderNodeVectorFunc.FUNC_FRACT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Fract", "Vector/Functions", "VisualShaderNodeVectorFunc", "Computes the fractional part of the argument.", [ VisualShaderNodeVectorFunc.FUNC_FRACT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Fract", "Vector/Functions", "VisualShaderNodeVectorFunc", "Computes the fractional part of the argument.", [ VisualShaderNodeVectorFunc.FUNC_FRACT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Fresnel", "Vector/Functions", "VisualShaderNodeFresnel", "Returns falloff based on the dot product of surface normal and view direction of camera (pass associated inputs to it).", [], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("InverseSqrt", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse of the square root of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_INVERSE_SQRT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("InverseSqrt", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse of the square root of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_INVERSE_SQRT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("InverseSqrt", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the inverse of the square root of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_INVERSE_SQRT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Length2D", "Vector/Functions", "VisualShaderNodeVectorLen", "Calculates the length of a vector.", [ VisualShaderNodeVectorLen.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Length3D", "Vector/Functions", "VisualShaderNodeVectorLen", "Calculates the length of a vector.", [ VisualShaderNodeVectorLen.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Length4D", "Vector/Functions", "VisualShaderNodeVectorLen", "Calculates the length of a vector.", [ VisualShaderNodeVectorLen.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_SCALAR));
	add_options.push_back(AddOption.new("Log", "Vector/Functions", "VisualShaderNodeVectorFunc", "Natural logarithm.", [ VisualShaderNodeVectorFunc.FUNC_LOG, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Log", "Vector/Functions", "VisualShaderNodeVectorFunc", "Natural logarithm.", [ VisualShaderNodeVectorFunc.FUNC_LOG, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Log", "Vector/Functions", "VisualShaderNodeVectorFunc", "Natural logarithm.", [ VisualShaderNodeVectorFunc.FUNC_LOG, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Log2", "Vector/Functions", "VisualShaderNodeVectorFunc", "Base-2 logarithm.", [ VisualShaderNodeVectorFunc.FUNC_LOG2, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Log2", "Vector/Functions", "VisualShaderNodeVectorFunc", "Base-2 logarithm.", [ VisualShaderNodeVectorFunc.FUNC_LOG2, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Log2", "Vector/Functions", "VisualShaderNodeVectorFunc", "Base-2 logarithm.", [ VisualShaderNodeVectorFunc.FUNC_LOG2, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Max", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the greater of two values.", [ VisualShaderNodeVectorOp.OP_MAX, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Max", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the greater of two values.", [ VisualShaderNodeVectorOp.OP_MAX, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Max", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the greater of two values.", [ VisualShaderNodeVectorOp.OP_MAX, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Min", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the lesser of two values.", [ VisualShaderNodeVectorOp.OP_MIN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Min", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the lesser of two values.", [ VisualShaderNodeVectorOp.OP_MIN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Min", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the lesser of two values.", [ VisualShaderNodeVectorOp.OP_MIN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Mix", "Vector/Functions", "VisualShaderNodeMix", "Linear interpolation between two vectors.", [ VisualShaderNodeMix.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Mix", "Vector/Functions", "VisualShaderNodeMix", "Linear interpolation between two vectors.", [ VisualShaderNodeMix.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Mix", "Vector/Functions", "VisualShaderNodeMix", "Linear interpolation between two vectors.", [ VisualShaderNodeMix.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("MixS", "Vector/Functions", "VisualShaderNodeMix", "Linear interpolation between two vectors using scalar.", [ VisualShaderNodeMix.OP_TYPE_VECTOR_2D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("MixS", "Vector/Functions", "VisualShaderNodeMix", "Linear interpolation between two vectors using scalar.", [ VisualShaderNodeMix.OP_TYPE_VECTOR_3D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("MixS", "Vector/Functions", "VisualShaderNodeMix", "Linear interpolation between two vectors using scalar.", [ VisualShaderNodeMix.OP_TYPE_VECTOR_4D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("MultiplyAdd (a * b + c)", "Vector/Functions", "VisualShaderNodeMultiplyAdd", "Performs a fused multiply-add operation (a * b + c) on vectors.", [ VisualShaderNodeMultiplyAdd.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("MultiplyAdd (a * b + c)", "Vector/Functions", "VisualShaderNodeMultiplyAdd", "Performs a fused multiply-add operation (a * b + c) on vectors.", [ VisualShaderNodeMultiplyAdd.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("MultiplyAdd (a * b + c)", "Vector/Functions", "VisualShaderNodeMultiplyAdd", "Performs a fused multiply-add operation (a * b + c) on vectors.", [ VisualShaderNodeMultiplyAdd.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Negate (*-1)", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the opposite value of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_NEGATE, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Negate (*-1)", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the opposite value of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_NEGATE, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Negate (*-1)", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the opposite value of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_NEGATE, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Normalize", "Vector/Functions", "VisualShaderNodeVectorFunc", "Calculates the normalize product of vector.", [ VisualShaderNodeVectorFunc.FUNC_NORMALIZE, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Normalize", "Vector/Functions", "VisualShaderNodeVectorFunc", "Calculates the normalize product of vector.", [ VisualShaderNodeVectorFunc.FUNC_NORMALIZE, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Normalize", "Vector/Functions", "VisualShaderNodeVectorFunc", "Calculates the normalize product of vector.", [ VisualShaderNodeVectorFunc.FUNC_NORMALIZE, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("OneMinus (1-)", "Vector/Functions", "VisualShaderNodeVectorFunc", "1.0 - vector", [ VisualShaderNodeVectorFunc.FUNC_ONEMINUS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("OneMinus (1-)", "Vector/Functions", "VisualShaderNodeVectorFunc", "1.0 - vector", [ VisualShaderNodeVectorFunc.FUNC_ONEMINUS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("OneMinus (1-)", "Vector/Functions", "VisualShaderNodeVectorFunc", "1.0 - vector", [ VisualShaderNodeVectorFunc.FUNC_ONEMINUS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Pow (^)", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the value of the first parameter raised to the power of the second.", [ VisualShaderNodeVectorOp.OP_POW, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Pow (^)", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the value of the first parameter raised to the power of the second.", [ VisualShaderNodeVectorOp.OP_POW, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Pow (^)", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the value of the first parameter raised to the power of the second.", [ VisualShaderNodeVectorOp.OP_POW, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Radians", "Vector/Functions", "VisualShaderNodeVectorFunc", "Converts a quantity in degrees to radians.", [ VisualShaderNodeVectorFunc.FUNC_RADIANS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Radians", "Vector/Functions", "VisualShaderNodeVectorFunc", "Converts a quantity in degrees to radians.", [ VisualShaderNodeVectorFunc.FUNC_RADIANS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Radians", "Vector/Functions", "VisualShaderNodeVectorFunc", "Converts a quantity in degrees to radians.", [ VisualShaderNodeVectorFunc.FUNC_RADIANS, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Reciprocal", "Vector/Functions", "VisualShaderNodeVectorFunc", "1.0 / vector", [ VisualShaderNodeVectorFunc.FUNC_RECIPROCAL, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Reciprocal", "Vector/Functions", "VisualShaderNodeVectorFunc", "1.0 / vector", [ VisualShaderNodeVectorFunc.FUNC_RECIPROCAL, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Reciprocal", "Vector/Functions", "VisualShaderNodeVectorFunc", "1.0 / vector", [ VisualShaderNodeVectorFunc.FUNC_RECIPROCAL, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Reflect", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the vector that points in the direction of reflection ( a : incident vector, b : normal vector ).", [ VisualShaderNodeVectorOp.OP_REFLECT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Reflect", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the vector that points in the direction of reflection ( a : incident vector, b : normal vector ).", [ VisualShaderNodeVectorOp.OP_REFLECT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Reflect", "Vector/Functions", "VisualShaderNodeVectorOp", "Returns the vector that points in the direction of reflection ( a : incident vector, b : normal vector ).", [ VisualShaderNodeVectorOp.OP_REFLECT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Refract", "Vector/Functions", "VisualShaderNodeVectorRefract", "Returns the vector that points in the direction of refraction.", [], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Refract", "Vector/Functions", "VisualShaderNodeVectorRefract", "Returns the vector that points in the direction of refraction.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Refract", "Vector/Functions", "VisualShaderNodeVectorRefract", "Returns the vector that points in the direction of refraction.", [], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	#add_options.push_back(AddOption.new("Remap", "Vector/Functions", "VisualShaderNodeRemap", "Remaps a vector from the input range to the output range.", [ VisualShaderNodeRemap.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	#add_options.push_back(AddOption.new("Remap", "Vector/Functions", "VisualShaderNodeRemap", "Remaps a vector from the input range to the output range.", [ VisualShaderNodeRemap.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	#add_options.push_back(AddOption.new("Remap", "Vector/Functions", "VisualShaderNodeRemap", "Remaps a vector from the input range to the output range.", [ VisualShaderNodeRemap.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	#add_options.push_back(AddOption.new("RemapS", "Vector/Functions", "VisualShaderNodeRemap", "Remaps a vector from the input range to the output range. Ranges defined with scalars.", [ VisualShaderNodeRemap.OP_TYPE_VECTOR_2D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	#add_options.push_back(AddOption.new("RemapS", "Vector/Functions", "VisualShaderNodeRemap", "Remaps a vector from the input range to the output range. Ranges defined with scalars.", [ VisualShaderNodeRemap.OP_TYPE_VECTOR_3D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	#add_options.push_back(AddOption.new("RemapS", "Vector/Functions", "VisualShaderNodeRemap", "Remaps a vector from the input range to the output range. Ranges defined with scalars.", [ VisualShaderNodeRemap.OP_TYPE_VECTOR_4D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Round", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest integer to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ROUND, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Round", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest integer to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ROUND, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Round", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest integer to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ROUND, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("RoundEven", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest even integer to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ROUNDEVEN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("RoundEven", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest even integer to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ROUNDEVEN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("RoundEven", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the nearest even integer to the parameter.", [ VisualShaderNodeVectorFunc.FUNC_ROUNDEVEN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Saturate", "Vector/Functions", "VisualShaderNodeVectorFunc", "Clamps the value between 0.0 and 1.0.", [ VisualShaderNodeVectorFunc.FUNC_SATURATE, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Saturate", "Vector/Functions", "VisualShaderNodeVectorFunc", "Clamps the value between 0.0 and 1.0.", [ VisualShaderNodeVectorFunc.FUNC_SATURATE, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Saturate", "Vector/Functions", "VisualShaderNodeVectorFunc", "Clamps the value between 0.0 and 1.0.", [ VisualShaderNodeVectorFunc.FUNC_SATURATE, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Sign", "Vector/Functions", "VisualShaderNodeVectorFunc", "Extracts the sign of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SIGN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Sign", "Vector/Functions", "VisualShaderNodeVectorFunc", "Extracts the sign of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SIGN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Sign", "Vector/Functions", "VisualShaderNodeVectorFunc", "Extracts the sign of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SIGN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Sin", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SIN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Sin", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SIN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Sin", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SIN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("SinH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the hyperbolic sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SINH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("SinH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the hyperbolic sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SINH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("SinH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the hyperbolic sine of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SINH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Sqrt", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the square root of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SQRT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Sqrt", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the square root of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SQRT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Sqrt", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the square root of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_SQRT, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("SmoothStep", "Vector/Functions", "VisualShaderNodeSmoothStep", "SmoothStep function( vector(edge0), vector(edge1), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge0' and 1.0 if 'x' is larger than 'edge1'. Otherwise the return value is interpolated between 0.0 and 1.0 using Hermite polynomials.", [ VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("SmoothStep", "Vector/Functions", "VisualShaderNodeSmoothStep", "SmoothStep function( vector(edge0), vector(edge1), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge0' and 1.0 if 'x' is larger than 'edge1'. Otherwise the return value is interpolated between 0.0 and 1.0 using Hermite polynomials.", [ VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("SmoothStep", "Vector/Functions", "VisualShaderNodeSmoothStep", "SmoothStep function( vector(edge0), vector(edge1), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge0' and 1.0 if 'x' is larger than 'edge1'. Otherwise the return value is interpolated between 0.0 and 1.0 using Hermite polynomials.", [ VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("SmoothStepS", "Vector/Functions", "VisualShaderNodeSmoothStep", "SmoothStep function( scalar(edge0), scalar(edge1), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge0' and 1.0 if 'x' is larger than 'edge1'. Otherwise the return value is interpolated between 0.0 and 1.0 using Hermite polynomials.", [ VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_2D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("SmoothStepS", "Vector/Functions", "VisualShaderNodeSmoothStep", "SmoothStep function( scalar(edge0), scalar(edge1), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge0' and 1.0 if 'x' is larger than 'edge1'. Otherwise the return value is interpolated between 0.0 and 1.0 using Hermite polynomials.", [ VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_3D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("SmoothStepS", "Vector/Functions", "VisualShaderNodeSmoothStep", "SmoothStep function( scalar(edge0), scalar(edge1), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge0' and 1.0 if 'x' is larger than 'edge1'. Otherwise the return value is interpolated between 0.0 and 1.0 using Hermite polynomials.", [ VisualShaderNodeSmoothStep.OP_TYPE_VECTOR_4D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Step", "Vector/Functions", "VisualShaderNodeStep", "Step function( vector(edge), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge' and otherwise 1.0.", [ VisualShaderNodeStep.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Step", "Vector/Functions", "VisualShaderNodeStep", "Step function( vector(edge), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge' and otherwise 1.0.", [ VisualShaderNodeStep.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("StepS", "Vector/Functions", "VisualShaderNodeStep", "Step function( scalar(edge), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge' and otherwise 1.0.", [ VisualShaderNodeStep.OP_TYPE_VECTOR_2D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("StepS", "Vector/Functions", "VisualShaderNodeStep", "Step function( scalar(edge), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge' and otherwise 1.0.", [ VisualShaderNodeStep.OP_TYPE_VECTOR_3D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("StepS", "Vector/Functions", "VisualShaderNodeStep", "Step function( scalar(edge), vector(x) ).\n\nReturns 0.0 if 'x' is smaller than 'edge' and otherwise 1.0.", [ VisualShaderNodeStep.OP_TYPE_VECTOR_4D_SCALAR ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Sum (+)", "Vector/Functions", "VisualShaderNodeDerivativeFunc", "(Fragment/Light mode only) (Vector) Sum of absolute derivative in 'x' and 'y'.", [ VisualShaderNodeDerivativeFunc.FUNC_SUM, VisualShaderNodeDerivativeFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D, -1, true))
	add_options.push_back(AddOption.new("Sum (+)", "Vector/Functions", "VisualShaderNodeDerivativeFunc", "(Fragment/Light mode only) (Vector) Sum of absolute derivative in 'x' and 'y'.", [ VisualShaderNodeDerivativeFunc.FUNC_SUM, VisualShaderNodeDerivativeFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D, -1, true))
	add_options.push_back(AddOption.new("Sum (+)", "Vector/Functions", "VisualShaderNodeDerivativeFunc", "(Fragment/Light mode only) (Vector) Sum of absolute derivative in 'x' and 'y'.", [ VisualShaderNodeDerivativeFunc.FUNC_SUM, VisualShaderNodeDerivativeFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D, -1, true))
	add_options.push_back(AddOption.new("Tan", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_TAN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Tan", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_TAN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Tan", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_TAN, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("TanH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the hyperbolic tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_TANH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("TanH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the hyperbolic tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_TANH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("TanH", "Vector/Functions", "VisualShaderNodeVectorFunc", "Returns the hyperbolic tangent of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_TANH, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Trunc", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the truncated value of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_TRUNC, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Trunc", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the truncated value of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_TRUNC, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Trunc", "Vector/Functions", "VisualShaderNodeVectorFunc", "Finds the truncated value of the parameter.", [ VisualShaderNodeVectorFunc.FUNC_TRUNC, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));

	add_options.push_back(AddOption.new("Add (+)", "Vector/Operators", "VisualShaderNodeVectorOp", "Adds 2D vector to 2D vector.", [ VisualShaderNodeVectorOp.OP_ADD, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Add (+)", "Vector/Operators", "VisualShaderNodeVectorOp", "Adds 3D vector to 3D vector.", [ VisualShaderNodeVectorOp.OP_ADD, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Add (+)", "Vector/Operators", "VisualShaderNodeVectorOp", "Adds 4D vector to 4D vector.", [ VisualShaderNodeVectorOp.OP_ADD, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Divide (/)", "Vector/Operators", "VisualShaderNodeVectorOp", "Divides 2D vector by 2D vector.", [ VisualShaderNodeVectorOp.OP_DIV, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Divide (/)", "Vector/Operators", "VisualShaderNodeVectorOp", "Divides 3D vector by 3D vector.", [ VisualShaderNodeVectorOp.OP_DIV, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Divide (/)", "Vector/Operators", "VisualShaderNodeVectorOp", "Divides 4D vector by 4D vector.", [ VisualShaderNodeVectorOp.OP_DIV, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Multiply (*)", "Vector/Operators", "VisualShaderNodeVectorOp", "Multiplies 2D vector by 2D vector.", [ VisualShaderNodeVectorOp.OP_MUL, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Multiply (*)", "Vector/Operators", "VisualShaderNodeVectorOp", "Multiplies 3D vector by 3D vector.", [ VisualShaderNodeVectorOp.OP_MUL, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Multiply (*)", "Vector/Operators", "VisualShaderNodeVectorOp", "Multiplies 4D vector by 4D vector.", [ VisualShaderNodeVectorOp.OP_MUL, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Remainder (%)", "Vector/Operators", "VisualShaderNodeVectorOp", "Returns the remainder of the two 2D vectors.", [ VisualShaderNodeVectorOp.OP_MOD, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Remainder (%)", "Vector/Operators", "VisualShaderNodeVectorOp", "Returns the remainder of the two 3D vectors.", [ VisualShaderNodeVectorOp.OP_MOD, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Remainder (%)", "Vector/Operators", "VisualShaderNodeVectorOp", "Returns the remainder of the two 4D vectors.", [ VisualShaderNodeVectorOp.OP_MOD, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Subtract (-)", "Vector/Operators", "VisualShaderNodeVectorOp", "Subtracts 2D vector from 2D vector.", [ VisualShaderNodeVectorOp.OP_SUB, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_2D ], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Subtract (-)", "Vector/Operators", "VisualShaderNodeVectorOp", "Subtracts 3D vector from 3D vector.", [ VisualShaderNodeVectorOp.OP_SUB, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Subtract (-)", "Vector/Operators", "VisualShaderNodeVectorOp", "Subtracts 4D vector from 4D vector.", [ VisualShaderNodeVectorOp.OP_SUB, VisualShaderNodeVectorOp.OP_TYPE_VECTOR_4D ], VisualShaderNode.PORT_TYPE_VECTOR_4D));

	add_options.push_back(AddOption.new("Vector2Constant", "Vector/Variables", "VisualShaderNodeVec2Constant", "2D vector constant.", [], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Vector2Parameter", "Vector/Variables", "VisualShaderNodeVec2Parameter", "2D vector parameter.", [], VisualShaderNode.PORT_TYPE_VECTOR_2D));
	add_options.push_back(AddOption.new("Vector3Constant", "Vector/Variables", "VisualShaderNodeVec3Constant", "3D vector constant.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Vector3Parameter", "Vector/Variables", "VisualShaderNodeVec3Parameter", "3D vector parameter.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Vector4Constant", "Vector/Variables", "VisualShaderNodeVec4Constant", "4D vector constant.", [], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("Vector4Parameter", "Vector/Variables", "VisualShaderNodeVec4Parameter", "4D vector parameter.", [], VisualShaderNode.PORT_TYPE_VECTOR_4D))
	#endregion
	#region Special
	add_options.push_back(AddOption.new("Frame", "Special", "VisualShaderNodeFrame", "A rectangular area with a description string for better graph organization."))
	#endregion


func update_options_menu() -> void:
	var root := node_list_tree.create_item()
	var folders := {}  # String, TreeItem
	for i in add_options.size():
		var option := add_options[i]
		if option.highend and not is_instance_valid(RenderingServer.get_rendering_device()):
			continue
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
	var to_node := graph_edit.get_node(to_node_name) as GraphNode
	graph_edit.connect_node(from_node_name, from_port, to_node_name, to_port)
	if to_node.has_meta(&"default_input_button_%s" % to_port):
		to_node.get_meta(&"default_input_button_%s" % to_port).visible = false
	#var vs_from_node := from_node.get_meta("visual_shader_node") as VisualShaderNode
	#var vs_to_node := to_node.get_meta("visual_shader_node") as VisualShaderNode
	var vs_from_node_id := int(from_node_name)
	var vs_to_node_id := int(to_node_name)
	visual_shader.connect_nodes(VisualShader.TYPE_FRAGMENT, vs_from_node_id, from_port, vs_to_node_id, to_port)
	_on_effect_changed()


func _on_graph_edit_disconnection_request(from_node_name: String, from_port: int, to_node_name: String, to_port: int) -> void:
	var to_node := graph_edit.get_node(to_node_name) as GraphNode
	graph_edit.disconnect_node(from_node_name, from_port, to_node_name, to_port)
	if to_node.has_meta(&"default_input_button_%s" % to_port):
		to_node.get_meta(&"default_input_button_%s" % to_port).visible = true
	var vs_from_node_id := int(from_node_name)
	var vs_to_node_id := int(to_node_name)
	visual_shader.disconnect_nodes(VisualShader.TYPE_FRAGMENT, vs_from_node_id, from_port, vs_to_node_id, to_port)
	_on_effect_changed()


func _on_graph_edit_connection_from_empty(_to_node: StringName, _to_port: int, release_position: Vector2) -> void:
	node_list_tree.get_window().popup_centered()
	spawn_node_in_position = release_position


func _on_graph_edit_connection_to_empty(_from_node: StringName, _from_port: int, release_position: Vector2) -> void:
	if not is_instance_valid(visual_shader):
		return
	node_list_tree.get_window().popup_centered()
	spawn_node_in_position = release_position


func _on_graph_edit_popup_request(at_position: Vector2) -> void:
	if not is_instance_valid(visual_shader):
		return
	node_list_tree.get_window().popup_centered()
	spawn_node_in_position = at_position


func _on_graph_edit_delete_nodes_request(node_names: Array[StringName]) -> void:
	for node_name in node_names:
		_on_delete_request(node_name)


func _on_graph_edit_graph_elements_linked_to_frame_request(elements: Array, frame: StringName) -> void:
	#var frame_node := graph_edit.get_node(String(frame))
	#var frame_vsn := frame_node.get_meta("visual_shader_node") as VisualShaderNodeFrame
	for element in elements:
		graph_edit.attach_graph_element_to_frame(element, frame)
		visual_shader.attach_node_to_frame(VisualShader.TYPE_FRAGMENT, int(String(element)), int(String(frame)))
		#frame_vsn.add_attached_node(int(String(element)))
	_on_effect_changed()


func _on_graph_edit_mouse_entered() -> void:
	can_undo = true


func _on_graph_edit_mouse_exited() -> void:
	can_undo = false
