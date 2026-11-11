extends Area3D

@export var puntaje: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		var id_jugador: int = int(str(body.name)) if str(body.name).is_valid_int() else 1
		GestorDeDatosPjs.registrar_huevo_recolectado(id_jugador, puntaje)
		if body.has_method("agregar_cuerpo"):
			body.agregar_cuerpo()
		queue_free()

func _on_body_exited(_body: Node3D) -> void:
	pass
