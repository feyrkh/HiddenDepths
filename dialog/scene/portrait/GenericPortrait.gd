extends Node2D
class_name GenericPortrait

@export var character_name:String = "nobody"
@onready var portrait = find_child("BasePortrait")

func set_character_name(char_name:String):
	self.character_name = char_name
	find_child("BasePortrait").texture = load("res://dialog/scene/portrait/%s.jpg" % char_name)
	set_mood("neutral")

func set_mood(mood:String):
	$MoodLabel.text = "mood: "+mood

func set_flip(flipped:bool=true):
	portrait.scale.x = -1 if flipped else 1
