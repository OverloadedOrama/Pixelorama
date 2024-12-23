class_name ShaderImageEffect
extends RefCounted
## Helper class to generate image effects using shaders

signal done


func generate_image(
	img: Image, shader: Shader, params: Dictionary, size: Vector2i, respect_indexed := true
) -> void:
	# duplicate shader before modifying code to avoid affecting original resource
	var resized_width := false
	var resized_height := false
	if size.x == 1:
		size.x = 2
		img.crop(2, img.get_height())
		resized_width = true
	if size.y == 1:
		size.y = 2
		img.crop(img.get_width(), 2)
		resized_height = true
	shader = shader.duplicate()
	shader.code = shader.code.replace("unshaded", "unshaded, blend_premul_alpha")
	var filter := RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	var repeat := RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_DEFAULT
	var filter_str := "PXO_SET_FILTER="
	var repeat_str := "PXO_SET_REPEAT="
	var filter_idx := shader.code.find(filter_str)
	if filter_idx != -1:
		var filter_to_set := int(shader.code[filter_idx + filter_str.length()])
		if filter_to_set > 0 and filter_to_set < RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_MAX:
			filter = filter_to_set
	var repeat_idx := shader.code.find(repeat_str)
	if repeat_idx != -1:
		var repeat_to_set := int(shader.code[repeat_idx + repeat_str.length()])
		if repeat_to_set > 0 and repeat_to_set < RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_MAX:
			repeat = repeat_to_set
	var vp := RenderingServer.viewport_create()
	var canvas := RenderingServer.canvas_create()
	RenderingServer.viewport_attach_canvas(vp, canvas)
	RenderingServer.viewport_set_size(vp, size.x, size.y)
	RenderingServer.viewport_set_disable_3d(vp, true)
	RenderingServer.viewport_set_active(vp, true)
	RenderingServer.viewport_set_transparent_background(vp, true)
	RenderingServer.viewport_set_default_canvas_item_texture_filter(vp, filter)
	if repeat != RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_DEFAULT:
		RenderingServer.viewport_set_default_canvas_item_texture_repeat(vp, repeat)
	var ci_rid := RenderingServer.canvas_item_create()
	RenderingServer.viewport_set_canvas_transform(vp, canvas, Transform3D())
	RenderingServer.canvas_item_set_parent(ci_rid, canvas)
	var texture := RenderingServer.texture_2d_create(img)
	RenderingServer.canvas_item_add_texture_rect(ci_rid, Rect2(Vector2.ZERO, size), texture)

	var mat_rid := RenderingServer.material_create()
	RenderingServer.material_set_shader(mat_rid, shader.get_rid())
	RenderingServer.canvas_item_set_material(ci_rid, mat_rid)
	for key in params:
		var param = params[key]
		if param is Texture2D or param is Texture2DArray:
			RenderingServer.material_set_param(mat_rid, key, [param])
		else:
			RenderingServer.material_set_param(mat_rid, key, param)

	RenderingServer.viewport_set_update_mode(vp, RenderingServer.VIEWPORT_UPDATE_ONCE)
	RenderingServer.force_draw(false)
	var viewport_texture := RenderingServer.texture_2d_get(RenderingServer.viewport_get_texture(vp))
	RenderingServer.free_rid(vp)
	RenderingServer.free_rid(canvas)
	RenderingServer.free_rid(ci_rid)
	RenderingServer.free_rid(mat_rid)
	RenderingServer.free_rid(texture)
	viewport_texture.convert(img.get_format())
	img.copy_from(viewport_texture)
	if resized_width:
		img.crop(img.get_width() - 1, img.get_height())
	if resized_height:
		img.crop(img.get_width(), img.get_height() - 1)
	if img is ImageExtended and respect_indexed:
		img.convert_rgb_to_indexed()
	done.emit()
