class_name ImpactRecord
extends RefCounted

var target_index: int
var point: Vector2


func _init(hit_target: int, stored_point: Vector2) -> void:
	target_index = hit_target
	point = stored_point


func position_at(target_centers: Array[Vector2]) -> Vector2:
	if target_index >= 0:
		return target_centers[target_index] + point
	return point
