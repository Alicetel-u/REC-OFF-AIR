extends "res://Inventory/ItemResource.gd"

class_name CraftItem

@export var itemsNeeded: Array[Resource]

func _init(p_itemsNeeded=[] as Array[Resource]):
	itemsNeeded = p_itemsNeeded
