extends Node3D
class_name CavernosoCueva
@export var intervalo : float = 2


@onready var cavernoso = $CavernosoComp
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@export_enum("Normal", "Giratorio") var tipo_de_sapo :String = "Normal"

func _ready() -> void:
	if animation_player != null:
		cavernoso.animation_player = animation_player
	cavernoso.intervalo = intervalo
	print(self.name, ' intervalo main: ', intervalo, ' | intervalo controlador: ', cavernoso.controladorcom.intervalo_rutina)
	cavernoso.tipo_de_sapo = tipo_de_sapo
	print(self,name , cavernoso.tipo_de_sapo)

func desactivar_cueva():
	cavernoso.desactivar_ciclo()
	
