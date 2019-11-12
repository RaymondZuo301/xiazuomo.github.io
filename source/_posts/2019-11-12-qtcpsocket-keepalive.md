---
title: qtcpsocket-keepalive
categories:
  - temp
tags:
  - temp
comments: true
mathjax: false
date: 2019-11-12 11:04:33
updated: 2019-11-12 11:04:33
---

# QTcpSocket利用setsockopt实现连接保活

## 保活机制

socket保活有三种机制：

- SO_KEEPALIVE
- SIO_KEEPALIVE_VALS
- Heart-Beat

## Linux的keepalive机制

Linux内置支持keepalive机制，涉及三个变量：

- tcp_keepalive_time：失连时间（秒）
- tcp_keepalive_intvl：重连间隔（秒）
- tcp_keepalive_probes：重连次数（次）

查看方式：

```bash
cat /proc/sys/net/ipv4/tcp_keepalive_time
cat /proc/sys/net/ipv4/tcp_keepalive_intvl
cat /proc/sys/net/ipv4/tcp_keepalive_probes
```

默认情况下为：

```bash
7200
75
9
```

手动设置方式（重启失效）：

```bash
echo 100 > /proc/sys/net/ipv4/tcp_keepalive_time
echo 10 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 1 > /proc/sys/net/ipv4/tcp_keepalive_probes
```

## QTcpSocket中设置keepalive

Qt提供了开启keepalive的接口，但是没有提供上述三个变量的配置接口：

```cpp
QTcpSocket::setSocketOption(QAbstractSocket::KeepAliveOption, 1);
```

设置方式需要使用<sys/socket.h>中提供的：

```cpp
/* Set socket FD's option OPTNAME at protocol level LEVEL
   to *OPTVAL (which is OPTLEN bytes long).
   Returns 0 on success, -1 for errors.  */
extern int setsockopt (int __fd, int __level, int __optname, const void *__optval, socklen_t __optlen) __THROW;
```

其中：

- fd: socket句柄
- level: 协议层（SOL_SOCKET、SOL_TCP）
- optname: 变量名（SO_KEEPALIVE、TCP_KEEPIDLE、TCP_KEEPINTVL、TCP_KEEPCNT）
- optval: 变量指针
- optlen: 变量长度

如使用了SO_KEEPALIVE可不设置qt自带的`QAbstractSocket::KeepAliveOption`

## 代码示例

```cpp
    #include <sys/types.h>
    #include <sys/socket.h>
    #include <fcntl.h>
    #include <netinet/tcp.h>

    QTcpSocket *client = new QTcpSocket(this);
    client->connectToHost(ip,8888);
    if(client->waitForConnected(1000))
    {
        if(client->socketDescriptor() == -1)
        {
            S_WARN("fail to get socketDescriptor");
        }
        else
        {
            Log("socketDescriptor {}", client->socketDescriptor());
        }

        //开启保活
        int enable = 1;
        if(setsockopt(client->socketDescriptor(), SOL_SOCKET, SO_KEEPALIVE, &enable, sizeof(enable)) != 0)
        {
            Log("fail to enable SO_KEEPALIVE");
        }
        //失连时间>0
        int lost_time = 1;
        if(setsockopt(client->socketDescriptor(), SOL_TCP, TCP_KEEPIDLE, &lost_time, sizeof(lost_time)) != 0)
        {
            Log("fail to enable TCP_KEEPIDLE");
        }
        //重连时间>0
        int retry_time = 1;
        if(setsockopt(client->socketDescriptor(), SOL_TCP, TCP_KEEPINTVL, &retry_time, sizeof(retry_time)) != 0)
        {
            Log("fail to enable TCP_KEEPINTVL");
        }
        //重连次数>0
        int retry_num = 1;
        if(setsockopt(client->socketDescriptor(), SOL_TCP, TCP_KEEPCNT, &retry_num, sizeof(retry_num)) != 0)
        {
            Log("fail to enable TCP_KEEPCNT");
        }
    }

```

## 参考

- https://forum.qt.io/topic/2371/qtcpsocket-check-cable-disconnected
- https://blog.csdn.net/yhc1991/article/details/46453585
- https://blog.csdn.net/wan_hust/article/details/25835025
- https://www.cnblogs.com/liushui-sky/p/6530406.html
