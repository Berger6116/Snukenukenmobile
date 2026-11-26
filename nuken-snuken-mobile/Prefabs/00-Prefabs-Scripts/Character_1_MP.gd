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
@export var push_force: float = 1.0
@export var movimiento_local: bool = false

var _cantidad_cuerpos_inicial: int = 2
var _material_skin: Material = null
var en_victoria: bool = false

@onready var camera: Camera3D = $Seguimiento/Camera3D
@onready var luz_invulnerabilidad: OmniLight3D = $LuzInvulnerabilidad
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _obtener_id_jugador() -> int:
	return int(str(name)) if str(name).is_valid_int() else id_jugador

func _exit_tree() -> void:
	if snake_component and snake_component is MPSnakeBodyComponent3D:
		snake_component.limpiar()

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

	_sincronizar_segmentos_locales()
	if snake_component and snake_component is MPSnakeBodyComponent3D:
		snake_component.reiniciar_en_posicion(self, global_position)

	_aplicar_skin_a_todo_el_cuerpo()

	if camera:
		camera.current = true
	_reproducir_idle()

func _physics_process(delta: float) -> void:
	if en_victoria:
		velocity = Vector3.ZERO
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
	var id := _obtener_id_jugador()
	if en_victoria or GestorDeDatosPjs.jugadores_invulnerables.has(id):
		return
	if cantidad_cuerpos > 0:
		cantidad_cuerpos -= cant
	if cantidad_cuerpos < 0:
		cantidad_cuerpos = 0
	_ejecutar_animacion_danio_local()

func _reproducir_idle() -> void:
	if not anim_player:
		return
	if anim_player.has_animation("Idle2_2"):
		anim_player.play("Idle2_2")

func _ejecutar_animacion_danio_local() -> void:
	if not anim_player or not anim_player.has_animation("RECIBE_DANIO"):
		return
	anim_player.stop()
	anim_player.play("RECIBE_DANIO")
	await anim_player.animation_finished
	if is_inside_tree() and anim_player and not en_victoria:
		if anim_player.has_animation("RESET"):
			anim_player.play("RESET")
			anim_player.advance(0.0)
		#_reproducir_idle()

func reproducir_animacion_victoria() -> void:
	en_victoria = true
	velocity = Vector3.ZERO
	if has_node("ColisshionSnakeHead"):
		$ColisshionSnakeHead.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	var id := _obtener_id_jugador()
	if is_instance_valid(GestorDeDatosPjs) and not GestorDeDatosPjs.jugadores_invulnerables.has(id):
		GestorDeDatosPjs.jugadores_invulnerables.append(id)
	if anim_player and anim_player.has_animation("victoria"):
		anim_player.stop()
		if anim_player.has_animation("RESET"):
			anim_player.play("RESET")
			anim_player.advance(0.0)
		var anim := anim_player.get_animation("victoria")
		if anim:
			anim.loop_mode = Animation.LOOP_NONE
		anim_player.play("victoria")
		await anim_player.animation_finished

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
