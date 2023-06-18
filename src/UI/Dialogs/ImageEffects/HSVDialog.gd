extends ImageEffect

enum Animate { HUE, SATURATION, VALUE }
var shader: Shader = preload("res://src/Shaders/HSV.shader")

onready var hue_slider := $VBoxContainer/HueSlider as ValueSlider
onready var sat_slider := $VBoxContainer/SaturationSlider as ValueSlider
onready var val_slider := $VBoxContainer/ValueSlider as ValueSlider


func _ready() -> void:
	var sm := ShaderMaterial.new()
	sm.shader = shader
	preview.set_material(sm)
	add_animatable_property(AnimatableProperty.new("Hue", hue_slider))
	add_animatable_property(AnimatableProperty.new("Saturation", sat_slider))
	add_animatable_property(AnimatableProperty.new("Value", val_slider))


func _about_to_show() -> void:
	_reset()
	._about_to_show()


func commit_action(cel: Image, project: Project = Global.current_project) -> void:
	.commit_action(cel, project)
	var hue: float = get_animated_value(project, hue_slider.value, Animate.HUE) / 360
	var sat: float = get_animated_value(project, sat_slider.value, Animate.SATURATION) / 100
	var val: float = get_animated_value(project, val_slider.value, Animate.VALUE) / 100
	var selection_tex := ImageTexture.new()
	if selection_checkbox.pressed and project.has_selection:
		selection_tex.create_from_image(project.selection_map, 0)

	var params := {"hue_shift": hue, "sat_shift": sat, "val_shift": val, "selection": selection_tex}
	if !confirmed:
		for param in params:
			preview.material.set_shader_param(param, params[param])
	else:
		var gen := ShaderImageEffect.new()
		gen.generate_image(cel, shader, params, project.size)
		yield(gen, "done")


func _reset() -> void:
	hue_slider.value = 0
	sat_slider.value = 0
	val_slider.value = 0
	confirmed = false


func _on_HueSlider_value_changed(_value: float) -> void:
	update_preview()


func _on_SaturationSlider_value_changed(_value: float) -> void:
	update_preview()


func _on_ValueSlider_value_changed(_value: float) -> void:
	update_preview()
