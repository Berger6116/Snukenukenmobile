extends Node3D

@export var objetivo : Node3D
@export var seguimiento_suave : bool = true
@export var velocidad : float = 6.0

var offset : Vector3

func _ready() -> void:
	if objetivo:
		# Guardamos la distancia y ángulo inicial respecto al objetivo
		offset = global_position - objetivo.global_position

func _physics_process(delta: float) -> void:
	if not objetivo:
		return
		
	var posicion_deseada = objetivo.global_position + offset
	
	if seguimiento_suave:
		# Interpolación suave hacia la posición del personaje
		global_position = global_position.lerp(posicion_deseada, velocidad * delta)
	else:
		global_position = posicion_deseada
