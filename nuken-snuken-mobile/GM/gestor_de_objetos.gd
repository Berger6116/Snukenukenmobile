extends Node

## Gestiona los objetos recolectados por el jugador en la partida.
## Al recolectar un ítem:
## 1. Alarga el cuerpo de la serpiente (+1 segmento).
## 2. Contabiliza el huevo hacia la meta del nivel (X huevos en X tiempo).
## 3. Si junta 3 ítems iguales seguidos, dispara el PowerUp correspondiente.

var lista_objetos_por_jugador: Dictionary = {}

func registrar_recoleccion(jugador: Node3D, nombre_item: String) -> void:
	if not is_instance_valid(jugador):
		return
	
	var id: int = int(str(jugador.name)) if str(jugador.name).is_valid_int() else 1
	
	if not lista_objetos_por_jugador.has(id):
		lista_objetos_por_jugador[id] = []
	
	var lista_objetos: Array = lista_objetos_por_jugador[id]
	
	if jugador.has_method("agregar_cuerpo"):
		jugador.agregar_cuerpo(1)
	
	# Contabilizar para la meta de victoria del nivel y conversión a diamantes (1:1)
	GestorDeDatosPjs.registrar_huevo_recolectado(id, 1)
	
	if not lista_objetos.is_empty():
		if lista_objetos[-1] != nombre_item:
			lista_objetos.clear()
	lista_objetos.append(nombre_item)
	
	if lista_objetos.size() == 3:
		print("¡PowerUp activado por juntar 3 ", nombre_item, "!")
		lista_objetos.clear()
		AplicadorDeEfectos.aplicar(nombre_item, jugador)
	
	actualizar_indicador(jugador, lista_objetos)

func eliminar_PJ(id: int) -> void:
	lista_objetos_por_jugador.erase(id)

func actualizar_indicador(jugador: Node3D, lista_objetos: Array) -> void:
	var indicador: Label3D = jugador.get_node_or_null("Label3D")
	if not indicador:
		return
	if lista_objetos.is_empty():
		indicador.text = ""
	else:
		var nombre_item: String = lista_objetos[-1]
		indicador.text = "%s: %d/3" % [nombre_item.replace("_", " "), lista_objetos.size()]
