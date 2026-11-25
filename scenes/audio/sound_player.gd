extends Node
## Reproduce efectos de sonido cortos desde varios canales. Se registra como autoload
## "SoundPlayer"; cualquier script puede llamar SoundPlayer.play(SoundPlayer.Sound.PASS).

enum Sound {BOUNCE, HURT, PASS, POWERSHOT, SHOT, TACKLING, UI_NAV, UI_SELECT, WHISTLE}

const CHANNEL_COUNT := 6
const SFX_MAP: Dictionary[Sound, AudioStream] = {
	Sound.BOUNCE: preload("res://assets/sfx/bounce.wav"),
	Sound.HURT: preload("res://assets/sfx/hurt.wav"),
	Sound.PASS: preload("res://assets/sfx/pass.wav"),
	Sound.POWERSHOT: preload("res://assets/sfx/power-shot.wav"),
	Sound.SHOT: preload("res://assets/sfx/shoot.wav"),
	Sound.TACKLING: preload("res://assets/sfx/tackle.wav"),
	Sound.UI_NAV: preload("res://assets/sfx/ui-navigate.wav"),
	Sound.UI_SELECT: preload("res://assets/sfx/ui-select.wav"),
	Sound.WHISTLE: preload("res://assets/sfx/whistle.wav"),
}

var _channels: Array[AudioStreamPlayer] = []


func _ready() -> void:
	# Los sonidos de interfaz también deben oírse con el partido en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in range(CHANNEL_COUNT):
		var channel := AudioStreamPlayer.new()
		add_child(channel)
		_channels.append(channel)


func play(sound: Sound) -> void:
	if not SFX_MAP.has(sound):
		return
	for channel in _channels:
		if not channel.playing:
			channel.stream = SFX_MAP[sound]
			channel.play()
			return
	# Sin canal libre se omite el efecto: es preferible a cortar otro sonido.
