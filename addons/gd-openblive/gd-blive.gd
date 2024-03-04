extends Node

## 用于控制直播间连接，应用开启，心跳，关闭的核心对象
## 必须作为WssClient和ApiClient这两个节点的父节点

class_name BLive

## 主播的身份码
@export var identity_code:String
## 应用的AppID 在bilibili创作者服务中心我的项目中查看
@export var app_id:int


var _wss_client
var _api_client
var _auth
var _game_id

var _timer:Timer


func _ready():
	if get_child_count() != 2:
		printerr("[GD-Blive Error]: This node is missing a necessary child node.")
	for i in get_children():
		if i.get_class() == "HTTPRequest":
			_api_client = i
		elif i.get_class() == "Node":
			_wss_client = i
		pass
	_timer = Timer.new()
	add_child(_timer)
	_timer.timeout.connect(Callable(self,"_on_timer_timeout"))
	_api_client.wss_link.connect(Callable(self,"_on_api_client_wss_link"))
	_wss_client._ws_connected.connect(Callable(self,"_on_wss_client_ws_connected"))
	pass # Replace with function body.

## 连接到直播间就用它
func connect_to_room():
	var data = {
		"code":identity_code,
		"app_id":app_id
	}
	_api_client._start_request(data,0)
	pass
	
## 关闭应用就用它
func end_application():
	var data = {
		"code":identity_code,
		"app_id":_api_client.get_game_id()
	}
	_api_client._start_request(data,1)
	pass
	
## 启动应用心跳包就用它
func start_application_heartbeat():
	_api_client._start_heartbeat()
	pass

func _on_api_client_wss_link(link, auth_body):
	_auth = auth_body
	_wss_client._connect_to_ws(link[0])
	pass
	
	
func _on_wss_client_ws_connected():
	_wss_client._pack(_auth,7)
	_timer.start(20)
	pass # Replace with function body.



func _on_timer_timeout():
	_wss_client._make_heartbeat()
	pass # Replace with function body.
# Called when the node enters the scene tree for the first time.


