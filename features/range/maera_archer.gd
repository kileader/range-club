class_name MaeraArcher
extends Node2D
## SpriteFrames and the bow socket are authored in the adjacent scene.

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var bow_socket: Marker2D = $BowSocket


func present_shot(shot: ShotModel, feedback_active: bool, focused: bool) -> void:
	if feedback_active:
		return
	if shot.phase == ShotModel.Phase.IDLE:
		sprite.play(&"idle")
	elif shot.phase == ShotModel.Phase.DRAW:
		sprite.animation = &"draw"
		sprite.stop()
		sprite.frame = mini(int(shot.elapsed / ShotModel.DRAW_READY_SECONDS * 3.0), 2)
	else:
		sprite.play(&"focus" if focused else &"hold")


func release() -> void:
	sprite.play(&"release")


func reset() -> void:
	sprite.play(&"idle")


func arrow_origin() -> Vector2:
	return bow_socket.global_position
