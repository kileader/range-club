class_name ShotModel
extends RefCounted

enum Phase { IDLE, HOLD_DRAW, HOLD_READY, TIMING_DRAW, TIMING_RELEASE }

const DRAW_READY_SECONDS: float = 0.52
const HOLD_STEER_SPEED: float = 340.0
const TIMING_DRAW_SECONDS: float = 0.95
const TIMING_SWEEP_SECONDS: float = 1.2
const IDEAL_DRAW: float = 0.72
const DRAW_VERTICAL_SCALE: float = 130.0
const TIMING_SWEEP_WIDTH: float = 65.0

var phase: Phase = Phase.IDLE
var aim_point: Vector2 = Vector2.ZERO
var impact_point: Vector2 = Vector2.ZERO
var elapsed: float = 0.0
var draw_level: float = 0.0
var locked_draw: float = 0.0
var sway_scale: float = 1.0
var steering_scale: float = 1.0


func configure(steering_multiplier: float, sway_multiplier: float) -> void:
	steering_scale = maxf(steering_multiplier, 0.2)
	sway_scale = maxf(sway_multiplier, 0.2)


func start_hold(initial_aim: Vector2) -> void:
	phase = Phase.HOLD_DRAW
	aim_point = initial_aim
	impact_point = initial_aim
	elapsed = 0.0
	draw_level = 0.0


func start_timing(initial_aim: Vector2) -> void:
	phase = Phase.TIMING_DRAW
	aim_point = initial_aim
	impact_point = initial_aim
	elapsed = 0.0
	draw_level = 0.0


func lock_draw(visible_level: float) -> void:
	if phase != Phase.TIMING_DRAW:
		return
	locked_draw = clampf(visible_level, 0.0, 1.0)
	phase = Phase.TIMING_RELEASE
	elapsed = 0.0
	impact_point = aim_point + Vector2(0.0, (IDEAL_DRAW - locked_draw) * DRAW_VERTICAL_SCALE)


func cancel() -> void:
	phase = Phase.IDLE
	elapsed = 0.0
	draw_level = 0.0


func tick(delta: float, mouse_aim: Vector2) -> void:
	match phase:
		Phase.HOLD_DRAW, Phase.HOLD_READY:
			elapsed += delta
			aim_point = aim_point.move_toward(mouse_aim, HOLD_STEER_SPEED * steering_scale * delta)
			draw_level = minf(elapsed / DRAW_READY_SECONDS, 1.0)
			if elapsed >= DRAW_READY_SECONDS:
				phase = Phase.HOLD_READY
				var ready_time: float = elapsed - DRAW_READY_SECONDS
				var settled: float = lerpf(85.0, 45.0, clampf(ready_time / 0.8, 0.0, 1.0))
				var fatigue: float = maxf(ready_time - 0.9, 0.0) * 18.0
				var amplitude: float = minf((settled + fatigue) * sway_scale, 110.0)
				impact_point = aim_point + Vector2(
					sin(ready_time * 5.5) * amplitude,
					sin(ready_time * 4.1 + 1.2) * amplitude * 0.72
				)
			else:
				impact_point = aim_point
		Phase.TIMING_DRAW:
			elapsed += delta
			# A repeated up/down sweep lets the player wait for a chosen draw.
			var cycle: float = fmod(elapsed / TIMING_DRAW_SECONDS, 2.0)
			draw_level = cycle if cycle <= 1.0 else 2.0 - cycle
		Phase.TIMING_RELEASE:
			elapsed += delta
			var horizontal: float = sin(elapsed * TAU / TIMING_SWEEP_SECONDS) * TIMING_SWEEP_WIDTH
			impact_point = aim_point + Vector2(horizontal, (IDEAL_DRAW - locked_draw) * DRAW_VERTICAL_SCALE)
