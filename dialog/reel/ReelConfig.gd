extends Resource
class_name ReelConfig

var reel_hearts:Array[int] = [1, 1, 1]
var reel_skulls:Array[int] = [5, 5, 5]

func get_heart_total() -> int:
	return reel_hearts.reduce(func(a, b): return a + b, 0)

func get_skull_total() -> int:
	return reel_skulls.reduce(func(a, b): return a + b, 0)

func get_total_slots() -> int:
	return reel_hearts.size() * HeartReel.TILE_COUNT
