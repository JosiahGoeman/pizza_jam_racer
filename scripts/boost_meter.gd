extends TextureFrame

var boost = 1

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func set_boost_level(val):
	boost = val
	update()

func _draw():
	var barLength = get_size().y * boost
	#306082
	draw_rect(Rect2(0, get_size().y - barLength, get_size().x, barLength), Color(0.117, 0.235, 0.321, 1))
	draw_texture_rect(get_texture(), Rect2(0, 0, get_size().x, get_size().y), false)
