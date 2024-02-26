extends Node


signal danmaku_received(data)
signal gift_received(data)
signal superchat_added(data)
signal superchat_removed(data)
signal guard_hired(data)
signal like(data)

class Proto:
	var operation:int
	var body:PackedByteArray
	

var sended = false
var is_start = false

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
signal ws_connected()

var ws_client = WebSocketPeer.new()

func _ready():
	pass

func connect_to_ws(ws_url):
	ws_client.connect_to_url(ws_url)
	is_start = true
	pass
	
	
func _process(delta):
	if is_start == true:
		ws_client.poll()
		var state = ws_client.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			if sended == false:
				emit_signal("ws_connected")
				sended = true
			while ws_client.get_available_packet_count():
				var ws_pack = ws_client.get_packet()
				print("数据包：", ws_pack)
				on_ws_data_received(ws_pack)
		elif state == WebSocketPeer.STATE_CLOSING:
			# 继续轮询才能正确关闭。
			pass
		elif state == WebSocketPeer.STATE_CLOSED:
			sended == false
			var code = ws_client.get_close_code()
			var reason = ws_client.get_close_reason()
			print("WebSocket 已关闭，代码：%d，原因 %s。干净得体：%s" % [code, reason, code != -1])
			set_process(false) # 停止处理。


func pack(body:PackedByteArray,operation:int) -> void:
		var buffer := StreamPeerBuffer.new()
		buffer.big_endian = true
		buffer.put_32(16 + body.size())
		buffer.put_16(16)
		buffer.put_16(0)
		buffer.put_32(operation)
		buffer.put_32(0)
		buffer.put_data(body)
		ws_client.put_packet(buffer.data_array)
		
		
func unpack(data: PackedByteArray) -> Array: # [Proto]
		var buffer := StreamPeerBuffer.new()
		buffer.big_endian = true
		buffer.data_array = data
		var result := []
		_unpack(buffer, result)
		return result
		
func _unpack(buffer: StreamPeerBuffer, protos: Array) -> int:
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
				var err := _unpack(uncompressed, protos)
				if err:
					return err
			_:
				push_warning("Invalid version: %d" % version)
				return FAILED
		return OK

func on_ws_data_received(pack) -> void:
	for entry in unpack(pack):
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
						#print(body.data)
					
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


func make_heartbeat():
	print("make_heartbeat")
	pack(PackedByteArray(),Operation.OP_HEARTBEAT)
	pass
