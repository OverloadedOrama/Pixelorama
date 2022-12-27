extends Spatial

var hovering: Object3D = null
var selected: Object3D = null


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed == true:
			if is_instance_valid(hovering):
				hovering.select()
				if is_instance_valid(selected) and hovering != selected:
					selected.unselect()
				selected = hovering
			else:
				if is_instance_valid(selected):
					selected.unselect()
					selected = null
#	print(event.position)
	var mouse_pos: Vector2 = event.position
	var camera := get_viewport().get_camera()
	var ray_from := camera.project_ray_origin(mouse_pos)
	var ray_to := ray_from + camera.project_ray_normal(mouse_pos) * 20
	var space_state := get_world().direct_space_state
	var selection := space_state.intersect_ray(ray_from, ray_to)
	if selection.empty():
		if is_instance_valid(hovering):
			hovering.unhover()
			hovering = null
	else:
		if is_instance_valid(hovering):
			hovering.unhover()
		hovering = selection["collider"].get_parent()
		hovering.hover()
#		print(hovering)
#	print(selection)
