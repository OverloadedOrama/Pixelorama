extends Spatial


func _ready() -> void:
	var static_body := StaticBody.new()
	var collision_shape := CollisionShape.new()
	var box_shape := BoxShape.new()
	box_shape.extents = scale + Vector3(0.2, 0.2, 0.2)
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	add_child(static_body)


func _input(event: InputEvent) -> void:
#	print(event.position)
	var mouse_pos = event.position
	var camera := get_viewport().get_camera()
	var ray_from = camera.project_ray_origin(mouse_pos)
	var ray_to = ray_from + camera.project_ray_normal(mouse_pos) * 20
	var space_state = get_world().direct_space_state
	var selection = space_state.intersect_ray(ray_from, ray_to)
	print(selection)
