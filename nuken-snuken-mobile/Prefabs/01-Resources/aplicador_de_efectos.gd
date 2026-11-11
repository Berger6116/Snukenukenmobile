extends Node
class_name AplicadorEfectos

func aplicar(item_a_aplicar: String, jugador: Node3D) -> void:
	var id: int = int(str(jugador.name)) if str(jugador.name).is_valid_int() else 1
	match item_a_aplicar:
		"HUEVO_AZUL":
			GestorDeDatosPjs.modificar_puntaje(id, 2)
			GestorDeDatosPjs.modificar_vida(id, 10)

		"HUEVO_VERDE":
			GestorDeDatosPjs.modificar_puntaje(id, 3)
			if jugador.has_method("activar_aumento_velocidad"):
				jugador.activar_aumento_velocidad(1.5, 5.0)

		"HUEVO_MARRON":
			GestorDeDatosPjs.modificar_vida(id, 20)

		"HUEVO_VIOLETA":
			if jugador.has_method("activar_aumento_velocidad"):
				jugador.activar_aumento_velocidad(2.25, 5.0)

		"HUEVO_DORADO":
			GestorDeDatosPjs.activar_invulnerabilidad(id, 5.0)

		_:
			push_warning("No existe un efecto definido para: ", item_a_aplicar)
			return
	print("Aplicando efecto de PowerUp: ", item_a_aplicar, " al jugador: ", id)
