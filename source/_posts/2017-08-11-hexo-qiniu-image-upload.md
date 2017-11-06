---
title: 【Hexo】利用七牛qshell工具上传博客图片
categories:
  - 技巧
tags:
  - hexo
comments: true
mathjax: true
date: 2017-08-11 09:34:11
updated: 2017-08-11 09:34:11
---

## 写在最前面
本文对利用七牛qshell上传博客图片的设置及使用方法进行了整理
****

## 系统环境
ubuntu: 16.04
hexo: 3.3.8
****

## qshell的配置
1. **下载qshell**
[**Github链接**](https://github.com/qiniu/qshell)
下载对应的版本，本文以ubuntu为例

2. **qhell的配置**
- 将qshell可执行文件存放到home文件夹下例如`/home/用户名/qiniu`
- 添加可执行权限`chmod +x qshell`
- 将qshell所在目录加入系统环境变量
```bash
$ sudo gedit ~/.bashrc
```
- 添加如下环境变量
```bash
export PATH=$PATH:/home/用户名/qiniu
```
- 运行`source ~/.bashrc`使修改立即生效
- 在终端内输入`qshell`测试一下是否添加成功

3. **配置账户**
- 在`/home/用户名/qiniu`内新建文件夹例如`xiazuomo`
- 
****

