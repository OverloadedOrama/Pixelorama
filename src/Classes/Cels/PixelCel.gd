class_name PixelCel
extends BaseCel
## A class for the properties of cels in PixelLayers.
## The term "cel" comes from "celluloid" (https://en.wikipedia.org/wiki/Cel).

## This variable is where the image data of the cel are.
var image: ImageExtended:
	set = image_changed


func _init(_image := ImageExtended.new(), _opacity := 1.0) -> void:
	image_texture = ImageTexture.new()
	image = _image  # Set image and call setter
	opacity = _opacity


func image_changed(value: ImageExtended) -> void:
	image = value
	if not image.is_empty() and is_instance_valid(image_texture):
		image_texture.set_image(image)


func set_indexed_mode(indexed: bool) -> void:
	image.is_indexed = indexed
	if image.is_indexed:
		image.resize_indices()
		image.select_palette("", false)
		image.convert_rgb_to_indexed()


## Grow the image so a canvas-space point is inside it,
## shifting the cel's [member offset] if needed. Returns the coordinate in the cel's local space.
func ensure_canvas_point_in_bounds(canvas_pos: Vector2i) -> Vector2i:
	if image.is_invisible():
		change_offset(canvas_pos)
	var local := canvas_pos - offset
	var new_offset := offset
	var new_size := image.get_size()
	if local.x < 0:
		new_size.x += -local.x
		new_offset.x += local.x
		local.x = 0
	elif local.x >= new_size.x:
		new_size.x = local.x + 1
		local.x = new_size.x - 1
	if local.y < 0:
		new_size.y += -local.y
		new_offset.y += local.y
		local.y = 0
	elif local.y >= new_size.y:
		new_size.y = local.y + 1
		local.y = new_size.y - 1
	if new_size != Vector2i(image.get_size()):
		resize_image(new_size, offset - new_offset)
		change_offset(new_offset)
	return local


func resize_image(new_size: Vector2i, content_offset: Vector2i) -> void:
	var new_image := ImageExtended.create_custom(
		new_size.x, new_size.y, false, image.get_format(), image.is_indexed
	)
	new_image.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), content_offset)
	image.copy_from(new_image)


## Reads data from a [param dict] [Dictionary], and uses them to add methods to [param undo_redo].
func deserialize_undo_data(dict: Dictionary, undo_redo: UndoRedo, undo: bool) -> void:
	if undo:
		if dict.has("offset"):
			undo_redo.add_undo_method(change_offset.bind(dict.offset))
	else:
		if dict.has("offset"):
			undo_redo.add_do_method(change_offset.bind(dict.offset))


func get_content() -> Variant:
	return image


func set_content(content, texture: ImageTexture = null) -> void:
	var proper_content: ImageExtended
	if content is not ImageExtended:
		proper_content = ImageExtended.new()
		proper_content.copy_from_custom(content, image.is_indexed)
	else:
		proper_content = content
	image = proper_content
	if is_instance_valid(texture) and is_instance_valid(texture.get_image()):
		image_texture = texture
		if image_texture.get_image().get_size() != image.get_size():
			image_texture.set_image(image)
	else:
		image_texture.update(image)


func create_empty_content() -> Variant:
	var empty := Image.create(image.get_width(), image.get_height(), false, image.get_format())
	var new_image := ImageExtended.new()
	new_image.copy_from_custom(empty, image.is_indexed)
	return new_image


func copy_content() -> Variant:
	var tmp_image := Image.create_from_data(
		image.get_width(), image.get_height(), false, image.get_format(), image.get_data()
	)
	var copy_image := ImageExtended.new()
	copy_image.copy_from_custom(tmp_image, image.is_indexed)
	return copy_image


func get_image() -> ImageExtended:
	return image


func update_texture(undo := false) -> void:
	image_texture.set_image(image)
	super.update_texture(undo)


func get_class_name() -> String:
	return "PixelCel"
