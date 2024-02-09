extends RichTextLabel

var dialogue_line:DialogueLine
var dialogue_response:DialogueResponse
var skill_test:bool = false

func set_dialogue_line(_line:DialogueLine):
	dialogue_line = _line

func set_dialogue_response(_response:DialogueResponse):
	dialogue_response = _response

func on_selected():
	if dialogue_response and dialogue_response.has_tag("skill"):
		var target_skill = dialogue_response.get_tag_value("skill")
		var heart_bonus = int(dialogue_response.get_tag_value("h"))
		var skull_bonus = int(dialogue_response.get_tag_value("s"))
		var slot_machine:HeartSlots = load("res://dialog/reel/HeartSlots.tscn").instantiate()
		slot_machine.setup(target_skill, heart_bonus, skull_bonus, dialogue_response.text)
		Events.show_overlay.emit(slot_machine)
		await slot_machine.finished
