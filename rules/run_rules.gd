class_name RunRules
extends RefCounted

const TRIAL_COUNT: int = 3
const SCENARIO_POOL: Array[StringName] = [&"safe_circuit", &"standard_relay", &"bold_surge"]
const UPGRADE_POOL: Array[StringName] = [&"anchor_coil", &"stabilizing_sight", &"edge_fuse", &"recirculator", &"last_light"]


static func goal_for_stage(stage: int) -> int:
	return TrialRules.GOAL_SCORE + stage * 4


static func cap_for_stage(stage: int) -> int:
	return TrialRules.BUST_SCORE + stage * 4


static func draw_scenarios(rng: RandomNumberGenerator) -> Array[StringName]:
	var remaining: Array[StringName] = SCENARIO_POOL.duplicate()
	var order: Array[StringName] = [&"triad"]
	for stage: int in range(1, TRIAL_COUNT):
		order.append(remaining.pop_at(rng.randi_range(0, remaining.size() - 1)))
	return order


static func draw_offers(owned: Array[StringName], rng: RandomNumberGenerator) -> Array[StringName]:
	var remaining: Array[StringName] = []
	for upgrade_id: StringName in UPGRADE_POOL:
		if not owned.has(upgrade_id):
			remaining.append(upgrade_id)
	var offers: Array[StringName] = []
	for pick: int in range(mini(3, remaining.size())):
		offers.append(remaining.pop_at(rng.randi_range(0, remaining.size() - 1)))
	return offers


static func scenario_title(id: StringName) -> String:
	match id:
		&"safe_circuit": return "SAFE CIRCUIT"
		&"standard_relay": return "STANDARD RELAY"
		&"bold_surge": return "BOLD SURGE"
		_: return "TRIAD TRIAL"


static func scenario_rule(id: StringName) -> String:
	match id:
		&"safe_circuit": return "Safe inner hits score +3 and still restore Focus."
		&"standard_relay": return "Standard inner hits score +2."
		&"bold_surge": return "Any Bold hit scores +3. Watch the bust cap."
		_: return "Base target scoring."


static func upgrade_title(id: StringName) -> String:
	match id:
		&"anchor_coil": return "ANCHOR COIL"
		&"stabilizing_sight": return "STABILIZING SIGHT"
		&"edge_fuse": return "EDGE FUSE"
		&"recirculator": return "RECIRCULATOR"
		&"last_light": return "LAST LIGHT"
		_: return "UNKNOWN"


static func upgrade_rule(id: StringName) -> String:
	match id:
		&"anchor_coil": return "Safe inner hits\nscore +2."
		&"stabilizing_sight": return "Smallest landing circle holds\nfor 0.7s before widening."
		&"edge_fuse": return "Bold outer rings 1–5\nscore +3."
		&"recirculator": return "Focused Standard inner\nhits refund Focus."
		&"last_light": return "Safe hits score +4\non shot five."
		_: return ""
