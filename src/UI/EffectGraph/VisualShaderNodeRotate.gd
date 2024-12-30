@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeRotate


func _get_name() -> String:
	return "Rotate"


func _get_category() -> String:
	return "Utility"


func _get_description() -> String:
	return "Nearest Neighbor Rotation"


func _init() -> void:
	set_input_port_default_value(0, 0.0)
	set_input_port_default_value(2, Vector2(0.5, 0.5))


func _get_return_icon_type() -> VisualShaderNode.PortType:
	return VisualShaderNode.PORT_TYPE_VECTOR_2D


func _get_input_port_count() -> int:
	return 3


func _get_input_port_name(port: int) -> String:
	match port:
		0:
			return "angle"
		1:
			return "uv"
		2:
			return "pivot"
		_:
			return ""


func _get_input_port_type(port: int) -> VisualShaderNode.PortType:
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_SCALAR
		1:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		2:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		3:
			return VisualShaderNode.PORT_TYPE_SCALAR
		_:
			return VisualShaderNode.PORT_TYPE_MAX


func _get_output_port_count() -> int:
	return 1


func _get_output_port_name(_port: int) -> String:
	return "result"


func _get_output_port_type(_port: int) -> VisualShaderNode.PortType:
	return VisualShaderNode.PORT_TYPE_VECTOR_2D


func _get_global_code(_mode: Shader.Mode) -> String:
	return """
		vec2 rotate(float angle, vec2 uv, vec2 pivot) {
			mat2 transformation_matrix = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
			// Scale and center image
			//uv.x = (uv.x - pivot.x) * ratio + pivot.x;
			uv -= pivot;

			// Rotate image
			uv *= transformation_matrix;
			//uv.x /= ratio;
			uv += pivot;

			return uv;
		}
	"""


func _get_code(
	input_vars: Array[String],
	output_vars: Array[String],
	_mode: Shader.Mode,
	_type: VisualShader.Type
) -> String:
	var angle := input_vars[0]
	if angle.is_empty():
		angle = str(get_input_port_default_value(0))
	var uv := input_vars[1]
	if uv.is_empty():
		uv = "UV"
	var pivot := input_vars[2]
	if pivot.is_empty():
		pivot = str(get_input_port_default_value(2))
	return (
		output_vars[0]
		+ " = rotate(%s, %s, %s);" % [angle, uv, pivot]
	)
