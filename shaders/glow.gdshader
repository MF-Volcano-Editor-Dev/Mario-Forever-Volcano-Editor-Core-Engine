// modified from https://godotshaders.com/shader/smooth-outline-2d/

shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform bool glow = true;
uniform float glow_scalar : hint_range(0.0, 10.0) = 1.0;
uniform float width : hint_range(0.0, 64) = 4.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform int pixel_size : hint_range(1, 10) = 1;

void fragment()
{
    vec2 unit = 1.0/float(pixel_size) * SCREEN_PIXEL_SIZE;
    vec4 pixel_color = textureLod(screen_texture, SCREEN_UV, 0.0);
    if (pixel_color.a < threshold) {
        pixel_color = outline_color;
        pixel_color.a = 0.0;
        for (float x = -ceil(width); x <= ceil(width); x++) {
            for (float y = -ceil(width); y <= ceil(width); y++) {
                if (textureLod(screen_texture, SCREEN_UV + vec2(x*unit.x, y*unit.y), 0.0).a < threshold || (x==0.0 && y==0.0)) {
                    continue;
                }
                if (glow) {
                    pixel_color.a += outline_color.a / (pow(x,2)+pow(y,2)) * (1.0-pow(2.0, -width)) / glow_scalar;
                    if (pixel_color.a > 1.0) {
                        pixel_color.a = 1.0;
                    }
                } else {
                    pixel_color.a = outline_color.a;
                }
            }
        }
    }
    COLOR = pixel_color;
}