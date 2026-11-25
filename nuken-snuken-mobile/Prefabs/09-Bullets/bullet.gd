extends RigidBody3D
class_name Bullet

@export var bullet_velocity: float = 25.0
@export var tiempo_vida: float = 4.0
@export var danio: int = 12

# Referencia al pool inyectada por el arma
var pool: ObjectPool = null

var _tiempo_restante: float = 0.0
var _activa: bool = false

func _process(delta: float) -> void:
	if not _activa:
		return
		
	_tiempo_restante -= delta
	if _tiempo_restante <= 0.0:
		desactivar()

## Se llama cada vez que el arma dispara esta bala
func activar(origen: Vector3, velocidad_inicial: Vector3, ref_pool: ObjectPool = null) -> void:
	pool = ref_pool
	global_position = origen
	linear_velocity = velocidad_inicial
	_tiempo_restante = tiempo_vida
	_activa = true

## Devuelve la bala al pool o la destruye si no hay pool asignado
func desactivar() -> void:
	if not _activa:
		return
	_activa = false
	
	if pool:
		pool.add_to_pool(self)
	else:
		queue_free()




func _al_chocar(body: Node) -> void:
	if body.is_in_group("Enemigo"):
		#La siguiente linea elimina al sapo por completo siempre que el StaticBody de su cueva esté en el grupo "Enemigo"
		#body.get_parent().get_parent().queue_free()
		#La siguiente linea desactiva al sapo pero no lo elimina.
		#body.get_parent().get_parent().desactivar_cueva()
		#print("Balubi chocandubi contra: ", body.name)
		pass
	desactivar()
