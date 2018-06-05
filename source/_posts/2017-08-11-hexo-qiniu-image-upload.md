---
title: 利用七牛qshell工具上传Hexo博客图片
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
### 下载qshell
[Github链接](https://github.com/qiniu/qshell)
下载对应的版本，本文以ubuntu为例

### qhell的配置
将qshell可执行文件存放到home文件夹下例如`/home/用户名/qiniu`
添加可执行权限`chmod +x qshell`
将qshell所在目录加入系统环境变量
```bash
$ sudo gedit ~/.bashrc
```
添加如下环境变量
```bash
export PATH=$PATH:/home/用户名/qiniu
```
运行`source ~/.bashrc`使修改立即生效
在终端内输入`qshell`测试一下是否添加成功

### 配置账户
进入`/home/用户名/qiniu`目录，建立账户，此处使用-m多账户模式将账户信息建立在qshell工具所在目录，其中AccessKey和SecretKey可从七牛账户中获取
```bash
$ qshell -m account <AccessKey> <SecretKey>
```
账户建立完毕用如下命令查看是否建立成功
```bash
$ qshell -m account
```

### 配置上传设置
在`/home/用户名/qiniu`目录下建立`config`文件
输入如下参数，前四项自行填写
```
{
   "src_dir"            :   "/home/用户名/.../source/_posts",
   "access_key"         :   "ak",
   "secret_key"         :   "sk",
   "bucket"             :   "bucket名称",
   "ignore_dir"         :   false,
   "overwrite"          :   true,
   "check_exists"       :   true,
   "check_hash"         :   false,
   "check_size"         :   false,
   "skip_file_prefixes" :   ".git",
   "skip_path_prefixes" :   "",
   "skip_fixed_strings" :   "",
   "skip_suffixes"      :   ".md",
   "rescan_local"       :   true,
   "log_file"           :   "upload.log",
   "log_level"          :   "info"
}
```
****

## 文件上传
当`_posts`下添加的图片之后，在`/home/用户名/qiniu`目录下运行一下命令即可完成上传
```bash
$ qshell -m qupload config
```
****

## 外链获取
### 方法1
直接在网页界面复制外链

### 方法2
使用qshell获取域名及文件列表，并将两者进行拼接，`/home/用户名/qiniu`目录下
获取域名
```bash
$ qshell -m domains <空间名>
```
获取文件列表
```bash
$ qshell -m listbucket <空间名> <存储文件列表的文件名>
```
将两者进行拼接即可获取完整外链存储至final文件
```bash
$ cat <存储文件列表的文件名> | awk '{print "域名/"$1}' >final
```
****

## 参考
https://github.com/qiniu/qshell
https://segmentfault.com/q/1010000005149132/a-1020000005150007
