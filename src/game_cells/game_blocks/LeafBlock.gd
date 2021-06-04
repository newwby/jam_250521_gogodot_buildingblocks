
class_name LeafBlock
extends GameBlock
var leaf_sprite = preload("res://art/block_leaf.png")

signal mulch_score

func _ready():
	emit_signal("mulch_score")

func sprite_setup():
	use_debug_sprite = false
	block_sprite.texture = leaf_sprite
	test_block_sprite.visible = false
	var measure_sprite_size = (block_sprite.get_rect().size)
	var scale_adjustment = measure_sprite_size/block_size
	block_sprite.scale /= scale_adjustment
