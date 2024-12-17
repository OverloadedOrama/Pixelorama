extends PanelContainer

enum NodeTypes { NONE = -1, BOOL, SCALAR, VEC2, VEC3, VEC4, TRANSFORM, SAMPLER }

var slot_colors := PackedColorArray(
	[
		Color(0.243, 0.612, 0.349),  # Bool
		Color(0.55, 0.55, 0.55),  # Scalar
		Color(0.44, 0.43, 0.64),  # Vector2
		Color(0.337, 0.314, 0.71),  # Vector3
		Color(0.7, 0.65, 0.147),  # Vector4/Color
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
	var mode := NodeTypes.BOOL
	var return_type := 0
	#int func = 0
	#bool highend = false
	#bool is_custom = false
	#bool is_native = false
	#int temp_idx = 0

	func _init(_option_name: String, _category: String, _type: String, _description: String, _ops: Array, _return_type := -1, _mode := NodeTypes.NONE) -> void:
		option_name = _option_name
		type = _type
		category = _category
		description = _description
		ops = _ops
		return_type = _return_type
		mode = _mode


func _ready() -> void:
	graph_edit.add_valid_connection_type(NodeTypes.VEC2, NodeTypes.VEC3)
	graph_edit.add_valid_connection_type(NodeTypes.VEC2, NodeTypes.VEC4)
	graph_edit.add_valid_connection_type(NodeTypes.VEC3, NodeTypes.VEC4)
	graph_edit.add_valid_connection_type(NodeTypes.VEC3, NodeTypes.VEC2)
	graph_edit.add_valid_connection_type(NodeTypes.VEC4, NodeTypes.VEC2)
	graph_edit.add_valid_connection_type(NodeTypes.VEC4, NodeTypes.VEC3)
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
	var popup_menu := effects_button.get_popup()
	popup_menu.add_item(effect_name)
	var effect_index := popup_menu.item_count - 1
	popup_menu.set_item_metadata(effect_index, visual_shader)


func _on_visibility_changed() -> void:
	# Only fill the options when the panel first becomes visible.
	if visible and add_options.size() == 0:
		fill_add_options()
		update_options_menu()


func get_color_type(type: NodeTypes) -> Color:
	if type == NodeTypes.NONE:
		return Color.TRANSPARENT
	return slot_colors[type]


func add_new_node(index: int) -> void:
	var option := add_options[index]
	if not option.type.is_empty():
		var vsn := ClassDB.instantiate(option.type) as VisualShaderNode
		var id := visual_shader.get_valid_node_id(VisualShader.TYPE_FRAGMENT)
		visual_shader.add_node(VisualShader.TYPE_FRAGMENT, vsn, Vector2.ZERO, id)
		add_node(vsn, id)


func add_node(vsn: VisualShaderNode, id: int) -> void:
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
		graph_node.set_slot(0, true, NodeTypes.VEC3, slot_colors[NodeTypes.VEC3], false, -1, Color.TRANSPARENT)
		graph_node.set_slot(1, true, NodeTypes.SCALAR, slot_colors[NodeTypes.SCALAR], false, -1, Color.TRANSPARENT)
	if vsn is VisualShaderNodeColorConstant:
		var color_picker_button := ColorPickerButton.new()
		color_picker_button.custom_minimum_size = Vector2(20, 20)
		color_picker_button.color = vsn.constant
		color_picker_button.color_changed.connect(func(color: Color): vsn.constant = color; ResourceSaver.save(visual_shader))
		graph_node.add_child(color_picker_button)
		graph_node.set_slot(0, false, -1, Color.TRANSPARENT, true, NodeTypes.VEC4, slot_colors[NodeTypes.VEC4])
	#VisualShaderNodeParameterRef
	graph_node.set_meta("visual_shader_node", vsn)
	graph_node.name = str(id)
	graph_node.position_offset = visual_shader.get_node_position(VisualShader.TYPE_FRAGMENT, id)
	graph_edit.add_child(graph_node)


func fill_add_options() -> void:
	# Color
	add_options.push_back(AddOption.new("ColorFunc", "Color/Common", "VisualShaderNodeColorFunc", "Color function.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("ColorOp", "Color/Common", "VisualShaderNodeColorOp", "Color operator.", [], VisualShaderNode.PORT_TYPE_VECTOR_3D));

	add_options.push_back(AddOption.new("Grayscale", "Color/Functions", "VisualShaderNodeColorFunc", "Grayscale function.", [ VisualShaderNodeColorFunc.FUNC_GRAYSCALE ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("HSV2RGB", "Color/Functions", "VisualShaderNodeColorFunc", "Converts HSV vector to RGB equivalent.", [ VisualShaderNodeColorFunc.FUNC_HSV2RGB, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("RGB2HSV", "Color/Functions", "VisualShaderNodeColorFunc", "Converts RGB vector to HSV equivalent.", [ VisualShaderNodeColorFunc.FUNC_RGB2HSV, VisualShaderNodeVectorFunc.OP_TYPE_VECTOR_3D ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Sepia", "Color/Functions", "VisualShaderNodeColorFunc", "Sepia function.", [ VisualShaderNodeColorFunc.FUNC_SEPIA ], VisualShaderNode.PORT_TYPE_VECTOR_3D));

	add_options.push_back(AddOption.new("Burn", "Color/Operators", "VisualShaderNodeColorOp", "Burn operator.", [ VisualShaderNodeColorOp.OP_BURN ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Darken", "Color/Operators", "VisualShaderNodeColorOp", "Darken operator.", [ VisualShaderNodeColorOp.OP_DARKEN ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Difference", "Color/Operators", "VisualShaderNodeColorOp", "Difference operator.", [ VisualShaderNodeColorOp.OP_DIFFERENCE ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Dodge", "Color/Operators", "VisualShaderNodeColorOp", "Dodge operator.", [ VisualShaderNodeColorOp.OP_DODGE ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("HardLight", "Color/Operators", "VisualShaderNodeColorOp", "HardLight operator.", [ VisualShaderNodeColorOp.OP_HARD_LIGHT ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Lighten", "Color/Operators", "VisualShaderNodeColorOp", "Lighten operator.", [ VisualShaderNodeColorOp.OP_LIGHTEN ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Overlay", "Color/Operators", "VisualShaderNodeColorOp", "Overlay operator.", [ VisualShaderNodeColorOp.OP_OVERLAY ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("Screen", "Color/Operators", "VisualShaderNodeColorOp", "Screen operator.", [ VisualShaderNodeColorOp.OP_SCREEN ], VisualShaderNode.PORT_TYPE_VECTOR_3D));
	add_options.push_back(AddOption.new("SoftLight", "Color/Operators", "VisualShaderNodeColorOp", "SoftLight operator.", [ VisualShaderNodeColorOp.OP_SOFT_LIGHT ], VisualShaderNode.PORT_TYPE_VECTOR_3D));

	add_options.push_back(AddOption.new("ColorConstant", "Color/Variables", "VisualShaderNodeColorConstant", "Color constant.", [], VisualShaderNode.PORT_TYPE_VECTOR_4D));
	add_options.push_back(AddOption.new("ColorParameter", "Color/Variables", "VisualShaderNodeColorParameter", "Color parameter.", [], VisualShaderNode.PORT_TYPE_VECTOR_4D));


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
	ResourceSaver.save(visual_shader)


func _on_graph_edit_disconnection_request(from_node_name: String, from_port: int, to_node_name: String, to_port: int) -> void:
	graph_edit.disconnect_node(from_node_name, from_port, to_node_name, to_port)
	var vs_from_node_id := int(from_node_name)
	var vs_to_node_id := int(to_node_name)
	visual_shader.disconnect_nodes(VisualShader.TYPE_FRAGMENT, vs_from_node_id, from_port, vs_to_node_id, to_port)
	ResourceSaver.save(visual_shader)
