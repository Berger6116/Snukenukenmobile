extends Node
class_name AdManager

const AD_ID_BANNER = "ca-app-pub-9036926653791319/6642507886"
const AD_ID_REWARD = "ca-app-pub-9036926653791319/6748251419"

var ads_initialized: bool = false
var _es_dispositivo_movil: bool = false
var ad_view_banner: AdView
var ad_view_reward: RewardedAd

signal on_ad_reward_gained

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_es_dispositivo_movil = OS.get_name() in ["Android", "iOS"]
	if _es_dispositivo_movil:
		var listener := OnInitializationCompleteListener.new()
		listener.on_initialization_complete = _on_ads_initialize
		MobileAds.initialize(listener)
	else:
		print("[AdManager] Ejecutando en PC/Editor: Modo de simulación de anuncios activo.")
		ads_initialized = true

func _on_ads_initialize(_status) -> void:
	print("[AdManager] AdMob inicializado correctamente!")
	ads_initialized = true

func create_banner_ad(ad_position: int = AdPosition.Values.BOTTOM) -> void:
	if not _es_dispositivo_movil:
		print("[AdManager Simulado] Mostrando Banner Ad en posición: ", ad_position)
		return
	var intentos := 0
	while not ads_initialized and intentos < 10:
		print("[AdManager] Esperando inicialización para Banner...")
		await get_tree().create_timer(0.5).timeout
		intentos += 1
	if not ads_initialized:
		return
	if ad_view_banner:
		ad_view_banner.destroy()
	ad_view_banner = AdView.new(AD_ID_BANNER, AdSize.BANNER, ad_position)
	var _ad_listener := AdListener.new()
	_ad_listener.on_ad_clicked = func(): print("[AdManager] Banner clicked")
	_ad_listener.on_ad_closed = func(): print("[AdManager] Banner closed")
	_ad_listener.on_ad_failed_to_load = func(_err): print("[AdManager] Banner failed to load")
	_ad_listener.on_ad_impression = func(): print("[AdManager] Banner impression")
	_ad_listener.on_ad_loaded = func(): print("[AdManager] Banner loaded")
	_ad_listener.on_ad_opened = func(): print("[AdManager] Banner opened")
	ad_view_banner.ad_listener = _ad_listener
	var ad_request := AdRequest.new()
	ad_view_banner.load_ad(ad_request)

func hide_banner_ad() -> void:
	if ad_view_banner:
		ad_view_banner.destroy()
		ad_view_banner = null

func create_reward_ad(motivo: String = "Recompensa") -> bool:
	if not _es_dispositivo_movil:
		await _mostrar_anuncio_simulado_editor(motivo)
		on_ad_reward_gained.emit()
		return true

	var intentos := 0
	while not ads_initialized and intentos < 8:
		print("[AdManager] Esperando inicialización para Rewarded Ad...")
		await get_tree().create_timer(0.5).timeout
		intentos += 1

	if not ads_initialized:
		print("[AdManager] AdMob no inicializó a tiempo, usando fallback.")
		await _mostrar_anuncio_simulado_editor(motivo)
		on_ad_reward_gained.emit()
		return true

	if ad_view_reward:
		ad_view_reward.destroy()
		ad_view_reward = null

	var finalizado := false
	var recompensa_obtenida := false

	var rewarded_ad_load_callback := RewardedAdLoadCallback.new()
	rewarded_ad_load_callback.on_ad_failed_to_load = func(ad_error: LoadAdError) -> void:
		print("[AdManager] Error al cargar RewardedAd: ", ad_error.message if ad_error else "desconocido")
		recompensa_obtenida = true
		finalizado = true

	rewarded_ad_load_callback.on_ad_loaded = func(new_rewarded_ad: RewardedAd) -> void:
		ad_view_reward = new_rewarded_ad
		var full_screen_cb := FullScreenContentCallback.new()
		full_screen_cb.on_ad_dismissed_full_screen_content = func() -> void:
			finalizado = true
		full_screen_cb.on_ad_failed_to_show_full_screen_content = func(_err) -> void:
			recompensa_obtenida = true
			finalizado = true
		ad_view_reward.full_screen_content_callback = full_screen_cb

		var on_user_earned_reward_listener := OnUserEarnedRewardListener.new()
		on_user_earned_reward_listener.on_user_earned_reward = func(_reward) -> void:
			recompensa_obtenida = true
			on_ad_reward_gained.emit()
		new_rewarded_ad.show(on_user_earned_reward_listener)

	RewardedAdLoader.new().load(AD_ID_REWARD, AdRequest.new(), rewarded_ad_load_callback)

	var tiempo_espera := 0.0
	while not finalizado and tiempo_espera < 30.0:
		await get_tree().create_timer(0.2).timeout
		tiempo_espera += 0.2

	if recompensa_obtenida:
		on_ad_reward_gained.emit()
	return recompensa_obtenida

func _mostrar_anuncio_simulado_editor(motivo: String) -> void:
	var capa := CanvasLayer.new()
	capa.layer = 120
	capa.process_mode = Node.PROCESS_MODE_ALWAYS
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.05, 0.12, 0.92)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	fondo.add_child(vbox)

	var lbl_titulo := Label.new()
	lbl_titulo.text = "[ ANUNCIO ADMOB SIMULADO - EDITOR ]\nMotivo: " + motivo
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 26)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(lbl_titulo)

	var lbl_timer := Label.new()
	lbl_timer.text = "Otorgando recompensa en 1.2s..."
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_timer.add_theme_font_size_override("font_size", 18)
	vbox.add_child(lbl_timer)

	get_tree().root.add_child(capa)
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(capa):
		capa.queue_free()
