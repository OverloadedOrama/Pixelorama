extends Spatial

var hovering: Object3D = null
var selected: Object3D = null
var dragging := false

onready var camera := get_viewport().get_camera()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed == true:
			if is_instance_valid(hovering):
				hovering.select()
				if is_instance_valid(selected):
					# Unselect previous object if we're hovering something else
					if hovering != selected:
						selected.unselect()
				selected = hovering
				dragging = true
			else:
				# We're not hovering, which means we're unselecting
				if is_instance_valid(selected):
					selected.unselect()
					selected = null
		elif event.button_index == BUTTON_LEFT and event.pressed == false:
			dragging = false
#	print(event.position)
	var mouse_pos: Vector2 = event.position

	var ray_from := camera.project_ray_origin(mouse_pos)
	var ray_to := ray_from + camera.project_ray_normal(mouse_pos) * 20
	var space_state := get_world().direct_space_state
	var selection := space_state.intersect_ray(ray_from, ray_to)

	if dragging and event is InputEventMouseMotion:
		var projected := camera.project_position(mouse_pos, 4)
		selected.move(projected)

	# Hover logic
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
