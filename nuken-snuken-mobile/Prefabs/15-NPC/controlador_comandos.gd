class_name ControladorComandos
extends Node

## Invocador (Invoker) del Patrón de Comandos.
## Administra la lista de comandos, despacha su ejecución secuencial y controla el ciclo de tiempo.

signal rutina_iniciada
signal rutina_finalizada
signal comando_iniciado(comando: Command)
signal comando_completado(comando: Command)

@export_category("Invocador de Comandos")
## Actor receptor que ejecutará las acciones
@export var actor: Node
## Tiempo en segundos que espera dentro de la cueva antes de volver a ejecutar la rutina
@export var intervalo_rutina: float = 10.0
## Lista ordenada de comandos que componen la rutina
@export var rutina: Array[Command] = []
## Si debe iniciar el ciclo periódico automáticamente
@export var auto_iniciar: bool = true
@export_enum("Normal", "Giratorio") var tipo_de_sapo:String

var _ejecutando: bool = false
var _activo: bool = false

func _ready() -> void:
	if actor == null:
		actor = get_parent()
	
	if auto_iniciar:
		iniciar_ciclo.call_deferred()

## Inicia el bucle repetitivo cada 'intervalo_rutina' segundos
func iniciar_ciclo() -> void:
	_activo = true
	while _activo and is_inside_tree():
		await get_tree().create_timer(intervalo_rutina).timeout
		if not _activo or not is_inside_tree():
			break
		await ejecutar_rutina()

## Detiene el bucle repetitivo
func detener_ciclo() -> void:
	_activo = false

## Despacha cada comando de la rutina en orden secuencial
func ejecutar_rutina() -> void:
	if _ejecutando or actor == null or not is_inside_tree():
		return
	
	_ejecutando = true
	rutina_iniciada.emit()
	
	for comando in rutina:
		if not is_inside_tree() or not _activo:
			break
		if comando != null:
			comando_iniciado.emit(comando)
			await comando.execute(actor)
			comando_completado.emit(comando)
	
	_ejecutando = false
	rutina_finalizada.emit()

func configurar_rutina() -> void:
	if tipo_de_sapo == "Normal":
		rutina = [ComandoEmerger.new(), ComandoEsperar.new(1.0), ComandoAtacar.new(), ComandoEsconderse.new()]
	elif tipo_de_sapo == "Giratorio":
		rutina = [ComandoEmerger.new(), ComandoEsperar.new(1.0), ComandoAtacarGirando.new(), ComandoEsconderse.new()]
