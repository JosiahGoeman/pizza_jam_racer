extends Node2D


func _ready():
	var carPrefab = load("res://prefabs/drunk_ai.tscn")
	var startPos = get_pos()
	set_pos(Vector2())
	for i in range(0, 10):
		var newCar = carPrefab.instance()
		newCar.get_node("car").set_pos(startPos + Vector2(rand_range(-200, 200), rand_range(-200, 200)))
		#add_child(newCar)
