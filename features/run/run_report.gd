class_name RunReport
extends Control
## Draws a read-only summary supplied by the controller; never resolves a shot.

const CREAM: Color = Color("f2ede0")
const GOLD: Color = Color("edbc4c")
const CYAN: Color = Color("8bd7c7")
const MUTED: Color = Color("a7b7a6")
const INK: Color = Color("112019")
const PORTRAITS: Dictionary = {
	&"bare_rig": preload("res://assets/art/concepts/natural_portrait_concept_v1.png"),
	&"gyro_brace": preload("res://assets/art/concepts/maera_portrait_concept_v1.png"),
	&"pulse_sight": preload("res://assets/art/concepts/vey_portrait_concept_v1.png"),
}

var _stats: Dictionary = {}
var _character: BuildDef
var _upgrades: Array[StringName] = []


func present(stats: Dictionary, character: BuildDef, upgrades: Array[StringName]) -> void:
	_stats = stats.duplicate(true)
	_character = character
	_upgrades = upgrades.duplicate()
	queue_redraw()


func _draw() -> void:
	if _stats.is_empty():
		return
	# The same three-trial motif as the range, kept beside the result heading.
	for index: int in range(RunRules.TRIAL_COUNT):
		var cleared: bool = _stats.trials[index].status == "CLEARED"
		var center: Vector2 = Vector2(800 + index * 46, -83)
		draw_circle(center, 15.0, CYAN if cleared else Color("2d4637"), false, 1.5, true)
		_text(center + Vector2(-4, 5), str(index + 1), 13, CYAN if cleared else MUTED)
	_card(Rect2(0, 0, 568, 122), INK)
	draw_line(Vector2(282, 20), Vector2(282, 102), Color("2d4637"), 1.0)
	_text(Vector2(22, 27), "TOTAL SCORE", 12, MUTED)
	_text(Vector2(22, 83), str(_stats.total_score), 56, GOLD)
	_text(Vector2(22, 108), "%d arrows across the run" % _stats.shots, 12, MUTED)
	_text(Vector2(320, 27), "ACCURACY · TARGET HITS", 12, MUTED)
	var accuracy: float = float(_stats.hits) / _stats.shots if int(_stats.shots) > 0 else 0.0
	_text(Vector2(320, 78), "%d%%" % roundi(accuracy * 100.0) if int(_stats.shots) > 0 else "—", 46, CYAN)
	_text(Vector2(320, 108), "%d hits / %d arrows" % [_stats.hits, _stats.shots], 12, MUTED)
	draw_rect(Rect2(320, 86, 226, 3), Color("2d4637"))
	draw_rect(Rect2(320, 86, 226 * accuracy, 3), CYAN)
	var values: Array[String] = ["%d pts" % _stats.best_shot, str(_stats.bullseyes), "%d hits" % _stats.longest_streak]
	var labels: Array[String] = ["BEST SHOT", "BULLSEYES · RING 10", "LONGEST HIT STREAK"]
	for index: int in range(values.size()):
		var x: float = index * 194.0
		_text(Vector2(x, 151), labels[index], 11, MUTED)
		_text(Vector2(x, 181), values[index], 25, CREAM)
	_text(Vector2(0, 221), "TRIAL LOG", 12, CYAN)
	_text(Vector2(242, 221), "WINDOW", 10, MUTED)
	_text(Vector2(320, 221), "ARROWS", 10, MUTED)
	_text(Vector2(398, 221), "PTS", 10, MUTED)
	for index: int in range(RunRules.TRIAL_COUNT):
		var row: Dictionary = _stats.trials[index]
		var y: float = 232.0 + index * 38.0
		var reached: bool = row.status != "NOT REACHED"
		var tint: Color = CYAN if row.status == "CLEARED" else (Color("e28a70") if reached else MUTED)
		_card(Rect2(0, y, 568, 34), Color("203328"))
		_text(Vector2(12, y + 22), "%02d" % (index + 1), 12, tint)
		_text(Vector2(44, y + 22), RunRules.scenario_title(row.scenario), 12, CREAM if reached else MUTED)
		_text(Vector2(244, y + 22), "%d–%d" % [RunRules.goal_for_stage(index), RunRules.cap_for_stage(index)], 12, MUTED)
		_text(Vector2(326, y + 22), "%d / %d" % [row.shots, TrialRules.SHOTS_PER_TRIAL] if reached else "—", 12, MUTED)
		_text(Vector2(398, y + 24), str(row.score) if reached else "—", 18, CREAM)
		_text(Vector2(446, y + 22), row.status, 10, tint)
	_draw_rig()


func _draw_rig() -> void:
	_card(Rect2(592, 0, 324, 350), INK)
	var portrait: Texture2D = PORTRAITS[_character.id]
	var art_size: Vector2 = portrait.get_size()
	var art_scale: float = minf(100.0 / art_size.x, 128.0 / art_size.y)
	var draw_size: Vector2 = art_size * art_scale
	draw_texture_rect(portrait, Rect2(Vector2(610, 18) + (Vector2(100, 128) - draw_size) * 0.5, draw_size), false)
	_text(Vector2(728, 32), "MARKSMAN / RIG", 10, MUTED)
	_text(Vector2(728, 63), _character.operator_name.to_upper(), 21, CREAM)
	_text(Vector2(728, 83), _character.operator_role, 10, MUTED)
	_text(Vector2(728, 116), _character.display_name, 20, GOLD)
	draw_line(Vector2(610, 155), Vector2(898, 155), Color("2d4637"), 1.0)
	_text(Vector2(610, 176), "INSTALLED MODULES / %02d" % _upgrades.size(), 11, CYAN)
	if _upgrades.is_empty():
		_text(Vector2(610, 208), "BASE RIG", 15, CREAM)
		_text(Vector2(610, 232), "No modules installed", 13, MUTED)
	for index: int in range(_upgrades.size()):
		var y: float = 186.0 + index * 72.0
		_card(Rect2(610, y, 288, 64), Color("203328"))
		_text(Vector2(622, y + 20), RunRules.upgrade_title(_upgrades[index]), 13, CREAM)
		var lines: PackedStringArray = RunRules.upgrade_rule(_upgrades[index]).split("\n")
		for line: int in range(lines.size()):
			_text(Vector2(622, y + 38 + line * 14), lines[line], 11, MUTED)
	_text(Vector2(610, 336), "RANGE CLUB · LANE 3909", 10, MUTED)


func _text(at: Vector2, text: String, font_size: int, tint: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, tint)


func _card(rect: Rect2, tint: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	style.set_corner_radius_all(8)
	draw_style_box(style, rect)
