class_name Cavernoso
extends Node3D

## Actor Receptor (Receiver) en el Patrón de Comandos.
## Contiene las capacidades físicas y visuales del sapo (moverse, esperar, atacar, esconderse).

signal emergio
signal ataco
signal escondio
@export var modelo3D : Node3D
@export_group("Puntos de Posición (Marker3D)")
## Marcador 3D que indica la posición de la cueva (escondite)
@export var punto_cueva: Marker3D
## Marcador 3D que indica la posición afuera de la cueva
@export var punto_salida: Marker3D

@export_group("Parámetros de Salto")
@export var duracion_salto: float = 0.8
@export var altura_salto: float = 1.2
@export var particulas_ataque: GPUParticles3D #Agregué particulas cuando aparece el escuerzo
@export_group("Combate y Ataque")
## Area3D que inflige daño (ej. Zona_Danio_Sphere o cualquier Area3D con zona_danio.gd)
@export var hitbox_ataque: Area3D
@export var lengua_ataque : Node3D
@export var tiempo_aviso_ataque: float = 0.4
@export var tiempo_activo_ataque: float = 0.4
@export var sfx_salto: AudioStreamPlayer3D
@export var sfx_ataque: AudioStreamPlayer3D
@export var animation_player: AnimationPlayer

@export_group("Comandos")
@export var intervalo :float = 2:
	set(value):
		intervalo = value
		if controladorcom != null:
			controladorcom.intervalo_rutina = intervalo
@onready var controladorcom = $ControladorComandos
@export_enum("Normal", "Giratorio") var tipo_de_sapo:String = "Normal":
	set(value):
		tipo_de_sapo = value
		if controladorcom != null:
			controladorcom.tipo_de_sapo = tipo_de_sapo
			controladorcom.configurar_rutina()

var posicion_cueva: Vector3
var posicion_afuera: Vector3
var _escala_original: Vector3 = Vector3.ONE
var _desactivado: bool = false
var _ciclo_token: int = 0

func usa_animaciones() -> bool:
	return animation_player != null and is_instance_valid(animation_player)

func _ready() -> void:
	if animation_player == null and get_parent() != null:
		animation_player = get_parent().get_node_or_null("AnimationPlayer") as AnimationPlayer

	controladorcom.intervalo_rutina = intervalo
	controladorcom.tipo_de_sapo = tipo_de_sapo
	controladorcom.configurar_rutina()
	
	_escala_original = scale
	
	if usa_animaciones():
		# Las animaciones mueven CavernosoComp:position entre Y=-5 (escondido) e Y=0 (emergido),
		# manteniendo cavernosoBody en su offset base local.
		position = Vector3(0.0, -5.0, 1.0)
		if punto_cueva != null:
			posicion_cueva = punto_cueva.global_position
		else:
			posicion_cueva = global_position
		if punto_salida != null:
			posicion_afuera = punto_salida.global_position
		else:
			posicion_afuera = posicion_cueva
	else:
		# Fijar coordenadas en vectores inmutables (fallback procedural sin AnimationPlayer)
		if punto_cueva != null:
			posicion_cueva = punto_cueva.global_position
			modelo3D.global_position = posicion_cueva
			print("DEBUG POSICION CAVERNOSO | [Cavernoso] Modelo: ",modelo3D.name," | Posición global: ",modelo3D.global_position)
		else:
			posicion_cueva = global_position
		
		if punto_salida != null:
			posicion_afuera = punto_salida.global_position
		else:
			posicion_afuera = posicion_cueva + transform.basis * Vector3(0, 0, 0.0)
	
	# Inicializar hitbox apagado
	if hitbox_ataque != null:
		hitbox_ataque.monitoring = false
		hitbox_ataque.visible = false
	if lengua_ataque != null:
		lengua_ataque.visible = false

## 1. Acción: Emerger (Salto parabólico de la cueva hacia afuera)
func emerger() -> void:
	if not is_inside_tree() or _desactivado:
		return
	if usa_animaciones():
		emergio.emit()
		return
	#Giramos aleatoriamente el escuerzo.
	rotation.y = randf_range(0.0, TAU)
	await _animar_salto(modelo3D.global_position, posicion_afuera, duracion_salto)
	emergio.emit()

## 2. Acción: Esperar un tiempo determinado
func esperar(segundos: float) -> void:
	if not is_inside_tree() or _desactivado:
		return
	await get_tree().create_timer(segundos).timeout

## 3. Acción: Atacar en área (animado con lightAttack o fallback procedural)
func atacar_area() -> void:
	if not is_inside_tree() or _desactivado:
		return

	if usa_animaciones() and animation_player.has_animation("lightAttack"):
		rotation = Vector3(0.0, randf_range(0.0, TAU), 0.0)
		await _ejecutar_ataque_animado("lightAttack", 0.70, 1.34)
		return
		
	if sfx_ataque != null: #SFX
		sfx_ataque.play()
		
	if not is_inside_tree() or _desactivado:
		return
	
	if hitbox_ataque != null:
		hitbox_ataque.monitoring = true
		hitbox_ataque.visible = false
		if lengua_ataque != null:
			lengua_ataque.visible = true
		if particulas_ataque != null:
			particulas_ataque.restart()
		
		# Si ya hay jugadores u objetivos solapados en el instante de encendido:
		for body in hitbox_ataque.get_overlapping_bodies():
			if hitbox_ataque.has_method("_on_body_entered"):
				hitbox_ataque._on_body_entered(body)
	
	await get_tree().create_timer(tiempo_activo_ataque).timeout
	if not is_inside_tree():
		return
	
	# Desactivar hitbox
	if hitbox_ataque != null:
		hitbox_ataque.monitoring = false
		hitbox_ataque.visible = false
	if lengua_ataque != null:
		lengua_ataque.visible = false
	
	ataco.emit()
	if sfx_ataque != null:
		sfx_ataque.stop()

## 3b. Acción: Girar y atacar (animado con Attack_2 o fallback procedural)
func atacar_girando() -> void:
	if not is_inside_tree() or _desactivado:
		return
	if usa_animaciones() and animation_player.has_animation("Attack_2"):
		await _ejecutar_ataque_animado("Attack_2", 0.57, 1.54)
		return
	var tween_giro := create_tween()
	tween_giro.tween_property(self, "rotation:y", rotation.y + TAU * 2, tiempo_activo_ataque).set_trans(Tween.TRANS_LINEAR)
	await atacar_area()

## Sincroniza el AnimationPlayer (emerger + lengua + esconderse) con el hitbox, partículas y SFX
func _ejecutar_ataque_animado(nombre_anim: String, inicio_hitbox: float, fin_hitbox: float) -> void:
	var token := _ciclo_token
	if sfx_salto != null:
		sfx_salto.play()

	animation_player.stop()
	animation_player.play(nombre_anim)

	# Esperar hasta que sale la lengua para activar hitbox y SFX de ataque
	await get_tree().create_timer(inicio_hitbox).timeout
	if not is_inside_tree() or _desactivado or token != _ciclo_token:
		return

	if sfx_ataque != null:
		sfx_ataque.play()
	if particulas_ataque != null:
		particulas_ataque.restart()
	if hitbox_ataque != null:
		hitbox_ataque.monitoring = true
		hitbox_ataque.visible = false
		for body in hitbox_ataque.get_overlapping_bodies():
			if hitbox_ataque.has_method("_on_body_entered"):
				hitbox_ataque._on_body_entered(body)

	# Mantener hitbox activo mientras dura la lengua
	await get_tree().create_timer(maxf(0.05, fin_hitbox - inicio_hitbox)).timeout
	if not is_inside_tree() or token != _ciclo_token:
		return

	if hitbox_ataque != null:
		hitbox_ataque.monitoring = false
	if sfx_ataque != null:
		sfx_ataque.stop()

	# Esperar a que termine de esconderse la animación
	if animation_player.is_playing() and animation_player.current_animation == nombre_anim:
		await animation_player.animation_finished

	if not is_inside_tree() or token != _ciclo_token:
		return

	if sfx_salto != null:
		sfx_salto.stop()
	ataco.emit()

## 4. Acción: Esconderse (Salto parabólico de regreso a la cueva)
func esconderse() -> void:
	if not is_inside_tree():
		return
	if usa_animaciones():
		position = Vector3(0.0, -5.0, 1.0)
		escondio.emit()
		return
	await _animar_salto(modelo3D.global_position, posicion_cueva, duracion_salto)
	escondio.emit()

## Animación procedural de salto con arco parabólico en Y
func _animar_salto(origen: Vector3, destino: Vector3, duracion: float) -> void:
	if sfx_salto !=null:
		sfx_salto.play()
	if not is_inside_tree():
		return
		
	#var dir := destino - origen
	#dir.y = 0.0
	#if dir.length_squared() > 0.01:
		#look_at(modelo3D.global_position + dir.normalized(), Vector3.UP)
	#
	var mitad := duracion * 0.5
	var pico_y := maxf(origen.y, destino.y) + altura_salto
	
	# Squash antes del salto
	#var tween_squash := create_tween()
	#tween_squash.tween_property(self, "scale", _escala_original * Vector3(1.2, 0.7, 1.2), 0.1)
	#await tween_squash.finished
	if not is_inside_tree():
		return
	
	# Desplazamiento horizontal + estiramiento en el aire
	#var tween_mov := create_tween().set_parallel(true)
	#tween_mov.tween_property(modelo3D, "global_position:x", destino.x, duracion)
	#tween_mov.tween_property(modelo3D, "global_position:z", destino.z, duracion)
	#tween_mov.tween_property(self, "scale", _escala_original * Vector3(0.9, 1.2, 0.9), mitad)
	
	# Arco parabólico en Y
	var tween_y := create_tween()
	tween_y.tween_property(modelo3D, "global_position:y", pico_y, mitad).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(modelo3D, "global_position:y", destino.y, mitad).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await tween_y.finished
	if not is_inside_tree():
		return
	
	# Squash al aterrizar
	#var tween_land := create_tween()
	#tween_land.tween_property(self, "scale", _escala_original * Vector3(1.25, 0.75, 1.25), 0.1)
	#tween_land.tween_property(self, "scale", _escala_original, 0.15)
	#await tween_land.finished
	
	if sfx_salto != null:
		sfx_salto.stop()
	
func desactivar_ciclo() -> void:
	if _desactivado:
		return
	_desactivado = true
	_ciclo_token += 1
	controladorcom.detener_ciclo()
	if hitbox_ataque != null:
		hitbox_ataque.monitoring = false
	if sfx_ataque != null:
		sfx_ataque.stop()
	if sfx_salto != null:
		sfx_salto.stop()
	if usa_animaciones() and animation_player.has_animation("muerte"):
		animation_player.stop()
		animation_player.play("muerte")
		await animation_player.animation_finished
		if is_inside_tree():
			visible = false
	else:
		esconderse()
