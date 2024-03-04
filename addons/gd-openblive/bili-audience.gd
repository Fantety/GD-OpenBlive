extends Sprite2D

## 这个节点用于转化弹幕数据
class_name BiliAudience

## 弹幕消息
var b_msg:String
## 用户UID
var b_uid:int
## 用户名称
var b_uname:String
## 头像URL
var b_uface:String
## 粉丝牌等级
var b_fans_medal_level:int
## 头像纹理
var b_head_img:ImageTexture

## 头像图片的大小
@export var img_size:Vector2i:
	set(value):
		img_size = value
	get:
		return img_size

var _head_img_httprequest:HTTPRequest
# Called when the node enters the scene tree for the first time.
func _ready():
	_head_img_httprequest = HTTPRequest.new()
	_head_img_httprequest.request_completed.connect(_on_head_img_httprequest)
	add_child(_head_img_httprequest)
	pass # Replace with function body.

## 用于初始化该节点
func init_audience_from_json(json:Dictionary):
	b_msg = json.get("msg")
	b_uid = json.get("uid")
	b_uname = json.get("uname")
	b_uface = json.get("uface")
	b_fans_medal_level = json.get("fans_medal_level")
	_head_img_httprequest.download_file = "user://"+String.num(b_uid)+".jpg"
	_do_http_request_head_img()
	pass

func _do_http_request_head_img():
	if FileAccess.open(_head_img_httprequest.download_file, FileAccess.READ) != null:
		var image = Image.load_from_file(_head_img_httprequest.download_file)
		b_head_img = ImageTexture.create_from_image(image)
		b_head_img.set_size_override(img_size)
		self.texture = b_head_img
		pass
	else:
		_head_img_httprequest.request(b_uface)


func _on_head_img_httprequest(result, response_code, headers, body):
	if response_code == 200:
		var image = Image.load_from_file(_head_img_httprequest.download_file)
		b_head_img = ImageTexture.create_from_image(image)
		b_head_img.set_size_override(img_size)
		self.texture = b_head_img
	pass

