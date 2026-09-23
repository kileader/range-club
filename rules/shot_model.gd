class_name ShotModel
extends RefCounted

enum Phase { IDLE, DRAW, READY }

const DRAW_READY_SECONDS: float = 0.52
const HOLD_STEER_SPEED: float = 340.0

var phase: Phase = Phase.IDLE
var aim_point: Vector2 = Vector2.ZERO
var impact_point: Vector2 = Vector2.ZERO
var elapsed: float = 0.0
var draw_level: float = 0.0
var steering_scale: float = 1.0
var lock_radius: float = 0.0
var target_locked: bool = false


func configure(steering_multiplier: float, focus_radius: float) -> void:
	steering_scale = maxf(steering_multiplier, 0.2)
	lock_radius = maxf(focus_radius, 0.0)


func start_hold(initial_aim: Vector2) -> void:
	phase = Phase.DRAW
	aim_point = initial_aim
	impact_point = initial_aim
	elapsed = 0.0
	draw_level = 0.0


func cancel() -> void:
	phase = Phase.IDLE
	elapsed = 0.0
	draw_level = 0.0
	target_locked = false


func tick(delta: float, mouse_aim: Vector2, target_centers: Array[Vector2]) -> void:
	if phase == Phase.IDLE:
		return
	elapsed += delta
	aim_point = aim_point.move_toward(mouse_aim, HOLD_STEER_SPEED * steering_scale * delta)
	draw_level = minf(elapsed / DRAW_READY_SECONDS, 1.0)
	if elapsed >= DRAW_READY_SECONDS:
		phase = Phase.READY
	target_locked = false
	if lock_radius > 0.0:
		for center: Vector2 in target_centers:
			if aim_point.distance_to(center) <= lock_radius and mouse_aim.distance_to(center) <= lock_radius:
				aim_point = center
				target_locked = true
				break
	impact_point = aim_point
