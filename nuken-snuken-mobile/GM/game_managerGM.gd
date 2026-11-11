extends Node

var escena_maquina = preload("res://GM/maquina_de_estados.tscn")
var maquina_estados: MaquinaDeEstados = null

func _ready() -> void:
	maquina_estados = escena_maquina.instantiate() as MaquinaDeEstados
	add_child(maquina_estados)
	maquina_estados.init(self)

func _process(delta: float) -> void:
	if maquina_estados:
		maquina_estados.update(delta)

func iniciar_nivel() -> void:
	print(">> Acción: Botón JUGAR presionado -> Pasando a Personalización de Personaje")
	if maquina_estados:
		maquina_estados.change_state(maquina_estados.personalizacion)

func _on_creditos_pressed() -> void:
	$MenuUI/PantallaCreditos.show()
	$MenuUI/VOLVER.show()

func _on_volver_pressed() -> void:
	$MenuUI/PantallaCreditos.hide()
	$MenuUI/VOLVER.hide()
