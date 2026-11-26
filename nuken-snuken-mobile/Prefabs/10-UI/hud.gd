extends Control

@onready var ID_host: Label = $ID_host
@onready var datos_label: Label = $DatosDeJugadores
@onready var barra_superior: Label = get_node_or_null("MarginTop/PanelTop/StatsLabel")
@onready var control_layer: Control = get_node_or_null("ControlLayer")
@onready var objetivo_label: Label = $PanelObjetivo/VBoxContainer/ObjetivoLabel

func _ready() -> void:
	if ID_host:
		ID_host.visible = false
	GestorDeDatosPjs.datos_actualizados.connect(actualizar_visor_datos)
	GestorDeDatosPjs.objetivo_actualizado.connect(actualizar_label_objetivo)
	actualizar_label_objetivo(GestorDeDatosPjs.objetivo_huevos, GestorDeDatosPjs.huevos_por_tipo)
	if is_instance_valid(MetaProgression):
		MetaProgression.diamantes_cambiaron.connect(func(_d): actualizar_visor_datos())
	actualizar_visor_datos()

func actualizar_visor_datos() -> void:
	var datos: Dictionary = GestorDeDatosPjs.jugadores.get(1, {})
	var vida: int = int(datos.get("vida", GestorDeDatosPjs.vida_inicial))
	var vida_max: int = int(datos.get("vida_maxima", GestorDeDatosPjs.vida_inicial))
	var segs: int = int(ceil(GestorDeDatosPjs.tiempo_restante_nivel))
	@warning_ignore("integer_division")
	var mins: int = segs / 60
	var rem_s: int = segs % 60
	var nivel: int = MetaProgression.nivel_actual if is_instance_valid(MetaProgression) else 1
	var diamantes: int = MetaProgression.diamantes if is_instance_valid(MetaProgression) else 0

	var texto_resumen := "NIVEL %d   |   TIEMPO: %02d:%02d   |   VIDA: %d / %d   |   DIAMANTES: %d" % [
	nivel,
	mins,
	rem_s,
	vida,
	vida_max,
	diamantes]

	if barra_superior:
		barra_superior.text = texto_resumen
		if datos_label:
			datos_label.text = ""
	elif datos_label:
		datos_label.text = texto_resumen

func actualizar_label_objetivo(objetivo: Dictionary, recolectados: Dictionary) -> void:
	if not objetivo_label:
		return

	var texto := ""

	for huevo in objetivo:
		var nombre: String = huevo.trim_prefix("HUEVO_").capitalize()
		var actual: int = recolectados.get(huevo, 0)
		var necesario: int = objetivo[huevo]

		texto += "%s: %d / %d\n" % [nombre, actual, necesario]

	if GestorDeDatosPjs.objetivo_huevos_completado():
		texto += "\n¡COMPLETADO!"

	objetivo_label.text = texto.strip_edges()
