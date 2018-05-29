---
title: 基于球面均匀采样的旋转变换采样
categories:
  - 算法
tags:
  - Eigen
  - 点云
comments: true
mathjax: true
date: 2018-05-28 15:24:43
updated: 2018-05-28 15:24:43
---

# 基于球面均匀采样的旋转变换采样
## 写在前面
在解决点云可见性问题时，需在同一视角（z轴正方向）下将点云绕其中心进行N次旋转变换，同时保证随机性（均匀性），所以需求一种生成N个随机旋转变换的采样方法。可以将求旋转变换的问题转化为对一个$r=1$的单位球面进行均匀采样的问题，因为球面上任意一点可看做是空间向量$\vec{v}(x,y,z)$，再用轴（叉乘产生的法向轴）角法计算与向量$\vec{z}(0,0,1)$间旋转变换，从而得到一些列的变换。但是！这样的操作选择性忽略了绕z轴的旋转，不过因为在z轴正方向视角下观察点云，绕z轴旋转并不影响可见性所以可以接受，因此这种方法其实并不是”全空间“的均匀采样。
## 球面均匀采样
### 球坐标系采样
为了对单位球面进行均匀采样，第一个想到的就是对球坐标系$(r,\theta,\phi)$中的$\theta$、$\phi$分别进行均匀采样，尝试绘制点云图如下所示，可见两级相较中间密度更大，整体并不均匀    
![](fig1.png)    
python代码如下：
```python
from numpy import *
import math
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D  

x = []
y = []
z = []
N = 50
d = 2*math.pi/N

for i in range(N):
    for j in range(N):
        zt = math.sin(d*j)
        zt_c = math.cos(d*j)
        xt = zt_*math.cos(d*i)
        yt = zt_*math.sin(d*i)
        z.append(zt)
        x.append(xt)
        y.append(yt)

fig=plt.figure(dpi=120)  
ax=fig.add_subplot(111,projection='3d')  
ax.scatter(x,y,z,c='b',marker='.',s=10,linewidth=0,alpha=1,cmap='spectral')  
plt.show()
```
### 基于斐波那契格点的球面均匀采样
根据[参考文献2](https://zhuanlan.zhihu.com/p/25988652?group_id=828963677192491008)中所述的方法，尝试利用斐波那契格点进行球面均匀采样，通式如下，其中$n$为总N个点中第n个点，$\phi$为转角系数，$\phi$的取值并非任意，其决定了曲面上螺旋的“混乱”程度，对此[参考文献3](https://zhuanlan.zhihu.com/p/25998937?group_id=829506039526354944)作出了详细的论证，较好的取值有$(\sqrt{5}-1)/2 \approx 0.618$、$\sqrt{2}-1 \approx 0.414$
$$
\begin{cases}
z_n &= (2n-1)/N-1 \\
x_n &= \sqrt{1-z_n^2} \cdot \cos(2 \pi n \phi)\\
y_n &= \sqrt{1-z_n^2} \cdot \sin(2 \pi n \phi)\\
\end{cases}
$$
结果如下图所示
![](fig2.png)  
python代码如下：
```python
import math
import matplotlib.pyplot as plt   
from mpl_toolkits.mplot3d import Axes3D  

x = []
y = []
z = []
N = 2500
pi = math.pi
phi = 0.618

for n in range(1,N+1):
    zt = (2*n-1.0)/float(N)-1
    xt = math.sqrt(1-zt*zt)*math.cos(2*pi*n*phi)
    yt = math.sqrt(1-zt*zt)*math.sin(2*pi*n*phi)
    z.append(zt)
    x.append(xt)
    y.append(yt)

fig=plt.figure(dpi=120)  
ax=fig.add_subplot(111,projection='3d')  
ax.scatter(x,y,z,c='b',marker='.',s=10,linewidth=0,alpha=1,cmap='spectral')  
plt.show()  
```
## 代码实现
在通过上述方法得到单位球面均匀采样点后，通过计算$\vec{z}(0,0,1)$与$\vec{v}(x,y,z)$之间的旋转变换来得到一系列旋转变换，代码如下：
### sphere_uniform_sampling.h
```cpp
#ifndef SPHERE_UNIFORM_SAMPLING_H
#define SPHERE_UNIFORM_SAMPLING_H

#include <iostream>
#include <vector>
#include <math.h>
#include <Eigen/Core>
#include <Eigen/Geometry>

class RotationSampling
{
public:
    RotationSampling(int num_, double phi_=0.414);//phi=0.414, 0.618
    std::vector<Eigen::Matrix3d> getR();
    std::vector<Eigen::Matrix4d> getRT();
private:
    int num;
    double phi;
    std::vector<Eigen::Vector3d> genPoints();
    Eigen::Matrix3d vectorRotation2R(Eigen::Vector3d v_from, Eigen::Vector3d v_to);
};

#endif // SPHERE_UNIFORM_SAMPLING_H
```
### sphere_uniform_sampling.cpp
```cpp
#include "sphere_uniform_sampling.h"

RotationSampling::RotationSampling(int num_, double phi_)
{
    num = num_;
    phi = phi_;
}

std::vector<Eigen::Matrix3d> RotationSampling::getR()
{
    std::vector<Eigen::Matrix3d> r;
    std::vector<Eigen::Vector3d> points = genPoints();

    Eigen::Vector3d v_from(0.0, 0.0, 1.0);
    for(int i=0; i<points.size(); ++i)
    {
        r.push_back(vectorRotation2R(v_from, points[i]));
    }

    return r;
}

std::vector<Eigen::Matrix4d> RotationSampling::getRT()
{
    std::vector<Eigen::Matrix3d> r = getR();
    std::vector<Eigen::Matrix4d> rt;
    for(int i=0; i<r.size(); ++i)
    {
        Eigen::Matrix4d rt_ = Eigen::MatrixXd::Identity(4,4);
        rt_.block<3, 3>(0, 0) = r[i];
        rt.push_back(rt_);
    }

    return rt;
}

std::vector<Eigen::Vector3d> RotationSampling::genPoints()
{
    std::vector<Eigen::Vector3d> points;
    for(int n=1; n<=num; ++n)
    {
        double z = (2.0*n-1.0)/double(num)-1.0;
        double x = sqrt(1.0-z*z)*cos(2.0*M_PI*n*phi);
        double y = sqrt(1.0-z*z)*sin(2.0*M_PI*n*phi);
        Eigen::Vector3d p(x,y,z);
        points.push_back(p);
    }
    return points;
}

Eigen::Matrix3d RotationSampling::vectorRotation2R(Eigen::Vector3d v_from, Eigen::Vector3d v_to)
{
    Eigen::Matrix3d r = Eigen::MatrixXd::Identity(3,3);

    v_from.normalize();
    v_to.normalize();

    //v_from到v_to的旋转轴
    Eigen::Vector3d from_to_axis = v_from.cross(v_to);
    from_to_axis.normalize();

    //v_from到v_to的旋转矩阵
    double theta = acos(v_from.dot(v_to));
    Eigen::AngleAxisd v(theta, from_to_axis);
    r = v.matrix();

    return r;
}
```
### 用法
```cpp
    RotationSampling gen(100);
    std::vector<Eigen::Matrix3d> rt = gen.getR();
    std::vector<Eigen::Matrix4d> rt = gen.getRT();
```
## 思考
- 将球面采样推广至高维
- 利用四元数进行旋转变换的均匀采样
- 分别对（1,0,0）、(0,1,0)、（0,0,1）进行旋转
## 参考文献
1. https://zhuanlan.zhihu.com/p/26052376
2. https://zhuanlan.zhihu.com/p/25988652?group_id=828963677192491008
3. https://zhuanlan.zhihu.com/p/25998937?group_id=829506039526354944

