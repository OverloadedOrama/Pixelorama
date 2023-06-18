extends ImageEffect

enum Animate { OFFSET }
var offset := Vector2(5, 5)
var color := Color.black
var shader: Shader = load("res://src/Shaders/DropShadow.tres")

onready var offset_sliders := $VBoxContainer/ShadowOptions/OffsetSliders as ValueSliderV2
onready var shadow_color := $VBoxContainer/ShadowOptions/ShadowColor as ColorPickerButton


func _ready() -> void:
	shadow_color.get_picker().presets_visible = false
	color = shadow_color.color
	var sm := ShaderMaterial.new()
	sm.shader = shader
	preview.set_material(sm)
	add_animatable_property(AnimatableProperty.new("Offset", offset_sliders))


func commit_action(cel: Image, project: Project = Global.current_project) -> void:
	.commit_action(cel, project)
	var anim_offset: Vector2 = get_animated_value(project, offset, Animate.OFFSET)
	var selection_tex := ImageTexture.new()
	if selection_checkbox.pressed and project.has_selection:
		selection_tex.create_from_image(project.selection_map, 0)

	var params := {"shadow_offset": anim_offset, "shadow_color": color, "selection": selection_tex}
	if !confirmed:
		for param in params:
			preview.material.set_shader_param(param, params[param])
	else:
		var gen := ShaderImageEffect.new()
		gen.generate_image(cel, shader, params, project.size)
		yield(gen, "done")


func _on_OffsetSliders_value_changed(value: Vector2) -> void:
	offset = value
	update_preview()


func _on_ShadowColor_color_changed(value: Color) -> void:
	color = value
	update_preview()
