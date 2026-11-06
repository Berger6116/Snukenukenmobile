extends Node

signal rewarded_earned(placement: String)
signal interstitial_closed

var ads_ready := true # Lo ponemos en true para poder probar en PC
var modo_prueba_pc := true # Cambiar a false cuando instales el plugin de AdMob real

func show_rewarded(placement: String) -> void:
	if not ads_ready:
		print("[AdsManager] El anuncio no está listo todavía.")
		return

	if modo_prueba_pc:
		print("[AdsManager] Simulando anuncio recompensado para: ", placement)
		# Simulamos 2 segundos de publicidad usando el timer de Godot
		await get_tree().create_timer(2.0).timeout
		print("[AdsManager] ¡Anuncio completado con éxito!")
		rewarded_earned.emit(placement)
		return

	# --- Aquí irá la llamada al plugin real de Android más adelante ---
	# Cuando el SDK confirme la recompensa:
	# rewarded_earned.emit(placement)

func show_interstitial() -> void:
	if not ads_ready:
		interstitial_closed.emit()
		return

	if modo_prueba_pc:
		print("[AdsManager] Simulando anuncio intersticial de pantalla completa...")
		await get_tree().create_timer(1.5).timeout
		print("[AdsManager] Anuncio intersticial cerrado.")
		interstitial_closed.emit()
		return

	# --- Aquí irá la llamada al plugin real de Android más adelante ---
	# Al cerrarse el anuncio:
	# interstitial_closed.emit()
