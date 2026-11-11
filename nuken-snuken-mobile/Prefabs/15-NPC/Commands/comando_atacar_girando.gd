class_name ComandoAtacarGirando
extends Command
## Comando para ordenar al sapo ejecutar su ataque giratorio.
func execute(actor: Node) -> void:
	if actor.has_method("atacar_girando"):
		await actor.atacar_girando()

func get_command_name() -> String:
	return "Atacar Girando"
