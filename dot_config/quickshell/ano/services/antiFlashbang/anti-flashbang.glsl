#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

float overlayOpacityForBrightness(float x) {
    float y = x * 0.75;
    return min(max(y, 0.001), 1.0);
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // Sample 10x10 grid (100 samples) for average brightness
    vec3 totalRGB = vec3(0.0);
    float samples = 0.0;
    for(float x = 0.05; x < 1.0; x += 0.1) {
        for(float y = 0.05; y < 1.0; y += 0.1) {
            totalRGB += texture(tex, vec2(x, y)).rgb;
            samples++;
        }
    }

    vec3 avgColor = totalRGB / samples;
    float globalBrightness = dot(avgColor, vec3(0.2126, 0.7152, 0.0722));
    float opacity = overlayOpacityForBrightness(globalBrightness);
    vec3 outColor = mix(pixColor.rgb, vec3(0.0), opacity);

    fragColor = vec4(outColor, pixColor.a);
}
