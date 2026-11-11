extends Node

## Sistema de MetaProgression y Economía de Diamantes para Nuke Snuken Mobile.
## Persiste Skins, Vida Máxima, PowerUps, Diamantes y Nivel Actual en user://meta_progression.cfg.

signal diamantes_cambiaron(nuevos_diamantes: int)
signal progreso_actualizado()

const SAVE_PATH: String = "user://meta_progression.cfg"
const MAX_REVIVES_CON_AD: int = 2
const COSTO_REVIVIR_DIAMANTES: int = 15

## Conversión 1:1 por defecto desde los huevos/ítems obtenidos en la partida.
@export var factor_conversion_diamantes: float = 1.0

var diamantes: int = 30:
	set(valor):
		diamantes = maxi(0, valor)
		diamantes_cambiaron.emit(diamantes)

var nivel_actual: int = 1
var nivel_maximo_alcanzado: int = 1

# ==============================================================================
# CATÁLOGO DE SKINS (SKIN X DIAMANTES)
# ==============================================================================
const CATALOGO_SKINS: Dictionary = {
	"azul": {
		"nombre": "Azul Clásico",
		"costo": 0,
		"material_path": "res://Materials/pinta-Azul.tres",
		"color_preview": Color(0.15, 0.45, 0.95)
	},
	"verde": {
		"nombre": "Verde Selva",
		"costo": 15,
		"material_path": "res://Materials/pinta-Verde.tres",
		"color_preview": Color(0.15, 0.75, 0.25)
	},
	"marron": {
		"nombre": "Marrón Tierra",
		"costo": 15,
		"material_path": "res://Materials/pinta-Marron.tres",
		"color_preview": Color(0.55, 0.35, 0.15)
	},
	"rojo": {
		"nombre": "Rojo Fuego",
		"costo": 25,
		"material_path": "res://Materials/rojo.tres",
		"color_preview": Color(0.9, 0.2, 0.2)
	},
	"amarillo": {
		"nombre": "Amarillo Solar",
		"costo": 25,
		"material_path": "res://Materials/amarillo.tres",
		"color_preview": Color(0.95, 0.85, 0.15)
	},
	"rosa_metalico": {
		"nombre": "Rosa Metálico",
		"costo": 40,
		"material_path": "res://Materials/rosa metalico.tres",
		"color_preview": Color(0.95, 0.35, 0.75)
	},
	"verde_metalico": {
		"nombre": "Verde Metálico",
		"costo": 40,
		"material_path": "res://Materials/verde_metalico.tres",
		"color_preview": Color(0.2, 0.9, 0.6)
	}
}

var skins_desbloqueadas: Array[String] = ["azul"]
var skin_equipada: String = "azul"

# ==============================================================================
# VIDA MÁXIMA (VIDA MÁXIMA X DIAMANTES)
# ==============================================================================
const VIDA_BASE: int = 100
const VIDA_POR_NIVEL: int = 25
var nivel_vida_maxima: int = 0

# ==============================================================================
# POWERUPS (POWERUPS X DIAMANTES / RECOMPENSA = POWERUPS)
# ==============================================================================
const CATALOGO_POWERUPS: Dictionary = {
	"velocidad_inicial": {
		"nombre": "Turbo Inicial (+50% Vel 8s)",
		"costo": 10
	},
	"escudo_inicial": {
		"nombre": "Escudo Inicial (Invulnerable 8s)",
		"costo": 15
	},
	"cuerpo_extra": {
		"nombre": "Cuerpo Largo (+3 Eslabones)",
		"costo": 12
	},
	"tiempo_extra": {
		"nombre": "Reloj Extendido (+20s en Nivel)",
		"costo": 15
	}
}

var powerups_inventario: Dictionary = {
	"velocidad_inicial": 0,
	"escudo_inicial": 0,
	"cuerpo_extra": 0,
	"tiempo_extra": 0
}
var powerup_equipado: String = ""

# ==============================================================================
# CONFIGURACIÓN DE MAPAS Y METAS POR NIVEL (Map 1, 2 y 3 apuntan al mismo por ahora)
# ==============================================================================
const MAPAS_POR_NIVEL: Dictionary = {
	1: "res://Prefabs/13-Worlds/Maps/Map2.tscn",
	2: "res://Prefabs/13-Worlds/Maps/Map2.tscn",
	3: "res://Prefabs/13-Worlds/Maps/Map2.tscn"
}

func _ready() -> void:
	cargar_progreso()

func obtener_ruta_mapa_nivel(nivel: int = nivel_actual) -> String:
	var indice_ciclo: int = ((maxi(nivel, 1) - 1) % 3) + 1
	return MAPAS_POR_NIVEL.get(indice_ciclo, "res://Prefabs/13-Worlds/Maps/Map2.tscn")

func obtener_meta_huevos(nivel: int = nivel_actual) -> int:
	# Ejemplo: Nivel 1 = 5 huevos, Nivel 2 = 7 huevos, Nivel 3 = 9 huevos...
	return 3 + (maxi(nivel, 1) * 2)

func obtener_tiempo_limite(nivel: int = nivel_actual) -> float:
	# Ejemplo: 60 segundos base + 10s por nivel adicional
	return 60.0 + float(maxi(nivel, 1) - 1) * 10.0

func obtener_vida_maxima() -> int:
	return VIDA_BASE + (nivel_vida_maxima * VIDA_POR_NIVEL)

func obtener_costo_mejora_vida() -> int:
	return 15 + (nivel_vida_maxima * 15)

# ==============================================================================
# COMPRAS Y ACCIONES DE TIENDA / MONETIZACIÓN
# ==============================================================================
func comprar_o_equipar_skin(skin_id: String) -> bool:
	if not CATALOGO_SKINS.has(skin_id):
		return false
	if skin_id in skins_desbloqueadas:
		skin_equipada = skin_id
		guardar_progreso()
		progreso_actualizado.emit()
		return true
	var costo: int = int(CATALOGO_SKINS[skin_id]["costo"])
	if diamantes < costo:
		return false
	diamantes -= costo
	skins_desbloqueadas.append(skin_id)
	skin_equipada = skin_id
	guardar_progreso()
	progreso_actualizado.emit()
	return true

func comprar_mejora_vida() -> bool:
	var costo := obtener_costo_mejora_vida()
	if diamantes < costo:
		return false
	diamantes -= costo
	nivel_vida_maxima += 1
	guardar_progreso()
	progreso_actualizado.emit()
	return true

func comprar_powerup(powerup_id: String) -> bool:
	if not CATALOGO_POWERUPS.has(powerup_id):
		return false
	var costo: int = int(CATALOGO_POWERUPS[powerup_id]["costo"])
	if diamantes < costo:
		return false
	diamantes -= costo
	powerups_inventario[powerup_id] = int(powerups_inventario.get(powerup_id, 0)) + 1
	powerup_equipado = powerup_id
	guardar_progreso()
	progreso_actualizado.emit()
	return true

func equipar_powerup(powerup_id: String) -> void:
	if powerup_id.is_empty() or int(powerups_inventario.get(powerup_id, 0)) > 0:
		powerup_equipado = powerup_id
		guardar_progreso()
		progreso_actualizado.emit()

func otorgar_powerup_aleatorio() -> String:
	var claves: Array = CATALOGO_POWERUPS.keys()
	var elegido: String = claves[randi() % claves.size()]
	powerups_inventario[elegido] = int(powerups_inventario.get(elegido, 0)) + 1
	if powerup_equipado.is_empty():
		powerup_equipado = elegido
	guardar_progreso()
	progreso_actualizado.emit()
	return CATALOGO_POWERUPS[elegido]["nombre"]

func consumir_powerup_equipado() -> String:
	if powerup_equipado.is_empty():
		return ""
	var cant: int = int(powerups_inventario.get(powerup_equipado, 0))
	if cant <= 0:
		powerup_equipado = ""
		return ""
	var usado := powerup_equipado
	powerups_inventario[usado] = cant - 1
	if powerups_inventario[usado] <= 0:
		powerup_equipado = ""
	guardar_progreso()
	progreso_actualizado.emit()
	return usado

func calcular_diamantes_de_items(cantidad_items_o_puntos: int, multiplicador_extra: int = 1) -> int:
	return int(round(float(cantidad_items_o_puntos) * factor_conversion_diamantes)) * maxi(1, multiplicador_extra)

func agregar_diamantes(cantidad: int) -> void:
	if cantidad <= 0:
		return
	diamantes += cantidad
	guardar_progreso()
	progreso_actualizado.emit()

func gastar_diamantes(cantidad: int) -> bool:
	if diamantes < cantidad:
		return false
	diamantes -= cantidad
	guardar_progreso()
	progreso_actualizado.emit()
	return true

func avanzar_siguiente_nivel() -> void:
	nivel_actual += 1
	if nivel_actual > nivel_maximo_alcanzado:
		nivel_maximo_alcanzado = nivel_actual
	guardar_progreso()
	progreso_actualizado.emit()

func obtener_material_skin_equipada() -> Material:
	var info: Dictionary = CATALOGO_SKINS.get(skin_equipada, CATALOGO_SKINS["azul"])
	var ruta: String = info.get("material_path", "")
	if not ruta.is_empty() and ResourceLoader.exists(ruta):
		return load(ruta) as Material
	return null

# ==============================================================================
# PERSISTENCIA EN DISCO (ConfigFile)
# ==============================================================================
func guardar_progreso() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("economia", "diamantes", diamantes)
	cfg.set_value("economia", "factor_conversion", factor_conversion_diamantes)
	cfg.set_value("niveles", "nivel_actual", nivel_actual)
	cfg.set_value("niveles", "nivel_maximo_alcanzado", nivel_maximo_alcanzado)
	cfg.set_value("mejoras", "skins_desbloqueadas", skins_desbloqueadas)
	cfg.set_value("mejoras", "skin_equipada", skin_equipada)
	cfg.set_value("mejoras", "nivel_vida_maxima", nivel_vida_maxima)
	cfg.set_value("mejoras", "powerups_inventario", powerups_inventario)
	cfg.set_value("mejoras", "powerup_equipado", powerup_equipado)
	cfg.save(SAVE_PATH)

func cargar_progreso() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		guardar_progreso()
		return
	diamantes = int(cfg.get_value("economia", "diamantes", 30))
	factor_conversion_diamantes = float(cfg.get_value("economia", "factor_conversion", 1.0))
	nivel_actual = int(cfg.get_value("niveles", "nivel_actual", 1))
	nivel_maximo_alcanzado = int(cfg.get_value("niveles", "nivel_maximo_alcanzado", 1))
	var skins_cargadas = cfg.get_value("mejoras", "skins_desbloqueadas", ["azul"])
	skins_desbloqueadas.clear()
	for s in skins_cargadas:
		skins_desbloqueadas.append(str(s))
	if not ("azul" in skins_desbloqueadas):
		skins_desbloqueadas.append("azul")
	skin_equipada = str(cfg.get_value("mejoras", "skin_equipada", "azul"))
	nivel_vida_maxima = int(cfg.get_value("mejoras", "nivel_vida_maxima", 0))
	var inv_cargado = cfg.get_value("mejoras", "powerups_inventario", {})
	if inv_cargado is Dictionary:
		for k in powerups_inventario.keys():
			if inv_cargado.has(k):
				powerups_inventario[k] = int(inv_cargado[k])
	powerup_equipado = str(cfg.get_value("mejoras", "powerup_equipado", ""))
