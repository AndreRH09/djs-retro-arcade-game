shader_type canvas_item;

// La fila 0 contiene los colores originales del sprite. Solo se sustituyen
// esas muestras: se conservan el contorno, los detalles y las animaciones.
uniform sampler2D team_palette : source_color, filter_nearest, repeat_disable;
uniform sampler2D skin_palette : source_color, filter_nearest, repeat_disable;
// Equipación: 1 = camiseta blanca / pantalón azul; 8 = azul / rojo.
uniform int team_row : hint_range(0, 8) = 1;
// Piel: 0 = clara, 1 = intermedia, 2 = oscura.
uniform int skin_row : hint_range(0, 2) = 0;

varying vec4 sprite_modulate;

void vertex() {
	sprite_modulate = COLOR;
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec3 replacement = original.rgb;
	for (int column = 0; column < 6; column++) {
		float x = (float(column) + 0.5) / 6.0;
		vec3 source = texture(team_palette, vec2(x, 0.5 / 9.0)).rgb;
		if (distance(original.rgb, source) < 0.001) {
			replacement = texture(team_palette, vec2(x, (float(team_row) + 0.5) / 9.0)).rgb;
		}
	}
	for (int column = 0; column < 4; column++) {
		float x = (float(column) + 0.5) / 4.0;
		vec3 source = texture(skin_palette, vec2(x, 0.5 / 3.0)).rgb;
		if (distance(original.rgb, source) < 0.001) {
			replacement = texture(skin_palette, vec2(x, (float(skin_row) + 0.5) / 3.0)).rgb;
		}
	}
	COLOR = vec4(replacement, original.a) * sprite_modulate;
}
