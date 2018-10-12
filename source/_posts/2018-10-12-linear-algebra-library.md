---
title: 线性代数库调研
categories:
  - 学习
tags:
  - Eigen
  - MKL
  - 线性代数
comments: true
mathjax: true
date: 2018-10-12 10:35:40
updated: 2018-10-12 10:35:40
---

# 线性代数库调研

## 前言

本文罗列了线性代数库/API相关的内容，包含基本数学库/API和高级数学库相关内容，以及他们之间的对比，可跳过前面直接阅读“线性代数库选用”相关内容。

## 基本数学库/API

### BLAS

简介：基本线性代数子程序，Basic Linear Algebra Subprograms，是一个API标淮，用以规范发布基础线性代数操作的数值库（如矢量或矩阵乘法）。Netlib用Fortran实现了BLAS的这些API接口，得到的库也叫做BLAS。Netlib只是一般性地实现了基本功能，并没有对运算做过多的优化。在高性能计算领域，BLAS被广泛使用。为提高性能，各软硬件厂商则针对其产品对BLAS接口实现进行高度最佳化。

参考链接：

- http://www.netlib.org/blas/
- https://zh.wikipedia.org/wiki/BLAS

### LAPACK

简介：线性代数库，也是Netlib用fortran语言编写的，其底层是BLAS。LAPACK提供了丰富的工具函式，可用于诸如解多元线性方程式、线性系统方程组的最小平方解、计算特徵向量、用于计算矩阵QR分解的Householder转换、以及奇异值分解等问题。该库的运行效率比BLAS库高。从某个角度讲，LAPACK也可以称作是一组科学计算（矩阵运算）的接口规范。Netlib实现了这一组规范的功能，得到的这个库叫做LAPACK库。

参考链接

- http://www.netlib.org/lapack/
- https://zh.wikipedia.org/wiki/LAPACK

### ScaLAPACK

简介：ScaLAPACK（Scalable LAPACK 简称）是一个并行计算软件包，适用于分布式存储的 MIMD （multiple instruction, multiple data）并行计算机。它是采用消息传递机制实现处理器/进程间通信，因此使用起来和编写传统的 MPI 程序比较类似。ScaLAPACK 主要针对密集和带状线性代数系统，提供若干线性代数求解功能，如各种矩阵运算，矩阵分解，线性方程组求解，最小二乘问题，本征值问题，奇异值问题等，具有高效、可移植、可伸缩、高可靠性等优点，利用它的求解库可以开发出基于线性代数运算的并行应用程序。

参考链接

- http://www.netlib.org/scalapack/index.html
- https://blog.csdn.net/zuoshifan/article/details/80273198


## 高级数学库

### MKL

简介：英特尔MKL基于英特尔® C++和Fortran编译器构建而成，并使用OpenMP\*实现了线程化。该函数库的算法能够平均分配数据和任务，充分利用多个核心和处理器。支持Linux/Win。

底层：

- BLAS：所有矩阵间运算（三级）均面向密集和稀疏 BLAS 实现了线程化。 许多矢量间运算（一级）和矩阵与矢量的运算（二级）均面向英特尔® 64 架构上 64 位程序中的密集型矩阵实现了线程化。 对于稀疏矩阵，除三角形稀疏矩阵解算器外的所有二级运算均实现了线程化。
- LAPACK：部分计算例程针对以下某类型的问题实现了线程化：线性方程解算器、正交因子分解、单值分解和对称特征值问题。 LAPACK 也调用 BLAS，因此即使是非线程化函数也可能并行运行。
- ScaLAPACK：面向集群的 LAPACK 分布式内存并行版本。
- PARDISO：该并行直接稀疏矩阵解算器的三个阶段均实现了线程化：重新排序（可选）、因子分解和解算（如果采用多个右侧项）。
- DFTs：离散傅立叶变换
- VML：矢量数学库
- VSL：矢量统计学库

参考资料：

- https://software.intel.com/es-es/node/699485
- http://www.docin.com/p-1907272173.html

### Armadillo

简介：使用模板元编程技术，与Matlab相似，易于使用的C++矩阵库，提供高效的 LAPACK, BLAS和ATLAS封装包，包含了 Intel MKL, AMD ACM和 OpenBLAS等诸多高性能版本。

底层：

- BLAS/LAPACK：支持OpenBLAS、ACML、MKL

参考链接：

- http://arma.sourceforge.net/
- https://en.wikipedia.org/wiki/Armadillo_(C%2B%2B_library)

### Eigen

简介：Eigen是可以用来进行线性代数、矩阵、向量操作等运算的C++库，它里面包含了很多算法。它支持多平台。Eigen采用源码的方式提供给用户使用，在使用时只需要包含Eigen的头文件即可进行使用。之所以采用这种方式，是因为Eigen采用模板方式实现，由于模板函数不支持分离编译，所以只能提供源码而不是动态库的方式供用户使用。

底层：

- BLAS/LAPACK：支持所有基于F77的BLAS或LAPACK库作为底层（`EIGEN_USE_BLAS`、`EIGEN_USE_LAPACKE`）
- MKL：支持MKL作为底层（`EIGEN_USE_MKL_ALL`）
- CUDA：支持在CUDA kernels里使用CUDA
- OpenMP：多线程优化

参考链接

- http://eigen.tuxfamily.org/index.php?title=Main_Page
- http://eigen.tuxfamily.org/dox/TopicUsingBlasLapack.html
- http://eigen.tuxfamily.org/dox/TopicUsingIntelMKL.html

## 线性代数库选用

### 关系

- 狭义的BLAS/LAPACK可理解为用于线性代数运算库的API
- Netlib实现了Fortran/C版的BLAS/LAPACK、CBLAS/CLAPACK
- 开源社区及商业公司针对API实现了BLAS（ATLAS、OpenBLAS）和LAPACK（MKL、ACML、CUBLAS）的针对性优化
- Eigen、Armadillo除自身实现线性代数运算库外还支持上述各种BLAS/LAPACK为基础的底层以加速运算

### 对比

- 备选：MKL、OpenBLAS、Eigen、Armadillo
- 接口易用程度：Eigen > Armadillo > MKL/OpenBLAS
- 速度：MKL≈OpenBLAS > Eigen(with MKL) > Eigen > Armadillo

其中：
- OpenBLAS没有单核版本，强行指定OMP_NUM_THREADS=1性能损失大，不考虑
- MKL直接使用学习成本较高，但是性能最强
- Armadillo效率和接口易用性不如Eigen
- Eigen的原生BLAS/LAPACK实现速度不如MKL、OpenBLAS，但是使用MKL做后台性能和MKL原生几乎一样，所以可以视情况决定是否使用MKL

## 参考资料

- [blas、lapack和atlas、openblas的区别联系](https://blog.csdn.net/u013677156/article/details/77865405)
- [比较OpenBLAS，Intel MKL和Eigen的矩阵相乘性能](http://www.leexiang.com/the-performance-of-matrix-multiplication-among-openblas-intel-mkl-and-eigen)
- [Eigen、OpenCV、Armadillo对比](https://blog.csdn.net/zyh821351004/article/details/46272685)
- [更多线性代数库的对比](https://scicomp.stackexchange.com/questions/351/recommendations-for-a-usable-fast-c-matrix-library)
