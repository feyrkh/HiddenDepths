extends CharacterBody2D

signal lever_pulled()

const RETURN_RATE := 200
const BOTTOM_SCALE := 0.2

@onready var slot_handle:Sprite2D = find_child("SlotHandle")

var can_grab = false
var grabbed_offset = Vector2()

var rod_offset_0:Vector2
var rod_offset_1:Vector2
var top_y:float
var bottom_y:float
var start_x:float
@export var rod:Polygon2D
var can_move := true
var returning := 0
var cur_scale

func _ready():
	rod_offset_0 = rod.polygon[0] - position
	rod_offset_1 = rod.polygon[1] - position
	top_y = position.y
	bottom_y = position.y + rod.polygon[3].y - $CollisionShape2D.position.y
	start_x = position.x
	position.y = bottom_y
	reset_lever()

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		can_grab = event.pressed and can_move
		if !can_grab:
			returning = RETURN_RATE
		grabbed_offset = position - get_global_mouse_position()

func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_grab and can_move:
		position.y = clampf(get_global_mouse_position().y + grabbed_offset.y, top_y, bottom_y)
		if abs(position.y - bottom_y) < 1:
			lever_pulled.emit()
			reset_lever()
	if returning > 0:
		position.y = clampf(position.y - returning * delta, top_y, bottom_y)
		if abs(position.y - top_y) < 1:
			can_move = true
	var position_progress = (position.y - top_y)/(bottom_y - top_y)
	cur_scale = position_progress * BOTTOM_SCALE
	slot_handle.scale = Vector2(1+cur_scale, 1+cur_scale)
	var offset_vec := Vector2((rod_offset_1.x - rod_offset_0.x) * cur_scale, 0)
	rod.polygon[0] = position + rod_offset_0 - offset_vec
	rod.polygon[1] = position + rod_offset_1 + offset_vec
	position.x = start_x + (position_progress) * 30

func reset_lever():
	can_move = false
	can_grab = false
	returning = RETURN_RATE
