
class_name GameBlock
extends GameCell

signal block_grabbed()
signal block_released()
signal highlight_new_block(identity)
signal delete_me()
signal spawn_new_block(array_position, block_type)

const CLICK_TIMER_WAIT = 0.25
const RETURN_TIMER_WAIT = 0.05
const ACTIVATION_COOLDOWN = 2.0
const BLOCK_PLACEMENT_TRANSITION_DURATION = 0.1
const BLOCK_PLACEMENT_TRANSITION_DELAY = 0.025
const BLOCK_RETURN_TRANSITION_DURATION = 0.2
const BLOCK_RETURN_TRANSITION_DELAY = 0.05
const MOUSE_HOLD_FOR_DRAG_TICKS = 25
const RADIAL_TICK_BUFFER = 5
const MAXIMUM_POWER_BAR_VALUE = 30
const WIGGLE_TWEEN_MAGNITUDE = 5
const WIGGLE_TWEEN_DURATION = 0.1

enum BlockGridShape {
	# 1x1 blocks
	SMALL,
	# 2x2 blocks
	MEDIUM,
	# 4x4 blocks
	LARGE
}

# blocks can be combined into larger blocks
var current_block_grid_shape = BlockGridShape.SMALL

var mouse_hold_tick_count = 0
var array_pos = Vector2(150,150)
var block_size = Vector2(100,100)
var grabbed_position = Vector2(0,0)

var is_grabbable = true
var is_interactable = true
var is_updating = true
var is_clickable = true

var _is_grabbed = false setget _set_is_grabbed
var _block_after_image = false setget _set_block_after_image
var _block_clicked = false setget _set_block_clicked
var is_clicked_recently = false
var is_ability_on_cooldown = false
var _block_highlighted = false

var tile_parent

var use_debug_sprite = false
var show_debug_array_label = false

onready var test_block_sprite = $NodeHolder/SpriteHolder/DebugSprite
onready var block_sprite = $NodeHolder/SpriteHolder/Sprite
onready var sprite_holder = $NodeHolder/SpriteHolder

onready var block_area = $NodeHolder/BlockArea
onready var block_collision = $NodeHolder/BlockArea/CollisionArea
onready var power_bar_prog = $NodeHolder/PowerProgressBar
onready var radial_prog = $NodeHolder/MouseHoldProgRadial
onready var ClickTimer = $NodeHolder/MouseHoldTimer
onready var ReturnBlockTimer = $NodeHolder/ReturnTimer
onready var BlockTransitionTween = $NodeHolder/ReturnTween
onready var ActivationTimer = $NodeHolder/ActivationCooldownTimer
onready var WiggleTween = $NodeHolder/WiggleTween

onready var EffectHolder = $NodeHolder/EffectGraphicHolder
onready var CooldownNotification = $NodeHolder/EffectGraphicHolder/OnCooldown

onready var debug_label_array_pos = $NodeHolder/DebugHolder/DebugLabel_ArrayPos

###############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	signal_setup()
	sprite_setup()
	timer_setup()
	block_setup()
	progress_counter_setups()
	graphical_effect_setup()


func _process(_delta):
	update_position_if_grabbed()
	block_pickup_validation()
	grab_release_validation()


###############################################################################


# on block click
func _set_block_clicked(value: bool) -> void:
	# defunct timer code removed
	_block_clicked = value

# defunct/moved features to functions
func _set_is_grabbed(value: bool) -> void:
	_is_grabbed = value

func _set_block_after_image(value: bool) -> void:
	_block_after_image = value


###############################################################################


# if double clicked within click timer wait time, activate block
func _on_BlockArea_input_event(_viewport, event, _shape_idx):
	if is_interactable:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				if event.pressed:
					is_clicked_recently = true
					_block_clicked = true
					if ClickTimer.is_stopped():
						ClickTimer.start()
					else:
						#ClickTimer.stop()
						_on_BlockActivation()
				else:
					is_clicked_recently = false
					block_no_longer_clicked()


###############################################################################


# on expiry of timer for checking double clicking
func _on_MouseHoldTimer_timeout():
	is_clicked_recently = false


# timer exists to catch exceptions with return block to origin logic
func _on_ReturnTimer_timeout():
	_block_clicked = false
	mouse_hold_tick_count_update(false)
	emit_signal("block_released")


# when tween finishes and block is at rest we remove the afterimage effect
func _on_ReturnTween_tween_completed(_object, _key):
	apply_after_image(false)


func _on_ActivationCooldownTimer_timeout():
	set_activation_cooldown(false)


# if mouse enters block apply a slight translucency to the block
func _on_BlockArea_mouse_entered():
	if not _is_grabbed:
		cell_highlight(true, true)
		emit_signal("highlight_new_block", self)


# if mouse leaves block unset highlight var and translucency
func _on_BlockArea_mouse_exited():
	if not _is_grabbed:
		cell_highlight(false, true)
	mouse_hold_tick_count_update(false)
	if _block_clicked:
		_block_clicked = false


func _on_Block_highlight_new_block(identity):
	if identity != self:
		_on_BlockArea_mouse_exited()

# on signal for grabbing a block
func _on_Block_block_grabbed():
	global_var.grabbed_block = self
	grabbed_position = position 
	apply_after_image(true)
	_is_grabbed = true


# on signal for block release
func _on_Block_block_released():
	# player is no longer holding a block
	global_var.grabbed_block = null
	
	var found_new_parent = false
	# check if player is highlighting a different tile to the origin tile
	for i in get_tree().get_nodes_in_group(global_var.string_highlight_group):
		if i is GameTile:
			# only interested in highlighted blocks
			# TODO check the logic again here, this check may be unnecessary
			if i._cell_highlighted:
				# cannot already be the tile parent
				# cannot already have a block child (be occupied)
				if i != tile_parent and i.block_child == null:
					# checks are finished
					# if highlighting a free, different tile
					# different tile is now the parent tile
					set_new_tile_parent(i)
					found_new_parent = true
					break
	
	# if this isn't a drag&drop situation, return block to whence it came
	if not found_new_parent:
		return_block_to_origin()

	_is_grabbed = false

###############################################################################


# itnroducing a node handler instance broke all the signals
# now have to instantiate signals by code
func signal_setup():
	var _discard_return_value
	block_area.connect("input_event", self, "_on_BlockArea_input_event")
	block_area.connect("mouse_entered", self, "_on_BlockArea_mouse_entered")
	block_area.connect("mouse_exited", self, "_on_BlockArea_mouse_exited")
	ClickTimer.connect("timeout", self, "_on_MouseHoldTimer_timeout")
	ReturnBlockTimer.connect("timeout", self, "_on_ReturnTimer_timeout")
	BlockTransitionTween.connect("tween_completed", self, "_on_ReturnTween_tween_completed")
	ActivationTimer.connect("timeout", self, "_on_ActivationCooldownTimer_timeout")
	_discard_return_value = self.connect("highlight_new_block", self, "_on_Block_highlight_new_block")
	_discard_return_value = self.connect("block_grabbed", self, "_on_Block_block_grabbed")
	_discard_return_value = self.connect("block_released", self, "_on_Block_block_released")


# all basic blocks follow the same setup
func block_setup():
	var block_center = block_size/2
	
	# set test block size
	test_block_sprite.rect_size = block_size
	
	block_collision.position = block_center
	block_collision.shape.set("extents", block_center)
	
	if show_debug_array_label:
		debug_label_update(true)
		
	debug_label_array_pos.visible = show_debug_array_label
	
	block_sprite.visible = !use_debug_sprite
	test_block_sprite = use_debug_sprite

	for i in sprites:
		i.visible = use_debug_sprite


func debug_label_update(initial_setup: bool = false):
		# check if debug_label_array_pos has yet to be readied
		if debug_label_array_pos != null:
		# set and center debug label
			debug_label_array_pos.text = str(array_pos)
			if initial_setup:
				debug_label_array_pos.rect_scale *= (block_size/100)
				debug_label_array_pos.rect_position = block_size/2
				debug_label_array_pos.rect_position.x -= debug_label_array_pos.rect_position.x/2
				debug_label_array_pos.rect_position.y -= debug_label_array_pos.rect_position.y/8

# list of all nodes that make up the graphical representation of the block
func sprite_setup():
	sprites = [
		test_block_sprite,
		block_sprite,
	]
	test_block_sprite.color = Color(1,0,0,1)


# sets up default parameters of miscellaneous graphical effects
func graphical_effect_setup():
	#EffectHolder.position = position
	var sprite_scaling = block_size/4
	var offset_multiplier = sprite_scaling*3
	var sprite_size = (CooldownNotification.get_rect().size)
	var notification_scale = sprite_scaling/sprite_size
	
	CooldownNotification.position = Vector2.ZERO
	CooldownNotification.offset = offset_multiplier
	CooldownNotification.scale = notification_scale
	CooldownNotification.visible = false


# setting timers to the values for their respective wait times
# these are stored by logic in case we need to reset them later
func timer_setup():
	ReturnBlockTimer.wait_time = RETURN_TIMER_WAIT
	ClickTimer.wait_time = CLICK_TIMER_WAIT


# center and set max value of the radial progress bar whilst holding mouse
func progress_counter_setups():
	var half_block_offset = block_size/2
	radial_prog.rect_size = half_block_offset
	#radial_prog.rect_position = half_block_offset/4
	radial_prog.rect_position = half_block_offset/2.5
	
	radial_prog.max_value = MOUSE_HOLD_FOR_DRAG_TICKS-RADIAL_TICK_BUFFER
	radial_prog.visible = false
	
	power_bar_prog.visible = false
	power_bar_prog.max_value = MAXIMUM_POWER_BAR_VALUE
	# TODO could fix this with a center container probably
	power_bar_prog.rect_position.x = (-half_block_offset.x)/(block_size.x/4)
#	if use_debug_sprite:
#	else:
#		power_bar_prog.rect_position = (half_block_offset)
#		power_bar_prog.rect_position.x -= (half_block_offset.x/2)


# give block a new tile parent
func set_new_tile_parent(given_tile: GameTile):
	if tile_parent != null:
		tile_parent.block_child = null
		self.disconnect("block_grabbed",tile_parent,"_on_Tile_block_grabbed")
	tile_parent = given_tile
	tile_parent.block_child = self
	var _discard = self.connect("block_grabbed",tile_parent,"_on_Tile_block_grabbed")
	update_position_on_move()


# this function is called AFTER setting a block to be the child of a new tile
func update_position_on_move():
	# must have a valid tile parent to run this function
	if check_if_tile_parent_is_present():
		
		array_pos = tile_parent.array_pos
		
		var position_offset = tile_parent.position + tile_parent.tile_size/16
		
		# if using debug label, reset the value
		if show_debug_array_label:
			
			debug_label_update(false)
		
		# if initialising, just place
		if not _is_grabbed:
			position = position_offset
		# if drag+drop, smooth the movement
		else:
			place_block_at_tile_offset(position_offset)

# make block follow the mouse cursor
func update_position_if_grabbed():
	if _is_grabbed:
		position = return_adjusted_mouse_position()


	# must have a valid tile parent to return true
func check_if_tile_parent_is_present():
	return tile_parent != null and tile_parent is GameTile


# if held on block for a duration the block is picked up
func block_pickup_validation():
	if Input.is_mouse_button_pressed(BUTTON_LEFT) and _block_clicked \
	and global_var.grabbed_block == null and is_grabbable:
		mouse_hold_tick_count_update(true)
		if global_var._enable_all_debug_mode: print("holding, @ ", mouse_hold_tick_count)
	if mouse_hold_tick_count >= MOUSE_HOLD_FOR_DRAG_TICKS:
		_block_clicked = false
		mouse_hold_tick_count_update(false)
		emit_signal("block_grabbed")


# sometimes the block fails to tween back/sticks on the cursor
# this func exists to check if somehow the mouse button not being held
# hasn't been caught and to execute return logic
# tbf it could even replace return logic as it is more reliable
func grab_release_validation():
	if _is_grabbed:
		if Input.is_mouse_button_pressed(BUTTON_LEFT) and not ReturnBlockTimer.is_stopped():
			ReturnBlockTimer.stop()
			ReturnBlockTimer.wait_time = RETURN_TIMER_WAIT
		if not Input.is_mouse_button_pressed(BUTTON_LEFT) and ReturnBlockTimer.is_stopped():
			ReturnBlockTimer.start()


# method for interrupting hold counts
func block_no_longer_clicked():
	_block_clicked = false
	mouse_hold_tick_count_update(false)
	# if block_no longer clicked we release it so it can return to origin
	# this is now defunct, using the timer method (onReturnTimer_timeout) instead
	#if _is_grabbed:
		#emit_signal("block_released")

# logic to update mouse_hold_tick_count whilst also interfacing with progress radial
func mouse_hold_tick_count_update(is_not_reset):
	if is_clickable and is_interactable:
		# if not reset, increment by one
		if is_not_reset and not _is_grabbed:
			mouse_hold_tick_count += 1
		else:
			mouse_hold_tick_count = 0
		radial_prog.value = mouse_hold_tick_count-RADIAL_TICK_BUFFER if mouse_hold_tick_count-RADIAL_TICK_BUFFER >= 0 else 0
		if radial_prog.value >= MOUSE_HOLD_FOR_DRAG_TICKS/8.0:
			radial_prog.visible = true
		else:
			radial_prog.visible = false


# calculate the center of the block position relative to cursor
func return_adjusted_mouse_position():
	return Vector2(
			get_global_mouse_position().x-(block_size.x/2),\
			get_global_mouse_position().y-(block_size.y/2)\
			)


# graphical function for utilising tween for movement smoothing
func place_block_at_tile_offset(tile_offset):
	# set up and process a tween to return the block to its origin
	BlockTransitionTween.interpolate_property(self, "position", \
	return_adjusted_mouse_position(), tile_offset,
	BLOCK_PLACEMENT_TRANSITION_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT,
	BLOCK_PLACEMENT_TRANSITION_DELAY)
	BlockTransitionTween.start()


# graphical function for tweening block back to where it started
func return_block_to_origin():
	# set up and process a tween to return the block to its origin
	BlockTransitionTween.interpolate_property(self, "position", \
	return_adjusted_mouse_position(), grabbed_position,
	BLOCK_RETURN_TRANSITION_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT,
	BLOCK_RETURN_TRANSITION_DELAY)
	BlockTransitionTween.start()



# graphical function
func apply_after_image(add_or_remove):
	# disable visibility of any active graphic effects (i.e. OnCooldown)
	EffectHolder.visible = !add_or_remove
	if add_or_remove:
		for i in sprites:
			i.color.a = 0.15
	else:
		for i in sprites:
			i.color.a = 1.0
	global_var.can_highlight_blocks = !add_or_remove
	_block_after_image = add_or_remove


func tween_wiggle(wiggle_right: bool):
	var rotation_magnitude = \
	WIGGLE_TWEEN_MAGNITUDE if wiggle_right \
	else -WIGGLE_TWEEN_MAGNITUDE
	
	var base_rotation = sprite_holder.rotation_degrees
	var new_rotation = base_rotation+rotation_magnitude
	perform_wiggle(sprite_holder, base_rotation, new_rotation)
	yield(WiggleTween, "tween_completed")
	perform_wiggle(sprite_holder, new_rotation, base_rotation)


func perform_wiggle(target, rotate_start, rotate_end):
	
	WiggleTween.interpolate_property(target, "rotation_degrees", \
	rotate_start, rotate_end, \
	WIGGLE_TWEEN_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	WiggleTween.start()

# function to run on double click
func _on_BlockActivation():
	if not is_ability_on_cooldown and global_var.grabbed_block == null:
		tween_wiggle(true)
		
		# test activation code
		#var switcheroo = test_block_sprite.color.r
		#test_block_sprite.color.r = test_block_sprite.color.b
		#test_block_sprite.color.b = switcheroo
		
		# start cooldown so can't doubleclick repeatedly
		set_activation_cooldown(true)


func _on_BlockUpdate():
	if is_updating:
		pass
		#self.rotation_degrees += 15


func _on_BlockDeath():
	emit_signal("delete_me")


func set_activation_cooldown(cooldown_starts):
		is_ability_on_cooldown = cooldown_starts
		CooldownNotification.visible = cooldown_starts
		if cooldown_starts:
			ActivationTimer.start()

###############################################################################
