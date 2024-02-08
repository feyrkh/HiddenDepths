extends CanvasLayer

@export var delete_on_finish = false

@onready var background: TextureRect = $Background
@onready var balloon: Control = $Balloon
@onready var dialogue_label: DialogueLabel = $Balloon/Margin/DialogueLabel
@onready var responses_menu: VBoxContainer = $Responses
@onready var response_template: RichTextLabel = $ResponseTemplate
@onready var slots = find_child("Slots")
## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

var portraits: Dictionary = {}
var speaking_characters:Array[String] = []

## The current line
var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		if not next_dialogue_line:
			await clear_all()
			if delete_on_finish:
				queue_free()
			return
		var char_name_lower = next_dialogue_line.character.to_lower()
		is_waiting_for_input = false

		# Remove any previous responses
		for child in responses_menu.get_children():
			responses_menu.remove_child(child)
			child.queue_free()

		dialogue_line = next_dialogue_line

		var mood = dialogue_line.get_tag_value("mood")
		
		# Dim all characters except the one talking
		for portrait in portraits:
			if portrait.to_lower() == char_name_lower:
				portraits[portrait].modulate = Color.WHITE
				if mood:
					portraits[portrait].set_mood(mood)
			else:
				portraits[portrait].modulate = Color("757575")
		await mark_character_as_speaking(char_name_lower)

		dialogue_label.modulate.a = 0
		dialogue_label.dialogue_line = dialogue_line

		# Show any responses we have
		responses_menu.modulate.a = 0
		if dialogue_line.responses.size() > 0:
			for response in dialogue_line.responses:
				# Duplicate the template so we can grab the fonts, sizing, etc
				var item: RichTextLabel = response_template.duplicate(0)
				item.name = "Response%d" % responses_menu.get_child_count()
				if not response.is_allowed:
					item.name = String(item.name) + "Disallowed"
					item.modulate.a = 0.4
				item.text = response.text
				item.show()
				responses_menu.add_child(item)

		dialogue_label.modulate.a = 1
		dialogue_label.type_out()
		await dialogue_label.finished_typing

		# Wait for input
		if dialogue_line.responses.size() > 0:
			responses_menu.modulate.a = 1
			configure_menu()
		elif dialogue_line.time != "":
			var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next(dialogue_line.next_id)
		else:
			is_waiting_for_input = true
			balloon.focus_mode = Control.FOCUS_ALL
			balloon.grab_focus()
	get:
		return dialogue_line


func _ready() -> void:
	response_template.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

var MAX_AUTO_SLOTS := 2
func mark_character_as_speaking(char_name_lower:String, portrait_slot=null):	
	var char_is_speaking := false
	var auto_slots_taken = true
	for i in range(MAX_AUTO_SLOTS):
		if slots.get_child(i).get_child_count() == 0:
			auto_slots_taken = false
			break
	for child in slots.get_children():
		if child.get_child_count() == 0: continue
		var cur_portrait = child.get_child(-1)
		if cur_portrait and cur_portrait.character_name.to_lower() == char_name_lower:
			char_is_speaking = true
			break
	if char_is_speaking:
		# No need to change any portraits, just move them to the front of the line
		speaking_characters.erase(char_name_lower)
	elif portrait_slot == null and auto_slots_taken:
		var removed_character = speaking_characters.pop_back()
		portrait_slot = find_slot_with_portrait(removed_character)
		await add_portrait(char_name_lower, portrait_slot)
	elif portrait_slot != null:
		var slot = slots.get_child(portrait_slot)
		if slot != null and slot.get_child_count() > 0:
			var portrait_to_remove = slot.get_child(-1)
			var char_to_remove = portrait_to_remove.character_name.to_lower()
			speaking_characters.erase(char_to_remove)
			await remove_portrait(char_to_remove)
		await add_portrait(char_name_lower, portrait_slot)
	else:
		portrait_slot = find_empty_slot()
		await add_portrait(char_name_lower, portrait_slot)
	speaking_characters.push_front(char_name_lower)
		
func find_slot_with_portrait(char_name_lower) -> int:
	for slot_id in slots.get_child_count():
		var cur_slot = slots.get_child(slot_id)
		if cur_slot.get_child_count() > 0 and cur_slot.get_child(0).character_name.to_lower() == char_name_lower:
			return slot_id
	return -1

func find_empty_slot() -> int:
	for slot_id in slots.get_child_count():
		var cur_slot = slots.get_child(slot_id)
		if cur_slot.get_child_count() == 0:
			return slot_id
	return -1
	

func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states = extra_game_states + [self]
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


### Mutations


func set_background(background_name: String) -> void:
	background.texture = load("res://dialog/scene/background/%s.jpg" % background_name)

func clear_portraits():
	print("Clearing all portraits")
	var any_removed := false
	speaking_characters = []
	for child in slots.get_children():
		if child.get_child_count() == 0: continue
		var cur_portrait = child.get_child(-1)
		if cur_portrait:
			any_removed = true
			remove_portrait(cur_portrait.character_name)
	if any_removed:
		await get_tree().create_timer(0.5).timeout
		
func clear_all():
	print("Clearing all")
	clear_portraits()
	var tween = create_tween()
	tween.tween_property(find_child("Balloon"), "modulate", Color.TRANSPARENT, 0.5)
	await tween.finished

func add_portrait(character: String, slot: int = 0):
	print("Adding portrait: ", character)
	if character == "":
		return
	var slot_marker: Marker2D = get_node("Slots/Slot%d" % slot)
	if !slot_marker:
		push_error("Invalid slot marker ", slot)
		return

	if slot_marker.get_child_count() > 0: 
		await remove_portrait(slot_marker.get_child(0).character_name)

	# Instantiate the character
	var packed_portrait = load("res://dialog/scene/portrait/%s.tscn" % character)
	if packed_portrait:
		var portrait = packed_portrait.instantiate()
		slot_marker.add_child(portrait)
		portrait.set_character_name(character)
		var on_right_side_of_screen = slot_marker.global_position.x > get_viewport().content_scale_size.x / 2
		if on_right_side_of_screen:
			portrait.scale.x = -1

		portraits[character] = portrait

		# Character appears
		var tween: Tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ease(Tween.EASE_IN_OUT)
		tween.set_parallel(true)
		tween.tween_property(portrait, "position:x", 0.0, 0.5).from(100 if on_right_side_of_screen else -100)
		tween.tween_property(portrait, "modulate", Color.WHITE, 0.5).from(Color.TRANSPARENT)
		return get_tree().create_timer(0.5).timeout


func call_portrait(character: String, method: String) -> void:
	portraits[character].call(method)


func remove_portrait(character: String):
	print("Removing portrait: ", character)
	var portrait = portraits.get(character, null)
	if portrait == null:
		return

	var on_right_side_of_screen = portrait.global_position.x > get_viewport().content_scale_size.x / 2
	# Character leaves
	var tween: Tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(portrait, "position:x", 100 if on_right_side_of_screen else -100, 0.5)
	tween.tween_property(portrait, "modulate", Color.TRANSPARENT, 0.5).from(Color.WHITE)
	#tween.tween_property(portrait, "position:y", 1000.0, 0.5).from(0.0)
	await get_tree().create_timer(0.5).timeout
	portraits.erase(character)
	if portrait and is_instance_valid(portrait):
		if portrait.get_parent() != null:
			portrait.get_parent().remove_child(portrait)
		portrait.queue_free()

### Helpers


# Set up keyboard movement and signals for the response menu
func configure_menu() -> void:
	balloon.focus_mode = Control.FOCUS_NONE

	var items = get_responses()
	for i in items.size():
		var item: Control = items[i]

		item.mouse_filter = Control.MOUSE_FILTER_STOP
		item.focus_mode = Control.FOCUS_ALL

		item.focus_neighbor_left = item.get_path()
		item.focus_neighbor_right = item.get_path()

		if i == 0:
			item.focus_neighbor_top = item.get_path()
			item.focus_previous = item.get_path()
		else:
			item.focus_neighbor_top = items[i - 1].get_path()
			item.focus_previous = items[i - 1].get_path()

		if i == items.size() - 1:
			item.focus_neighbor_bottom = item.get_path()
			item.focus_next = item.get_path()
		else:
			item.focus_neighbor_bottom = items[i + 1].get_path()
			item.focus_next = items[i + 1].get_path()

		item.mouse_entered.connect(_on_response_mouse_entered.bind(item))
		item.gui_input.connect(_on_response_gui_input.bind(item))

	items[0].grab_focus()


# Get a list of enabled items
func get_responses() -> Array:
	var items: Array = []
	for child in responses_menu.get_children():
		if "Disallowed" in child.name: continue
		items.append(child)

	return items


### Signals


func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	dialogue_label.modulate.a = 0.0


func _on_response_mouse_entered(item: Control) -> void:
	if "Disallowed" in item.name: return

	item.grab_focus()


func _on_response_gui_input(event: InputEvent, item: Control) -> void:
	if "Disallowed" in item.name: return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		responses_menu.modulate.a = 0.0
		next(dialogue_line.responses[item.get_index()].next_id)
	elif event.is_action_pressed("ui_accept") and item in get_responses():
		responses_menu.modulate.a = 0.0
		next(dialogue_line.responses[item.get_index()].next_id)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialogue_line.next_id)
	elif event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)
