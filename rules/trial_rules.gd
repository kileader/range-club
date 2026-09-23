class_name TrialRules
extends RefCounted

const SHOTS_PER_TRIAL: int = 5
const GOAL_SCORE: int = 55
const BUST_SCORE: int = 60
const START_FOCUS: int = 1
const MAX_FOCUS: int = 2
const SAFE_FOCUS_RING: int = 6
const VEY_TEMPO_RING: int = 8
const VEY_TEMPO_SECONDS: float = 1.2


static func is_bust(score: int) -> bool:
	return score > BUST_SCORE


static func is_cleared(score: int) -> bool:
	return score >= GOAL_SCORE and not is_bust(score)


static func is_trial_over(score: int, shots_taken: int) -> bool:
	return is_cleared(score) or is_bust(score) or shots_taken >= SHOTS_PER_TRIAL


static func resolve_hit(hit: Dictionary, build_id: StringName, spent_focus: bool, shot_time: float) -> Dictionary:
	var points: int = hit.score
	var bonus: String = ""
	var focus_gain: int = 0
	if points > 0:
		if hit.target_index == 0 and hit.ring >= SAFE_FOCUS_RING:
			focus_gain = 1
		elif hit.target_index > 0 and build_id == &"bare_rig" and not spent_focus and hit.ring == 10:
			points += 2
			bonus = "PRECISION +2"
		elif hit.target_index > 0 and build_id == &"pulse_sight" and hit.ring >= VEY_TEMPO_RING and shot_time <= VEY_TEMPO_SECONDS:
			points += 3
			bonus = "QUICK HIT +3"
	return {"points": points, "focus_gain": focus_gain, "bonus": bonus}
