class_name RangeView
extends Node2D

signal primary_pressed
signal primary_released
signal mode_requested(mode: ShotMode)
signal retry_requested
signal cancel_requested

enum ShotMode { HOLD, TIMING }

const TARGET_CENTER: Vector2 = Vector2(820.0, 416.0)
const TARGET_RADIUS: float = 248.0
const AIM_AREA: Rect2 = Rect2(390.0, 122.0, 824.0, 598.0)
const RING_COLORS: Array[Color] = [
	Color("f2ede0"), Color("e5dfd1"),
	Color("303a3b"), Color("263032"),
	Color("58a7c0"), Color("4595b0"),
	Color("d66050"), Color("c65145"),
	Color("f2cb65"), Color("edbc4c"),
]

@onready var title_label: Label = $UI/Title
@onready var description_label: Label = $UI/Description
@onready var score_label: Label = $UI/ScoreLine
@onready var status_label: Label = $UI/Status
@onready var instruction_label: Label = $UI/NextStep
@onready var footer_label: Label = $UI/Footer
@onready var hold_button: Button = $UI/HoldButton
@onready var timing_button: Button = $UI/TimingButton
@onready var retry_button: Button = $UI/RetryButton

var visible_reticle: Vector2 = Vector2.ZERO
var visible_reticle_valid: bool = false
var visible_draw_level: float = 0.0
var visible_draw_valid: bool = false

var _mode: ShotMode = ShotMode.HOLD
var _shot: ShotModel
var _impacts: Array[Vector2] = []
var _total_score: int = 0
var _last_score: int = -1
var _best_hold: int = -1
var _best_timing: int = -1
var _round_size: int = 5
var _drawn_phase: ShotModel.Phase = ShotModel.Phase.IDLE


func _ready() -> void:
	hold_button.pressed.connect(func() -> void: mode_requested.emit(ShotMode.HOLD))
	timing_button.pressed.connect(func() -> void: mode_requested.emit(ShotMode.TIMING))
	retry_button.pressed.connect(func() -> void: retry_requested.emit())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var active_timing: bool = _mode == ShotMode.TIMING and _shot != null and _shot.phase != ShotModel.Phase.IDLE
		if event.pressed and (AIM_AREA.has_point(event.position) or active_timing):
			primary_pressed.emit()
			get_viewport().set_input_as_handled()
		elif not event.pressed:
			primary_released.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_requested.emit()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		cancel_requested.emit()


func mouse_aim() -> Vector2:
	var position_on_canvas: Vector2 = get_viewport().get_mouse_position()
	return position_on_canvas.clamp(Vector2(410.0, 176.0), Vector2(1194.0, 682.0))


func target_center() -> Vector2:
	return TARGET_CENTER


func target_radius() -> float:
	return TARGET_RADIUS


func present(
	mode: ShotMode,
	shot: ShotModel,
	impacts: Array[Vector2],
	total_score: int,
	last_score: int,
	best_hold: int,
	best_timing: int,
	round_size: int
) -> void:
	_mode = mode
	_shot = shot
	_impacts = impacts
	_total_score = total_score
	_last_score = last_score
	_best_hold = best_hold
	_best_timing = best_timing
	_round_size = round_size
	if _drawn_phase != shot.phase:
		visible_reticle_valid = false
		visible_draw_valid = false
	_update_labels()
	queue_redraw()


func _update_labels() -> void:
	var completed: bool = _impacts.size() >= _round_size
	var arrow_number: int = mini(_impacts.size() + 1, _round_size)
	title_label.text = "Find your\nrelease."
	description_label.text = "One target. Two shot styles.\nTry five arrows with each."
	score_label.text = "ARROW %d / %d     SCORE %d / %d" % [arrow_number, _round_size, _total_score, _round_size * 10]
	hold_button.text = "● HOLD & SWAY" if _mode == ShotMode.HOLD else "HOLD & SWAY"
	timing_button.text = "● 3-PRESS TIMING" if _mode == ShotMode.TIMING else "3-PRESS TIMING"
	retry_button.visible = completed
	var hold_best_text: String = "—" if _best_hold < 0 else str(_best_hold)
	var timing_best_text: String = "—" if _best_timing < 0 else str(_best_timing)
	footer_label.text = "BEST FIVE   HOLD %s / 50     TIMING %s / 50                           RANGE 01" % [hold_best_text, timing_best_text]
	if completed:
		status_label.text = "ROUND COMPLETE: %d / 50" % _total_score
		instruction_label.text = "Switch styles or retry\nthe same five arrows."
	elif _shot.phase == ShotModel.Phase.HOLD_DRAW:
		status_label.text = "DRAWING — WAIT FOR READY"
		instruction_label.text = "Hold left mouse. Move to aim.\nEarly release cancels."
	elif _shot.phase == ShotModel.Phase.HOLD_READY:
		status_label.text = "READY — RELEASE ON THE MARK"
		instruction_label.text = "The gold reticle is the hit.\nIt settles, then fatigue grows."
	elif _shot.phase == ShotModel.Phase.TIMING_DRAW:
		status_label.text = "2 / 3  SET THE DRAW"
		instruction_label.text = "Watch the bar below the target.\nClick when it enters the gold box."
	elif _shot.phase == ShotModel.Phase.TIMING_RELEASE:
		status_label.text = "3 / 3  RELEASE THE SHOT"
		instruction_label.text = "Watch the gold circle. Click\nwhen it meets your pale aim mark."
	else:
		status_label.text = "SIMPLE KIT. STEADY HAND."
		if _last_score == 0:
			status_label.text = "MISS — TRY THE NEXT ARROW"
		elif _last_score > 0:
			status_label.text = "RING %d — TRY THE NEXT ARROW" % _last_score
		if _mode == ShotMode.HOLD:
			instruction_label.text = "Hold left mouse to draw.\nRelease at the gold reticle."
		else:
			status_label.text = "1 / 3  AIM AND CLICK"
			instruction_label.text = "Point at the target and click.\nThen watch the bar below it."


func _draw() -> void:
	_draw_range()
	for point: Vector2 in _impacts:
		_draw_impact_mark(point)
	visible_reticle_valid = false
	visible_draw_valid = false
	if _shot == null or _impacts.size() >= _round_size:
		_drawn_phase = ShotModel.Phase.IDLE
		return
	_drawn_phase = _shot.phase
	if _shot.phase == ShotModel.Phase.IDLE:
		_draw_crosshair(mouse_aim(), Color("b6c7b6"), 12.0)
	else:
		_draw_crosshair(_shot.aim_point, Color("b6c7b6"), 11.0)
		if _shot.phase == ShotModel.Phase.HOLD_READY or _shot.phase == ShotModel.Phase.TIMING_RELEASE:
			visible_reticle = _shot.impact_point
			visible_reticle_valid = true
			_draw_crosshair(visible_reticle, Color("ffd269"), 18.0)
	_draw_gauge()


func _draw_range() -> void:
	draw_style_box(_panel_style(Color("182720"), 24), AIM_AREA)
	for plank: int in range(7):
		var x: float = 426.0 + plank * 124.0
		draw_line(Vector2(x, 142), Vector2(x, 700), Color("203127"), 1.0)
	draw_line(Vector2(746, 536), Vector2(702, 695), Color("647060"), 12.0, true)
	draw_line(Vector2(894, 536), Vector2(938, 695), Color("647060"), 12.0, true)
	draw_circle(TARGET_CENTER + Vector2(0, 10), TARGET_RADIUS + 14, Color("101c17"), true, -1.0, true)
	draw_circle(TARGET_CENTER, TARGET_RADIUS + 7, Color("afa58d"), true, -1.0, true)
	for ring: int in range(10):
		var unit_radius: float = 1.0 - ring / 10.0
		var radius: float = unit_radius * TARGET_RADIUS
		draw_circle(TARGET_CENTER, radius, RING_COLORS[ring], true, -1.0, true)
		draw_arc(TARGET_CENTER, radius, 0, TAU, 192, Color(0.1, 0.13, 0.12, 0.5), 1.0, true)
	draw_line(TARGET_CENTER - Vector2(5, 0), TARGET_CENTER + Vector2(5, 0), Color("67532b"), 1.0, true)
	draw_line(TARGET_CENTER - Vector2(0, 5), TARGET_CENTER + Vector2(0, 5), Color("67532b"), 1.0, true)


func _draw_impact_mark(point: Vector2) -> void:
	draw_circle(point, 8.0, Color("14211c"), true, -1.0, true)
	draw_line(point + Vector2(-5, -5), point + Vector2(5, 5), Color("f5dea3"), 2.0, true)
	draw_line(point + Vector2(-5, 5), point + Vector2(5, -5), Color("f5dea3"), 2.0, true)


func _draw_crosshair(point: Vector2, color: Color, size: float) -> void:
	draw_arc(point, size, 0, TAU, 40, color, 2.0, true)
	draw_line(point + Vector2(-size - 6, 0), point + Vector2(-size + 1, 0), color, 2.0, true)
	draw_line(point + Vector2(size - 1, 0), point + Vector2(size + 6, 0), color, 2.0, true)
	draw_line(point + Vector2(0, -size - 6), point + Vector2(0, -size + 1), color, 2.0, true)
	draw_line(point + Vector2(0, size - 1), point + Vector2(0, size + 6), color, 2.0, true)


func _draw_gauge() -> void:
	if _shot.phase != ShotModel.Phase.HOLD_DRAW and _shot.phase != ShotModel.Phase.HOLD_READY and _shot.phase != ShotModel.Phase.TIMING_DRAW:
		return
	var gauge: Rect2 = Rect2(650.0, 682.0, 340.0, 18.0)
	draw_rect(gauge, Color("2d3e32"))
	draw_rect(Rect2(gauge.position, Vector2(gauge.size.x * _shot.draw_level, gauge.size.y)), Color("83a998"))
	if _shot.phase == ShotModel.Phase.TIMING_DRAW:
		var ideal_x: float = gauge.position.x + gauge.size.x * ShotModel.IDEAL_DRAW
		var sweet_zone: Rect2 = Rect2(ideal_x - 43.0, gauge.position.y - 3.0, 86.0, gauge.size.y + 6.0)
		draw_rect(sweet_zone, Color(1.0, 0.82, 0.41, 0.2))
		draw_rect(sweet_zone, Color("ffd269"), false, 2.0)
		draw_line(Vector2(ideal_x, sweet_zone.position.y), Vector2(ideal_x, sweet_zone.end.y), Color("ffd269"), 2.0)
		visible_draw_level = _shot.draw_level
		visible_draw_valid = true


func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
