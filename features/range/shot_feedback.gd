class_name ShotFeedback
extends Node2D
## Presentation clock only. The controller has already scored the release snapshot.

signal impact_reached
signal finished

enum ResultSound { NONE, CLEAR, BUST, FAIL }

@export_range(0.1, 0.5) var flight_seconds: float = 0.22
@export_range(0.1, 1.0) var recovery_seconds: float = 0.38
@export_range(0.3, 2.0) var result_recovery_seconds: float = 0.82
@export_group("Impact and result audio")
@export var hit_sound: AudioStream
@export var miss_sound: AudioStream
@export var clear_sound: AudioStream
@export var bust_sound: AudioStream
@export var fail_sound: AudioStream

@onready var release_player: AudioStreamPlayer = $ReleaseSound
@onready var impact_player: AudioStreamPlayer = $ImpactSound
@onready var result_player: AudioStreamPlayer = $ResultSound
@onready var score_popup: Label = $ScorePopup

var active: bool = false
var has_landed: bool = false
var elapsed: float = 0.0
var _origin: Vector2
var _impact: Vector2
var _points: int = 0
var _result: ResultSound = ResultSound.NONE
var _result_played: bool = false


func start(origin: Vector2, impact: Vector2, points: int, result: ResultSound) -> void:
	reset()
	_origin = origin
	_impact = impact
	_points = points
	_result = result
	active = true
	visible = true
	score_popup.text = "+%d" % points if points > 0 else "MISS"
	score_popup.modulate = Color("ffe2a0") if points > 0 else Color("c3cfcc")
	release_player.play()
	queue_redraw()


func reset() -> void:
	active = false
	has_landed = false
	elapsed = 0.0
	_result_played = false
	release_player.stop()
	impact_player.stop()
	result_player.stop()
	score_popup.hide()
	queue_redraw()


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if not has_landed and elapsed >= flight_seconds:
		has_landed = true
		impact_player.stream = hit_sound if _points > 0 else miss_sound
		impact_player.play()
		score_popup.show()
		impact_reached.emit()
	if _result != ResultSound.NONE and not _result_played and elapsed >= flight_seconds + 0.14:
		_result_played = true
		match _result:
			ResultSound.CLEAR: result_player.stream = clear_sound
			ResultSound.BUST: result_player.stream = bust_sound
			ResultSound.FAIL: result_player.stream = fail_sound
		result_player.play()
	var impact_age: float = maxf(elapsed - flight_seconds, 0.0)
	score_popup.position = Vector2(clampf(_impact.x - 64.0, 398.0, 1080.0), maxf(_impact.y - 54.0 - impact_age * 32.0, 130.0))
	score_popup.modulate.a = clampf(1.0 - maxf(impact_age - 0.3, 0.0) * 2.0, 0.0, 1.0)
	var recovery: float = result_recovery_seconds if _result != ResultSound.NONE else recovery_seconds
	if elapsed >= flight_seconds + recovery:
		active = false
		score_popup.hide()
		finished.emit()
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	if not has_landed:
		var progress: float = clampf(elapsed / flight_seconds, 0.0, 1.0)
		var point: Vector2 = _origin.lerp(_impact, progress)
		var direction: Vector2 = (_impact - _origin).normalized()
		var normal: Vector2 = direction.orthogonal()
		var tail: Vector2 = point - direction * lerpf(44.0, 22.0, progress)
		draw_line(tail - direction * 22.0, point, Color(1.0, 0.8, 0.4, 0.16), 8.0, true)
		draw_line(tail, point, Color("f5dda4"), 2.5, true)
		draw_colored_polygon(PackedVector2Array([point + direction * 5.0, point - direction * 5.0 + normal * 3.5, point - direction * 5.0 - normal * 3.5]), Color("fff0cb"))
		draw_line(tail + normal * 4.0, tail + direction * 9.0, Color("83d6ca"), 2.0, true)
		draw_line(tail - normal * 4.0, tail + direction * 9.0, Color("83d6ca"), 2.0, true)
	else:
		var age: float = elapsed - flight_seconds
		var fade: float = maxf(1.0 - age / 0.38, 0.0)
		var tint: Color = Color("ffd27e") if _points > 0 else Color("98aaa5")
		tint.a = fade
		draw_arc(_impact, 5.0 + age * 85.0, 0.0, TAU, 32, tint, 2.0, true)
		for index: int in range(9):
			var direction: Vector2 = Vector2.from_angle(index * TAU / 9.0 + 0.2)
			var distance: float = age * (62.0 + (index % 3) * 24.0)
			var point: Vector2 = _impact + direction * distance + Vector2(0.0, age * age * 65.0)
			draw_line(point, point + direction * 5.0 * fade, tint, 2.0, true)
