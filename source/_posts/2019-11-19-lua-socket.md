---
title: Lua5.3.5/LuaSocket编译及LuaSocket使用范例
categories:
  - 技巧
tags:
  - Socket
  - TCP
  - 通信
  - Lua
comments: true
mathjax: false
date: 2019-11-19 17:14:12
updated: 2019-11-19 17:14:12
---

## Lua编译

- 下载，http://www.lua.org/download.html
- `make clean all linux`
- `sudo make install`

## LuaSocket编译

- `sudo git clone https://github.com/diegonehab/luasocket`
- `cd luasocket`
- `sudo make clean all install LUAV=5.3`

## 使用范例

### 包引用

- `local socket = require("socket")`

### 连接

服务端

```lua
host = "*"
port = 8080
--创建TCPsoket
server = socket.bind(host, port)
--获取连接信息
i, p = server:getsockname()
--设置超时时间
socket:settimeout(5)
--等待连接
client = server:accept()
```

客户端

```lua
host = "localhost"
port = 8080
--连接
client = socket.connect(host, port)
--设置超时时间
client:settimeout(5)
```

### 接受/发送

接收端

```lua
l, e = client:receive()
```

发送端

```lua
str = "hello"
-- 发送端结尾一定要加`\n`
c:send(str .. "\n")
```

### 其他接口

- `setoption(option [, value])`：进行keepalive等设置
- `client:shutdown(mode)`：mode = [both/send/receive]，关闭全双工连接的全部或部分

## luaSocket其他功能

- DNS
- FTP
- HTTP
- LTN12
- MIME
- SMTP
- UDP
- URL

## 测试代码

Listener.lua

```lua
local socket = require("socket")
host = host or "*"
port = port or 8080
if arg then
	host = arg[1] or host
	port = arg[2] or port
end
print("Binding to host '" ..host.. "' and port " ..port.. "...")
s = assert(socket.bind(host, port))
i, p   = s:getsockname()
assert(i, p)
print("Waiting connection from talker on " .. i .. ":" .. p .. "...")
c = assert(s:accept())
print("Connected. Here is the stuff:")
l, e = c:receive()
while not e do
	print(l)
	l, e = c:receive()
end
print(e)
```

Talker.lua

```lua
local socket = require("socket")
host = host or "localhost"
port = port or 8080
if arg then
	host = arg[1] or host
	port = arg[2] or port
end
print("Attempting connection to host '" ..host.. "' and port " ..port.. "...")
c = assert(socket.connect(host, port))
print("Connected! Please type stuff (empty line to stop):")
l = "123"
i = 0
while l and l ~= "" and not e do
	assert(c:send(l .. "\n"))
	l = i
	i = i+1
end
```

## 参考链接

- [Home](http://w3.impa.br/~diego/software/luasocket/)
- [Reference](http://w3.impa.br/~diego/software/luasocket/tcp.html)
