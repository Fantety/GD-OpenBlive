extends HTTPRequest

## 用于获取直播间长链，开启应用，开启应用心跳，关闭应用的http节点
## 必须作为BLive的子节点使用

class_name ApiClient

signal wss_link(link:String,auth_body)

var start_route

## 开启应用后服务器返回的应用唯一标识game_id，将用于关闭应用和应用心跳包的body
var game_id:
	get:
		return game_id

## SHA256鉴权，用于签名生成，不要单独用它！！！！
var _ctx = HMACContext.new()

## Access Key Secret 在bilibili创作者服务中心个人资料中查看
@export var access_key_secret:String
## Access Key Id 在bilibili创作者服务中心个人资料中查看
@export var access_key_id:String

var current_api

const main_url = "https://live-open.biliapi.com"

var _app_heartbeat_request:HTTPRequest
var _timer:Timer
# Called when the node enters the scene tree for the first time.
func _ready():
	_app_heartbeat_request = HTTPRequest.new()
	_timer = Timer.new()
	add_child(_app_heartbeat_request)
	add_child(_timer)
	_timer.timeout.connect(Callable(self,"_heartbeat_unit"))
	_app_heartbeat_request.request_completed.connect(_on_heartbeat_request_completed)
	request_completed.connect(_on_request_completed)
	pass # Replace with function body.

func _on_heartbeat_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if current_api == 0:
		print("[Application Hearbeat respond]: ",json)
		pass
	print(json)
	pass


func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if current_api == 0:
		emit_signal("wss_link",json["data"]["websocket_info"]["wss_link"],json["data"]["websocket_info"]["auth_body"].to_utf8_buffer())
		game_id = json["data"]["game_info"]["game_id"]
		pass
	print(json)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _start_heartbeat():
	_timer.start(15)
	pass
	
	
func _heartbeat_unit():
	var data = {
		"game_id":game_id
	}
	_app_heartbeat_request.request(main_url+"/v2/app/heartbeat", _get_http_header(data), HTTPClient.METHOD_POST, JSON.stringify(data))
	pass

func _start_request(body,api):
	if api == 0:
		current_api = 0
		start_route = "/v2/app/start"
	elif api == 1:
		current_api = 1
		start_route = "/v2/app/end"
	request(main_url+start_route, _get_http_header(body), HTTPClient.METHOD_POST, JSON.stringify(body))
	pass


func _get_http_header(body:Dictionary):
	var headers = ["x-bili-accesskeyid:"+access_key_id,
					"x-bili-content-md5:"+_get_body_md5(body),
					"x-bili-signature-method:HMAC-SHA256",
					"x-bili-signature-nonce:"+String.num(randi()),
					"x-bili-signature-version:1.0",
					"x-bili-timestamp:"+_get_timetamp()]
	var sign_string:String
	var count = 0
	for i in headers:
		sign_string = sign_string+i
		count = count+1
		if count < 6:
			sign_string = sign_string+"\n"
		pass
	headers.append("Authorization:"+_get_signature(sign_string))
	headers.append("Accept:application/json")
	headers.append("Content-Type:application/json")
	return headers
	pass


func _get_timetamp() -> String:
	return String.num(int(Time.get_unix_time_from_system()))
	

func _get_body_md5(body:Dictionary) -> String:
	return JSON.stringify(body).md5_text()

func _get_signature(chunk: String) -> String:
	var err := _ctx.start(HashingContext.HASH_SHA256, access_key_secret.to_utf8_buffer())
	if err:
		printerr("OpenBlive: failed to start HMAC context.")
		return String()
	err = _ctx.update(chunk.to_utf8_buffer())
	if err:
		printerr("OpenBlive: failed to update HMAC context.")
		_ctx.finish()
		return String()
	return _ctx.finish().hex_encode()
