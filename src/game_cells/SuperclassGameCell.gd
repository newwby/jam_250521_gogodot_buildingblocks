
# a superclass for handling common methods of the block and tile classes

class_name GameCell
extends Node2D

const TILE_ALPHA_HIGHLIGHT_ON = 0.5
const TILE_ALPHA_HIGHLIGHT_OFF = 0.0
const BLOCK_ALPHA_HIGHLIGHT_ON = 0.75
const BLOCK_ALPHA_HIGHLIGHT_OFF = 1.0

var _cell_highlighted = false
var sprites = []


# method to add a cell to the highlighted group
func technical_cell_highlight(add_highlight: bool):
	if add_highlight:
		if not self.is_in_group(global_var.string_highlight_group):
			self.add_to_group(global_var.string_highlight_group)
		_cell_highlighted = true
	else:
		if self.is_in_group(global_var.string_highlight_group):
			self.remove_from_group(global_var.string_highlight_group)
		_cell_highlighted = false


# method to change the alpha value of the cell
# this is to show subtle confirmation of highlight
func alpha_visual_highlight(apply_visual: bool, is_tile: bool = false):
	# determine the alpha modifier to apply by the given arguments
	var alpha_strength
	if apply_visual and is_tile:
		alpha_strength = TILE_ALPHA_HIGHLIGHT_ON
	elif apply_visual and not is_tile:
		alpha_strength = BLOCK_ALPHA_HIGHLIGHT_ON
	elif not apply_visual and is_tile:
		alpha_strength = TILE_ALPHA_HIGHLIGHT_OFF
	elif not apply_visual and not is_tile:
		alpha_strength = BLOCK_ALPHA_HIGHLIGHT_OFF
	
	# apply the determined modifier to the alpha channel
	for i in sprites:
		if i is ColorRect:
			i.color.a = alpha_strength
		elif i is Sprite:
			i.modulate.a = alpha_strength


# method to apply a more striking visual highlight
# utilised for debugging purposes
func debug_visual_highlight(apply_visual: bool):
	# a more distinct visual effect for debug tiles
	if apply_visual:
		for i in sprites:
				i.color.b = 1.0
	else:
		for i in sprites:
				i.color.b = 0.0


func cell_highlight(add_or_remove: bool, can_apply_visual = true, ignore_highlight_permissions = false, is_tile = false):
		# are we allowed to visually highlight blocks right now
		# or are we ignoring permission checking
		if global_var.can_highlight_blocks\
		or ignore_highlight_permissions\
		or global_var.BLOCK_PLACEMENT_ALL_HIGHLIGHT_OVERRIDE:
			# apply the technical highlight always
			technical_cell_highlight(add_or_remove)
			# are we applying the standard highlight or debug highlight?
			# must have set to not apply normal visual or it overrides
			if global_var.enable_debug_tile_highlight and not can_apply_visual:
				debug_visual_highlight(add_or_remove)
			else:
				alpha_visual_highlight(add_or_remove, is_tile)



## this was the original cell highlight method
## now superseded by the above but kept for reference
#func defunct_cell_highlight(apply_highlight, apply_visual = true, ignore_highlight_permissions = false):
#	# if adding/applying a highlight
#	if apply_highlight:
#		# are we allowed to highlight blocks right now
#		# or are we ignoring permission checking
#		if global_var.can_highlight_blocks and not _cell_highlighted \
#		or ignore_highlight_permissions and not _cell_highlighted:
#			# are we applying a visual effect or animation to the highlighted cell?
#			# or are we applying a visual effect for debugging purposes?
#			if apply_visual\
#			or global_var.enable_debug_tile_highlight and not apply_visual:
#				for i in sprites:
#					i.color.a = 0.75
#					# a more distinct visual effect for debug tiles
#					if global_var.enable_debug_tile_highlight and not apply_visual:
#						i.color.b = 1
#			if not self.is_in_group(global_var.string_highlight_group):
#				self.add_to_group(global_var.string_highlight_group)
#		_cell_highlighted = true
#
#	# if removing a highlight
#	else:
#		if global_var.can_highlight_blocks and _cell_highlighted \
#		or ignore_highlight_permissions and _cell_highlighted:
#			if apply_visual\
#			or global_var.enable_debug_tile_highlight and not apply_visual:
#				for i in sprites:
#					i.color.a = 1.0
#					if global_var.enable_debug_tile_highlight and not apply_visual:
#						i.color.b = 0
#		if self.is_in_group(global_var.string_highlight_group):
#			self.remove_from_group(global_var.string_highlight_group)
#		_cell_highlighted = false
