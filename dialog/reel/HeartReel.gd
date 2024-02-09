extends Node2D
class_name HeartReel

signal reel_score_available()

const TILE_COUNT := 10
const TILE_HEIGHT := 100
const TILE_WIDTH := 100
const MIN_SPEED := 350
const MAX_SPEED := 600
const MIN_SPIN_UP_TIME := 1.0
const MAX_SPIN_UP_TIME := 2.5
var tile_container

var heart_count = 0
var skull_count = 0

var move_speed := 0.0
var stopped := true
var reel_score

# Called when the node enters the scene tree for the first time.
func _ready():
	tile_container = find_child("Tiles")
	var top_y = -TILE_HEIGHT
	for tile in tile_container.get_children():
		tile.position.y = top_y
		top_y += TILE_HEIGHT
	start_moving()

func start_moving():
	var tween = create_tween()
	var eventual_speed = randf_range(MIN_SPEED, MAX_SPEED)
	tween.tween_property(self, "move_speed", eventual_speed, randf_range(MIN_SPIN_UP_TIME, MAX_SPIN_UP_TIME)).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "stopped", false, 0.0)

func setup(hearts_to_add:int, skulls_to_add:int):
	var choices = range(TILE_COUNT)
	choices.shuffle()
	while (hearts_to_add > 0 or skulls_to_add > 0) and choices.size() > 0:
		var cur_tile = find_child("Tiles").get_child(choices.pop_back())
		if hearts_to_add and skulls_to_add:
			if randf() < 0.6:
				change_tile_to_heart(cur_tile)
				hearts_to_add -= 1
			else:
				change_tile_to_skull(cur_tile)
				skulls_to_add -= 1
		elif hearts_to_add > 0:
			change_tile_to_heart(cur_tile)
			hearts_to_add -= 1
		elif skulls_to_add > 0:
			change_tile_to_skull(cur_tile)
			skulls_to_add -= 1
		else:
			break

func can_change_neutral_to_heart():
	return heart_count + skull_count < TILE_COUNT

func can_change_skull_to_neutral():
	return skull_count > 0

func change_neutral_to_heart():
	var tiles = tile_container.get_children().filter(func(tile): return tile.get_meta("tile_score") == 0)
	if tiles.size() > 0:
		var tile = tiles.pick_random()
		change_tile_to_heart(tile)

func change_skull_to_neutral():
	var tiles = find_child("Tiles").get_children().filter(func(tile): return tile.get_meta("tile_score") == -1)
	if tiles.size() > 0:
		var tile = tiles.pick_random()
		change_tile_to_neutral(tile)

func change_tile_to_heart(cur_tile:TextureRect):
	cur_tile.texture = load("res://dialog/reel/heart_icon.jpg")
	cur_tile.set_meta("tile_score", 1)
	heart_count += 1

func change_tile_to_skull(cur_tile:TextureRect):
	cur_tile.texture = load("res://dialog/reel/skull_icon.jpg")
	cur_tile.set_meta("tile_score", -1)
	skull_count += 1

func change_tile_to_neutral(cur_tile:TextureRect):
	cur_tile.texture = load("res://dialog/reel/neutral_icon.jpg")
	cur_tile.set_meta("tile_score", 0)

func stop_reel():
	if stopped: return
	move_speed = 0
	stopped = true
	var target_position = Vector2(0, find_child("TileViewArea").get_rect().size.y/2)
	var closest_child
	var closest_position := Vector2(0, 99999)
	var closest_distance := 99999.0
	for tile in tile_container.get_children():
		var cur_pos = tile.position + Vector2(0, TILE_HEIGHT/2)
		var cur_distance = abs(cur_pos.y - target_position.y)
		if cur_distance < closest_distance:
			closest_position = cur_pos
			closest_distance = cur_distance
			closest_child = tile
	var offset = target_position - closest_position
	var tween = create_tween()
	tween.set_parallel(true)
	for tile in tile_container.get_children():
		tween.tween_property(tile, "position", tile.position + offset, 0.6).set_ease(Tween.EASE_IN)
	await tween.finished
	reel_score = closest_child.get_meta("tile_score")
	reel_score_available.emit()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var cur_move = delta * move_speed
	for tile in tile_container.get_children():
		tile.position.y -= cur_move
		if tile.position.y < -TILE_HEIGHT*2:
			tile.position.y += TILE_HEIGHT * TILE_COUNT

