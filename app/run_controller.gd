extends Node

const ARROWS_PER_ROUND: int = 5

@onready var range_view: RangeView = $RangeView

var shot: ShotModel = ShotModel.new()
var mode: RangeView.ShotMode = RangeView.ShotMode.HOLD
var impacts: Array[Vector2] = []
var total_score: int = 0
var last_score: int = -1
var best_hold: int = -1
var best_timing: int = -1


func _ready() -> void:
	range_view.primary_pressed.connect(_on_primary_pressed)
	range_view.primary_released.connect(_on_primary_released)
	range_view.mode_requested.connect(_on_mode_requested)
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
			shot.start_hold(range_view.mouse_aim())
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
	var normalized: Vector2 = (visible_impact - range_view.target_center()) / range_view.target_radius()
	last_score = Scoring.ring_score(normalized)
	total_score += last_score
	impacts.append(visible_impact)
	shot.cancel()
	if impacts.size() == ARROWS_PER_ROUND:
		if mode == RangeView.ShotMode.HOLD:
			best_hold = maxi(best_hold, total_score)
		else:
			best_timing = maxi(best_timing, total_score)


func _on_mode_requested(requested_mode: RangeView.ShotMode) -> void:
	mode = requested_mode
	_reset_round()


func _on_retry_requested() -> void:
	_reset_round()


func _on_cancel_requested() -> void:
	shot.cancel()
	_refresh_view()


func _reset_round() -> void:
	shot.cancel()
	impacts.clear()
	total_score = 0
	last_score = -1
	_refresh_view()


func _refresh_view() -> void:
	range_view.present(mode, shot, impacts, total_score, last_score, best_hold, best_timing, ARROWS_PER_ROUND)
