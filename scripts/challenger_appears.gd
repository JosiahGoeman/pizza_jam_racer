extends CanvasLayer

export var backgroundSpinSpeed = 1
export var lightnessInc = 2

onready var spinnyBackground = get_node("spinny_background")
onready var trumpSprite = get_node("drumpf")

var spriteLightnessAccum = -5

func _ready():
	trumpSprite.set_modulate(Color(0, 0, 0))
	set_process(true)

func _process(delta):
	if(Input.is_key_pressed(KEY_SPACE)):
		get_tree().change_scene("res://rooms/boss_arena.tscn")
	
	spinnyBackground.set_rot(spinnyBackground.get_rot() + backgroundSpinSpeed * delta)
	
	spriteLightnessAccum += lightnessInc * delta
	if(spriteLightnessAccum > 1):
		spriteLightnessAccum = 1
	var spriteLightness = max(0, spriteLightnessAccum)
	trumpSprite.set_modulate(Color(spriteLightness, spriteLightness, spriteLightness))
