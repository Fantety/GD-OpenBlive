extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	$BLive.connect_to_room()
	pass # Replace with function body.
