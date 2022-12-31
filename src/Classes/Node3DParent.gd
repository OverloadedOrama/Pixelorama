extends Spatial

var cel
var hovering: Object3D = null
var selected: Object3D = null
var dragging := false
var prev_mouse_pos := Vector2.ZERO

onready var camera := get_viewport().get_camera()


func _input(event: InputEvent) -> void:
	var found_cel := false
	for frame_layer in Global.current_project.selected_cels:
		if cel == Global.current_project.frames[frame_layer[0]].cels[frame_layer[1]]:
			found_cel = true
	if not found_cel:
		return
	var mouse_pos: Vector2 = event.position
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
				prev_mouse_pos = mouse_pos
			else:
				# We're not hovering, which means we're unselecting
				if is_instance_valid(selected):
					selected.unselect()
					selected = null
		elif event.button_index == BUTTON_LEFT and event.pressed == false:
			dragging = false

	var ray_from := camera.project_ray_origin(mouse_pos)
	var ray_to := ray_from + camera.project_ray_normal(mouse_pos) * 20
	var space_state := get_world().direct_space_state
	var selection := space_state.intersect_ray(ray_from, ray_to)

	if dragging and event is InputEventMouseMotion:
		var prev_projected := camera.project_position(prev_mouse_pos, camera.translation.z)
		var projected := camera.project_position(mouse_pos, camera.translation.z)
		if selected.applying_gizmos == Object3D.Gizmos.X_TRANS:
			selected.move(Vector3(projected.x - prev_projected.x, 0, 0))
		elif selected.applying_gizmos == Object3D.Gizmos.Y_TRANS:
			selected.move(Vector3(0, projected.y - prev_projected.y, 0))
		elif selected.applying_gizmos == Object3D.Gizmos.Z_TRANS:
			selected.move(Vector3(0, 0, projected.x - prev_projected.x))
		elif selected.applying_gizmos == Object3D.Gizmos.X_ROT:
			selected.change_rotation(Vector3(projected.x - prev_projected.x, 0, 0))
		elif selected.applying_gizmos == Object3D.Gizmos.Y_ROT:
			selected.change_rotation(Vector3(0, projected.y - prev_projected.y, 0))
		elif selected.applying_gizmos == Object3D.Gizmos.Z_ROT:
			selected.change_rotation(Vector3(0, 0, projected.x - prev_projected.x))
		elif selected.applying_gizmos == Object3D.Gizmos.X_SCALE:
			selected.change_scale(Vector3(projected.x - prev_projected.x, 0, 0))
		elif selected.applying_gizmos == Object3D.Gizmos.Y_SCALE:
			selected.change_scale(Vector3(0, projected.y - prev_projected.y, 0))
		elif selected.applying_gizmos == Object3D.Gizmos.Z_SCALE:
			selected.change_scale(Vector3(0, 0, projected.x - prev_projected.x))
		else:
			selected.move(projected - prev_projected)
		prev_mouse_pos = mouse_pos

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
