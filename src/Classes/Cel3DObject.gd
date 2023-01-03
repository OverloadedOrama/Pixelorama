class_name Cel3DObject
extends Spatial

signal property_changed

enum Type { MESH, DIR_LIGHT, SPOT_LIGHT, OMNI_LIGHT }
enum Gizmos { NONE, X_POS, Y_POS, Z_POS, X_ROT, Y_ROT, Z_ROT, X_SCALE, Y_SCALE, Z_SCALE }

var cel
var type: int = Type.MESH
var mesh: Mesh
var selected := false
var hovered := false
var box_shape: BoxShape
var camera: Camera
var applying_gizmos := 0

var dir_light_texture := preload("res://assets/graphics/gizmos/directional_light.svg")

onready var gizmos_3d: Node2D = Global.canvas.gizmos_3d


func _ready() -> void:
	camera = get_viewport().get_camera()
	match type:
		Type.MESH:
			if mesh:
				var mesh_instance := MeshInstance.new()
				mesh_instance.mesh = mesh
				add_child(mesh_instance)
		Type.DIR_LIGHT:
			var light := DirectionalLight.new()
			gizmos_3d.add_always_visible(self, dir_light_texture)
			add_child(light)
		Type.SPOT_LIGHT:
			var light := SpotLight.new()
			add_child(light)
		Type.OMNI_LIGHT:
			var light := OmniLight.new()
			add_child(light)
	var static_body := StaticBody.new()
	var collision_shape := CollisionShape.new()
	box_shape = BoxShape.new()
	box_shape.extents = scale
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	add_child(static_body)


func find_cel() -> bool:
	var project: Project = Global.current_project
	return cel == project.frames[project.current_frame].cels[project.current_layer]


func serialize() -> Dictionary:
	return {"type": type, "mesh": mesh, "transform": transform}


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		unselect()
		gizmos_3d.remove_always_visible(self)


func select() -> void:
	selected = true
	gizmos_3d.get_points(camera, self)


func unselect() -> void:
	selected = false
	gizmos_3d.clear_points(self)


func hover() -> void:
	if hovered:
		return
	hovered = true
	if selected:
		return
	gizmos_3d.get_points(camera, self)


func unhover() -> void:
	if not hovered:
		return
	hovered = false
	if selected:
		return
	gizmos_3d.clear_points(self)


func delete() -> void:
	cel.remove_object(self)
	queue_free()


func change_transform(a: Vector3, b: Vector3) -> void:
	var diff := a - b
	match applying_gizmos:
		Gizmos.X_POS:
			move_axis(diff, transform.basis.x)
		Gizmos.Y_POS:
			move_axis(diff, transform.basis.y)
		Gizmos.Z_POS:
			move_axis(diff, transform.basis.z)
		Gizmos.X_ROT:
			change_rotation(a, b, transform.basis.x)
		Gizmos.Y_ROT:
			change_rotation(a, b, transform.basis.y)
		Gizmos.Z_ROT:
			change_rotation(a, b, transform.basis.z)
		Gizmos.X_SCALE:
			change_scale(diff, transform.basis.x, Vector3.RIGHT)
		Gizmos.Y_SCALE:
			change_scale(diff, transform.basis.y, Vector3.UP)
		Gizmos.Z_SCALE:
			change_scale(diff, transform.basis.z, Vector3.BACK)
		_:
			move(diff)


func move(position: Vector3) -> void:
	translation += position
	change_property()


func move_axis(diff: Vector3, axis: Vector3) -> void:
	# Move the object in the direction it is facing, and restrict mouse movement in that axis
	var axis_v2 := Vector2(axis.x, axis.y).normalized()
	if axis_v2 == Vector2.ZERO:
		axis_v2 = Vector2(axis.y, axis.z).normalized()
	var diff_v2 := Vector2(diff.x, diff.y).normalized()
	translation += axis * axis_v2.dot(diff_v2) * diff.length()
	change_property()


func change_rotation(a: Vector3, b: Vector3, axis: Vector3) -> void:
	var a_local := a - translation
	var a_local_v2 := Vector2(a_local.x, a_local.y)
	var b_local := b - translation
	var b_local_v2 := Vector2(b_local.x, b_local.y)
	var angle := b_local_v2.angle_to(a_local_v2)
	# Rotate the object around a basis axis, instead of a fixed axis, such as
	# Vector3.RIGHT, Vector3.UP or Vector3.BACK
	rotate(axis.normalized(), angle)
	rotation.x = wrapf(rotation.x, -PI, PI)
	rotation.y = wrapf(rotation.y, -PI, PI)
	rotation.z = wrapf(rotation.z, -PI, PI)
	change_property()


func change_scale(diff: Vector3, axis: Vector3, dir: Vector3) -> void:
	# Scale the object in the direction it is facing, and restrict mouse movement in that axis
	var axis_v2 := Vector2(axis.x, axis.y).normalized()
	if axis_v2 == Vector2.ZERO:
		axis_v2 = Vector2(axis.y, axis.z).normalized()
	var diff_v2 := Vector2(diff.x, diff.y).normalized()
	scale += dir * axis_v2.dot(diff_v2) * diff.length()
	change_property()


func change_property() -> void:
	select()
	emit_signal("property_changed")
