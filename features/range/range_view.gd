class_name RangeView
extends Node2D

signal primary_pressed(aim_position: Vector2)
signal primary_released
signal gear_requested(gear_id: StringName)
signal build_screen_requested
signal rig_details_requested
signal build_screen_closed
signal focus_requested
signal cancel_requested
signal back_requested

const BARE_RIG: BuildDef = preload("res://content/equipment/bare_rig.tres")
const GYRO_BRACE: BuildDef = preload("res://content/equipment/gyro_brace.tres")
const PULSE_SIGHT: BuildDef = preload("res://content/equipment/pulse_sight.tres")
const NATURAL_PORTRAIT: Texture2D = preload("res://assets/art/concepts/natural_portrait_concept_v1.png")
const MAERA_PORTRAIT: Texture2D = preload("res://assets/art/concepts/maera_portrait_concept_v1.png")
const VEY_PORTRAIT: Texture2D = preload("res://assets/art/concepts/vey_portrait_concept_v1.png")
const NATURAL_RANGE_SPRITE: Texture2D = preload("res://assets/art/concepts/natural_range_sprite_concept_v1.png")
const MAERA_RANGE_SPRITE: Texture2D = preload("res://assets/art/concepts/maera_range_sprite_concept_v1.png")
const VEY_RANGE_SPRITE: Texture2D = preload("res://assets/art/concepts/vey_range_sprite_concept_v1.png")

enum SelectionPage { RULES, CHARACTERS }
enum ResultSound { NONE, CLEAR, BUST, FAIL }

const RELEASE_SOUND: AudioStream = preload("res://assets/audio/release.wav")
const HIT_SOUND: AudioStream = preload("res://assets/audio/hit.wav")
const MISS_SOUND: AudioStream = preload("res://assets/audio/miss.wav")
const CLEAR_SOUND: AudioStream = preload("res://assets/audio/clear.wav")
const BUST_SOUND: AudioStream = preload("res://assets/audio/bust.wav")
const FAIL_SOUND: AudioStream = preload("res://assets/audio/fail.wav")

const AIM_AREA: Rect2 = Rect2(390.0, 122.0, 824.0, 598.0)
const RING_COLORS: Array[Color] = [
	Color("f2ede0"), Color("e5dfd1"),
	Color("303a3b"), Color("263032"),
	Color("58a7c0"), Color("4595b0"),
	Color("d66050"), Color("c65145"),
	Color("f2cb65"), Color("edbc4c"),
]

@onready var title_label: Label = $UI/Title
@onready var stage_label: Label = $UI/StageLabel
@onready var scenario_label: Label = $UI/ScenarioRule
@onready var description_label: Label = $UI/Description
@onready var score_label: Label = $UI/ScoreLine
@onready var status_label: Label = $UI/Status
@onready var instruction_label: Label = $UI/NextStep
@onready var footer_label: Label = $UI/Footer
@onready var focus_button: Button = $UI/FocusButton
@onready var build_button: Button = $UI/BuildButton
@onready var rig_details_button: Button = $UI/RigDetailsButton
@onready var target_labels: Array[Label] = [$UI/SafeLabel, $UI/StandardLabel, $UI/BoldLabel]
@onready var build_overlay: Control = $UI/BuildOverlay
@onready var heading_label: Label = $UI/BuildOverlay/Heading
@onready var rules_label: Label = $UI/BuildOverlay/Rules
@onready var safe_rules_label: Label = $UI/BuildOverlay/SafeRules
@onready var standard_rules_label: Label = $UI/BuildOverlay/StandardRules
@onready var bold_rules_label: Label = $UI/BuildOverlay/BoldRules
@onready var focus_rules_label: Label = $UI/BuildOverlay/FocusRules
@onready var control_rules_label: Label = $UI/BuildOverlay/ControlRules
@onready var rules_next_button: Button = $UI/BuildOverlay/RulesNextButton
@onready var how_to_play_button: Button = $UI/BuildOverlay/HowToPlayButton
@onready var archive_button: Button = $UI/BuildOverlay/ArchiveButton
@onready var archive_page: ColorRect = $UI/BuildOverlay/ArchivePage
@onready var archive_close_button: Button = $UI/BuildOverlay/ArchivePage/CloseButton
@onready var natural_card: Button = $UI/BuildOverlay/NaturalCard
@onready var maera_card: Button = $UI/BuildOverlay/MaeraCard
@onready var vey_card: Button = $UI/BuildOverlay/VeyCard
@onready var natural_portrait: TextureRect = $UI/BuildOverlay/NaturalCard/Portrait
@onready var maera_portrait: TextureRect = $UI/BuildOverlay/MaeraCard/Portrait
@onready var vey_portrait: TextureRect = $UI/BuildOverlay/VeyCard/Portrait
@onready var natural_card_label: Label = $UI/BuildOverlay/NaturalCard/CardText
@onready var maera_card_label: Label = $UI/BuildOverlay/MaeraCard/CardText
@onready var vey_card_label: Label = $UI/BuildOverlay/VeyCard/CardText
@onready var choose_hint: Label = $UI/BuildOverlay/ChooseHint
@onready var back_button: Button = $UI/BuildOverlay/BackButton
@onready var release_player: AudioStreamPlayer = $ReleaseSound
@onready var impact_player: AudioStreamPlayer = $ImpactSound
@onready var result_player: AudioStreamPlayer = $ResultSound
@onready var impact_delay: Timer = $ImpactDelay
@onready var result_delay: Timer = $ResultDelay

var visible_reticle: Vector2 = Vector2.ZERO
var visible_spread_radius: float = 0.0
var visible_reticle_valid: bool = false
var visible_target_centers: Array[Vector2] = TargetLayout.centers_at(0.0)

var _shot: ShotModel
var _impacts: Array[ImpactRecord] = []
var _total_score: int = 0
var _last_score: int = -1
var _best_score: int = -1
var _round_size: int = 5
var _goal_score: int = 40
var _cap_score: int = 52
var _stage: int = 0
var _scenario_id: StringName = &"triad"
var _upgrades: Array[StringName] = []
var _allow_character_change: bool = false
var _allow_rig_details: bool = false
var _equipped: BuildDef
var _last_target: String = ""
var _last_bonus: String = ""
var _last_focus_gain: int = 0
var _range_time: float = 0.0
var _focus: int = TrialRules.START_FOCUS
var _focus_armed: bool = false
var _shot_focused: bool = false
var _selection_open: bool = true
var _build_selected: bool = false
var _selection_page: SelectionPage = SelectionPage.RULES
var _target_centers: Array[Vector2] = TargetLayout.centers_at(0.0)
var _drawn_phase: ShotModel.Phase = ShotModel.Phase.IDLE
var _pending_hit: bool = false
var _pending_result: ResultSound = ResultSound.NONE


func _ready() -> void:
	release_player.stream = RELEASE_SOUND
	impact_delay.timeout.connect(_play_impact_sound)
	result_delay.timeout.connect(_play_result_sound)
	focus_button.pressed.connect(func() -> void: focus_requested.emit())
	build_button.pressed.connect(func() -> void: build_screen_requested.emit())
	rig_details_button.pressed.connect(func() -> void: rig_details_requested.emit())
	natural_card.pressed.connect(func() -> void: gear_requested.emit(&"bare_rig"))
	maera_card.pressed.connect(func() -> void: gear_requested.emit(&"gyro_brace"))
	vey_card.pressed.connect(func() -> void: gear_requested.emit(&"pulse_sight"))
	back_button.pressed.connect(func() -> void: build_screen_closed.emit())
	rules_next_button.pressed.connect(func() -> void: _set_selection_page(SelectionPage.CHARACTERS))
	how_to_play_button.pressed.connect(func() -> void: _set_selection_page(SelectionPage.RULES))
	archive_button.pressed.connect(func() -> void: archive_page.visible = true)
	archive_close_button.pressed.connect(func() -> void: archive_page.visible = false)
	natural_card.text = ""
	maera_card.text = ""
	vey_card.text = ""
	natural_card_label.text = _portrait_card_text(BARE_RIG)
	maera_card_label.text = _portrait_card_text(GYRO_BRACE)
	vey_card_label.text = _portrait_card_text(PULSE_SIGHT)
	_setup_card_art(natural_portrait, NATURAL_PORTRAIT)
	_setup_card_art(maera_portrait, MAERA_PORTRAIT)
	_setup_card_art(vey_portrait, VEY_PORTRAIT)
	rules_label.text = "Three trials · 5 shots each. First gate %d–%d; above it busts.\nRings count 1 (edge) to 10 (center); Safe caps at 6, Bold adds 5." % [TrialRules.GOAL_SCORE, TrialRules.BUST_SCORE]
	safe_rules_label.text = "SAFE · 1–6\nLarge target\nInner half: 6 +1 Focus"
	standard_rules_label.text = "STANDARD · 1–10\nMedium target"
	bold_rules_label.text = "BOLD · 6–15\nSmall target"
	focus_rules_label.text = "FOCUS · Each trial starts with %d (max %d). Press F to tighten the circle.\nNatural/Vey also slow targets. Ready release spends 1; right-click cancels." % [TrialRules.START_FOCUS, TrialRules.MAX_FOCUS]
	control_rules_label.text = "Gold = possible hits; cyan = smallest circle. Hits land inside gold.\nRelease after READY; long holds widen gold. Right-click to cancel."


func play_shot_feedback(hit: bool, result: ResultSound) -> void:
	impact_delay.stop()
	result_delay.stop()
	_pending_hit = hit
	_pending_result = result
	release_player.stop()
	release_player.play()
	impact_delay.start()
	if result != ResultSound.NONE:
		result_delay.start()


func stop_sound_feedback() -> void:
	impact_delay.stop()
	result_delay.stop()
	release_player.stop()
	impact_player.stop()
	result_player.stop()


func _play_impact_sound() -> void:
	impact_player.stream = HIT_SOUND if _pending_hit else MISS_SOUND
	impact_player.play()


func _play_result_sound() -> void:
	match _pending_result:
		ResultSound.CLEAR:
			result_player.stream = CLEAR_SOUND
		ResultSound.BUST:
			result_player.stream = BUST_SOUND
		ResultSound.FAIL:
			result_player.stream = FAIL_SOUND
		_:
			return
	result_player.play()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not _selection_open and event.pressed and AIM_AREA.has_point(event.position):
			primary_pressed.emit(_clamp_aim(event.position))
			get_viewport().set_input_as_handled()
		elif not _selection_open and not event.pressed:
			primary_released.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not _selection_open:
		cancel_requested.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if archive_page.visible:
			archive_page.visible = false
		else:
			back_requested.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F and not _selection_open:
		focus_requested.emit()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		cancel_requested.emit()


func mouse_aim() -> Vector2:
	var position_on_canvas: Vector2 = get_viewport().get_mouse_position()
	return _clamp_aim(position_on_canvas)


func _clamp_aim(position_on_canvas: Vector2) -> Vector2:
	return position_on_canvas.clamp(Vector2(410.0, 176.0), Vector2(1194.0, 660.0))


func present(
	shot: ShotModel,
	impacts: Array[ImpactRecord],
	total_score: int,
	last_score: int,
	best_score: int,
	round_size: int,
	goal_score: int,
	cap_score: int,
	equipped: BuildDef,
	last_target: String,
	last_bonus: String,
	last_focus_gain: int,
	range_time: float,
	focus: int,
	focus_armed: bool,
	shot_focused: bool,
	selection_open: bool,
	build_selected: bool,
	stage: int,
	scenario_id: StringName,
	upgrades: Array[StringName],
	allow_character_change: bool,
	allow_rig_details: bool
) -> void:
	_shot = shot
	_impacts = impacts
	_total_score = total_score
	_last_score = last_score
	_best_score = best_score
	_round_size = round_size
	_goal_score = goal_score
	_cap_score = cap_score
	_stage = stage
	_scenario_id = scenario_id
	_upgrades = upgrades
	_allow_character_change = allow_character_change
	_allow_rig_details = allow_rig_details
	_equipped = equipped
	_last_target = last_target
	_last_bonus = last_bonus
	_last_focus_gain = last_focus_gain
	_range_time = range_time
	_focus = focus
	_focus_armed = focus_armed
	_shot_focused = shot_focused
	if selection_open and not _selection_open:
		_selection_page = SelectionPage.CHARACTERS if build_selected else SelectionPage.RULES
	_selection_open = selection_open
	if not _selection_open:
		archive_page.visible = false
	_build_selected = build_selected
	_target_centers = TargetLayout.centers_at(_range_time)
	for target: int in range(target_labels.size()):
		var label: Label = target_labels[target]
		label.position = Vector2(_target_centers[target].x - label.size.x * 0.5, _target_centers[target].y + TargetLayout.RADII[target] + 20.0)
	if _drawn_phase != shot.phase:
		visible_reticle_valid = false
	_update_labels()
	queue_redraw()


func _update_labels() -> void:
	var completed: bool = TrialRules.is_trial_over(_total_score, _impacts.size(), _goal_score, _cap_score)
	var shot_number: int = _impacts.size() if completed else _impacts.size() + 1
	title_label.text = "Choose your\nmark."
	description_label.text = "Reach %d–%d in up to five shots.\nAbove %d busts." % [_goal_score, _cap_score, _cap_score]
	score_label.text = "SHOT %d / %d     SCORE %d / %d–%d" % [shot_number, _round_size, _total_score, _goal_score, _cap_score]
	stage_label.text = "%02d / %s" % [_stage + 1, RunRules.scenario_title(_scenario_id)]
	scenario_label.text = RunRules.scenario_rule(_scenario_id)
	build_overlay.visible = _selection_open
	back_button.visible = _build_selected
	_update_selection_page()
	build_button.visible = _allow_character_change
	build_button.disabled = not _allow_character_change or _shot.phase != ShotModel.Phase.IDLE
	rig_details_button.visible = _allow_rig_details
	rig_details_button.disabled = _shot.phase != ShotModel.Phase.IDLE
	focus_button.disabled = _selection_open or _focus <= 0 or _shot.phase != ShotModel.Phase.IDLE or completed
	if _shot_focused:
		focus_button.text = "FOCUS ACTIVE · CIRCLE TIGHTER" if _equipped.id == &"gyro_brace" else "FOCUS ACTIVE · SLOW + TIGHT"
	elif _focus_armed:
		focus_button.text = "FOCUS ARMED · %d / %d" % [_focus, TrialRules.MAX_FOCUS]
	else:
		focus_button.text = "FOCUS %d / %d · ARM (F)" % [_focus, TrialRules.MAX_FOCUS]
	var best_text: String = "—" if _best_score < 0 else str(_best_score)
	footer_label.text = "%s / %s     BEST %s     FOCUS %d / %d     RIG %s" % [_equipped.operator_name.to_upper(), _equipped.display_name.to_upper(), best_text, _focus, TrialRules.MAX_FOCUS, _upgrade_names()]
	if completed:
		if TrialRules.is_bust(_total_score, _cap_score):
			status_label.text = "BUST — OVER %d" % _cap_score
			instruction_label.text = "The run is over."
		else:
			status_label.text = "TRIAL CLEARED" if TrialRules.is_cleared(_total_score, _goal_score, _cap_score) else "TRIAL FAILED"
			instruction_label.text = "Choose the next rig module." if TrialRules.is_cleared(_total_score, _goal_score, _cap_score) else "The run is over."
	elif _shot.phase == ShotModel.Phase.DRAW:
		if _shot_focused:
			status_label.text = "FOCUS — CIRCLE TIGHTER" if _equipped.id == &"gyro_brace" else "FOCUS — SLOW + TIGHT"
		else:
			status_label.text = "CHARGING — WAIT FOR READY"
		instruction_label.text = "Hold to shrink the circle.\nRight-click to cancel."
	elif _shot.phase == ShotModel.Phase.READY:
		if _equipped.id == &"pulse_sight":
			var quick_remaining: float = maxf(TrialRules.VEY_TEMPO_SECONDS - _shot.elapsed, 0.0)
			if quick_remaining > 0.0 and _shot.elapsed >= _shot.precision_peak_seconds - 0.08 and _shot.elapsed <= _shot.precision_peak_seconds + maxf(_shot.minimum_hold_seconds, 0.08):
				status_label.text = "TIGHTEST — +3 AVAILABLE"
			else:
				status_label.text = "BONUS +3 — %.1fS LEFT" % quick_remaining if quick_remaining > 0.0 else _spread_status()
		else:
			status_label.text = _spread_status()
		instruction_label.text = "Cyan = smallest; gold = possible hit.\nRight-click to cancel this hold."
	else:
		status_label.text = "%s / %s" % [_equipped.operator_name.to_upper(), _equipped.operator_role]
		if _last_score == 0:
			status_label.text = "MISS — FOCUS REFUNDED" if _last_focus_gain > 0 else "MISS — TRY THE NEXT SHOT"
		elif _last_score > 0:
			status_label.text = "%s +%d" % [_last_target, _last_score]
			if _last_focus_gain > 0:
				status_label.text += " · FOCUS +1"
			elif not _last_bonus.is_empty():
				status_label.text += " · " + _last_bonus
		if _focus > 0:
			instruction_label.text = "Press F for a tighter circle.\nHold to shrink it further."
		else:
			instruction_label.text = "Hit near Safe's center for Focus.\nHold to shrink the circle."


func _portrait_card_text(build: BuildDef) -> String:
	return "%s / %s\n\n%s\n%s\nSELECT" % [build.operator_name.to_upper(), build.display_name.to_upper(), build.strategy, build.tradeoff]


func _setup_card_art(layer: TextureRect, art: Texture2D) -> void:
	layer.texture = art
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _upgrade_names() -> String:
	if _upgrades.is_empty():
		return "NONE"
	var names: PackedStringArray = []
	for upgrade_id: StringName in _upgrades:
		names.append(RunRules.upgrade_title(upgrade_id))
	return ", ".join(names)


func _spread_status() -> String:
	if _shot.elapsed < _shot.precision_peak_seconds - 0.12:
		return "READY — CIRCLE SHRINKING"
	if _shot.elapsed <= _shot.precision_peak_seconds + _shot.minimum_hold_seconds:
		return "STABLE — RELEASE" if _shot.minimum_hold_seconds > 0.0 else "TIGHTEST — RELEASE"
	if _shot.elapsed <= _shot.precision_peak_seconds + 0.12:
		return "TIGHTEST — RELEASE"
	return "CIRCLE WIDENING"


func _set_selection_page(page: SelectionPage) -> void:
	_selection_page = page
	_update_selection_page()


func _update_selection_page() -> void:
	var showing_rules: bool = _selection_page == SelectionPage.RULES
	heading_label.text = "How the run works" if showing_rules else "Choose your marksman"
	rules_label.visible = showing_rules
	safe_rules_label.visible = showing_rules
	standard_rules_label.visible = showing_rules
	bold_rules_label.visible = showing_rules
	focus_rules_label.visible = showing_rules
	control_rules_label.visible = showing_rules
	rules_next_button.visible = showing_rules
	natural_card.visible = not showing_rules
	maera_card.visible = not showing_rules
	vey_card.visible = not showing_rules
	choose_hint.visible = not showing_rules
	how_to_play_button.visible = not showing_rules
	archive_button.visible = true


func _draw() -> void:
	if _selection_open:
		visible_reticle_valid = false
		_drawn_phase = ShotModel.Phase.IDLE
		return
	_draw_range()
	for impact: ImpactRecord in _impacts:
		_draw_impact_mark(impact.position_at(visible_target_centers))
	visible_reticle_valid = false
	if _shot == null or TrialRules.is_trial_over(_total_score, _impacts.size(), _goal_score, _cap_score):
		_drawn_phase = ShotModel.Phase.IDLE
		return
	_drawn_phase = _shot.phase
	if _shot.phase == ShotModel.Phase.IDLE:
		if AIM_AREA.has_point(get_viewport().get_mouse_position()):
			_draw_crosshair(mouse_aim(), Color("b6c7b6"), 12.0)
	elif _shot.phase == ShotModel.Phase.DRAW:
		_draw_spread_circle(_shot.aim_point, _shot.spread_radius, false)
	elif _shot.phase == ShotModel.Phase.READY:
		visible_reticle = _shot.impact_point
		visible_spread_radius = _shot.spread_radius
		visible_reticle_valid = true
		_draw_spread_circle(visible_reticle, visible_spread_radius, true)


func _draw_range() -> void:
	visible_target_centers = _target_centers.duplicate()
	draw_style_box(_panel_style(Color("182720"), 24), AIM_AREA)
	for plank: int in range(7):
		var x: float = 426.0 + plank * 124.0
		draw_line(Vector2(x, 142), Vector2(x, 700), Color("203127"), 1.0)
	draw_line(Vector2(420, 585), Vector2(1185, 585), Color("3b7168"), 2.0, true)
	var range_sprite: Texture2D
	if _equipped != null:
		match _equipped.id:
			&"bare_rig":
				range_sprite = NATURAL_RANGE_SPRITE
			&"gyro_brace":
				range_sprite = MAERA_RANGE_SPRITE
			&"pulse_sight":
				range_sprite = VEY_RANGE_SPRITE
	if range_sprite != null:
		if _equipped.id == &"gyro_brace":
			draw_set_transform(Vector2(700.0, 535.0), 0.0, Vector2(-1.0, 1.0))
		else:
			draw_set_transform(Vector2(990.0, 535.0))
		draw_texture_rect(range_sprite, Rect2(0.0, 0.0, 200.0, 200.0), false)
		draw_set_transform(Vector2.ZERO)
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


func _draw_spread_circle(center: Vector2, radius: float, ready: bool) -> void:
	var color: Color = Color("ffd269") if ready else Color("b6c7b6")
	var minimum_radius: float = _shot.minimum_spread_radius()
	if radius > minimum_radius + 1.5:
		for segment: int in range(8):
			var start_angle: float = segment * TAU / 8.0
			draw_arc(center, minimum_radius, start_angle, start_angle + TAU / 16.0, 5, Color("8bd7c7"), 1.5, true)
	elif ready:
		color = Color("8bd7c7")
	draw_circle(center, radius, Color(color.r, color.g, color.b, 0.12), true, -1.0, true)
	draw_arc(center, radius, 0.0, TAU, 64, color, 2.0, true)
	draw_circle(center, 2.5, color, true, -1.0, true)


func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
