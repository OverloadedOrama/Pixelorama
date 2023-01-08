extends Panel

onready var dockable_container: Container = $DockableContainer
onready var main_canvas_container: Container = $"%Main Canvas"
onready var global_tool_options: PanelContainer = $"%Global Tool Options"
onready var left_tool_options: ScrollContainer = $"%Left Tool Options"
onready var right_tool_options: ScrollContainer = $"%Right Tool Options"
onready var palettes: PanelContainer = $"%Palettes"
onready var options_3d: PanelContainer = $"%3D Options"


func _ready() -> void:
	Global.connect("cel_changed", self, "_cel_changed")
	update_transparent_shader()


func _cel_changed() -> void:
	if Global.current_project.get_current_cel() is Cel3D:
		dockable_container.set_control_hidden(global_tool_options, true)
		dockable_container.set_control_hidden(left_tool_options, true)
		dockable_container.set_control_hidden(right_tool_options, true)
		dockable_container.set_control_hidden(palettes, true)
		dockable_container.set_control_hidden(options_3d, false)
	else:
		dockable_container.set_control_hidden(global_tool_options, false)
		dockable_container.set_control_hidden(left_tool_options, false)
		dockable_container.set_control_hidden(right_tool_options, false)
		dockable_container.set_control_hidden(palettes, false)
		dockable_container.set_control_hidden(options_3d, true)


func _on_main_canvas_item_rect_changed() -> void:
	update_transparent_shader()


func _on_main_canvas_visibility_changed() -> void:
	update_transparent_shader()


func update_transparent_shader() -> void:
	# Works independently of the transparency feature
	var canvas_size: Vector2 = (main_canvas_container.rect_size - Vector2.DOWN * 2) * Global.shrink
	material.set("shader_param/screen_resolution", get_viewport().size)
	material.set(
		"shader_param/position", main_canvas_container.rect_global_position * Global.shrink
	)
	material.set("shader_param/size", canvas_size)
