extends Control

# Ruta hacia el botón que acabamos de crear en la escena
@onready var boton_anuncio: Button = $BotonAnuncio
var diamantes_de_esta_ronda: int = 15

func _ready() -> void:
	# 1. Nos conectamos a la señal del AdsManager que avisa cuando terminó el video
	AdsManager.rewarded_earned.connect(_on_recompensa_ganada)
	
	# Opcional: mostrar el botón solo si los anuncios están listos
	boton_anuncio.visible = AdsManager.ads_ready

# 2. Esta función se conecta al botón para reproducir el anuncio
func _on_boton_anuncio_pressed() -> void:
	boton_anuncio.disabled = true # Desactivamos para evitar doble clic
	AdsManager.show_rewarded("duplicar_uranio")

# 3. Esta función se ejecuta AUTOMÁTICAMENTE solo si el jugador vio el anuncio completo
func _on_recompensa_ganada(placement: String) -> void:
	if placement == "duplicar_uranio":
		GameManager.dar_recompensa_extra(diamantes_de_esta_ronda)
		print("¡Diamantes duplicados con éxito!")
		boton_anuncio.disabled = false
