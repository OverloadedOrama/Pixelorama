extends Spatial

var wireframe_shader := preload("res://src/Shaders/Wireframe.gdshader")


func _ready() -> void:
	var static_body := StaticBody.new()
	var collision_shape := CollisionShape.new()
	var box_shape := BoxShape.new()
	box_shape.extents = scale + Vector3(0.2, 0.2, 0.2)
	var outline := MeshInstance.new()
	outline.mesh = CubeMesh.new()
	outline.scale = box_shape.extents
	var shader_material := ShaderMaterial.new()
	shader_material.shader = wireframe_shader
	outline.set_surface_material(0, shader_material)
#	outline.material = shader_material
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	add_child(static_body)
	add_child(outline)


func select() -> void:
	print("Selected")
