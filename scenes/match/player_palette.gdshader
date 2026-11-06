shader_type canvas_item;

// La fila 0 contiene los colores originales del sprite. Solo se sustituyen
// esas muestras: se conservan el contorno, los detalles y las animaciones.
//
// Columnas de la paleta (cada fila es una equipación):
//   0-1 medias (claro, oscuro) | 2-3 pantalón | 4-5 camiseta | 6-7 camiseta secundaria
// La camiseta secundaria solo se usa en los patrones de shirt_pattern.
uniform sampler2D team_palette : source_color, filter_nearest, repeat_disable;
uniform sampler2D skin_palette : source_color, filter_nearest, repeat_disable;
// Equipación: 1 = blanca / azul; 8 = azul / roja (selección).
// Liga 1: 9 = Melgar, 10 = Alianza Lima, 11 = Sporting Cristal, 12 = Cienciano.
uniform int team_row : hint_range(0, 12) = 1;
// Piel: 0 = clara, 1 = intermedia, 2 = oscura.
uniform int skin_row : hint_range(0, 2) = 0;
// Diseño de la camiseta: 0 = liso, 1 = mitades (Melgar), 2 = franjas verticales (Alianza).
uniform int shirt_pattern : hint_range(0, 2) = 0;

const float FRAME_SIZE = 32.0;
const int FRAME_COLUMNS = 6;
const int FRAME_COUNT = 78;
// Centro horizontal de la camiseta en cada fotograma de la hoja de sprites,
// para que mitades y franjas sigan al torso en cada animación.
const float SHIRT_CENTER[78] = float[78](15.2, 15.1, 14.9, 14.7, 16.0, 16.0, 14.3, 13.4, 14.2, 12.7, 12.6, 14.2, 13.9, 13.9, 14.2, 13.1, 14.2, 14.1, 13.8, 16.0, 16.0, 16.0, 16.0, 16.0, 12.7, 15.4, 16.0, 16.0, 16.0, 16.0, 15.0, 16.0, 16.0, 16.0, 16.0, 16.0, 15.4, 18.1, 18.7, 16.0, 16.0, 16.0, 14.8, 16.0, 16.0, 16.0, 16.0, 16.0, 13.4, 14.6, 16.7, 17.5, 16.0, 16.0, 14.7, 14.7, 16.0, 16.0, 16.0, 16.0, 16.3, 14.7, 16.5, 16.0, 16.0, 16.0, 14.4, 16.0, 16.0, 16.0, 16.0, 16.0, 15.2, 16.0, 16.0, 16.0, 16.0, 16.0);

varying vec4 sprite_modulate;

void vertex() {
	sprite_modulate = COLOR;
}

bool use_secondary_shirt(vec2 uv) {
	if (shirt_pattern == 0) {
		return false;
	}
	// UV recorre toda la hoja: se obtiene el fotograma y la X dentro de él.
	vec2 pixel = uv / TEXTURE_PIXEL_SIZE;
	int frame_x = int(floor(pixel.x / FRAME_SIZE));
	int frame_y = int(floor(pixel.y / FRAME_SIZE));
	int frame = clamp(frame_y * FRAME_COLUMNS + frame_x, 0, FRAME_COUNT - 1);
	float local_x = pixel.x - float(frame_x) * FRAME_SIZE;
	float center = SHIRT_CENTER[frame];
	if (shirt_pattern == 1) {
		return local_x >= center;
	}
	return abs(int(floor((local_x - center + 1.5) / 3.0))) % 2 == 0;
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec3 replacement = original.rgb;
	vec2 palette_size = vec2(textureSize(team_palette, 0));
	float row_y = (float(team_row) + 0.5) / palette_size.y;
	for (int column = 0; column < 6; column++) {
		float source_x = (float(column) + 0.5) / palette_size.x;
		vec3 source = texture(team_palette, vec2(source_x, 0.5 / palette_size.y)).rgb;
		if (distance(original.rgb, source) < 0.001) {
			int target_column = column;
			if (column >= 4 && use_secondary_shirt(UV)) {
				target_column = column + 2;
			}
			float target_x = (float(target_column) + 0.5) / palette_size.x;
			replacement = texture(team_palette, vec2(target_x, row_y)).rgb;
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
