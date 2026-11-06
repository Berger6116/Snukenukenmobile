extends Node

@export var vida_inicial:int = 100
@export var puntaje_inicial:int = 0

var jugadores: Dictionary = {}
var jugadores_invulnerables: Array = []

#señal solo para actualizar el HUD
signal datos_actualizados
#Señal para avisar que murió un jugador
signal jugador_murio(id)

#En esta región del código está la lógica de cómo funciona el gestor si quien lo corre es el servidor.
#region sistema en servidor
#Cuando se instancia un nuevo jugador se llama a esta función para crear sus datos.
func registrar_jugador(id: int) -> void:
	#Se fija que sea el servidor el que está ejecutando la función.
	if not multiplayer.is_server():
		return
	#Se fija que el id no esté ya registrado
	if jugadores.has(id):
		print("ID: "+ str(id)+" ya está registrado.")
		return
	#Crea y guarda los datos del personaje. Guarda un diccionario donde la clave para los datos de cada jugador es su id que es igual a su peer_id.
	jugadores[id] = {"vida": vida_inicial, "puntaje": puntaje_inicial}

#Función para obtener los datos de un jugador en concreto mediante su id.
func obtener_datos_jugador(id:int) -> Dictionary:
	if not jugadores.has(id):
		return {}
	return jugadores[id]

#Modifica la cantidad de vida de un personaje referenciandolo por su id y pasandole la cantidad a cambiar. Para hacer daño utilizar una cantidad negativa.
func modificar_vida(id:int, cantidad:int) -> void:
	if not multiplayer.is_server():
		return
	if not jugadores.has(id):
		return
	#Si es un daño comprueba que el jugador no sea invulnerable.
	if cantidad < 0 and jugadores_invulnerables.has(id):
		return
	jugadores[id]["vida"] += cantidad
	if jugadores[id]["vida"] <= 0:
		jugador_murio.emit(id)
	if jugadores[id]["vida"] > 100:
		jugadores[id]["vida"] = 100
	sincronizar_datos_a_clientes()

#Modifica la cantidad de puntos de un personaje referenciandolo por su id y pasandole la cantidad a cambiar.
func modificar_puntaje(id:int, cantidad:int) -> void:
	if not multiplayer.is_server():
		return
	if not jugadores.has(id):
		return
	jugadores[id]["puntaje"] += cantidad
	sincronizar_datos_a_clientes()

#region invulnerabilidad
#Establece invulnerabilidad sobre un jugador.
func activar_invulnerabilidad(id: int, duracion: float) -> void:
	if not multiplayer.is_server():
		return

	if jugadores_invulnerables.has(id):
		return

	jugadores_invulnerables.append(id)
	_cambiar_luz_invulnerabilidad(id, true)

	var timer := Timer.new()
	timer.name = "TimerInvulnerabilidad_" + str(id)
	timer.one_shot = true
	timer.wait_time = duracion

	add_child(timer)

	timer.timeout.connect(_finalizar_invulnerabilidad.bind(id, timer))
	timer.start()

	print("Jugador ", id, " ahora es invulnerable.")

#Finaliza la invulnerabilidad en un jugador.
func _finalizar_invulnerabilidad(id: int, timer: Timer) -> void:
	jugadores_invulnerables.erase(id)
	_cambiar_luz_invulnerabilidad(id, false)
	timer.queue_free()

	print("Jugador ", id, " ya no es invulnerable.")

func _cambiar_luz_invulnerabilidad(id: int, activar: bool) -> void:
	var escena = get_tree().current_scene
	#Busca el personaje por id en todo el árbol de la escena.
	var jugador = escena.find_child(str(id), true, false)

	if jugador == null:
		print("No se encontró al jugador: ", id)
		return

	var luz := jugador.get_node_or_null("LuzInvulnerabilidad") as OmniLight3D

	if luz:
		luz.visible = activar
#endregion
#Función que le envía a los gestores de cada cliente la información actualizada del servidor.
func sincronizar_datos_a_clientes() -> void:
	if not multiplayer.is_server():
		return
	#Recorre los jugadores guardados y envía sus datos a los gestores de los clientes.
	for id in jugadores:
		var datos = jugadores[id]
		recibir_datos_jugador.rpc(id, datos["vida"], datos["puntaje"])
	#El host se avisa a su propio HUD que los datos cambiaron.
	datos_actualizados.emit()
#endregion

#En esta región está la lógica de cómo funciona el gestor en cada cliente.
#region sistema en clientes

#Función que se llama remota mediante el gestor de datos del servidor en cada cliente para sincronizar los datos de los gestores.
@rpc("authority", "call_remote", "reliable")
func recibir_datos_jugador(id: int, vida: int, puntaje: int) -> void:
	jugadores[id] = {"vida": vida, "puntaje": puntaje}
	#El gestor del cliente emite la señal al HUD propio de cada cliente.
	datos_actualizados.emit()
#endregion
