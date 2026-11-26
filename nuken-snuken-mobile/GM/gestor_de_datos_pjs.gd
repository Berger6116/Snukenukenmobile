extends Node

@export var vida_inicial: int = 100
@export var puntaje_inicial: int = 0

var jugadores: Dictionary = {}
var jugadores_invulnerables: Array = []

var huevos_recolectados_nivel: int = 0
var huevos_objetivo_nivel: int = 5
var tiempo_restante_nivel: float = 60.0
var objetivo_huevos: Dictionary = {}
var huevos_por_tipo: Dictionary = {}

signal datos_actualizados
signal jugador_murio(id: int)
signal meta_huevos_alcanzada
signal objetivo_actualizado(objetivo: Dictionary, recolectados: Dictionary)

func registrar_jugador(id: int) -> void:
	var vida_max: int = MetaProgression.obtener_vida_maxima() if is_instance_valid(MetaProgression) else vida_inicial
	vida_inicial = vida_max
	jugadores[id] = {
		"vida": vida_max,
		"vida_maxima": vida_max,
		"puntaje": puntaje_inicial,
		"huevos": 0
	}
	huevos_objetivo_nivel = MetaProgression.obtener_meta_huevos() if is_instance_valid(MetaProgression) else 5
	huevos_recolectados_nivel = 0
	generar_objetivo_huevos()
	datos_actualizados.emit()
#region Funciones y datos propios del jugador
func obtener_datos_jugador(id: int) -> Dictionary:
	if not jugadores.has(id):
		return {}
	return jugadores[id]

func modificar_vida(id: int, cantidad: int) -> void:
	if not jugadores.has(id):
		return
	if jugadores[id]["vida"] <= 0:
		return
	if cantidad < 0 and jugadores_invulnerables.has(id):
		return
	var vida_max: int = int(jugadores[id].get("vida_maxima", vida_inicial))
	jugadores[id]["vida"] += cantidad
	if jugadores[id]["vida"] <= 0:
		jugadores[id]["vida"] = 0
		datos_actualizados.emit()
		jugador_murio.emit(id)
		return
	if jugadores[id]["vida"] > vida_max:
		jugadores[id]["vida"] = vida_max
	datos_actualizados.emit()

func restaurar_vida_respawn(id: int) -> void:
	if not jugadores.has(id):
		return
	var vida_max: int = MetaProgression.obtener_vida_maxima() if is_instance_valid(MetaProgression) else vida_inicial
	jugadores[id]["vida_maxima"] = vida_max
	jugadores[id]["vida"] = vida_max
	datos_actualizados.emit()

func eliminar_jugador(id: int) -> void:
	jugadores.erase(id)
	jugadores_invulnerables.erase(id)
	datos_actualizados.emit()

func modificar_puntaje(id: int, cantidad: int) -> void:
	if not jugadores.has(id):
		return
	jugadores[id]["puntaje"] += cantidad
	datos_actualizados.emit()

func registrar_huevo_recolectado(id: int, cantidad: int = 1) -> void:
	huevos_recolectados_nivel += cantidad
	if jugadores.has(id):
		jugadores[id]["huevos"] = huevos_recolectados_nivel
		jugadores[id]["puntaje"] += cantidad
	datos_actualizados.emit()
	if huevos_recolectados_nivel >= huevos_objetivo_nivel:
		meta_huevos_alcanzada.emit()
#endregion

#region datos y funciones de partida
func actualizar_tiempo_nivel(segundos_restantes: float) -> void:
	tiempo_restante_nivel = maxf(0.0, segundos_restantes)
	datos_actualizados.emit()

func generar_objetivo_huevos() -> void:
	objetivo_huevos.clear()
	huevos_por_tipo.clear()

	var tipos_huevos = ["HUEVO_MARRON", "HUEVO_VERDE", "HUEVO_AZUL"]

	for i in range(huevos_objetivo_nivel):
		var huevo: String = tipos_huevos.pick_random()
		objetivo_huevos[huevo] = objetivo_huevos.get(huevo, 0) + 1

	for huevo in objetivo_huevos:
		huevos_por_tipo[huevo] = 0
	
	objetivo_actualizado.emit(objetivo_huevos, huevos_por_tipo)

func objetivo_huevos_completado() -> bool:
	for huevo in objetivo_huevos:
		if huevos_por_tipo[huevo] < objetivo_huevos[huevo]:
			return false
	return true
#endregion

#region invulnerabilidad
func activar_invulnerabilidad(id: int, duracion: float) -> void:
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

	print("Jugador ", id, " ahora es invulnerable por ", duracion, "s.")

func _finalizar_invulnerabilidad(id: int, timer: Timer) -> void:
	jugadores_invulnerables.erase(id)
	_cambiar_luz_invulnerabilidad(id, false)
	if is_instance_valid(timer):
		timer.queue_free()

func _cambiar_luz_invulnerabilidad(id: int, activar: bool) -> void:
	var escena = get_tree().current_scene
	if not escena:
		return
	var jugador = escena.find_child(str(id), true, false)
	if jugador == null:
		return
	var luz := jugador.get_node_or_null("LuzInvulnerabilidad") as OmniLight3D
	if luz:
		luz.visible = activar
#endregion

func sincronizar_datos_a_clientes() -> void:
	datos_actualizados.emit()
