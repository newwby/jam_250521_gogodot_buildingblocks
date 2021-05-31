
class_name GameCell
extends Node2D

var _cell_highlighted = false
var sprites = []

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



func cell_highlight(apply_highlight, apply_visual = true, ignore_highlight_permissions = false):
	if apply_highlight:
		if global_var.can_highlight_blocks and not _cell_highlighted \
		or ignore_highlight_permissions and not _cell_highlighted:
			if apply_visual\
			or global_var.enable_debug_tile_highlight and not apply_visual:
				for i in sprites:
					i.color.a = 0.75
					if global_var.enable_debug_tile_highlight and not apply_visual:
						i.color.b = 1
			if not self.is_in_group(global_var.string_highlight_group):
				self.add_to_group(global_var.string_highlight_group)
		_cell_highlighted = true
	else:
		if global_var.can_highlight_blocks and _cell_highlighted \
		or ignore_highlight_permissions and _cell_highlighted:
			if apply_visual\
			or global_var.enable_debug_tile_highlight and not apply_visual:
				for i in sprites:
					i.color.a = 1.0
					if global_var.enable_debug_tile_highlight and not apply_visual:
						i.color.b = 0
		if self.is_in_group(global_var.string_highlight_group):
			self.remove_from_group(global_var.string_highlight_group)
		_cell_highlighted = false
