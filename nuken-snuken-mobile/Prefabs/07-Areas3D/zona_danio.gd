extends Area3D
@export var danio: int = 10
@export var objetivo: String = "Global"
var propietario: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if get_parent() and get_parent().get_parent():
		propietario = get_parent().get_parent().name.split("_")[0]

func _on_body_entered(body: Node3D) -> void:
	if body.name == propietario:
		return
	if body.is_in_group(objetivo):
		if body.has_method("quitar_cuerpo"):
			body.quitar_cuerpo(maxi(1, danio / 10))
		var id_jugador: int = int(str(body.name)) if str(body.name).is_valid_int() else 1
		GestorDeDatosPjs.modificar_vida(id_jugador, -danio)
