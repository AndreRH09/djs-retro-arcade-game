extends Node2D
## Menú principal (HU-08): Un jugador / PvP local / Salir. Navega P1 con flechas; K o Enter confirma.

const TEAM_SELECTION := "res://scenes/screens/team_selection.tscn"
const OPTIONS: Array[String] = ["UN JUGADOR", "PVP LOCAL", "SALIR"]
const INK := Color("dedede")
const YELLOW := Color("e8ef00")
const PANEL := Color(0.09, 0.09, 0.11, 0.85)
const BALL := preload("res://assets/art/ui/mainmenu/ball-selection.png")

var _selected := 0


func _ready() -> void:
	get_tree().paused = false
	MusicPlayer.play_music(MusicPlayer.Music.MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	# Se marca antes de actuar: _confirm() cambia de escena y saca este nodo del árbol.
	if event.is_action_pressed("ui_up") or event.is_action_pressed("p1_up"):
		get_viewport().set_input_as_handled()
		_move(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("p1_down"):
		get_viewport().set_input_as_handled()
		_move(1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("p1_pass"):
		get_viewport().set_input_as_handled()
		_confirm()


func _move(step: int) -> void:
	_selected = wrapi(_selected + step, 0, OPTIONS.size())
	SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
	queue_redraw()


func _confirm() -> void:
	SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
	match _selected:
		0, 1:
			GameSession.mode = GameSession.Mode.SINGLE if _selected == 0 else GameSession.Mode.PVP
			get_tree().change_scene_to_file(TEAM_SELECTION)
		2:
			get_tree().quit()


func _draw() -> void:
	var center := get_viewport_rect().size.x / 2.0
	draw_rect(Rect2(center - 70, 14, 140, 26), PANEL)
	PixelText.draw_centered(self, "DSJ RETRO", Vector2(center, 34), 12, YELLOW)
	draw_rect(Rect2(center - 60, 104, 120, 64), PANEL)
	for i in OPTIONS.size():
		var y := 122 + i * 18
		var selected := i == _selected
		PixelText.draw_centered(self, OPTIONS[i], Vector2(center, y), 6, YELLOW if selected else INK)
		if selected:
			draw_texture_rect(BALL, Rect2(center - 56, y - 9, 10, 10), false)
