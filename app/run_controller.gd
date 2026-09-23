extends Node

const ARROWS_PER_ROUND: int = 5
const GOAL_SCORE: int = 40
const REST_POINT: Vector2 = Vector2(820.0, 645.0)
const BARE_RIG: BuildDef = preload("res://content/equipment/bare_rig.tres")
const GYRO_BRACE: BuildDef = preload("res://content/equipment/gyro_brace.tres")
const PULSE_SIGHT: BuildDef = preload("res://content/equipment/pulse_sight.tres")

@onready var range_view: RangeView = $RangeView

var shot: ShotModel = ShotModel.new()
var impacts: Array[ImpactRecord] = []
var total_score: int = 0
var last_score: int = -1
var best_score: int = -1
var gear_unlocked: bool = false
var equipped: BuildDef = BARE_RIG
var last_target: String = ""
var range_time: float = 0.0


func _ready() -> void:
	range_view.primary_pressed.connect(_on_primary_pressed)
	range_view.primary_released.connect(_on_primary_released)
	range_view.gear_requested.connect(_on_gear_requested)
	range_view.retry_requested.connect(_on_retry_requested)
	range_view.cancel_requested.connect(_on_cancel_requested)
	_refresh_view()


func _physics_process(delta: float) -> void:
	if impacts.size() < ARROWS_PER_ROUND:
		range_time += delta
		shot.tick(delta, range_view.mouse_aim(), TargetLayout.centers_at(range_time))
	_refresh_view()


func _on_primary_pressed() -> void:
	if impacts.size() >= ARROWS_PER_ROUND:
		return
	if shot.phase == ShotModel.Phase.IDLE:
		shot.configure(equipped.steering_scale, equipped.lock_radius)
		shot.start_hold(REST_POINT)
	_refresh_view()


func _on_primary_released() -> void:
	if shot.phase == ShotModel.Phase.DRAW:
		shot.cancel()
	elif shot.phase == ShotModel.Phase.READY:
		if range_view.visible_reticle_valid:
			_accept_shot(range_view.visible_reticle)
		else:
			shot.cancel()
	_refresh_view()


func _accept_shot(visible_impact: Vector2) -> void:
	var result: Dictionary = TargetLayout.score_at(visible_impact, range_view.visible_target_centers)
	last_score = result.score
	last_target = result.target
	total_score += last_score
	var hit_target: int = result.target_index
	var stored_point: Vector2 = visible_impact
	if hit_target >= 0:
		stored_point -= range_view.visible_target_centers[hit_target]
	impacts.append(ImpactRecord.new(hit_target, stored_point))
	shot.cancel()
	if impacts.size() == ARROWS_PER_ROUND:
		gear_unlocked = true
		best_score = maxi(best_score, total_score)


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
	range_time = 0.0
	_refresh_view()


func _refresh_view() -> void:
	range_view.present(
		shot, impacts, total_score, last_score, best_score,
		ARROWS_PER_ROUND, GOAL_SCORE, gear_unlocked, equipped, last_target, range_time
	)
