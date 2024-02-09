extends Node

var reel_configs = {}

func get_reel_config(char_name:String) -> ReelConfig:
	var saved:ReelConfig = reel_configs.get(char_name, null)
	if saved == null:
		saved = ReelConfig.new()
		reel_configs[char_name] = saved
	return saved.duplicate()
