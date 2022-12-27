extends Spatial

var hovering: Spatial = null


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and is_instance_valid(hovering):
		if event.button_index == BUTTON_LEFT and event.pressed == true:
			hovering.select()
#	print(event.position)
	var mouse_pos: Vector2 = event.position
	var camera := get_viewport().get_camera()
	var ray_from := camera.project_ray_origin(mouse_pos)
	var ray_to := ray_from + camera.project_ray_normal(mouse_pos) * 20
	var space_state := get_world().direct_space_state
	var selection := space_state.intersect_ray(ray_from, ray_to)
	if selection.empty():
		hovering = null
	else:
		hovering = selection["collider"].get_parent()
		print(hovering)
#	print(selection)
