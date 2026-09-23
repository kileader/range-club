class_name BuildDef
extends Resource

@export var id: StringName
@export var operator_name: String
@export var operator_role: String
@export var display_name: String
@export_multiline var description: String
@export_multiline var strategy: String
@export_multiline var tradeoff: String
@export_range(0.2, 3.0, 0.05) var steering_scale: float = 1.0
@export_range(0.1, 1.0, 0.05) var focus_spread_scale: float = 0.8
