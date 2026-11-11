extends Node3D

const PLAYER_SCENE = preload("res://Prefabs/12-Players/Player-red.tscn")

@export var tipo_coneccion: String = "local"
@onready var players_container: Node3D = $Players
@onready var ui_layer: CanvasLayer = $UI
@onready var ui_lobby: Control = get_node_or_null("UI/LobbyPanel")
@onready var ui_respawn: Control = $UI/RespawnPanel
@onready var camera1: Camera3D = $Camera3D

var _jugador_actual: Player_MP = null
var _partida_activa: bool = false
var _tiempo_restante: float = 60.0
var _revives_ad_usados: int = 0
var _motivo_derrota: String = "vida"
var _invitacion_usada_en_partida: bool = false

# Referencias dinámicas de UI para los modales del diagrama Monetización
var _lbl_titulo_muerte: Label
var _lbl_subtitulo_muerte: Label
var _btn_revivir_ad: Button
var _btn_revivir_diamantes: Button
var _btn_invitacion_powerup: Button
var _btn_ir_fin_partida: Button

var _panel_fin_partida: PanelContainer
var _lbl_fin_titulo: Label
var _lbl_fin_resumen: Label
var _btn_ad_gratis_powerup: Button
var _btn_ad_x2_diamantes: Button
var _btn_saltar_o_menu: Button

func _ready() -> void:
	if ui_lobby:
		ui_lobby.visible = false
	if ui_respawn:
		ui_respawn.visible = false
	if has_node("Hud/ID_host"):
		$Hud/ID_host.visible = false
	if camera1:
		camera1.far = 95.0
		camera1.current = false

	_construir_interfaces_monetizacion()

	if not GestorDeDatosPjs.meta_huevos_alcanzada.is_connected(_on_meta_huevos_alcanzada):
		GestorDeDatosPjs.meta_huevos_alcanzada.connect(_on_meta_huevos_alcanzada)

	_iniciar_partida_local()

func _process(delta: float) -> void:
	if not _partida_activa:
		return
	if not is_instance_valid(_jugador_actual) or _jugador_actual.esta_muerto:
		return

	_tiempo_restante -= delta
	GestorDeDatosPjs.actualizar_tiempo_nivel(_tiempo_restante)

	if _tiempo_restante <= 0.0:
		_tiempo_restante = 0.0
		_partida_activa = false
		_jugador_actual.esta_muerto = true
		mostrar_lobby_respawn("tiempo")

func _iniciar_partida_local() -> void:
	_revives_ad_usados = 0
	_invitacion_usada_en_partida = false
	var nivel: int = MetaProgression.nivel_actual if is_instance_valid(MetaProgression) else 1
	_tiempo_restante = MetaProgression.obtener_tiempo_limite(nivel) if is_instance_valid(MetaProgression) else 60.0

	# Cargar el mapa correspondiente al Nivel (Map 1, 2 y 3 apuntan al mismo mapa base por ahora)
	_verificar_mapa_nivel(nivel)

	_spawn_player(1)
	_aplicar_powerup_equipado_inicio()

	if has_node("FabricasItems"):
		$FabricasItems.generar_todos_los_items()

	GestorDeDatosPjs.actualizar_tiempo_nivel(_tiempo_restante)
	_partida_activa = true

func _verificar_mapa_nivel(nivel: int) -> void:
	if not is_instance_valid(MetaProgression):
		return
	var ruta_mapa := MetaProgression.obtener_ruta_mapa_nivel(nivel)
	print("[World] Iniciando PARTIDA NIVEL %d con mapa: %s" % [nivel, ruta_mapa])

func _spawn_player(peer_id: int) -> void:
	for child in players_container.get_children():
		child.queue_free()

	var player_instance := PLAYER_SCENE.instantiate() as Player_MP
	player_instance.name = str(peer_id)
	player_instance.modo_Singleplayer = true
	players_container.add_child(player_instance)
	player_instance.global_position = $SpawnPos.global_position
	_jugador_actual = player_instance

	GestorDeDatosPjs.registrar_jugador(peer_id)

func _aplicar_powerup_equipado_inicio() -> void:
	if not is_instance_valid(MetaProgression) or not is_instance_valid(_jugador_actual):
		return
	var pw_usado := MetaProgression.consumir_powerup_equipado()
	if pw_usado.is_empty():
		return
	print("[World] Aplicando PowerUp inicial equipado: ", pw_usado)
	match pw_usado:
		"velocidad_inicial":
			_jugador_actual.activar_aumento_velocidad(1.5, 8.0)
		"escudo_inicial":
			GestorDeDatosPjs.activar_invulnerabilidad(1, 8.0)
		"cuerpo_extra":
			_jugador_actual.agregar_cuerpo(3)
		"tiempo_extra":
			_tiempo_restante += 20.0

# ==============================================================================
# CONSTRUCCIÓN DE PANELES UI (MORIR Y FIN DE PARTIDA / VICTORIA)
# ==============================================================================
func _construir_interfaces_monetizacion() -> void:
	var vbox_respawn := $UI/RespawnPanel/VBoxContainer
	for hijo in vbox_respawn.get_children():
		hijo.queue_free()

	var estilo_panel := StyleBoxFlat.new()
	estilo_panel.bg_color = Color(0.11, 0.04, 0.22, 0.95)
	estilo_panel.border_width_left = 3
	estilo_panel.border_width_top = 3
	estilo_panel.border_width_right = 3
	estilo_panel.border_width_bottom = 3
	estilo_panel.border_color = Color(0.42, 0.0, 1.0, 1.0)
	estilo_panel.set_corner_radius_all(16)
	estilo_panel.content_margin_left = 28
	estilo_panel.content_margin_right = 28
	estilo_panel.content_margin_top = 22
	estilo_panel.content_margin_bottom = 22
	ui_respawn.add_theme_stylebox_override("panel", estilo_panel)
	ui_respawn.set_anchors_preset(Control.PRESET_CENTER)
	ui_respawn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ui_respawn.grow_vertical = Control.GROW_DIRECTION_BOTH
	ui_respawn.custom_minimum_size = Vector2(680, 420)

	var estilo_rojo := StyleBoxFlat.new()
	estilo_rojo.bg_color = Color(0.85, 0.08, 0.05, 1.0)
	estilo_rojo.set_corner_radius_all(10)
	estilo_rojo.content_margin_top = 10
	estilo_rojo.content_margin_bottom = 10

	var estilo_verde := StyleBoxFlat.new()
	estilo_verde.bg_color = Color(0.0, 0.54, 0.08, 1.0)
	estilo_verde.set_corner_radius_all(10)
	estilo_verde.content_margin_top = 10
	estilo_verde.content_margin_bottom = 10

	vbox_respawn.add_theme_constant_override("separation", 12)

	_lbl_titulo_muerte = Label.new()
	_lbl_titulo_muerte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_titulo_muerte.add_theme_font_size_override("font_size", 28)
	vbox_respawn.add_child(_lbl_titulo_muerte)

	_lbl_subtitulo_muerte = Label.new()
	_lbl_subtitulo_muerte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_subtitulo_muerte.add_theme_font_size_override("font_size", 18)
	vbox_respawn.add_child(_lbl_subtitulo_muerte)

	_btn_revivir_ad = Button.new()
	_btn_revivir_ad.custom_minimum_size = Vector2(0, 46)
	_btn_revivir_ad.add_theme_stylebox_override("normal", estilo_rojo)
	_btn_revivir_ad.pressed.connect(_on_revivir_con_ad_pressed)
	vbox_respawn.add_child(_btn_revivir_ad)

	_btn_revivir_diamantes = Button.new()
	_btn_revivir_diamantes.custom_minimum_size = Vector2(0, 46)
	_btn_revivir_diamantes.add_theme_stylebox_override("normal", estilo_verde)
	_btn_revivir_diamantes.pressed.connect(_on_revivir_con_diamantes_pressed)
	vbox_respawn.add_child(_btn_revivir_diamantes)

	_btn_invitacion_powerup = Button.new()
	_btn_invitacion_powerup.custom_minimum_size = Vector2(0, 44)
	_btn_invitacion_powerup.add_theme_stylebox_override("normal", estilo_verde)
	_btn_invitacion_powerup.pressed.connect(_on_invitacion_powerup_pressed)
	vbox_respawn.add_child(_btn_invitacion_powerup)

	_btn_ir_fin_partida = Button.new()
	_btn_ir_fin_partida.custom_minimum_size = Vector2(0, 42)
	_btn_ir_fin_partida.text = "NO REVIVIR  ->  IR A FIN DE PARTIDA"
	_btn_ir_fin_partida.pressed.connect(func(): _mostrar_panel_fin_partida(false))
	vbox_respawn.add_child(_btn_ir_fin_partida)

	# Panel de Fin de Partida (Victoria / Derrota + Recompensas)
	_panel_fin_partida = PanelContainer.new()
	_panel_fin_partida.name = "FinDePartidaPanel"
	_panel_fin_partida.visible = false
	_panel_fin_partida.add_theme_stylebox_override("panel", estilo_panel)
	_panel_fin_partida.set_anchors_preset(Control.PRESET_CENTER)
	_panel_fin_partida.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel_fin_partida.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel_fin_partida.custom_minimum_size = Vector2(720, 430)
	ui_layer.add_child(_panel_fin_partida)

	var vbox_fin := VBoxContainer.new()
	vbox_fin.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_fin.add_theme_constant_override("separation", 14)
	_panel_fin_partida.add_child(vbox_fin)

	_lbl_fin_titulo = Label.new()
	_lbl_fin_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_fin_titulo.add_theme_font_size_override("font_size", 28)
	vbox_fin.add_child(_lbl_fin_titulo)

	_lbl_fin_resumen = Label.new()
	_lbl_fin_resumen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_fin_resumen.add_theme_font_size_override("font_size", 19)
	vbox_fin.add_child(_lbl_fin_resumen)

	_btn_ad_gratis_powerup = Button.new()
	_btn_ad_gratis_powerup.custom_minimum_size = Vector2(0, 46)
	_btn_ad_gratis_powerup.add_theme_stylebox_override("normal", estilo_rojo)
	vbox_fin.add_child(_btn_ad_gratis_powerup)

	_btn_ad_x2_diamantes = Button.new()
	_btn_ad_x2_diamantes.custom_minimum_size = Vector2(0, 48)
	_btn_ad_x2_diamantes.add_theme_stylebox_override("normal", estilo_rojo)
	vbox_fin.add_child(_btn_ad_x2_diamantes)

	_btn_saltar_o_menu = Button.new()
	_btn_saltar_o_menu.custom_minimum_size = Vector2(0, 44)
	vbox_fin.add_child(_btn_saltar_o_menu)

# ==============================================================================
# FLUJO 1: MORIR / PERDER (Revivir con Ad [máx 2], Revivir x Diamantes, Invitación)
# ==============================================================================
func mostrar_lobby_respawn(motivo: String = "vida") -> void:
	_partida_activa = false
	_motivo_derrota = motivo
	if camera1:
		camera1.current = true
	if _panel_fin_partida:
		_panel_fin_partida.visible = false
	if ui_respawn:
		ui_respawn.visible = true
	_actualizar_botones_respawn()

func _actualizar_botones_respawn() -> void:
	var max_ads := MetaProgression.MAX_REVIVES_CON_AD
	var restantes := maxi(0, max_ads - _revives_ad_usados)
	var costo_diam := MetaProgression.COSTO_REVIVIR_DIAMANTES
	var diam_disp := MetaProgression.diamantes

	if _motivo_derrota == "tiempo":
		_lbl_titulo_muerte.text = "¡SE AGOTÓ EL TIEMPO EN EL NIVEL %d!" % MetaProgression.nivel_actual
	else:
		_lbl_titulo_muerte.text = "¡HAS MUERTO EN EL NIVEL %d!" % MetaProgression.nivel_actual

	_lbl_subtitulo_muerte.text = "Huevos recolectados: %d / %d   |   Tus Diamantes: %d" % [
		GestorDeDatosPjs.huevos_recolectados_nivel,
		GestorDeDatosPjs.huevos_objetivo_nivel,
		diam_disp
	]

	if restantes > 0:
		_btn_revivir_ad.text = "VER ANUNCIO PARA REVIVIR (%d / %d DISPONIBLES)" % [restantes, max_ads]
		_btn_revivir_ad.disabled = false
	else:
		_btn_revivir_ad.text = "VER ANUNCIO PARA REVIVIR (0 / %d - LÍMITE ALCANZADO)" % max_ads
		_btn_revivir_ad.disabled = true

	_btn_revivir_diamantes.text = "REVIVIR X %d DIAMANTES (Tenés: %d)" % [costo_diam, diam_disp]
	_btn_revivir_diamantes.disabled = diam_disp < costo_diam

	_btn_invitacion_powerup.text = "INVITACIONES POR POWER UP (+1 PowerUp y Fin de Partida)"
	_btn_invitacion_powerup.disabled = _invitacion_usada_en_partida

func ocultar_lobby_respawn() -> void:
	if ui_respawn:
		ui_respawn.visible = false
	if camera1:
		camera1.current = false

func _on_revivir_con_ad_pressed() -> void:
	if _revives_ad_usados >= MetaProgression.MAX_REVIVES_CON_AD:
		return
	_btn_revivir_ad.disabled = true
	await AdManagerSingleton.create_reward_ad("Revivir en Nivel %d" % MetaProgression.nivel_actual)
	_revives_ad_usados += 1
	_ejecutar_revivir()

func _on_revivir_con_diamantes_pressed() -> void:
	if not MetaProgression.gastar_diamantes(MetaProgression.COSTO_REVIVIR_DIAMANTES):
		return
	_ejecutar_revivir()

func _ejecutar_revivir() -> void:
	ocultar_lobby_respawn()
	if _tiempo_restante <= 5.0:
		_tiempo_restante += 30.0
	GestorDeDatosPjs.actualizar_tiempo_nivel(_tiempo_restante)
	if is_instance_valid(_jugador_actual):
		_jugador_actual.respawnear_en_servidor($SpawnPos.global_position)
	_partida_activa = true

func _on_invitacion_powerup_pressed() -> void:
	_invitacion_usada_en_partida = true
	var ganado := MetaProgression.otorgar_powerup_aleatorio()
	DisplayServer.clipboard_set("¡Jugá Nuke Snuken Mobile conmigo!")
	_mostrar_panel_fin_partida(false, "¡Invitación copiada! Ganaste PowerUp: " + ganado)

# ==============================================================================
# FLUJO 2: GANAR / FIN DE PARTIDA (Conversión 1:1 + Recompensa PowerUp + x2 Ad)
# ==============================================================================
func _on_meta_huevos_alcanzada() -> void:
	if not _partida_activa:
		return
	_partida_activa = false
	if is_instance_valid(_jugador_actual):
		_jugador_actual.velocity = Vector3.ZERO
	_mostrar_panel_fin_partida(true)

func _mostrar_panel_fin_partida(es_victoria: bool, mensaje_extra: String = "") -> void:
	_partida_activa = false
	if ui_respawn:
		ui_respawn.visible = false
	if camera1:
		camera1.current = true
	_panel_fin_partida.visible = true

	var huevos := GestorDeDatosPjs.huevos_recolectados_nivel
	var diamantes_base := MetaProgression.calcular_diamantes_de_items(huevos, 1)
	var diamantes_x2 := MetaProgression.calcular_diamantes_de_items(huevos, 2)
	var nivel := MetaProgression.nivel_actual

	# Desconectar conexiones previas
	for conn in _btn_ad_gratis_powerup.pressed.get_connections():
		_btn_ad_gratis_powerup.pressed.disconnect(conn["callable"])
	for conn in _btn_ad_x2_diamantes.pressed.get_connections():
		_btn_ad_x2_diamantes.pressed.disconnect(conn["callable"])
	for conn in _btn_saltar_o_menu.pressed.get_connections():
		_btn_saltar_o_menu.pressed.disconnect(conn["callable"])

	if es_victoria:
		_lbl_fin_titulo.text = "¡GANASTE EL NIVEL %d!  —  FIN DE PARTIDA" % nivel
		_lbl_fin_resumen.text = "ITEMS RECOLECTADOS: %d Huevos\nDAN DIAMANTES (1:1): +%d Diamantes" % [huevos, diamantes_base]
		_btn_ad_gratis_powerup.visible = true
		_btn_ad_gratis_powerup.disabled = false
		_btn_ad_gratis_powerup.text = "1) VER ANUNCIO (VERSIÓN GRATIS)  ->  RECOMPENSA = POWERUP"
		_btn_ad_gratis_powerup.pressed.connect(func():
			_btn_ad_gratis_powerup.disabled = true
			await AdManagerSingleton.create_reward_ad("Fin de Partida - Recompensa PowerUp")
			var pw_nombre := MetaProgression.otorgar_powerup_aleatorio()
			_lbl_fin_resumen.text = "¡Recibiste PowerUp: %s!\nItems recolectados: %d -> +%d Diamantes" % [pw_nombre, huevos, diamantes_base]
			_btn_ad_gratis_powerup.text = "RECOMPENSA POWERUP OBTENIDA (%s)" % pw_nombre
		)

		_btn_ad_x2_diamantes.visible = true
		_btn_ad_x2_diamantes.disabled = false
		_btn_ad_x2_diamantes.text = "2) VER ANUNCIO PARA DESBLOQUEAR RECOMPENSA x2 (+%d DIAMANTES) -> NIVEL %d" % [diamantes_x2, nivel + 1]
		_btn_ad_x2_diamantes.pressed.connect(func():
			_btn_ad_x2_diamantes.disabled = true
			_btn_saltar_o_menu.disabled = true
			await AdManagerSingleton.create_reward_ad("Recompensa x2 Diamantes")
			MetaProgression.agregar_diamantes(diamantes_x2)
			MetaProgression.avanzar_siguiente_nivel()
			_cargar_siguiente_nivel()
		)

		_btn_saltar_o_menu.visible = true
		_btn_saltar_o_menu.disabled = false
		_btn_saltar_o_menu.text = "SALTAR (Reclamar +%d Diamantes e ir a PARTIDA NIVEL %d)" % [diamantes_base, nivel + 1]
		_btn_saltar_o_menu.pressed.connect(func():
			MetaProgression.agregar_diamantes(diamantes_base)
			MetaProgression.avanzar_siguiente_nivel()
			_cargar_siguiente_nivel()
		)
	else:
		_lbl_fin_titulo.text = "FIN DE PARTIDA  —  NIVEL %d" % nivel
		var texto_base := "ITEMS RECOLECTADOS: %d Huevos  ->  +%d Diamantes (1:1)" % [huevos, diamantes_base]
		if not mensaje_extra.is_empty():
			texto_base = mensaje_extra + "\n" + texto_base
		_lbl_fin_resumen.text = texto_base

		_btn_ad_gratis_powerup.visible = false

		_btn_ad_x2_diamantes.visible = huevos > 0
		_btn_ad_x2_diamantes.disabled = false
		_btn_ad_x2_diamantes.text = "VER ANUNCIO RECOMPENSA x2 (+%d DIAMANTES) Y VOLVER A INICIO" % diamantes_x2
		_btn_ad_x2_diamantes.pressed.connect(func():
			_btn_ad_x2_diamantes.disabled = true
			_btn_saltar_o_menu.disabled = true
			await AdManagerSingleton.create_reward_ad("Duplicar Diamantes x2")
			MetaProgression.agregar_diamantes(diamantes_x2)
			_volver_a_menu_inicial()
		)

		_btn_saltar_o_menu.visible = true
		_btn_saltar_o_menu.disabled = false
		_btn_saltar_o_menu.text = "VA A MENÚ INICIAL (Reclamar +%d Diamantes)" % diamantes_base
		_btn_saltar_o_menu.pressed.connect(func():
			MetaProgression.agregar_diamantes(diamantes_base)
			_volver_a_menu_inicial()
		)

func _cargar_siguiente_nivel() -> void:
	_panel_fin_partida.visible = false
	if camera1:
		camera1.current = false
	for child in $ItemsSpawnPath.get_children():
		child.queue_free()
	_iniciar_partida_local()

func _volver_a_menu_inicial() -> void:
	_panel_fin_partida.visible = false
	ocultar_lobby_respawn()
	GestorDeDatosPjs.jugadores.clear()
	GestorDeDatosPjs.jugadores_invulnerables.clear()
	GestorDeObjetos.lista_objetos_por_jugador.clear()

	var gm: Node = null
	if get_parent() and get_parent().has_node("MenuUI") and "maquina_estados" in get_parent():
		gm = get_parent()
	elif get_tree().current_scene and get_tree().current_scene.has_node("MenuUI") and "maquina_estados" in get_tree().current_scene:
		gm = get_tree().current_scene

	if gm and gm.maquina_estados:
		gm.maquina_estados.change_state(gm.maquina_estados.en_menu)
	else:
		get_tree().change_scene_to_file("res://GM/game_managerGM.tscn")
