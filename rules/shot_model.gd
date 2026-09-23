class_name ShotModel
extends RefCounted

enum Phase { IDLE, DRAW, READY }

const DRAW_READY_SECONDS: float = 0.52
const HOLD_STEER_SPEED: float = 340.0
const PRECISION_PEAK_SECONDS: float = 1.5
const START_SPREAD_RADIUS: float = 72.0
const MIN_SPREAD_RADIUS: float = 16.0
const LATE_BLOOM_PER_SECOND: float = 20.0
const LATE_PULSE_RADIUS: float = 12.0
const MAX_SPREAD_RADIUS: float = 90.0
const STABILIZING_SIGHT_HOLD_SECONDS: float = 0.7

var phase: Phase = Phase.IDLE
var aim_point: Vector2 = Vector2.ZERO
var impact_point: Vector2 = Vector2.ZERO
var elapsed: float = 0.0
var steering_scale: float = 1.0
var precision_peak_seconds: float = PRECISION_PEAK_SECONDS
var spread_scale: float = 1.0
var minimum_hold_seconds: float = 0.0
var spread_radius: float = START_SPREAD_RADIUS


func minimum_spread_radius() -> float:
	return MIN_SPREAD_RADIUS * spread_scale


func configure(steering_multiplier: float, spread_multiplier: float, peak_seconds: float = PRECISION_PEAK_SECONDS, hold_seconds: float = 0.0) -> void:
	steering_scale = maxf(steering_multiplier, 0.2)
	spread_scale = clampf(spread_multiplier, 0.1, 1.0)
	precision_peak_seconds = maxf(peak_seconds, DRAW_READY_SECONDS)
	minimum_hold_seconds = maxf(hold_seconds, 0.0)


func start_hold(initial_aim: Vector2) -> void:
	phase = Phase.DRAW
	aim_point = initial_aim
	impact_point = initial_aim
	elapsed = 0.0
	spread_radius = START_SPREAD_RADIUS * spread_scale


func cancel() -> void:
	phase = Phase.IDLE
	elapsed = 0.0
	spread_radius = START_SPREAD_RADIUS * spread_scale


func tick(delta: float, mouse_aim: Vector2) -> void:
	if phase == Phase.IDLE:
		return
	elapsed += delta
	aim_point = aim_point.move_toward(mouse_aim, HOLD_STEER_SPEED * steering_scale * delta)
	if elapsed >= DRAW_READY_SECONDS:
		phase = Phase.READY
	spread_radius = spread_at(elapsed, precision_peak_seconds, minimum_hold_seconds) * spread_scale
	impact_point = aim_point


static func spread_at(hold_seconds: float, peak_seconds: float = PRECISION_PEAK_SECONDS, minimum_hold_seconds: float = 0.0) -> float:
	if hold_seconds <= peak_seconds:
		return lerpf(START_SPREAD_RADIUS, MIN_SPREAD_RADIUS, clampf(hold_seconds / peak_seconds, 0.0, 1.0))
	var late_seconds: float = maxf(hold_seconds - peak_seconds - minimum_hold_seconds, 0.0)
	var pulse: float = pow(sin(late_seconds * 4.0), 2.0) * LATE_PULSE_RADIUS
	return minf(MIN_SPREAD_RADIUS + late_seconds * LATE_BLOOM_PER_SECOND + pulse, MAX_SPREAD_RADIUS)


static func sample_impact(center: Vector2, radius: float, rng: RandomNumberGenerator) -> Vector2:
	var angle: float = rng.randf_range(0.0, TAU)
	var distance: float = sqrt(rng.randf()) * maxf(radius, 0.0)
	return center + Vector2.from_angle(angle) * distance
