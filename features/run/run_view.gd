class_name RunView
extends CanvasLayer

signal upgrade_selected(upgrade_id: StringName)
signal new_run_requested

@onready var heading: Label = $Panel/Heading
@onready var summary: Label = $Panel/Summary
@onready var next_trial: Label = $Panel/NextTrial
@onready var installed: Label = $Panel/Installed
@onready var offer_buttons: Array[Button] = [$Panel/OfferOne, $Panel/OfferTwo, $Panel/OfferThree]
@onready var new_run_button: Button = $Panel/NewRunButton

var _offers: Array[StringName] = []


func _ready() -> void:
	offer_buttons[0].pressed.connect(func() -> void: _choose(0))
	offer_buttons[1].pressed.connect(func() -> void: _choose(1))
	offer_buttons[2].pressed.connect(func() -> void: _choose(2))
	new_run_button.pressed.connect(func() -> void: new_run_requested.emit())
	visible = false


func show_reward(completed_stage: int, score: int, next_id: StringName, offers: Array[StringName], upgrades: Array[StringName], character: String) -> void:
	_offers = offers.duplicate()
	heading.text = "TRIAL %d CLEARED" % (completed_stage + 1)
	summary.text = "%s scored %d. Choose one rig module for the next trial." % [character, score]
	next_trial.text = "NEXT · %s · %d–%d\n%s" % [RunRules.scenario_title(next_id), RunRules.goal_for_stage(completed_stage + 1), RunRules.cap_for_stage(completed_stage + 1), RunRules.scenario_rule(next_id)]
	installed.text = "INSTALLED · %s" % _upgrade_list(upgrades)
	for index: int in range(offer_buttons.size()):
		var button: Button = offer_buttons[index]
		button.visible = index < _offers.size()
		if button.visible:
			button.text = "%s\n\n%s\n\nINSTALL" % [RunRules.upgrade_title(_offers[index]), RunRules.upgrade_rule(_offers[index])]
	new_run_button.visible = false
	visible = true


func show_result(won: bool, stage: int, score: int, upgrades: Array[StringName], character: String) -> void:
	_offers.clear()
	heading.text = "RUN COMPLETE" if won else "RUN ENDED"
	summary.text = "%s · Trial %d / %d · %d points" % [character, stage + 1, RunRules.TRIAL_COUNT, score]
	next_trial.text = "Three trials cleared." if won else "The score missed the window or went over the cap."
	installed.text = "INSTALLED · %s" % _upgrade_list(upgrades)
	for button: Button in offer_buttons:
		button.visible = false
	new_run_button.visible = true
	visible = true


func hide_screen() -> void:
	visible = false


func _choose(index: int) -> void:
	if index < _offers.size():
		upgrade_selected.emit(_offers[index])


func _upgrade_list(upgrades: Array[StringName]) -> String:
	if upgrades.is_empty():
		return "NONE"
	var names: PackedStringArray = []
	for upgrade_id: StringName in upgrades:
		names.append(RunRules.upgrade_title(upgrade_id))
	return ", ".join(names)
