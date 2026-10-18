shader_type canvas_item;
render_mode blend_mix;

// Resolution of the SubViewport being displayed (the game's 800x600 screen).
// All pixel-sized effects are expressed in these source pixels so the look is
// stable regardless of the size the SubViewportContainer is drawn at.
uniform vec2 source_resolution = vec2(800.0, 600.0);

// --- Color controls ---
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float contrast   : hint_range(0.0, 2.0) = 1.05;
uniform float saturation : hint_range(0.0, 2.0) = 1.08;
uniform float gamma      : hint_range(0.2, 3.0) = 1.0;

// --- CRT geometry / lens ---
uniform float curvature     : hint_range(0.0, 0.40) = 0.05;
uniform float corner_soften : hint_range(0.0, 0.20) = 0.02;
uniform float vignette      : hint_range(0.0, 1.00) = 0.22;

// --- Scanlines / phosphor ---
uniform float scanline_strength : hint_range(0.0, 2.0) = 0.30;
uniform float scanline_density  : hint_range(0.5, 3.0) = 1.0; // 1.0 = one line per source row
uniform float interlace_strength: hint_range(0.0, 1.0) = 0.10;

// Shadow mask (RGB triads). Turn down if you hate the "screen door".
uniform float mask_strength : hint_range(0.0, 1.0) = 0.12;
uniform float mask_scale    : hint_range(0.5, 4.0) = 1.0; // bigger = chunkier triads

// --- VHS/VCR artifacts (off by default for a clean CRT) ---
uniform float chroma_offset_px : hint_range(0.0, 6.0) = 0.75; // RGB split in source pixels
uniform float luma_smear_px    : hint_range(0.0, 8.0) = 0.75; // horizontal smear
uniform float jitter_px        : hint_range(0.0, 8.0) = 0.0; // per-line horizontal jitter
uniform float wobble_px        : hint_range(0.0, 10.0) = 0.0; // slow wave wobble

uniform float tape_noise       : hint_range(0.0, 1.0) = 0.05; // grain + specks
uniform float tape_lines       : hint_range(0.0, 1.0) = 0.0; // horizontal "tracking" lines

uniform float roll_speed       : hint_range(0.0, 1.5) = 0.10; // vertical roll bar speed
uniform float roll_strength    : hint_range(0.0, 0.6) = 0.0; // roll bar intensity

// --- Bloom-ish glow (cheap) ---
uniform float glow_strength  : hint_range(0.0, 2.0) = 0.30;
uniform float glow_threshold : hint_range(0.0, 1.0) = 0.70;

float hash11(float n) {
	return fract(sin(n) * 43758.5453123);
}

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 crt_curve(vec2 uv, float k) {
	vec2 p = uv * 2.0 - 1.0;
	float r2 = dot(p, p);
	vec2 warped = p * (1.0 + k * r2);
	return warped * 0.5 + 0.5;
}

float inside01(vec2 uv) {
	// 1.0 if uv in [0..1], else 0.0
	return step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
}

vec3 apply_color_controls(vec3 c) {
	// brightness
	c *= brightness;

	// contrast around 0.5
	c = mix(vec3(0.5), c, contrast);

	// saturation
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(vec3(l), c, saturation);

	// gamma-ish
	c = pow(max(c, vec3(0.0)), vec3(1.0 / max(gamma, 0.0001)));
	return c;
}

vec3 triad_mask(vec2 frag_xy) {
	// Simple RGB triad mask across X.
	float x = floor(frag_xy.x / max(mask_scale, 0.0001));
	float m = mod(x, 3.0);
	// Slightly tinted triads
	if (m < 1.0) return vec3(1.10, 0.85, 0.85);
	if (m < 2.0) return vec3(0.85, 1.10, 0.85);
	return vec3(0.85, 0.85, 1.10);
}

void fragment() {
	vec2 src  = max(source_resolution, vec2(1.0));
	vec2 px   = 1.0 / src;
	float t   = TIME;

	// Start from the container UV
	vec2 uv = UV;

	// --- VHS line jitter (per scanline) ---
	float y_line = floor(uv.y * src.y);
	float jitter = (hash11(y_line + floor(t * 15.0) * 37.0) - 0.5) * 2.0;
	uv.x += jitter * (jitter_px * px.x);

	// Slow wobble
	uv.x += sin(uv.y * 8.0 + t * 1.2) * (wobble_px * px.x);

	// CRT curve. Normalize so the middle of each edge still samples the
	// full texture: only the corners get cropped/rounded.
	vec2 cuv = crt_curve(uv, curvature);
	cuv = (cuv - 0.5) / (1.0 + curvature) + 0.5;
	float in_bounds = inside01(cuv);

	// Rounded corners (soft clip)
	vec2 d = abs(cuv - 0.5) * 2.0;      // 0 at center, ~1 at edges
	float edge = max(d.x, d.y);

	// 1 in center, fades to 0 near edges
	float corner_mask = 1.0 - smoothstep(1.0 - corner_soften, 1.0, edge);

	// --- Chromatic aberration / VHS chroma shift ---
	vec2 chroma = vec2(chroma_offset_px * px.x, 0.0);
	vec3 chr_p = texture(TEXTURE, cuv + chroma).rgb;
	vec3 chr_0 = texture(TEXTURE, cuv).rgb;
	vec3 chr_m = texture(TEXTURE, cuv - chroma).rgb;
	vec3 col = vec3(chr_p.r, chr_0.g, chr_m.b);

	// --- Luma smear (horizontal) ---
	float smear = luma_smear_px * px.x;
	vec3 s1 = texture(TEXTURE, cuv + vec2(smear, 0.0)).rgb;
	vec3 s2 = texture(TEXTURE, cuv - vec2(smear, 0.0)).rgb;
	col = mix(col, (col + s1 + s2) / 3.0, 0.35);

	// --- Scanlines (fixed to the glass, one cycle per source row) ---
	float scan = sin(uv.y * src.y * 3.14159265 * scanline_density);
	float scan_mul = 1.0 - scanline_strength * (0.5 - 0.5 * scan); // darker troughs
	col *= scan_mul;

	// --- Interlacing (alternate rows flicker) ---
	float field = mod(floor(uv.y * src.y) + floor(t * 60.0), 2.0);
	col *= 1.0 - interlace_strength * field * 0.10;

	// --- Rolling tracking bar ---
	float roll_y = fract(t * max(roll_speed, 0.0001));
	float dist = abs(cuv.y - roll_y);
	float bar = smoothstep(0.20, 0.0, dist); // wide soft bar
	col += bar * roll_strength * vec3(0.12, 0.12, 0.12);

	// --- Tape lines (random horizontal streaks) ---
	float line_n = hash11(y_line * 0.7 + floor(t * 12.0) * 11.0);
	float line = smoothstep(0.985, 1.0, line_n) * tape_lines;
	col += line * vec3(0.18, 0.18, 0.18);

	// --- Grain / specks (source-pixel space) ---
	vec2 px_coord = uv * src;
	float n = hash12(px_coord + vec2(t * 120.0, t * 90.0));
	float grain = (n - 0.5) * 2.0;
	col += grain * (tape_noise * 0.06);

	// Occasional white specks
	float speck = smoothstep(0.995, 1.0, hash12(px_coord * 0.73 + t * 40.0));
	col += speck * (tape_noise * 0.25);

	// --- Cheap glow (cross blur on brights) ---
	vec3 c0 = col;
	vec3 cx1 = texture(TEXTURE, cuv + vec2(px.x, 0.0)).rgb;
	vec3 cx2 = texture(TEXTURE, cuv - vec2(px.x, 0.0)).rgb;
	vec3 cy1 = texture(TEXTURE, cuv + vec2(0.0, px.y)).rgb;
	vec3 cy2 = texture(TEXTURE, cuv - vec2(0.0, px.y)).rgb;
	vec3 blur = (c0 + cx1 + cx2 + cy1 + cy2) / 5.0;
	float br = dot(blur, vec3(0.2126, 0.7152, 0.0722));
	vec3 glow = max(blur - vec3(glow_threshold), vec3(0.0));
	col += glow * glow_strength * (0.5 + 0.5 * br);

	// --- Vignette ---
	vec2 v = cuv - 0.5;
	float vig = smoothstep(0.9, 0.2, dot(v, v) * 2.2);
	col *= mix(1.0 - vignette, 1.0, vig);

	// --- Shadow mask triads (fixed to the glass) ---
	vec3 mask = triad_mask(uv * src);
	col *= mix(vec3(1.0), mask, mask_strength);

	// Color grading last
	col = apply_color_controls(col);

	COLOR = vec4(col, in_bounds * corner_mask);
}
