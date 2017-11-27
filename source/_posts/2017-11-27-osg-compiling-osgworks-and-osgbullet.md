---
title: 【OSG】osgWorks、osgBullet编译及安装（适用于最新的OSG-3.5.7，Bullet-2.87）
categories:
  - 技巧
tags:
  - OSG
  - Bullet
comments: true
mathjax: false
date: 2017-11-27 15:47:04
updated: 2017-11-27 15:47:04
---

## 写在最前面
osgWorks：一些osg工具
osgBullet：基于Bullet的osg物理引擎
本文介绍了osgWorks及osgBullet编译过程中的一些坑，这两个库最后一次更新都在数年之前，因为年久失修与现有版本的Bullet间有诸多问题
****

## 系统环境
ubuntu: 16.04
CMake: 3.5.1
OSG: 3.5.7
Bullet: 2.87
osgWorks: 3.0
osgBullet: 3.0
****

## osgWorks编译及配置
### 源代码下载、编译
源代码：[Github链接](https://github.com/mccdo/osgworks)
```bash
mkdir build
cd build
cmake ..
make
make install 2>&1 | tee  install.log
```
### 过程中出现的问题及解决办法：
#### 1.报错：mgv.mergeGeode(geode)
在`/src/osgwTools/GeometryModifier.cpp`中添加头文件`#include <osg/Group>`
将`mgv.mergeGeode(geode);`修改为`mgv.mergeGroup(*geode.asGroup());`
#### 2.报错：void set(value_type a00, value_type a01, value_type a02,value_type a03,
在`/src/osgwTools/Orientation`中将
```cpp
osg::Vec3d Orientation::getYPR( const osg::Quat& q ) const
{
    osg::Matrix m;
    m.set( q );
    return( getYPR( m ) );
}
void Orientation::getYPR( const osg::Quat& q, double& yaw, double& pitch, double& roll ) const
{
    osg::Matrix m;
    m.set( q );
    getYPR( m, yaw, pitch, roll );
}
```
修改为
```cpp
osg::Vec3d Orientation::getYPR( const osg::Quat& q ) const
{
    osg::Matrix m(q);
    return( getYPR( m ) );
}
void Orientation::getYPR( const osg::Quat& q, double& yaw, double& pitch, double& roll ) const
{
    osg::Matrix m(q);
    getYPR( m, yaw, pitch, roll );
}
```
****

## osgBullet编译及配置
### 源代码下载、编译
源代码：[Github链接](https://github.com/mccdo/osgbullet)
```bash
mkdir build
cd build
cmake ..
make
make install 2>&1 | tee  install.log
```
### 过程中出现的问题及解决办法：
#### 1.报错：找不到osgWorks，CMake Error at CMakeModules/FindosgWorks.cmake:39 (MESSAGE)
指定`osgWorks_DIR`为`usr/local/lib`
#### 2.报错：无法生成动态链接库
```bash
/usr/bin/ld: /usr/local/lib/libBulletCollision.a(btBoxShape.o): relocation R_X86_64_32S against _ZNK21btConvexInternalShape9getMarginEv can not be used when making a shared object; recompile with -fPIC
```
将`BUILD_SHARED_LIBS`取消勾选
#### 3.报错：编译example/patch-lowlevel时报“未定义的引用”错误
将`/examples/CMakeLists.txt`中的`ADD_SUBDIRECTORY( patch-lowlevel )`注释掉
#### 4.报错：no matching function for call to ‘osg::TriangleFunctor<osgbCollision::ComputeTriMeshFunc>::operator()(const Vec3&, const Vec3&, const Vec3&)’
将`/usr/local/include/osg/TriangleFunctor`中以`this->operator()`开头的语句末尾增加一个参数`false`
例如：
```cpp
this->operator()(*(vptr),*(vptr+1),*(vptr+2));
```
改为：
```cpp
this->operator()(*(vptr),*(vptr+1),*(vptr+2),false);
```
****
以上osgWorks及osgBullet编译安装完毕
## 参考
https://www.cnblogs.com/lyggqm/p/6733423.html
