extends HTTPRequest


signal wss_link(link:String,auth_body)

var start_route

var ctx = HMACContext.new()

@export var access_key_secret:String
@export var access_key_id:String

var current_api

const main_url = "https://live-open.biliapi.com"
# Called when the node enters the scene tree for the first time.
func _ready():
	request_completed.connect(_on_request_completed)
	pass # Replace with function body.


func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if current_api == 0:
		emit_signal("wss_link",json["data"]["websocket_info"]["wss_link"],json["data"]["websocket_info"]["auth_body"].to_utf8_buffer())
		pass
	print(json)
# Called every frame. 'delta' is the elapsed time since the previous frame.

func start_request(body,api):
	if api == 0:
		current_api = 0
		start_route = "/v2/app/start"
	elif api == 1:
		current_api = 1
		start_route = "/v2/app/end"
	request(main_url+start_route, get_http_header(body), HTTPClient.METHOD_POST, JSON.stringify(body))
	pass


func get_http_header(body:Dictionary):
	var headers = ["x-bili-accesskeyid:"+access_key_id,
					"x-bili-content-md5:"+get_body_md5(body),
					"x-bili-signature-method:HMAC-SHA256",
					"x-bili-signature-nonce:"+String.num(randi()),
					"x-bili-signature-version:1.0",
					"x-bili-timestamp:"+get_timetamp()]
	var sign_string:String
	var count = 0
	for i in headers:
		sign_string = sign_string+i
		count = count+1
		if count < 6:
			sign_string = sign_string+"\n"
		pass
	headers.append("Authorization:"+get_signature(sign_string))
	headers.append("Accept:application/json")
	headers.append("Content-Type:application/json")
	return headers
	pass


func get_timetamp() -> String:
	return String.num(int(Time.get_unix_time_from_system()))
	

func get_body_md5(body:Dictionary) -> String:
	return JSON.stringify(body).md5_text()

func get_signature(chunk: String) -> String:
	var err := ctx.start(HashingContext.HASH_SHA256, access_key_secret.to_utf8_buffer())
	if err:
		printerr("OpenBlive: failed to start HMAC context.")
		return String()
	err = ctx.update(chunk.to_utf8_buffer())
	if err:
		printerr("OpenBlive: failed to update HMAC context.")
		ctx.finish()
		return String()
	return ctx.finish().hex_encode()
