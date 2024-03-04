extends Node

## 用于保持和直播间长连的websocket节点，主要用于接收直播间消息
## 必须作为BLive节点的子节点使用

class_name WssClient

## 当收到弹幕消息后会发送此信号
signal danmaku_received(data)
## 当收到礼物后会发送此信号
signal gift_received(data)
## 当收到superchat后会发送此信号
signal superchat_added(data)
## 当收到superchat被移除后发送此信号
signal superchat_removed(data)
## 当收到上舰消息后会发送此信号
signal guard_hired(data)
## 当收到点赞后会发送此信号
signal like(data)

class Proto:
	var operation:int
	var body:PackedByteArray
	
var _sended = false
var _is_start = false

enum Version {
		PLAIN = 0,
		COMPRESSED = 2,
	}

enum Operation{
	OP_HEARTBEAT=2,#客户端发送的心跳包(30秒发送一次)
	OP_HEARTBEAT_REPLY=3,#服务器收到心跳包的回复
	OP_SEND_SMS_REPLY=5,#服务器推送的弹幕消息包
	OP_AUTH=7,#客户端发送的鉴权包(客户端发送的第一个包)
	OP_AUTH_REPLY=8,#服务器收到鉴权包后的回复
}
signal _ws_connected()

var _ws_client = WebSocketPeer.new()

func _ready():
	#保留
	pass

func _connect_to_ws(ws_url):
	_ws_client.connect_to_url(ws_url)
	_is_start = true
	pass
	
	
func _process(delta):
	if _is_start == true:
		_ws_client.poll()
		var _state = _ws_client.get_ready_state()
		if _state == WebSocketPeer.STATE_OPEN:
			if _sended == false:
				emit_signal("_ws_connected")
				_sended = true
			while _ws_client.get_available_packet_count():
				var _ws_pack = _ws_client.get_packet()
				print("数据包：", _ws_pack)
				_on_ws_data_received(_ws_pack)
		elif _state == WebSocketPeer.STATE_CLOSING:
			# 继续轮询才能正确关闭。
			pass
		elif _state == WebSocketPeer.STATE_CLOSED:
			_sended == false
			var code = _ws_client.get_close_code()
			var reason = _ws_client.get_close_reason()
			print("WebSocket 已关闭，代码：%d，原因 %s。干净得体：%s" % [code, reason, code != -1])
			set_process(false) # 停止处理。


func _pack(body:PackedByteArray,operation:int) -> void:
		var buffer := StreamPeerBuffer.new()
		buffer.big_endian = true
		buffer.put_32(16 + body.size())
		buffer.put_16(16)
		buffer.put_16(0)
		buffer.put_32(operation)
		buffer.put_32(0)
		buffer.put_data(body)
		_ws_client.put_packet(buffer.data_array)
		
		
func _unpack(data: PackedByteArray) -> Array: # [Proto]
		var buffer := StreamPeerBuffer.new()
		buffer.big_endian = true
		buffer.data_array = data
		var result := []
		__unpack(buffer, result)
		return result
		
func __unpack(buffer: StreamPeerBuffer, protos: Array) -> int:
		var packet_length := buffer.get_32()
		var header_length := buffer.get_16()
		if header_length != 16:
			push_warning("Invalid header length: %d" % header_length)
			return FAILED
		
		var version := buffer.get_16()
		var operation := buffer.get_32()
		
		buffer.seek(buffer.get_position() + 4)
		
		var raw := buffer.get_data(packet_length - header_length)
		if raw[0]:
			push_warning("Not enough body data")
			return raw[0]
		
		match version:
			Version.PLAIN:
				var proto := Proto.new()
				proto.operation = operation
				proto.body = raw[1]
				protos.append(proto)
				print("Version.PLAIN")
			
			Version.COMPRESSED:
				var uncompressed := StreamPeerBuffer.new()
				uncompressed.big_endian = true
				uncompressed.data_array = raw[1].decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
				var err := __unpack(uncompressed, protos)
				if err:
					return err
			_:
				push_warning("Invalid version: %d" % version)
				return FAILED
		return OK

func _on_ws_data_received(pack) -> void:
	for entry in _unpack(pack):
		match entry.operation:
			Operation.OP_HEARTBEAT_REPLY:
				# 可以获取当前人气值
				var buffer := StreamPeerBuffer.new()
				buffer.big_endian = true
				buffer.data_array = entry.body
				print("Popularity: ", buffer.get_32())
				
			Operation.OP_AUTH_REPLY:
				print("auth_success")
				emit_signal("auth_success")
			
			Operation.OP_SEND_SMS_REPLY:
				var body: Dictionary = JSON.parse_string(entry.body.get_string_from_utf8())
				var command: String = body.get("cmd")
				match command:
					"LIVE_OPEN_PLATFORM_DM":
						#print("danmaku_received")
						emit_signal("danmaku_received", body.data)
						print(body.data)
					
					"LIVE_OPEN_PLATFORM_SEND_GIFT":
						#print("gift_received")
						emit_signal("gift_received", body.data)
					
					"LIVE_OPEN_PLATFORM_SUPER_CHAT":
						#print("superchat_added")
						emit_signal("superchat_added", body.data)
					
					"LIVE_OPEN_PLATFORM_SUPER_CHAT_DEL":
						#print("superchat_removed")
						emit_signal("superchat_removed", body.data)
					
					"LIVE_OPEN_PLATFORM_GUARD":
						#print("guard_hired")
						emit_signal("guard_hired", body.data)
					"LIVE_OPEN_PLATFORM_LIKE":
						emit_signal("like", body.data)
			_:
				push_warning("Unknown operation: %d" % (entry.operation))


func _make_heartbeat():
	print("make_heartbeat")
	_pack(PackedByteArray(),Operation.OP_HEARTBEAT)
	pass
