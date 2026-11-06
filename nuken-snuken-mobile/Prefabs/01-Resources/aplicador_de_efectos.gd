extends Node
class_name AplicadorEfectos

func aplicar(item_a_aplicar:String,jugador: Player_MP) -> void:
	var id:int = int(jugador.name)
	#Comprobamos que solo el servidor aplique.
	if not multiplayer.is_server():
		return
	match item_a_aplicar:
		"HUEVO_AZUL":
			GestorDeDatosPjs.modificar_puntaje(id, 10)
			GestorDeDatosPjs.modificar_vida(id, 5)

		"HUEVO_VERDE":
			GestorDeDatosPjs.modificar_puntaje(id, 20)

		"HUEVO_MARRON":
			GestorDeDatosPjs.modificar_vida(id, 20)

		"HUEVO_VIOLETA":
			jugador.activar_aumento_velocidad(1.75, 5.0)

		"HUEVO_DORADO":
			GestorDeDatosPjs.activar_invulnerabilidad(id, 5.0)

		_:
			push_warning("No existe un efecto definido para: ", item_a_aplicar)
			return
	print("Aplicando efecto de: ", item_a_aplicar, " al jugador: ", id)
