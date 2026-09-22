extends Node2D


func _draw() -> void:
	# Placeholder so we can have a material here
	var image_to_draw := Global.current_project.new_empty_image()
	draw_texture(ImageTexture.create_from_image(image_to_draw), Vector2.ZERO)
