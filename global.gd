extends Node

# to implement block placement added override for previous logic
# due to gamejam deadline, TODO fix this properly
const BLOCK_PLACEMENT_ALL_HIGHLIGHT_OVERRIDE = true

var mouse_last_right_click_position = Vector2(0,0)
var mouse_last_left_click_position = Vector2(0,0)
var is_rmb_held = false
var is_lmb_held = false
var mouse_moving = false
var camera_moving = false

var grabbed_block = null
var can_highlight_blocks = true
var last_highlighted_tile

# defunct values kept for debug testing compatibility
var button_held_ticks = 0
var hidden_debug_messages = 0

enum BlockType {
	DEBUG_BASIC_BLOCK,
	BOUNDARY_BLOCK,
	SHRUB_BLOCK,
	BRANCH_BLOCK,
	LEAF_BLOCK,
}

##############################################################################

# global strings for references
var string_highlight_group = "highlighting"

# TODO, strings don't work for texture loads when passed as variables
# Fix this how? Raise godot issue?
#var string_texture_day_phase_day = "res://art/phase_day.png"
#var string_texture_day_phase_evening = "res://art/phase_evening.png"
#var string_texture_day_phase_morning = "res://art/phase_morning.png"
#var string_texture_day_phase_night = "res://art/phase_night.png"

##############################################################################

# debug testing values
# for console logging
var _enable_all_debug_mode = false setget _set_enable_all_debug_mode
var enable_world_spawn_log = false
var enable_debug_camera_motion_update = false
var enable_debug_camera_click_updates = false
var enable_debug_day_phase_checks = false
var enable_shrub_entropy_logging = false
var enable_shrub_spawning_logging = true
var enable_audio_debug_logging = false

# debug testing values
# for behaviours
var enable_debug_tile_highlight = false
var enable_debug_command_button = false
var enable_developer_speed_mode = false

# setter for _enable_all_debug_mode
# if '_enable_all_debug_mode' is set true
# all other debug values are set true
func _set_enable_all_debug_mode(value):
	var debug_switches = [
	
	# debug testing values
	enable_world_spawn_log,
	enable_debug_camera_motion_update,
	enable_debug_camera_click_updates,
	enable_debug_day_phase_checks,
	enable_shrub_entropy_logging,
	enable_shrub_spawning_logging,
	enable_audio_debug_logging,
	
	# debug testing values
	enable_debug_tile_highlight,
	enable_debug_command_button,
	enable_developer_speed_mode,
	]
	if value:
		for i in debug_switches:
			i = true


##############################################################################


func return_new_random(min_range, max_range):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return int(rng.randf_range((min_range), max_range))
