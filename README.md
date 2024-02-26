# GD-OpenBLive

bilibili直播开放平台Godot插件，仅支持Godot4.2+版本

![](./doc/bilibili.svg)

### 新节点

| 节点        | 描述                                                                 |
| --------- | ------------------------------------------------------------------ |
| BLive     | 用于启动服务的节点，可以通过它连接至弹幕服务器，必须identity_code属性中填入你的身份码，必须在app_id中填入项目ID |
| WssClient | 与websocket相关的节点，必须作为BLive的子节点使用，其中包含了不同弹幕种类相关的信号                   |
| ApiClient | 与API鉴权相关的节点，必须作为BLive的子节点使用，属性access_key_secret和access_key_id为必填项  |

### 详细说明

##### Blive

- connect_to_room() 只需执行此函数即可连接至对应的主播房间

##### WssClient

- signal danmaku_received(data)
  
  接收到弹幕后会发送此信号，data为原始json数据

- signal gift_received(data)
  
  接收到礼物幕后会发送此信号，data为原始json数据

- signal superchat_added(data)
  
  收到superchat后会发送此信号，data为原始json数据

- signal superchat_removed(data)
  
  superchat移除后会发送此信号，data为原始json数据

- signal guard_hired(data)
  
  收到舰长后会发送此信号，data为原始json数据

- signal like(data)
  
  收到点赞后会发送此信号，data为原始json数据


