extends Node

@export var identity_code:String
@export var app_id:int
var wss_client
var api_client
var auth

var timer:Timer


func _ready():
	if get_child_count() != 2:
		printerr("[GD-Blive Error]: This node is missing a necessary child node.")
	for i in get_children():
		if i.get_class() == "HTTPRequest":
			api_client = i
		elif i.get_class() == "Node":
			wss_client = i
		pass
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(Callable(self,"on_timer_timeout"))
	api_client.wss_link.connect(Callable(self,"on_api_client_wss_link"))
	wss_client.ws_connected.connect(Callable(self,"on_wss_client_ws_connected"))
	pass # Replace with function body.

func connect_to_room():
	var data = {
		"code":identity_code,
		"app_id":app_id
	}
	api_client.start_request(data,0)
	pass
	
	
func on_api_client_wss_link(link, auth_body):
	auth = auth_body
	wss_client.connect_to_ws(link[0])
	pass
	
	
func on_wss_client_ws_connected():
	wss_client.pack(auth,7)
	timer.start(20)
	pass # Replace with function body.



func on_timer_timeout():
	wss_client.make_heartbeat()
	pass # Replace with function body.
# Called when the node enters the scene tree for the first time.


