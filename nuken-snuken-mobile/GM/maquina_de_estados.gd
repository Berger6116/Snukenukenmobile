extends Node
class_name MaquinaDeEstados

var juego
var estado_actual: Estado

@onready var en_menu = $EnMenu
@onready var personalizacion = $Personalizacion
@onready var jugando_local = $JugandoLocal
@onready var en_pausa = $EnPausa
@onready var derrotado = $Derrotado
@onready var victoria = $Victoria

func init(instancia_de_juego) -> void:
	juego = instancia_de_juego
	change_state(en_menu)

func change_state(new_state) -> void:
	if estado_actual:
		estado_actual.exit(juego)

	estado_actual = new_state
	if estado_actual:
		estado_actual.enter(juego)

func update(delta: float) -> void:
	if estado_actual:
		estado_actual.update(juego, delta)
