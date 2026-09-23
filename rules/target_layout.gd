class_name TargetLayout
extends RefCounted

const CENTERS: Array[Vector2] = [Vector2(530.0, 390.0), Vector2(820.0, 390.0), Vector2(1080.0, 390.0)]
const RADII: Array[float] = [118.0, 78.0, 45.0]
const NAMES: Array[String] = ["SAFE", "STANDARD", "BOLD"]
const MAX_SCORES: Array[int] = [6, 10, 15]
const MOTION_X: Array[float] = [0.0, 55.0, 55.0]
const MOTION_Y: Array[float] = [25.0, 0.0, 25.0]
const MOTION_SPEED: Array[float] = [0.9, 1.2, 1.8]


static func centers_at(time: float) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for target: int in range(CENTERS.size()):
		var speed: float = MOTION_SPEED[target]
		positions.append(CENTERS[target] + Vector2(
			sin(time * speed) * MOTION_X[target],
			sin(time * speed) * MOTION_Y[target]
		))
	return positions


static func score_at(impact: Vector2, target_centers: Array[Vector2]) -> Dictionary:
	for target: int in range(CENTERS.size()):
		var local: Vector2 = (impact - target_centers[target]) / RADII[target]
		var ring: int = Scoring.ring_score(local)
		if ring > 0:
			var score: int = ring
			if target == 0:
				score = mini(ring, 6)
			elif target == 2:
				score = ring + 5
			return {"score": score, "ring": ring, "target": NAMES[target], "target_index": target}
	return {"score": 0, "ring": 0, "target": "MISS", "target_index": -1}
