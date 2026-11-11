extends CharacterBody3D
class_name Player_MP

@export_category("Components")
@export var movement_component: CharacterMovementComponent3D
@export var aim_component: MouseAimComponent3D
@export var snake_component: MPSnakeBodyComponent3D

@export_category("Attachments")
@export var weapon: Weapon

@export_category("Propierties")
@export var modo_Singleplayer: bool = true
@export var id_jugador: int = 1
@export var cantidad_cuerpos: int = 2:
	set(val):
		cantidad_cuerpos = val
		if is_node_ready():
			_sincronizar_segmentos_locales()
@export var esta_muerto: bool = false:
	set(val):
		var cambio: bool = (esta_muerto != val)
		esta_muerto = val
		if is_node_ready() and cambio:
			_aplicar_estado_muerto(esta_muerto)
@export var push_force: float = 1.0
@export var movimiento_local: bool = false

var _cantidad_cuerpos_inicial: int = 2
var _material_skin: Material = null

@onready var camera: Camera3D = $Seguimiento/Camera3D
@onready var luz_invulnerabilidad: OmniLight3D = $LuzInvulnerabilidad

func _ready() -> void:
	_cantidad_cuerpos_inicial = cantidad_cuerpos
	if movement_component:
		movement_component = movement_component.duplicate(true)
	if is_instance_valid(MetaProgression):
		_material_skin = MetaProgression.obtener_material_skin_equipada()

	if snake_component and snake_component is MPSnakeBodyComponent3D:
		if not snake_component.cuerpo_agregado.is_connected(_on_segmento_creado):
			snake_component.cuerpo_agregado.connect(_on_segmento_creado)
		if not snake_component.cola_creada.is_connected(_on_cola_creada):
			snake_component.cola_creada.connect(_on_cola_creada)

	GestorDeDatosPjs.jugador_murio.connect(_on_jugador_murio)
	_sincronizar_segmentos_locales()
	if snake_component and snake_component is MPSnakeBodyComponent3D:
		snake_component.reiniciar_en_posicion(self, global_position)

	_aplicar_skin_a_todo_el_cuerpo()

	if esta_muerto:
		_aplicar_estado_muerto(true)
	elif camera:
		camera.current = true

func _physics_process(delta: float) -> void:
	if esta_muerto:
		return
	if movement_component:
		movement_component.process_movement(self, movimiento_local, delta)
	move_and_slide()
	empujar()
	if aim_component and not (movement_component is HeadingMovementComponent3D):
		aim_component.actualizar_rotacion(self, delta)
	if weapon and Input.is_action_pressed("shoot_1"):
		weapon.shoot()
	if snake_component and snake_component is MPSnakeBodyComponent3D:
		snake_component.actualizar(self, delta)

func _sincronizar_segmentos_locales() -> void:
	if not snake_component or not (snake_component is MPSnakeBodyComponent3D):
		return
	var actuales: int = snake_component.obtener_cantidad_cuerpos()
	while actuales < cantidad_cuerpos:
		var seg := snake_component.agregar_cuerpo(self)
		if seg and _material_skin:
			_aplicar_material_recursivo(seg, _material_skin)
		actuales += 1
	while actuales > cantidad_cuerpos:
		snake_component.quitar_cuerpo()
		actuales -= 1

func _on_segmento_creado(segmento: Node3D, _indice: int) -> void:
	if segmento and _material_skin:
		_aplicar_material_recursivo(segmento, _material_skin)

func _on_cola_creada(cola: Node3D) -> void:
	if cola and _material_skin:
		_aplicar_material_recursivo(cola, _material_skin)

func _aplicar_skin_a_todo_el_cuerpo() -> void:
	if not _material_skin:
		return
	if has_node("SnakeHead/cabeza1"):
		_aplicar_material_recursivo($SnakeHead/cabeza1, _material_skin)
	if snake_component and snake_component is MPSnakeBodyComponent3D:
		for seg in snake_component.obtener_cuerpos():
			if is_instance_valid(seg):
				_aplicar_material_recursivo(seg, _material_skin)
		var cola := snake_component.obtener_cola()
		if is_instance_valid(cola):
			_aplicar_material_recursivo(cola, _material_skin)

func _aplicar_material_recursivo(nodo: Node, mat: Material) -> void:
	if nodo is MeshInstance3D:
		(nodo as MeshInstance3D).material_override = mat
	for hijo in nodo.get_children():
		_aplicar_material_recursivo(hijo, mat)

func agregar_cuerpo(cant: int = 1) -> void:
	cantidad_cuerpos += cant

func quitar_cuerpo(cant: int = 1) -> void:
	if cantidad_cuerpos > 0:
		cantidad_cuerpos -= cant
	if cantidad_cuerpos < 0:
		cantidad_cuerpos = 0

func empujar() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody3D:
			collider.apply_force(-collision.get_normal() * push_force)

func mostrar_invulnerabilidad() -> void:
	if luz_invulnerabilidad:
		luz_invulnerabilidad.visible = true

func ocultar_invulnerabilidad() -> void:
	if luz_invulnerabilidad:
		luz_invulnerabilidad.visible = false

func activar_aumento_velocidad(multiplicador: float, duracion: float) -> void:
	_aplicar_aumento_velocidad(multiplicador, duracion)

func _aplicar_aumento_velocidad(multiplicador: float, duracion: float) -> void:
	if movement_component is HeadingMovementComponent3D:
		movement_component.aumentar_velocidad(multiplicador, duracion)

func _on_jugador_murio(id: int) -> void:
	if int(str(name)) != id:
		return
	_morir()

func _morir() -> void:
	var id := int(str(name))
	GestorDeObjetos.eliminar_PJ(id)
	if has_node("Label3D"):
		$Label3D.text = ""
	ocultar_invulnerabilidad()
	esta_muerto = true
	_aplicar_estado_muerto(true)

func respawnear_en_servidor(pos_spawn: Vector3) -> void:
	var id := int(str(name))
	GestorDeDatosPjs.restaurar_vida_respawn(id)
	esta_muerto = false
	_aplicar_estado_muerto(false)
	velocity = Vector3.ZERO
	global_position = pos_spawn
	_sincronizar_segmentos_locales()
	if snake_component and snake_component is MPSnakeBodyComponent3D:
		snake_component.reiniciar_en_posicion(self, pos_spawn)
	# Otorgar 3 segundos de invulnerabilidad tras revivir para no morir de inmediato
	GestorDeDatosPjs.activar_invulnerabilidad(id, 3.0)

func _aplicar_estado_muerto(muerto: bool) -> void:
	visible = not muerto
	if has_node("ColisshionSnakeHead"):
		$ColisshionSnakeHead.set_deferred("disabled", muerto)
	if muerto:
		velocity = Vector3.ZERO
	if snake_component and snake_component is MPSnakeBodyComponent3D:
		snake_component.establecer_visibilidad(not muerto)
	
	var mundo := _obtener_mundo()
	if muerto:
		if camera:
			camera.current = false
		if mundo and mundo.has_method("mostrar_lobby_respawn"):
			mundo.mostrar_lobby_respawn("vida")
	else:
		if mundo and mundo.has_method("ocultar_lobby_respawn"):
			mundo.ocultar_lobby_respawn()
		if camera:
			camera.current = true

func _obtener_mundo() -> Node:
	if get_parent() and get_parent().get_parent():
		var candidato := get_parent().get_parent()
		if candidato.has_method("mostrar_lobby_respawn"):
			return candidato
	if get_tree() and get_tree().current_scene:
		return get_tree().current_scene
	return null
