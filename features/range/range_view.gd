class_name RangeView
extends Node2D

signal primary_pressed
signal primary_released
signal gear_requested(gear_id: StringName)
signal retry_requested
signal cancel_requested

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
@onready var gyro_button: Button = $UI/GyroButton
@onready var pulse_button: Button = $UI/PulseButton
@onready var starter_button: Button = $UI/StarterButton
@onready var retry_button: Button = $UI/RetryButton
@onready var target_labels: Array[Label] = [$UI/SafeLabel, $UI/StandardLabel, $UI/BoldLabel]

var visible_reticle: Vector2 = Vector2.ZERO
var visible_reticle_valid: bool = false
var visible_target_centers: Array[Vector2] = TargetLayout.centers_at(0.0)

var _shot: ShotModel
var _impacts: Array[ImpactRecord] = []
var _total_score: int = 0
var _last_score: int = -1
var _best_score: int = -1
var _round_size: int = 5
var _goal_score: int = 40
var _gear_unlocked: bool = false
var _equipped: BuildDef
var _last_target: String = ""
var _range_time: float = 0.0
var _target_centers: Array[Vector2] = TargetLayout.centers_at(0.0)
var _drawn_phase: ShotModel.Phase = ShotModel.Phase.IDLE


func _ready() -> void:
	gyro_button.pressed.connect(func() -> void: gear_requested.emit(&"gyro_brace"))
	pulse_button.pressed.connect(func() -> void: gear_requested.emit(&"pulse_sight"))
	starter_button.pressed.connect(func() -> void: gear_requested.emit(&"bare_rig"))
	retry_button.pressed.connect(func() -> void: retry_requested.emit())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and AIM_AREA.has_point(event.position):
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
	return position_on_canvas.clamp(Vector2(410.0, 176.0), Vector2(1194.0, 660.0))


func present(
	shot: ShotModel,
	impacts: Array[ImpactRecord],
	total_score: int,
	last_score: int,
	best_score: int,
	round_size: int,
	goal_score: int,
	gear_unlocked: bool,
	equipped: BuildDef,
	last_target: String,
	range_time: float
) -> void:
	_shot = shot
	_impacts = impacts
	_total_score = total_score
	_last_score = last_score
	_best_score = best_score
	_round_size = round_size
	_goal_score = goal_score
	_gear_unlocked = gear_unlocked
	_equipped = equipped
	_last_target = last_target
	_range_time = range_time
	_target_centers = TargetLayout.centers_at(_range_time)
	for target: int in range(target_labels.size()):
		var label: Label = target_labels[target]
		label.position = Vector2(_target_centers[target].x - label.size.x * 0.5, _target_centers[target].y + TargetLayout.RADII[target] + 20.0)
	if _drawn_phase != shot.phase:
		visible_reticle_valid = false
	_update_labels()
	queue_redraw()


func _update_labels() -> void:
	var completed: bool = _impacts.size() >= _round_size
	var arrow_number: int = mini(_impacts.size() + 1, _round_size)
	title_label.text = "Choose your\nmark."
	description_label.text = "Three moving targets.\nScore %d in five shots." % _goal_score
	score_label.text = "SHOT %d / %d     SCORE %d / %d" % [arrow_number, _round_size, _total_score, _goal_score]
	gyro_button.text = ("● " if _equipped.id == &"gyro_brace" else "") + "MAERA · GYRO BRACE"
	pulse_button.text = ("● " if _equipped.id == &"pulse_sight" else "") + "VEY · PULSE SIGHT"
	starter_button.text = ("● " if _equipped.id == &"bare_rig" else "") + "THE NATURAL · BARE RIG"
	gyro_button.disabled = not _gear_unlocked or _shot.phase != ShotModel.Phase.IDLE or (not _impacts.is_empty() and not completed)
	pulse_button.disabled = gyro_button.disabled
	starter_button.disabled = gyro_button.disabled
	retry_button.visible = completed
	var best_text: String = "—" if _best_score < 0 else str(_best_score)
	footer_label.text = "%s / %s     BEST %s     SAFE 6  /  STANDARD 10  /  BOLD 15" % [_equipped.operator_name.to_upper(), _equipped.display_name.to_upper(), best_text]
	if completed:
		status_label.text = "TRIAL CLEARED" if _total_score >= _goal_score else "TRIAL FAILED"
		instruction_label.text = "Choose a marksman and rig.\nEach handles the aim differently."
	elif _shot.phase == ShotModel.Phase.DRAW:
		status_label.text = "DRAWING — WAIT FOR READY"
		instruction_label.text = "Hold left mouse to track.\nEarly release cancels."
	elif _shot.phase == ShotModel.Phase.READY:
		status_label.text = "READY — RELEASE ON THE MARK"
		instruction_label.text = "Track the moving target.\nCyan ring means focus lock."
	else:
		status_label.text = "%s / %s" % [_equipped.operator_name.to_upper(), _equipped.operator_role]
		if _last_score == 0:
			status_label.text = "MISS — TRY THE NEXT ARROW"
		elif _last_score > 0:
			status_label.text = "%s +%d — NEXT SHOT" % [_last_target, _last_score]
		instruction_label.text = "%s\nHold to steer. Release at gold." % _equipped.description


func _draw() -> void:
	_draw_range()
	for impact: ImpactRecord in _impacts:
		_draw_impact_mark(impact.position_at(visible_target_centers))
	visible_reticle_valid = false
	if _shot == null or _impacts.size() >= _round_size:
		_drawn_phase = ShotModel.Phase.IDLE
		return
	_drawn_phase = _shot.phase
	if _shot.phase == ShotModel.Phase.IDLE:
		_draw_crosshair(Vector2(820.0, 645.0), Color("b6c7b6"), 12.0)
	elif _shot.phase == ShotModel.Phase.DRAW:
		_draw_crosshair(_shot.aim_point, Color("b6c7b6"), 11.0)
	elif _shot.phase == ShotModel.Phase.READY:
		visible_reticle = _shot.impact_point
		visible_reticle_valid = true
		_draw_crosshair(visible_reticle, Color("ffd269"), 18.0)
		if _shot.target_locked:
			draw_arc(visible_reticle, 29.0, 0, TAU, 48, Color("8bd7c7"), 2.0, true)
	_draw_gauge()


func _draw_range() -> void:
	visible_target_centers = _target_centers.duplicate()
	draw_style_box(_panel_style(Color("182720"), 24), AIM_AREA)
	for plank: int in range(7):
		var x: float = 426.0 + plank * 124.0
		draw_line(Vector2(x, 142), Vector2(x, 700), Color("203127"), 1.0)
	draw_line(Vector2(420, 585), Vector2(1185, 585), Color("3b7168"), 2.0, true)
	for target: int in range(visible_target_centers.size()):
		var center: Vector2 = visible_target_centers[target]
		var target_radius: float = TargetLayout.RADII[target]
		draw_line(center + Vector2(0, target_radius + 23), Vector2(center.x, 585), Color("3b7168"), 2.0, true)
		draw_circle(Vector2(center.x, 585), 5.0, Color("8bd7c7"), true, -1.0, true)
		draw_circle(center + Vector2(0, 10), target_radius + 14, Color("101c17"), true, -1.0, true)
		draw_circle(center, target_radius + 7, Color("afa58d"), true, -1.0, true)
		draw_arc(center, target_radius + 19, -PI * 0.36, PI * 0.36, 48, Color("8bd7c7"), 2.0, true)
		draw_arc(center, target_radius + 19, PI * 0.64, PI * 1.36, 48, Color("8bd7c7"), 2.0, true)
		for ring: int in range(10):
			var radius: float = (1.0 - ring / 10.0) * target_radius
			draw_circle(center, radius, RING_COLORS[ring], true, -1.0, true)
			draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), Color(0.1, 0.13, 0.12, 0.12), 1.0)
			draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), Color(0.1, 0.13, 0.12, 0.12), 1.0)
			draw_line(center - Vector2(5, 0), center + Vector2(5, 0), Color("67532b"), 1.0, true)
			draw_line(center - Vector2(0, 5), center + Vector2(0, 5), Color("67532b"), 1.0, true)


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
	if _shot.phase != ShotModel.Phase.DRAW and _shot.phase != ShotModel.Phase.READY:
		return
	var gauge: Rect2 = Rect2(650.0, 682.0, 340.0, 18.0)
	draw_rect(gauge, Color("2d3e32"))
	draw_rect(Rect2(gauge.position, Vector2(gauge.size.x * _shot.draw_level, gauge.size.y)), Color("83a998"))


func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
