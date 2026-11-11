extends Estado
class_name EstadoJugando

var escena_nivel = preload("res://Prefabs/13-Worlds/World-MP-2.tscn")
var nivel_actual = null

func enter(juego) -> void:
	var n_nivel := MetaProgression.nivel_actual if is_instance_valid(MetaProgression) else 1
	print("--- ESTADO ACTUAL: PARTIDA NIVEL %d ---" % n_nivel)
	nivel_actual = escena_nivel.instantiate()
	juego.add_child(nivel_actual)

func update(_juego, _delta) -> void:
	pass

func exit(_juego) -> void:
	print("--- SALIENDO DEL NIVEL ---")
	if is_instance_valid(nivel_actual):
		nivel_actual.queue_free()
		nivel_actual = null
