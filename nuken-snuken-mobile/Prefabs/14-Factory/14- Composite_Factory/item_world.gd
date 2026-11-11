class_name ItemWorld
extends Area3D

@export var data_path: String = "":
	set(valor):
		data_path = valor
		if not data_path.is_empty():
			data = load(data_path)

@export var data: ItemData:
	set(nuevo_data):
		data = nuevo_data
		if data and data_path.is_empty() and not data.resource_path.is_empty():
			data_path = data.resource_path
		if is_node_ready():
			_actualizar_visuales()

@export var mesh_instance: MeshInstance3D
var _instancia_escena: Node3D = null
@export var collision_shape: CollisionShape3D
var _consumiendose: bool = false

func _ready() -> void:
	if not mesh_instance and has_node("MeshInstance3D"):
		mesh_instance = $MeshInstance3D
	if not collision_shape and has_node("CollisionShape3D"):
		collision_shape = $CollisionShape3D
	body_entered.connect(_on_body_entered)
	_actualizar_visuales()

func _actualizar_visuales() -> void:
	if not data:
		return
	if _instancia_escena and is_instance_valid(_instancia_escena):
		_instancia_escena.queue_free()
		_instancia_escena = null
	if data.modelo_escena:
		if mesh_instance:
			mesh_instance.visible = false
		_instancia_escena = data.modelo_escena.instantiate() as Node3D
		if _instancia_escena:
			add_child(_instancia_escena)
			_instancia_escena.scale = data.escala_visual
	elif data.modelo_mesh and mesh_instance:
		mesh_instance.visible = true
		mesh_instance.mesh = data.modelo_mesh
		mesh_instance.scale = data.escala_visual
		if data.material_override:
			mesh_instance.material_override = data.material_override

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Jugador"):
		return
	if _consumiendose:
		return
	_consumiendose = true
	if data:
		GestorDeObjetos.registrar_recoleccion(body, data.nombre)
	despawn()

func despawn() -> void:
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	_reproducir_animacion_consumir()
	await get_tree().create_timer(0.9).timeout
	if is_inside_tree():
		queue_free()

func _reproducir_animacion_consumir() -> void:
	if _instancia_escena is ItemVisual:
		var visual: ItemVisual = _instancia_escena as ItemVisual
		visual.despawn_animation_play()
