extends Node

var mouse_last_right_click_position = Vector2(0,0)
var mouse_last_left_click_position = Vector2(0,0)
var is_rmb_held = false
var is_lmb_held = false
var mouse_moving = false
var camera_moving = false

var grabbed_block = null
var can_highlight_blocks = true

# defunct values kept for debug testing compatibility
var button_held_ticks = 0
var hidden_debug_messages = 0

##############################################################################

# global strings for references
var string_highlight_group = "highlighting"

##############################################################################

# debug testing values
var _enable_all_debug_mode = false setget _set_enable_all_debug_mode
var enable_world_spawn_log = false
var enable_debug_camera_motion_update = false
var enable_debug_camera_click_updates = false
var enable_debug_tile_highlight = true
var enable_debug_command_button = true

# if '_enable_all_debug_mode' is set true, all debug values are set true
func _set_enable_all_debug_mode(value):
	var debug_switches = [
		enable_world_spawn_log,
		enable_debug_camera_motion_update,
		enable_debug_camera_click_updates,
		enable_debug_tile_highlight,
		enable_debug_command_button,
	]
	if value:
		for i in debug_switches:
			i = true


##############################################################################


func return_new_random(min_range, max_range):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return int(rng.randf_range((min_range), max_range))
