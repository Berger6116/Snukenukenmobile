extends Node3D
class_name CavernosoCueva
@export var intervalo : float = 2


@onready var cavernoso = $CavernosoComp
@export_enum("Normal", "Giratorio") var tipo_de_sapo :String = "Normal"

func _ready() -> void:
	cavernoso.intervalo = intervalo
	print(self.name, ' intervalo main: ', intervalo, ' | intervalo controlador: ', cavernoso.controladorcom.intervalo_rutina)
	cavernoso.tipo_de_sapo = tipo_de_sapo
	print(self,name , cavernoso.tipo_de_sapo)
