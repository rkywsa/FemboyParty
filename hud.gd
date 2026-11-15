extends CanvasLayer

@onready var coin_label: Label = $MarginContainer/Label

var coins: int = 0

func _ready() -> void:
	_setup_position()
	update_label()

func _setup_position() -> void:
	var margin = $MarginContainer

	margin.anchor_left = 0
	margin.anchor_top = 0
	margin.anchor_right = 0
	margin.anchor_bottom = 0

	margin.offset_left = 20
	margin.offset_top = 20
	margin.offset_right = -20
	margin.offset_bottom = -20

func add_coin(amount: int = 1) -> void:
	coins += amount
	update_label()

func update_label() -> void:
	coin_label.text = "Coins: %d" % coins
