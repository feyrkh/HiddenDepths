extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	DialogueManager.show_dialogue_balloon(load("res://dialog/school_intro.dialogue") as DialogueResource)
	Events.show_overlay.connect(show_overlay)

func show_overlay(overlay_scene:Node):
	move_child($PopupLayer, -1)
	overlay_scene.process_mode = PROCESS_MODE_ALWAYS
	get_tree().paused = true
	$PopupLayer.add_child(overlay_scene)
	await overlay_scene.tree_exited
	get_tree().paused = false
