class_name TrialRules
extends RefCounted

const SHOTS_PER_TRIAL: int = 5
const GOAL_SCORE: int = 48
const BUST_SCORE: int = 52
const START_FOCUS: int = 1
const MAX_FOCUS: int = 2
const SAFE_FOCUS_RING: int = 6
const MAERA_FOCUS_RING: int = 6
const MAERA_STANDARD_BONUS: int = 3
const VEY_TEMPO_RING: int = 8
const VEY_TEMPO_SECONDS: float = 1.2


static func is_bust(score: int, cap: int = BUST_SCORE) -> bool:
	return score > cap


static func is_cleared(score: int, goal: int = GOAL_SCORE, cap: int = BUST_SCORE) -> bool:
	return score >= goal and not is_bust(score, cap)


static func is_trial_over(score: int, shots_taken: int, goal: int = GOAL_SCORE, cap: int = BUST_SCORE) -> bool:
	return is_cleared(score, goal, cap) or is_bust(score, cap) or shots_taken >= SHOTS_PER_TRIAL


static func resolve_hit(
	hit: Dictionary, build_id: StringName, spent_focus: bool, shot_time: float,
	scenario_id: StringName = &"triad", upgrades: Array[StringName] = [], shot_number: int = 1
) -> Dictionary:
	var points: int = hit.score
	var bonus: String = ""
	var focus_gain: int = 0
	if points > 0:
		if hit.target_index == 0 and hit.ring >= SAFE_FOCUS_RING:
			focus_gain = 1
		elif hit.target_index == 1 and build_id == &"gyro_brace" and spent_focus and hit.ring >= MAERA_FOCUS_RING:
			points += MAERA_STANDARD_BONUS
			bonus = "BRACED +3"
		elif hit.target_index > 0 and build_id == &"bare_rig" and not spent_focus and hit.ring == 10:
			points += 2
			bonus = "PRECISION +2"
		elif hit.target_index > 0 and build_id == &"pulse_sight" and hit.ring >= VEY_TEMPO_RING and shot_time <= VEY_TEMPO_SECONDS:
			points += 3
			bonus = "QUICK HIT +3"
		match scenario_id:
			&"safe_circuit":
				if hit.target_index == 0 and hit.ring >= SAFE_FOCUS_RING:
					points += 3
					bonus = _append_bonus(bonus, "CIRCUIT +3")
			&"standard_relay":
				if hit.target_index == 1 and hit.ring >= 6:
					points += 2
					bonus = _append_bonus(bonus, "RELAY +2")
			&"bold_surge":
				if hit.target_index == 2:
					points += 3
					bonus = _append_bonus(bonus, "SURGE +3")
		if upgrades.has(&"anchor_coil") and hit.target_index == 0 and hit.ring >= SAFE_FOCUS_RING:
			points += 2
			bonus = _append_bonus(bonus, "ANCHOR +2")
		if upgrades.has(&"prism_lens") and hit.target_index == 1 and hit.ring >= 4 and hit.ring <= 7:
			points += 3
			bonus = _append_bonus(bonus, "PRISM +3")
		if upgrades.has(&"edge_fuse") and hit.target_index == 2 and hit.ring <= 5:
			points += 3
			bonus = _append_bonus(bonus, "EDGE +3")
		if upgrades.has(&"recirculator") and spent_focus and hit.target_index == 1 and hit.ring >= 6:
			focus_gain += 1
			bonus = _append_bonus(bonus, "FOCUS REFUND")
		if upgrades.has(&"last_light") and shot_number == SHOTS_PER_TRIAL and hit.target_index == 0:
			points += 4
			bonus = _append_bonus(bonus, "LAST LIGHT +4")
	return {"points": points, "focus_gain": focus_gain, "bonus": bonus}


static func _append_bonus(current: String, next: String) -> String:
	return next if current.is_empty() else current + " · " + next
