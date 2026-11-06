extends Node
#Acá el servidor guarda las listas de objetos recolectados por cada jugador.
#Estructuramos un diccionario cuya key es el id del jugador y tiene asociado un array con los objetos que viene recolectando.
#Una vez llega a tres objetos iguales se le aplica el efecto del item. Si recolecta un item distinto al que ya tenía se borra el o los anteriores y se coloca el nuevo item solo.

var lista_objetos_por_jugador: Dictionary = {}

func registrar_recoleccion(jugador: Player_MP, nombre_item: String) -> void:
	#Solo el servidor debe ejecutar.
	if not multiplayer.is_server():
		return
	#Si el jugador ya no existe no debe aplicarse la recoleccion.
	if not is_instance_valid(jugador):
		print("Un jugador inválido está intentando recoger el item: ", nombre_item)
		return
	
	var id:int = int(jugador.name)
	
	#Corroboramos si está o no en la lista.
	if not lista_objetos_por_jugador.has(id):
		lista_objetos_por_jugador[id]=[]
	
	var lista_objetos:Array = lista_objetos_por_jugador[id]
	
	#Aplicamos el alargamiento de cuerpo definido para la recolección de todo objeto, más allá del efecto cuando recolecta tres objetos iguales.
	jugador.agregar_cuerpo(1)
	#Si el objeto es diferente al último recogido descartamos lo recogido hasta el momento.
	if not lista_objetos.is_empty():
		if lista_objetos[-1] !=nombre_item:
			lista_objetos.clear()
	#Agregamos el nuevo objeto
	lista_objetos.append(nombre_item)
	
	print("El jugador ", id," tomó ", nombre_item, ". Actualmente tiene los siguientes objetos: ", lista_objetos)
	
	#Comprobamos si llegó a tres objetos y si es así aplicamos el efecto.
	if lista_objetos.size() == 3:
		print("El jugador ", id, " consiguió tres ", nombre_item)
		#limpiamos su lista.
		lista_objetos.clear()
		AplicadorDeEfectos.aplicar(nombre_item, jugador)
	actualizar_indicador(jugador, lista_objetos)

#Esta función sirve para eliminar los datos de un jugador, por ejemplo cuando abandona el juego, pierde, etc.
func eliminar_PJ(id:int) -> void:
	if not multiplayer.is_server():
		return
	lista_objetos_por_jugador.erase(id)

#Función para actualizar los indicadores de cada jugador.
func actualizar_indicador(jugador: Player_MP, lista_objetos: Array) -> void:
	var indicador: Label3D = jugador.get_node_or_null("Label3D")

	if not indicador:
		return

	if lista_objetos.is_empty():
		indicador.text = ""
	else:
		var nombre_item: String = lista_objetos[-1]
		indicador.text = "%s: %d/3" % [nombre_item.replace("_", " "), lista_objetos.size()]
