// https://godotengine.org/qa/22714/how-to-render-a-wireframe?show=88004#a88004
shader_type spatial;
render_mode unshaded;

void fragment() {
	float distance_from_edge = min(
		min(
			min( UV.x, UV.y ),
			min( abs( 1.0 - UV.x ), abs( 1.0- UV.y ) ) ),
		abs( UV.x + UV.y ) 
		);
	if (distance_from_edge < 0.03 ) {
		ALBEDO = vec3( 0.0, 0.0, 0.0 );
	}
	else {
		ALBEDO = vec3( 1.0, 1.0, 1.0 );
		ALPHA = 0.0;
	}
}
