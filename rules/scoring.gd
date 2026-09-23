class_name Scoring
extends RefCounted

## Coordinates are relative to the target center; radius 1 is the outer edge.
static func ring_score(target_local: Vector2) -> int:
	var distance: float = target_local.length()
	if distance > 1.0:
		return 0
	# Vector2 uses floats; avoid pushing an exact ring edge into the next ring.
	return clampi(11 - ceili(distance * 10.0 - 0.000001), 1, 10)
