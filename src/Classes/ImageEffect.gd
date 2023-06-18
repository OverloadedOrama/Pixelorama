class_name ImageEffect
extends ConfirmationDialog
## Parent class for all image effects
## Methods that only contain "pass" are meant to be replaced by the inherited scripts

enum { SELECTED_CELS, FRAME, ALL_FRAMES, ALL_PROJECTS }

const VALUE_SLIDER_V2_TSCN := preload("res://src/UI/Nodes/ValueSliderV2.tscn")

var affect := SELECTED_CELS
var selected_cels := Image.new()
var current_frame := Image.new()
var preview_image := Image.new()
var preview_texture := ImageTexture.new()
var preview: TextureRect
var selection_checkbox: CheckBox
var affect_option_button: OptionButton
var animatable_properties := []  # Array[AnimatebleProperty]
var animation_container: CollapsibleContainer
var animation_container_grid: GridContainer
var selected_idx := 0  # the current selected cel to apply animation to
var confirmed := false


class AnimatableProperty:
	var name := ""
	var initial_value_node: Node
	var is_animating := false
	var initial_value
	var final_value
	var trans_type := Tween.TRANS_LINEAR
	var ease_type := Tween.EASE_IN

	func _init(_name: String, _initial_value_node) -> void:
		name = _name
		initial_value_node = _initial_value_node
		initial_value = initial_value_node.value
		initial_value_node.connect("value_changed", self, "_initial_value_changed")

	func create_nodes(container: GridContainer) -> void:
		var checkbox := CheckBox.new()
		checkbox.text = name
		checkbox.connect("toggled", self, "_is_animating_changed")
		checkbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(checkbox)
		var value_slider: Control
		if initial_value_node is ValueSlider:
			value_slider = ValueSlider.new()
		elif initial_value_node is ValueSliderV2:
			value_slider = VALUE_SLIDER_V2_TSCN.instance()
		container.add_child(value_slider)
		value_slider.min_value = initial_value_node.min_value
		value_slider.max_value = initial_value_node.max_value
		value_slider.allow_lesser = initial_value_node.allow_lesser
		value_slider.allow_greater = initial_value_node.allow_greater
		value_slider.step = initial_value_node.step
		value_slider.snap_step = initial_value_node.snap_step
		value_slider.snap_by_default = initial_value_node.snap_by_default
		value_slider.value = initial_value_node.value
		final_value = value_slider.value
		value_slider.connect("value_changed", self, "_final_value_changed")
		value_slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		value_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var transition_types := OptionButton.new()
		transition_types.add_item("Linear")
		transition_types.add_item("Sine")
		transition_types.add_item("Quint")
		transition_types.add_item("Quart")
		transition_types.add_item("Quad")
		transition_types.add_item("Expo")
		transition_types.add_item("Elastic")
		transition_types.add_item("Cubic")
		transition_types.add_item("Circ")
		transition_types.add_item("Bounce")
		transition_types.add_item("Back")
		transition_types.connect("item_selected", self, "_trans_type_changed")
		transition_types.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		transition_types.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(transition_types)
		var ease_types := OptionButton.new()
		ease_types.add_item("Ease in")
		ease_types.add_item("Ease out")
		ease_types.add_item("Ease in out")
		ease_types.add_item("Ease out in")
		ease_types.connect("item_selected", self, "_ease_type_changed")
		ease_types.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		ease_types.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(ease_types)

	func _is_animating_changed(value: bool) -> void:
		is_animating = value

	func _initial_value_changed(value) -> void:
		initial_value = value

	func _final_value_changed(value) -> void:
		final_value = value

	func _trans_type_changed(value: int) -> void:
		trans_type = value

	func _ease_type_changed(value: int) -> void:
		ease_type = value

	func tween(tw: SceneTreeTween, current_frame: int, frame_count: int):
		var delta_value = final_value - initial_value
		var value = tw.interpolate_value(
			initial_value, delta_value, current_frame, frame_count, trans_type, ease_type
		)
		tw.kill()
		return value


func _ready() -> void:
	set_nodes()
	get_ok().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	get_cancel().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_frame.create(
		Global.current_project.size.x, Global.current_project.size.y, false, Image.FORMAT_RGBA8
	)
	selected_cels.create(
		Global.current_project.size.x, Global.current_project.size.y, false, Image.FORMAT_RGBA8
	)
	connect("about_to_show", self, "_about_to_show")
	connect("popup_hide", self, "_popup_hide")
	connect("confirmed", self, "_confirmed")
	if selection_checkbox:
		selection_checkbox.connect("toggled", self, "_on_SelectionCheckBox_toggled")
	if affect_option_button:
		affect_option_button.connect("item_selected", self, "_on_AffectOptionButton_item_selected")


func _about_to_show() -> void:
	confirmed = false
	Global.canvas.selection.transform_content_confirm()
	var frame: Frame = Global.current_project.frames[Global.current_project.current_frame]
	selected_cels.resize(Global.current_project.size.x, Global.current_project.size.y)
	selected_cels.fill(Color(0, 0, 0, 0))
	Export.blend_selected_cels(selected_cels, frame)
	current_frame.resize(Global.current_project.size.x, Global.current_project.size.y)
	current_frame.fill(Color(0, 0, 0, 0))
	Export.blend_all_layers(current_frame, frame)
	update_preview()
	update_transparent_background_size()
	animation_container.visible = not animatable_properties.empty()


func _confirmed() -> void:
	selected_idx = 0
	confirmed = true
	var project: Project = Global.current_project
	if affect == SELECTED_CELS:
		var undo_data := _get_undo_data(project)
		var frame_indices := []
		for cel_index in project.selected_cels:
			if !project.layers[cel_index[1]].can_layer_get_drawn():
				continue
			var cel: BaseCel = project.frames[cel_index[0]].cels[cel_index[1]]
			if not cel is PixelCel:
				continue
			var f: int = cel_index[0]
			if not f in frame_indices:
				# Make sure to only increase selected_idx on cels of different frames
				frame_indices.append(f)
				selected_idx += 1
			var cel_image: Image = cel.image
			commit_action(cel_image)
		_commit_undo("Draw", undo_data, project)

	elif affect == FRAME:
		var undo_data := _get_undo_data(project)
		var i := 0
		for cel in project.frames[project.current_frame].cels:
			if not cel is PixelCel:
				i += 1
				continue
			if project.layers[i].can_layer_get_drawn():
				commit_action(cel.image)
			i += 1
		_commit_undo("Draw", undo_data, project)

	elif affect == ALL_FRAMES:
		var undo_data := _get_undo_data(project)
		for frame in project.frames:
			var i := 0
			for cel in frame.cels:
				if not cel is PixelCel:
					i += 1
					continue
				if project.layers[i].can_layer_get_drawn():
					commit_action(cel.image)
				i += 1
			selected_idx += 1
		_commit_undo("Draw", undo_data, project)

	elif affect == ALL_PROJECTS:
		for _project in Global.projects:
			selected_idx = 0
			var undo_data := _get_undo_data(_project)
			for frame in _project.frames:
				var i := 0
				for cel in frame.cels:
					if not cel is PixelCel:
						i += 1
						continue
					if _project.layers[i].can_layer_get_drawn():
						commit_action(cel.image, _project)
					i += 1
				selected_idx += 1
			_commit_undo("Draw", undo_data, _project)


func commit_action(_cel: Image, _project: Project = Global.current_project) -> void:
	pass


func set_nodes() -> void:
	preview = $VBoxContainer/AspectRatioContainer/Preview
	selection_checkbox = $VBoxContainer/OptionsContainer/SelectionCheckBox
	affect_option_button = $VBoxContainer/OptionsContainer/AffectOptionButton
	animation_container = $VBoxContainer/AnimationContainer
	animation_container_grid = animation_container.get_node("GridContainer")


func add_animatable_property(property: AnimatableProperty) -> void:
	animatable_properties.append(property)
	property.create_nodes(animation_container_grid)


func get_animated_value(project: Project, final, property_idx: int):
	if animatable_properties.size() < property_idx + 1:
		return final
	var property: AnimatableProperty = animatable_properties[property_idx]
	if property.is_animating and confirmed:
		var frame_size := project.selected_cels.size()
		if affect == ALL_FRAMES or affect == ALL_PROJECTS:
			frame_size = project.frames.size()
		return property.tween(create_tween(), selected_idx, frame_size)
	else:
		return final


func _commit_undo(action: String, undo_data: Dictionary, project: Project) -> void:
	var redo_data := _get_undo_data(project)
	project.undos += 1
	project.undo_redo.create_action(action)
	for image in redo_data:
		project.undo_redo.add_do_property(image, "data", redo_data[image])
	for image in undo_data:
		project.undo_redo.add_undo_property(image, "data", undo_data[image])
	project.undo_redo.add_do_method(Global, "undo_or_redo", false, -1, -1, project)
	project.undo_redo.add_undo_method(Global, "undo_or_redo", true, -1, -1, project)
	project.undo_redo.commit_action()


func _get_undo_data(project: Project) -> Dictionary:
	var data := {}
	var images := _get_selected_draw_images(project)
	for image in images:
		image.unlock()
		data[image] = image.data
	return data


func _get_selected_draw_images(project: Project) -> Array:  # Array of Images
	var images := []
	if affect == SELECTED_CELS:
		for cel_index in project.selected_cels:
			var cel: BaseCel = project.frames[cel_index[0]].cels[cel_index[1]]
			if cel is PixelCel:
				images.append(cel.image)
	else:
		for frame in project.frames:
			for cel in frame.cels:
				if cel is PixelCel:
					images.append(cel.image)
	return images


func _on_SelectionCheckBox_toggled(_button_pressed: bool) -> void:
	update_preview()


func _on_AffectOptionButton_item_selected(index: int) -> void:
	affect = index
	update_preview()


func update_preview() -> void:
	match affect:
		SELECTED_CELS:
			preview_image.copy_from(selected_cels)
		_:
			preview_image.copy_from(current_frame)
	commit_action(preview_image)
	preview_image.unlock()
	preview_texture.create_from_image(preview_image, 0)
	preview.texture = preview_texture


func update_transparent_background_size() -> void:
	if !preview:
		return
	var image_size_y := preview.rect_size.y
	var image_size_x := preview.rect_size.x
	if preview_image.get_size().x > preview_image.get_size().y:
		var scale_ratio = preview_image.get_size().x / image_size_x
		image_size_y = preview_image.get_size().y / scale_ratio
	else:
		var scale_ratio = preview_image.get_size().y / image_size_y
		image_size_x = preview_image.get_size().x / scale_ratio

	preview.get_node("TransparentChecker").rect_size.x = image_size_x
	preview.get_node("TransparentChecker").rect_size.y = image_size_y


func _popup_hide() -> void:
	Global.dialog_open(false)


func _is_webgl1() -> bool:
	return OS.get_name() == "HTML5" and OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2
