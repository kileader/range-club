class_name ImpactRecord
extends RefCounted

var target_index: int
var point: Vector2
var direction: Vector2


func _init(hit_target: int, stored_point: Vector2, travel_direction: Vector2) -> void:
	target_index = hit_target
	point = stored_point
	# A coincident origin/impact has no travel direction; keep its mark visible.
	direction = Vector2.UP if travel_direction.is_zero_approx() else travel_direction.normalized()


func position_at(target_centers: Array[Vector2]) -> Vector2:
	if target_index >= 0:
		return target_centers[target_index] + point
	return point
