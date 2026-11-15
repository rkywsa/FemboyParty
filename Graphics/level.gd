extends Node2D

@onready var backgroundmusic = $backgroundmusic
@onready var pipebye = $pipebye


func _ready() -> void:
	backgroundmusic.play()
	await get_tree().create_timer(2.38).timeout
	pipebye.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
