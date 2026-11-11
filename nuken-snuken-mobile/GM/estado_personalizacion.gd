extends Estado
class_name EstadoPersonalizacion

var escena_personalizacion = preload("res://Scenes/Screens/PersonalizacionScreen.tscn")
var capa_ui: CanvasLayer = null
var instancia_ui: PersonalizacionScreen = null

func enter(juego) -> void:
	print("--- ESTADO ACTUAL: PERSONALIZACIÓN DE PERSONAJE ---")
	capa_ui = CanvasLayer.new()
	capa_ui.name = "PersonalizacionLayer"
	instancia_ui = escena_personalizacion.instantiate() as PersonalizacionScreen
	capa_ui.add_child(instancia_ui)
	juego.add_child(capa_ui)

	instancia_ui.continuar_a_partida.connect(func():
		if juego and juego.maquina_estados:
			juego.maquina_estados.change_state(juego.maquina_estados.jugando_local)
	)
	instancia_ui.volver_a_menu.connect(func():
		if juego and juego.maquina_estados:
			juego.maquina_estados.change_state(juego.maquina_estados.en_menu)
	)

func update(_juego, _delta) -> void:
	pass

func exit(_juego) -> void:
	if is_instance_valid(capa_ui):
		capa_ui.queue_free()
		capa_ui = null
		instancia_ui = null
