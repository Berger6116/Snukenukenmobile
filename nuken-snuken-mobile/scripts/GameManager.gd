extends Node

signal partida_terminada(puntos_obtenidos: int, diamantes_ganados: int)
signal diamantes_actualizados(total_diamantes: int)

var diamantes_uranio: int = 0
var puntos_partida_actual: int = 0
var partidas_jugadas: int = 0

func iniciar_partida() -> void:
	puntos_partida_actual = 0

func finalizar_partida() -> void:
	partidas_jugadas += 1
	var diamantes_ganados = int(puntos_partida_actual / 10) # Ej: 1 diamante cada 10 puntos
	diamantes_uranio += diamantes_ganados
	
	diamantes_actualizados.emit(diamantes_uranio)
	partida_terminada.emit(puntos_partida_actual, diamantes_ganados)
	
	# Cada 3 partidas, mostramos un anuncio intersticial automático
	if partidas_jugadas % 3 == 0:
		AdsManager.show_interstitial()

func dar_recompensa_extra(cantidad: int) -> void:
	diamantes_uranio += cantidad
	diamantes_actualizados.emit(diamantes_uranio)
