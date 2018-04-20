---
title: 【CMake】CMake中遇到的问题汇总(持续更新)
categories:
  - 技巧
tags:
  - Cmake
comments: true
mathjax: false
date: 2018-04-20 08:46:06
updated: 2018-04-20 08:46:06
---

## 编译动态库B时提示被链接的A库需用“-fPIC”重新编译
错误：can not be used when making a shared object; recompile with -fPIC    
解决：重新编译A库    
```
add_library( A ${SRC})
set_property(TARGET A PROPERTY POSITION_INDEPENDENT_CODE ON)
```
