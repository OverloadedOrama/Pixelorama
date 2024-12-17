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
var visual_shader: VisualShader
var effects_button: MenuButton

@onready var graph_edit := $GraphEdit as GraphEdit
@onready var output: GraphNode = $GraphEdit/Output
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
	node_list_tree.get_window().get_ok_button().set_disabled(true)
	effect_name_line_edit.get_window().get_ok_button().set_disabled(true)
	effects_button = MenuButton.new()
	effects_button.text = "Effects"
	effects_button.flat = false
	effects_button.get_popup().add_item("New")
	effects_button.get_popup().id_pressed.connect(_on_effects_button_id_pressed)
	_find_loaded_effects()
	OpenSave.shader_copied.connect(_load_shader_file)
	var add_node_button := Button.new()
	add_node_button.text = "Add node"
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
		# TODO: Add logic that adds the shader's nodes


func new_effect(effect_name: String) -> void:
	output.set_slot(0, true, NodeTypes.VEC3, slot_colors[NodeTypes.VEC3], false, -1, Color.TRANSPARENT)
	output.set_slot(1, true, NodeTypes.SCALAR, slot_colors[NodeTypes.SCALAR], false, -1, Color.TRANSPARENT)
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


func add_node(index: int) -> void:
	var option := add_options[index]
	#if not option.type.is_empty():
		#var vsn := ClassDB.instantiate(option.type) as VisualShaderNode
		#VisualShaderNodeParameterRef


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
					folders[path_temp ]= category
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
