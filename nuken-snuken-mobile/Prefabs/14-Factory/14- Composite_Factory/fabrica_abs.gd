@abstract
class_name FabricaAbstracta
extends Node3D

@export var spawn_path: Node3D
@export var escena_base_item: PackedScene = preload("res://Prefabs/14-Factory/14- Composite_Factory/Item.tscn")

@abstract
func obtener_item_data() -> ItemData

func fabricar() -> ItemWorld:
	if not escena_base_item:
		push_error("Fabrica: No se ha asignado escena_base_item.")
		return null
	var item_data: ItemData = obtener_item_data()
	if not item_data:
		push_error("Fabrica: No se devolvió ningún ItemData.")
		return null
	var nuevo_item: ItemWorld = escena_base_item.instantiate() as ItemWorld
	nuevo_item.data = item_data
	nuevo_item.data_path = item_data.resource_path
	return nuevo_item

func spawn_en_pos(posicion: Vector3) -> ItemWorld:
	var item: ItemWorld = fabricar()
	if item:
		var destino = spawn_path if spawn_path else get_parent()
		destino.add_child(item, true)
		item.global_position = posicion
	return item

func spawn_en_nodo(nodo: Node3D) -> ItemWorld:
	return spawn_en_pos(nodo.global_position)
