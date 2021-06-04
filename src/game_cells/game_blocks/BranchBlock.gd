
class_name BranchBlock
extends GameBlock

var branch_sprite = preload("res://art/block_branch.png")

func sprite_setup():
	use_debug_sprite = false
	block_sprite.texture = branch_sprite
	test_block_sprite.visible = false
	var measure_sprite_size = (block_sprite.get_rect().size)
	var scale_adjustment = measure_sprite_size/block_size
	block_sprite.scale /= scale_adjustment

const BASE_SPAWN_MTTH = 20

var leaf_spawn_mtth = BASE_SPAWN_MTTH
var cardinal_leaves_owned = []


func _on_BlockUpdate():
	if global_var.enable_shrub_entropy_logging: print("current leaf mtth is ", leaf_spawn_mtth)
	var generate_entropy = global_var.return_new_random(1,10)
	if global_var.enable_shrub_entropy_logging: print("new leaf entropy is -", generate_entropy)
	leaf_spawn_mtth -= generate_entropy
	if leaf_spawn_mtth <= 0:
		if global_var.enable_shrub_entropy_logging: print("spawned!")
		leaf_spawn_mtth = BASE_SPAWN_MTTH
		spawn_leaf()


func spawn_leaf():
	var own_array_position = tile_parent.array_pos
	var generate_cardinal_direction = global_var.return_new_random(1,5)
	var new_spawn_position = Vector2.ZERO
	match generate_cardinal_direction:
		1:
			new_spawn_position = Vector2(own_array_position.x+1, own_array_position.y)
		2:
			new_spawn_position = Vector2(own_array_position.x-1, own_array_position.y)
		3:
			new_spawn_position = Vector2(own_array_position.x, own_array_position.y+1)
		4:
			new_spawn_position = Vector2(own_array_position.x, own_array_position.y-1)
		
	emit_signal("spawn_new_block", new_spawn_position, global_var.BlockType.LEAF_BLOCK)
	# TODO if spawning branch connect the death function to 
