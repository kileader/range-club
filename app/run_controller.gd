extends Node

const ARROWS_PER_ROUND: int = 5
const GOAL_SCORE: int = 40
const REST_POINT: Vector2 = Vector2(820.0, 645.0)
const BARE_RIG: BuildDef = preload("res://content/equipment/bare_rig.tres")
const GYRO_BRACE: BuildDef = preload("res://content/equipment/gyro_brace.tres")
const PULSE_SIGHT: BuildDef = preload("res://content/equipment/pulse_sight.tres")

@onready var range_view: RangeView = $RangeView

var shot: ShotModel = ShotModel.new()
var mode: RangeView.ShotMode = RangeView.ShotMode.HOLD
var impacts: Array[Vector2] = []
var total_score: int = 0
var last_score: int = -1
var best_hold: int = -1
var best_timing: int = -1
var gear_unlocked: bool = false
var equipped: BuildDef = BARE_RIG
var last_target: String = ""


func _ready() -> void:
	range_view.primary_pressed.connect(_on_primary_pressed)
	range_view.primary_released.connect(_on_primary_released)
	range_view.mode_requested.connect(_on_mode_requested)
	range_view.gear_requested.connect(_on_gear_requested)
	range_view.retry_requested.connect(_on_retry_requested)
	range_view.cancel_requested.connect(_on_cancel_requested)
	_refresh_view()


func _physics_process(delta: float) -> void:
	if impacts.size() < ARROWS_PER_ROUND:
		shot.tick(delta, range_view.mouse_aim())
	_refresh_view()


func _on_primary_pressed() -> void:
	if impacts.size() >= ARROWS_PER_ROUND:
		return
	if mode == RangeView.ShotMode.HOLD:
		if shot.phase == ShotModel.Phase.IDLE:
			shot.configure(equipped.steering_scale, equipped.sway_scale)
			shot.start_hold(REST_POINT)
	else:
		match shot.phase:
			ShotModel.Phase.IDLE:
				shot.start_timing(range_view.mouse_aim())
			ShotModel.Phase.TIMING_DRAW:
				if range_view.visible_draw_valid:
					shot.lock_draw(range_view.visible_draw_level)
			ShotModel.Phase.TIMING_RELEASE:
				if range_view.visible_reticle_valid:
					_accept_shot(range_view.visible_reticle)
	_refresh_view()


func _on_primary_released() -> void:
	if mode != RangeView.ShotMode.HOLD:
		return
	if shot.phase == ShotModel.Phase.HOLD_DRAW:
		shot.cancel()
	elif shot.phase == ShotModel.Phase.HOLD_READY:
		if range_view.visible_reticle_valid:
			_accept_shot(range_view.visible_reticle)
		else:
			shot.cancel()
	_refresh_view()


func _accept_shot(visible_impact: Vector2) -> void:
	var result: Dictionary = TargetLayout.score_at(visible_impact)
	last_score = result.score
	last_target = result.target
	total_score += last_score
	impacts.append(visible_impact)
	shot.cancel()
	if impacts.size() == ARROWS_PER_ROUND:
		gear_unlocked = true
		if mode == RangeView.ShotMode.HOLD:
			best_hold = maxi(best_hold, total_score)
		else:
			best_timing = maxi(best_timing, total_score)


func _on_mode_requested(requested_mode: RangeView.ShotMode) -> void:
	mode = requested_mode
	_reset_round()


func _on_retry_requested() -> void:
	_reset_round()


func _on_gear_requested(gear_id: StringName) -> void:
	if not gear_unlocked or shot.phase != ShotModel.Phase.IDLE or (not impacts.is_empty() and impacts.size() < ARROWS_PER_ROUND):
		return
	if gear_id == GYRO_BRACE.id:
		equipped = GYRO_BRACE
	elif gear_id == PULSE_SIGHT.id:
		equipped = PULSE_SIGHT
	elif gear_id == BARE_RIG.id:
		equipped = BARE_RIG
	else:
		return
	_reset_round()


func _on_cancel_requested() -> void:
	shot.cancel()
	_refresh_view()


func _reset_round() -> void:
	shot.cancel()
	impacts.clear()
	total_score = 0
	last_score = -1
	last_target = ""
	_refresh_view()


func _refresh_view() -> void:
	range_view.present(
		mode, shot, impacts, total_score, last_score, best_hold, best_timing,
		ARROWS_PER_ROUND, GOAL_SCORE, gear_unlocked, equipped, last_target
	)
