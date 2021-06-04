
class_name FadeTimer
extends Timer

signal refresh_visibility

var FadeDelay = 3.0
var FadeDuration = 2.0
var UndoFadeDuration = FadeDuration/4

onready var FadeTween = $FadeTimerTween

func _ready():
	wait_time = FadeDelay

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if get_parent_visibility():
		start_countdown_to_fade()


func get_parent_visibility():
	if get_parent().modulate.a == 0:
		return false
	else:
		return true


func start_countdown_to_fade():
	# ignore all if already fading
	# ignore all if already counting down to fade
	if not FadeTween.is_active() \
	or not is_stopped():
		start()


# fade parent
func _on_FadeTimer_timeout():
	# ignore all if fade tween is already running
	if not FadeTween.is_active():
		FadeTween.interpolate_property(get_parent(), "modulate:a", \
		get_parent().modulate.a, 0, FadeDuration, \
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		FadeTween.start()



# if signal is received the timer is reset and the parent is made visible
func _on_FadeTimer_refresh_visibility():
	if FadeTween.is_active():
		FadeTween.stop_all()
	FadeTween.interpolate_property(get_parent(), "modulate:a", \
	get_parent().modulate.a, 1, UndoFadeDuration, \
	Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	FadeTween.start()
