extends Node2D
## Presentation only. Target geometry uses a unit radius for future shot rules.

const TARGET_CENTER: Vector2 = Vector2(820.0, 416.0)
const TARGET_RADIUS: float = 248.0
const RING_COLORS: Array[Color] = [
	Color("f2ede0"), Color("e5dfd1"),
	Color("303a3b"), Color("263032"),
	Color("58a7c0"), Color("4595b0"),
	Color("d66050"), Color("c65145"),
	Color("f2cb65"), Color("edbc4c"),
]


func _draw() -> void:
	# Backstop and a pair of supports give the target a little range context.
	draw_style_box(_panel_style(Color("182720"), 24), Rect2(390, 122, 824, 598))
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


func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
