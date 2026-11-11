extends Control
class_name PersonalizacionScreen

signal continuar_a_partida
signal volver_a_menu

var _skin_keys: Array = []
var _skin_idx: int = 0

var _powerup_keys: Array = []
var _powerup_idx: int = 0

@onready var lbl_titulo: Label = $Margin/MainVBox/HeaderHBox/TituloLabel
@onready var lbl_diamantes: Label = $Margin/MainVBox/HeaderHBox/DiamantesLabel
@onready var lbl_feedback: Label = $Margin/MainVBox/FeedbackLabel

# Card 1: Skins
@onready var lbl_skin_info: Label = $Margin/MainVBox/GridCards/CardSkin/VBox/InfoLabel
@onready var color_preview: ColorRect = $Margin/MainVBox/GridCards/CardSkin/VBox/ColorPreview
@onready var btn_prev_skin: Button = $Margin/MainVBox/GridCards/CardSkin/VBox/NavHBox/PrevSkinBtn
@onready var btn_next_skin: Button = $Margin/MainVBox/GridCards/CardSkin/VBox/NavHBox/NextSkinBtn
@onready var btn_accion_skin: Button = $Margin/MainVBox/GridCards/CardSkin/VBox/ComprarSkinBtn

# Card 2: Vida Máxima
@onready var lbl_vida_info: Label = $Margin/MainVBox/GridCards/CardVida/VBox/InfoLabel
@onready var btn_comprar_vida: Button = $Margin/MainVBox/GridCards/CardVida/VBox/ComprarVidaBtn

# Card 3: PowerUps
@onready var lbl_pw_info: Label = $Margin/MainVBox/GridCards/CardPowerUp/VBox/InfoLabel
@onready var btn_prev_pw: Button = $Margin/MainVBox/GridCards/CardPowerUp/VBox/NavHBox/PrevPwBtn
@onready var btn_next_pw: Button = $Margin/MainVBox/GridCards/CardPowerUp/VBox/NavHBox/NextPwBtn
@onready var btn_comprar_pw: Button = $Margin/MainVBox/GridCards/CardPowerUp/VBox/ComprarPwBtn

# Card 4: Comprar Diamantes
@onready var lbl_diam_shop_info: Label = $Margin/MainVBox/GridCards/CardDiamantes/VBox/InfoLabel
@onready var btn_ad_diamantes: Button = $Margin/MainVBox/GridCards/CardDiamantes/VBox/AdDiamantesBtn
@onready var btn_pack_diamantes: Button = $Margin/MainVBox/GridCards/CardDiamantes/VBox/PackDiamantesBtn

# Botones inferiores
@onready var btn_volver: Button = $Margin/MainVBox/FooterHBox/VolverBtn
@onready var btn_continuar_ad: Button = $Margin/MainVBox/FooterHBox/ContinuarAdBtn

func _ready() -> void:
	_skin_keys = MetaProgression.CATALOGO_SKINS.keys()
	_skin_idx = maxi(0, _skin_keys.find(MetaProgression.skin_equipada))
	_powerup_keys = MetaProgression.CATALOGO_POWERUPS.keys()
	_powerup_idx = 0

	btn_prev_skin.pressed.connect(func(): _cambiar_indice_skin(-1))
	btn_next_skin.pressed.connect(func(): _cambiar_indice_skin(1))
	btn_accion_skin.pressed.connect(_on_comprar_o_equipar_skin)

	btn_comprar_vida.pressed.connect(_on_comprar_vida)

	btn_prev_pw.pressed.connect(func(): _cambiar_indice_pw(-1))
	btn_next_pw.pressed.connect(func(): _cambiar_indice_pw(1))
	btn_comprar_pw.pressed.connect(_on_comprar_powerup)

	btn_ad_diamantes.pressed.connect(_on_ver_ad_por_diamantes)
	btn_pack_diamantes.pressed.connect(_on_comprar_pack_diamantes)

	btn_volver.pressed.connect(func(): volver_a_menu.emit())
	btn_continuar_ad.pressed.connect(_on_continuar_con_anuncio)

	MetaProgression.diamantes_cambiaron.connect(func(_d): refrescar_ui())
	MetaProgression.progreso_actualizado.connect(refrescar_ui)
	refrescar_ui()

func _cambiar_indice_skin(delta: int) -> void:
	_skin_idx = (_skin_idx + delta + _skin_keys.size()) % _skin_keys.size()
	refrescar_ui()

func _cambiar_indice_pw(delta: int) -> void:
	_powerup_idx = (_powerup_idx + delta + _powerup_keys.size()) % _powerup_keys.size()
	refrescar_ui()

func refrescar_ui() -> void:
	var nivel := MetaProgression.nivel_actual
	var meta_huevos := MetaProgression.obtener_meta_huevos(nivel)
	var tiempo_lim := int(MetaProgression.obtener_tiempo_limite(nivel))
	lbl_titulo.text = "PERSONALIZACIÓN DE PERSONAJE  —  PRÓXIMO: NIVEL %d (Meta: %d Huevos en %ds)" % [nivel, meta_huevos, tiempo_lim]
	lbl_diamantes.text = "DIAMANTES: %d" % MetaProgression.diamantes

	# 1. Skin
	var skin_id: String = _skin_keys[_skin_idx]
	var skin_data: Dictionary = MetaProgression.CATALOGO_SKINS[skin_id]
	var desbloqueada: bool = skin_id in MetaProgression.skins_desbloqueadas
	var equipada: bool = (MetaProgression.skin_equipada == skin_id)
	color_preview.color = skin_data.get("color_preview", Color.WHITE)
	lbl_skin_info.text = "%s\nEstado: %s" % [
		skin_data["nombre"],
		"EQUIPADA" if equipada else ("DESBLOQUEADA" if desbloqueada else ("Costo: %d Diamantes" % skin_data["costo"]))
	]
	if equipada:
		btn_accion_skin.text = "SKIN EQUIPADA"
		btn_accion_skin.disabled = true
	elif desbloqueada:
		btn_accion_skin.text = "EQUIPAR SKIN"
		btn_accion_skin.disabled = false
	else:
		btn_accion_skin.text = "COMPRAR (%d DIAMANTES)" % int(skin_data["costo"])
		btn_accion_skin.disabled = MetaProgression.diamantes < int(skin_data["costo"])

	# 2. Vida Máxima
	var vida_actual := MetaProgression.obtener_vida_maxima()
	var costo_vida := MetaProgression.obtener_costo_mejora_vida()
	lbl_vida_info.text = "Nivel de Mejora: %d\nVida Máxima Actual: %d HP\nPróximo Nivel: %d HP" % [
		MetaProgression.nivel_vida_maxima,
		vida_actual,
		vida_actual + MetaProgression.VIDA_POR_NIVEL
	]
	btn_comprar_vida.text = "MEJORAR VIDA (%d DIAMANTES)" % costo_vida
	btn_comprar_vida.disabled = MetaProgression.diamantes < costo_vida

	# 3. PowerUps
	var pw_id: String = _powerup_keys[_powerup_idx]
	var pw_data: Dictionary = MetaProgression.CATALOGO_POWERUPS[pw_id]
	var cant_inv: int = int(MetaProgression.powerups_inventario.get(pw_id, 0))
	var pw_eq_nombre: String = "Ninguno"
	if not MetaProgression.powerup_equipado.is_empty() and MetaProgression.CATALOGO_POWERUPS.has(MetaProgression.powerup_equipado):
		pw_eq_nombre = MetaProgression.CATALOGO_POWERUPS[MetaProgression.powerup_equipado]["nombre"]
	lbl_pw_info.text = "%s\nEn Inventario: %d\nEquipado: %s" % [pw_data["nombre"], cant_inv, pw_eq_nombre]
	btn_comprar_pw.text = "COMPRAR Y EQUIPAR (%d DIAMANTES)" % int(pw_data["costo"])
	btn_comprar_pw.disabled = MetaProgression.diamantes < int(pw_data["costo"])

	# 4. Botón Continuar a Nivel n
	btn_continuar_ad.text = "VER ANUNCIO PARA CONTINUAR  ->  PARTIDA NIVEL %d" % nivel

func _on_comprar_o_equipar_skin() -> void:
	var skin_id: String = _skin_keys[_skin_idx]
	if MetaProgression.comprar_o_equipar_skin(skin_id):
		lbl_feedback.text = "Skin lista: " + MetaProgression.CATALOGO_SKINS[skin_id]["nombre"]
	else:
		lbl_feedback.text = "No tenés suficientes diamantes para esta Skin."
	refrescar_ui()

func _on_comprar_vida() -> void:
	if MetaProgression.comprar_mejora_vida():
		lbl_feedback.text = "¡Vida Máxima aumentada a %d HP!" % MetaProgression.obtener_vida_maxima()
	else:
		lbl_feedback.text = "No tenés suficientes diamantes para mejorar Vida Máxima."
	refrescar_ui()

func _on_comprar_powerup() -> void:
	var pw_id: String = _powerup_keys[_powerup_idx]
	if MetaProgression.comprar_powerup(pw_id):
		lbl_feedback.text = "¡PowerUp comprado y equipado para el Nivel %d!" % MetaProgression.nivel_actual
	else:
		lbl_feedback.text = "No tenés suficientes diamantes para este PowerUp."
	refrescar_ui()

func _on_ver_ad_por_diamantes() -> void:
	btn_ad_diamantes.disabled = true
	await AdManagerSingleton.create_reward_ad("Obtener +20 Diamantes")
	MetaProgression.agregar_diamantes(20)
	lbl_feedback.text = "¡Recibiste +20 Diamantes por ver el anuncio!"
	btn_ad_diamantes.disabled = false
	refrescar_ui()

func _on_comprar_pack_diamantes() -> void:
	MetaProgression.agregar_diamantes(50)
	lbl_feedback.text = "¡Pack de +50 Diamantes acreditado!"
	refrescar_ui()

func _on_continuar_con_anuncio() -> void:
	btn_continuar_ad.disabled = true
	lbl_feedback.text = "Cargando anuncio para iniciar Nivel %d..." % MetaProgression.nivel_actual
	await AdManagerSingleton.create_reward_ad("Continuar a Partida Nivel %d" % MetaProgression.nivel_actual)
	btn_continuar_ad.disabled = false
	continuar_a_partida.emit()
