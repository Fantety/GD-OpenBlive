extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	$BLive.connect_to_room()
	$BLive.start_application_heartbeat()
	pass # Replace with function body.


func _on_wss_client_danmaku_received(data):
	$BiliAudience.init_audience_from_json(data)
	pass # Replace with function body.
