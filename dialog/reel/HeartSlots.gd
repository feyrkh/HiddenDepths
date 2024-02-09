extends Node2D
class_name HeartSlots

signal finished(total_score:int)

const REEL_MARGIN := 20

var target:String
var heart_bonus:int
var skull_bonus:int

var reels:Array[HeartReel] = []
var cur_reel_to_stop:int = 0
var total_score := 0
var label:String = ""

func _ready():
	find_child("SlotLever").lever_pulled.connect(stop_reel)
	if get_tree().root == self.get_parent():
		await get_tree().process_frame
		setup("Emi", 3, 1)
	render()

func setup(_target:String, _heart_bonus:int, _skull_bonus:int, _label:String=""):
	target = _target
	heart_bonus = _heart_bonus
	skull_bonus = _skull_bonus
	label = _label

func render():
	find_child("Label").text = "[center]%s[/center]" % label
	var reel_count = 0
	total_score = 0
	var reel_config:ReelConfig = GameState.get_reel_config(target)
	var heart_change = 1 if heart_bonus > 0 else -1
	for i in range(abs(heart_bonus)):
		reel_config.reel_hearts[randi_range(0, reel_config.reel_hearts.size()-1)] += heart_change
	var skull_change = 1 if skull_bonus > 0 else -1
	for i in range(abs(skull_bonus)):
		reel_config.reel_skulls[randi_range(0, reel_config.reel_skulls.size()-1)] += skull_change
	
	var space_needed := REEL_MARGIN
	for i in reel_config.reel_hearts.size():
		var new_reel := preload("res://dialog/reel/HeartReel.tscn").instantiate()
		reels.append(new_reel)
		reel_count += 1
		add_child(new_reel)
		new_reel.setup(reel_config.reel_hearts[i], reel_config.reel_skulls[i])
		space_needed += HeartReel.TILE_WIDTH
	
	var reel_start := get_viewport_rect().size.x / 2 - space_needed / 2
	var reel_y := get_viewport_rect().size.y / 2 - HeartReel.TILE_HEIGHT * 1.5
	var selection_marker = find_child("SelectionMarker")
	var l = reel_start - 3 - REEL_MARGIN
	var t = reel_y + HeartReel.TILE_HEIGHT * 0.25
	var r = reel_start + 3 + reel_count * (HeartReel.TILE_WIDTH + REEL_MARGIN)
	var b = reel_y + HeartReel.TILE_HEIGHT * 1.25
	selection_marker.points = [
		Vector2(l, t), Vector2(r, t), Vector2(r, b), Vector2(l, b), Vector2(l, t)
	]
	for i in reels.size():
		reels[i].position.x = reel_start + i * (HeartReel.TILE_WIDTH + REEL_MARGIN)
		reels[i].position.y = reel_y

func stop_reel():
	if cur_reel_to_stop < reels.size() and !reels[cur_reel_to_stop].stopped:
		reels[cur_reel_to_stop].stop_reel()
		await reels[cur_reel_to_stop].reel_score_available
		total_score += reels[cur_reel_to_stop].reel_score
		cur_reel_to_stop += 1
		if cur_reel_to_stop >= reels.size():
			print("Closing reels")
			queue_free()
			finished.emit(total_score)
	
