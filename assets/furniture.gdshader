shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

//void fragment() {
	//// Called for every pixel the material is visible on.
//}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}


uniform vec4 outline_color = vec4(1,1,0,1);
uniform float thickness = 0.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * thickness;
    vec4 col = texture(TEXTURE, UV);

    float alpha = col.a;

    if (alpha == 0.0) {
        float sum = 0.0;
        sum += texture(TEXTURE, UV + vec2(size.x, 0)).a;
        sum += texture(TEXTURE, UV - vec2(size.x, 0)).a;
        sum += texture(TEXTURE, UV + vec2(0, size.y)).a;
        sum += texture(TEXTURE, UV - vec2(0, size.y)).a;

        if (sum > 0.0) {
            COLOR = outline_color;
            //return;
        }
    }
	else
    	COLOR = col;
}
