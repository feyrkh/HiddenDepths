extends Node2D

var character_name:String = "nobody"

func set_character_name(char_name:String):
	self.character_name = char_name

func set_mood(mood:String):
	print("Mood is ", mood)
