@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("BLive", "Node", preload("gd-blive.gd"), preload("assets/bilibili.svg"))
	add_custom_type("ApiClient", "HTTPRequest", preload("api_client.gd"), preload("assets/bilibili.svg"))
	add_custom_type("WssClient", "Node", preload("wss_client.gd"), preload("assets/bilibili.svg"))
	add_custom_type("BiliAudience", "Sprite2D", preload("bili-audience.gd"), preload("assets/bilibili.svg"))
	# Initialization of the plugin goes here.
	pass


func _exit_tree():
	remove_custom_type("BLive")
	remove_custom_type("ApiClient")
	remove_custom_type("WssClient")
	remove_custom_type("BiliAudience")
	# Clean-up of the plugin goes here.
	pass
