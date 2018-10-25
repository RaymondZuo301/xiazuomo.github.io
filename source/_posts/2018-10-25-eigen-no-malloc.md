---
title: Eigen禁止Malloc动态内存分配的方法
categories:
  - 技巧
tags:
  - Eigen
  - C++
  - 内存管理
comments: true
mathjax: false
date: 2018-10-25 10:43:09
updated: 2018-10-25 10:43:09
---

## 前言

Eigen的基本数据类型分为Matrix和Array，其中Matrix用于线性代数运算，而Array用于更通用、可扩展的场景，在此仅讨论Matrix相关内容。本问主要讨论了Eigen中使用动态内存分配/堆分配的情况，以及避免或检测动态内存分配的方法。

## Matrix的内存分配

### 常用Eigen类型的内存分配

|          派生类型           |                 Matrix类型                 |                             例                             | 内存分配 |
| :-------------------------: | :----------------------------------------: | :--------------------------------------------------------: | :------: |
|  `Vector<n><type>`, 2≤n≤4   |      `Matrix<float/double/int,<n>,1>`      |             `Vector2f`、`Vector3d`、`Vector4i`             |   静态   |
|       `VectorX<type>`       |    `Matrix<float/double/int,Dynamic,1>`    |     `VectorXf(10)`、`VectorXd(100)`、`VectorXi(1000)`      |   动态   |
| `RowVector<n><type>`, 2≤n≤4 |      `Matrix<float/double/int,1,<n>>`      |        `RowVector2f`、`RowVector3d`、`RowVector4i`         |   静态   |
|     `RowVectorX<type>`      |    `Matrix<float/double/int,1,Dynamic>`    | `RowVectorXf(10)`、`RowVectorXd(100)`、`RowVectorXi(1000)` |   动态   |
|  `Matrix<n><type>`, 2≤n≤4   |     `Matrix<float/double/int,<n>,<n>>`     |             `Matrix2f`、`Matrix3d`、`Matrix4i`             |   静态   |
|       `MatrixX<type>`       | `Matrix<float/double/int,Dynamic,Dynamic>` |   `MatrixXf(3,3)`、`MatrixXd(5,100)`、`Matrix4i(200,50)`   |   动态   |

### 数据类型通用记法

Eigen数据类型可通用的记成：<矩阵类型><维度><数据类型>的形式，具体的：

- <矩阵类型>可分为：`Vector`列向量、`RowVector`行向量、`Matrix`矩阵
- <维度>对向量可分为：2、3、4、X，其中X为动态向量
- <维度>对矩阵可分为：2、3、4、2X、3X、4X、X2、X3、X4、X，其中如2X代表2行任意列的动态矩阵，X代表行列均动态大小的矩阵
- <数据类型>包含：f、d、i，分别对应float、double、int，以及cf、cd、ci，对应相应的复数形式

注：对于维度中所有包含X的类型均为动态类型，在变量定义时会使用动态内存分配

## 禁止动态内存分配的方法

### Eigen中的预编译宏

Eigen中提供了两个宏来禁止内存分配：

- `EIGEN_NO_MALLOC`: if defined, any request from inside the Eigen to allocate memory from the heap results in an assertion failure. This is useful to check that some routine does not allocate memory dynamically. Not defined by default.
- `EIGEN_RUNTIME_NO_MALLOC`: if defined, a new switch is introduced which can be turned on and off by calling set_is_malloc_allowed(bool). If malloc is not allowed and Eigen tries to allocate memory dynamically anyway, an assertion failure results. Not defined by default.

简单的讲：

- `EIGEN_NO_MALLOC`: 禁止使用堆内存分配，如果使用将会触发断言
- `EIGEN_RUNTIME_NO_MALLOC`: 提供一个接口`set_is_malloc_allowed(bool)`来细粒度控制禁止堆内存分配的代码段

注：两者不可混用

### 例子

【重要】宏的声明必须在inclued之前，以保证正确启用

`EIGEN_NO_MALLOC`例：

```cpp
#define EIGEN_NO_MALLOC
#include <Eigen/Core>
#include <Eigen/Dense>

int main()
{
	EEigen::Vector3f v1;		//不会触发断言
	Eigen::VectorXf v2;			//不会触发断言
	v2.resize(3);				//会触发断言
	Eigen::VectorXf v3(10); 	//会触发断言
	
	Eigen::Matrix3f m1;			//不会触发断言
	Eigen::MatrixXf m2;			//不会触发断言
	m2.resize(5,5);				//会触发断言
	Eigen::MatrixXf m3(10,5);	//会触发断言
	
	//会触发断言
	Eigen::MatrixXf m_svd = Eigen::MatrixXf::Random(6, 6);
	//会触发断言
	Eigen::JacobiSVD<Eigen::MatrixXf> svd(m_svd, Eigen::ComputeFullV | Eigen::ComputeFullU);
	
	return 0;
}
```

`EIGEN_RUNTIME_NO_MALLOC`例：

```cpp
#define EIGEN_RUNTIME_NO_MALLOC
#include <Eigen/Core>
#include <Eigen/Dense>

int main()
{
	Eigen::internal::set_is_malloc_allowed(true);
	Eigen::VectorXf v1(10); 	//不会触发断言
	Eigen::internal::set_is_malloc_allowed(false);
	
	Eigen::VectorXf v2(10);		//会触发断言

	return 0;
}
```

断言内容：

```
/usr/include/eigen3/Eigen/src/Core/util/Memory.h:206: void Eigen::internal::check_that_malloc_is_allowed(): Assertion `is_malloc_allowed() && "heap allocation is forbidden (EIGEN_RUNTIME_NO_MALLOC is defined and g_is_malloc_allowed is false)"' failed.
```

### 避免动态内存分配的方法

- 对于2-4维的向量及矩阵可使用原生数据类型：Vector3f、Matrix4d等
- 避免使用带X的预制数据类型如：VectorXf、Matrix3Xd等
- 对于高维向量及矩阵可显式声明如：Matrix<float, 10, 1>等价于10维Vector、Matrix<double, 100, 50>等价于100行50列Matrix
- 编码中使用上述宏来检查是否使用动态内存分配

例：

```cpp
#define EIGEN_NO_MALLOC
#include <Eigen/Core>
#include <Eigen/Dense>

int main()
{
	Eigen::Matrix<float, 10, 1> v1 		//不会触发断言，等价于Eigen::VectorXf v1(10);
	
	Eigen::Matrix<float, 10, 10> m1		//不会触发断言，等价于Eigen::MatrixXf m1(10,10);
	
	Eigen::JacobiSVD<Eigen::Matrix<float, 10, 10>> svd(m1, Eigen::ComputeFullV | Eigen::ComputeFullU);	//不会触发断言

	return 0;
}
```

## 参考
- http://eigen.tuxfamily.org/dox/TopicPreprocessorDirectives.html