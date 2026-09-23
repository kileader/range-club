class_name TargetLayout
extends RefCounted

const CENTERS: Array[Vector2] = [Vector2(530.0, 390.0), Vector2(820.0, 390.0), Vector2(1080.0, 390.0)]
const RADII: Array[float] = [118.0, 78.0, 45.0]
const NAMES: Array[String] = ["SAFE", "STANDARD", "BOLD"]
const MAX_SCORES: Array[int] = [6, 10, 15]


static func score_at(impact: Vector2) -> Dictionary:
	for target: int in range(CENTERS.size()):
		var local: Vector2 = (impact - CENTERS[target]) / RADII[target]
		var ring: int = Scoring.ring_score(local)
		if ring > 0:
			var score: int = ring
			if target == 0:
				score = mini(ring, 6)
			elif target == 2:
				score = ring + 5
			return {"score": score, "ring": ring, "target": NAMES[target]}
	return {"score": 0, "ring": 0, "target": "MISS"}
