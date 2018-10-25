---
title: Eigen使用MKL作为backend加速矩阵运算
categories:
  - 技巧
tags:
  - Eigen
  - C++
  - MKL
  - OpenMP
  - 并行/并发/多线程
comments: true
mathjax: false
date: 2018-10-25 10:43:21
updated: 2018-10-25 10:43:21
---

## 前言

本文包含MKL配置、Cmake写法、Eigen中使用MKL的方法。

## MKL安装

下载地址：https://software.intel.com/en-us/mkl

解压后使用`install_GUI.sh`安装，默认安装路径为`/opt/intel/mkl`

可选配置项：

- 运行`sudo gedit /etc/ld.so.conf.d/intel_mkl.conf`，添加：

```
/opt/intel/lib/intel64
/opt/intel/mkl/lib/intel64
```

运行`sudo ldconfig`

- 运行`sudo gedit /etc/profile`，添加：

```bash
export MKL_ROOT_DIR=/opt/intel/mkl
```

运行`sudo source /etc/profile`，尽量重启电脑以保证生效

## Eigen+MKL的cmake写法

### 工程目录结构

```
/root
	├── CMakeLists.txt
	├── FindMKL.cmake
	└── main.cpp
```

### 工程CmakeList.txt写法

其中启用OpenMP通过添加`-fopenmp`实现

```cmake
cmake_minimum_required (VERSION 2.6 FATAL_ERROR)
project(test)

# 将根目录加入cmake module文件的搜索路径
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/")

find_package(Eigen3)
include_directories(${EIGEN3_INCLUDE_DIR})

find_package(MKL)
include_directories(${MKL_INCLUDE_DIR})

include_directories(${PROJECT_SOURCE_DIR})
set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -fopenmp" )
ADD_EXECUTABLE(exe main.cpp)
TARGET_LINK_LIBRARIES(exe ${MKL_LIBRARIES})
```

### FindMKL.cmake写法

代码见文末，参考自[链接](https://github.com/Eyescale/CMake/blob/master/FindMKL.cmake)，做了部分修改，其中`set(MKL_LIBRARIES ${MKL_LP_SEQUENTIAL_LIBRARIES})`一行最为关键。

MKL有以下概念：

- 数据格式，LP64和ILP64，其中LP64用于64位系统，ILP用于32位系统
- 线程类型，单线程SEQUENTIAL、GNU多线程GNUTHREAD、Intel多线程INTELTHREAD，Ubuntu下可使用GNU多线程，Win下可使用Intel多线程，对于较低维度的矩阵运算单线程似乎更快
- MPI，分为NOMP、INTELMPI、OPENMPI、SGIMPT四种，本FindMKL.cmake暂未支持配置MPI

Ubuntu下常用配置为

- `set(MKL_LIBRARIES ${MKL_LP_SEQUENTIAL_LIBRARIES})`单线程
- `set(MKL_LIBRARIES ${MKL_LP_GNUTHREAD_LIBRARIES})`多线程

## 示例代码

### Eigen

```cpp
#define EIGEN_VECTORIZE_SSE4_2

#include <iostream>
#include <time.h>

#include <Eigen/Core>
#include <Eigen/Dense>

int main()
{
    srand((unsigned)time(NULL));
    clock_t start,finish;
    double totaltime;
    start=clock();
    
    Eigen::MatrixXf m1 = Eigen::MatrixXf::Random(7000, 7000);
    Eigen::MatrixXf m2 = Eigen::MatrixXf::Random(7000, 7000);
    Eigen::MatrixXf m3 = m1*m2;

    finish=clock();
    totaltime=(double)(finish-start)/CLOCKS_PER_SEC;
    std::cout<< "此程序的运行时间为" << totaltime << "秒" <<std::endl;
    
    return 0;
}
```

### Eigen+OpenMP

添加`-fopenmp`编译参数，2线程，上一代码添加如下语句：

```cpp
#define EIGEN_VECTORIZE_SSE4_2

#include <iostream>
#include <time.h>

#include <Eigen/Core>
#include <Eigen/Dense>

int main()
{
    omp_set_num_threads(2);
    ...
}
```

### Eigen+MKL单线程

FindMKL.cmake中使用`MKL_LP_SEQUENTIAL_LIBRARIES`，添加`#define EIGEN_USE_MKL_ALL`

```
#define EIGEN_USE_MKL_ALL
#define EIGEN_VECTORIZE_SSE4_2

#include <iostream>
#include <time.h>

#include <Eigen/Core>
#include <Eigen/Dense>

int main()
{
    ...
}
```

### Eigen+MKL多线程

FindMKL.cmake中使用`MKL_LP_GNUTHREAD_LIBRARIES`，添加`#define EIGEN_USE_MKL_ALL`、`omp_set_num_threads(2);`，使用2线程

```cpp
#define EIGEN_USE_MKL_ALL
#define EIGEN_VECTORIZE_SSE4_2

#include <iostream>
#include <time.h>

#include <Eigen/Core>
#include <Eigen/Dense>

int main()
{
    omp_set_num_threads(2);
    ...
}
```

### 结果对比

由结果可见MKL可显著提升高阶矩阵的运算速度（另外测试发现低阶矩阵速度差别不大），在当前测试环境（i3+4g+Ubuntu15.04）下多线程并没有提升乘法的运算速度

|     测试项      | 线程 | 时间/秒 |
| :-------------: | :--: | :-----: |
|      Eigen      |  1   | 27.1427 |
|  Eigen+OpenMP   |  2   | 31.3295 |
| Eigen+MKL单线程 |  1   | 8.43301 |
| Eigen+MKL多线程 |  2   | 9.5142  |

### 其他

添加`#define EIGEN_DONT_PARALLELIZE`可使Eigen不适用任何并行加速，但对
Eigen+MKL的配置方式无效，仅对Eigen或Eigen+OpenMP生效。

## 参考

- http://eigen.tuxfamily.org/dox/TopicPreprocessorDirectives.html
- http://eigen.tuxfamily.org/dox/TopicUsingIntelMKL.html
- https://software.intel.com/en-us/mkl
- https://github.com/Eyescale/CMake/blob/master/FindMKL.cmake
- https://blog.csdn.net/LG1259156776/article/details/52730074?locationNum=6&fps=1

## 附

FindMKL.cmake

```cmake
# - Try to find the Intel Math Kernel Library
#   Forked from: https://github.com/openmeeg/openmeeg/blob/master/macros/FindMKL.cmake
# Once done this will define
#
# MKL_FOUND - system has MKL
# MKL_ROOT_DIR - path to the MKL base directory
# MKL_INCLUDE_DIR - the MKL include directory
# MKL_LIBRARIES - MKL libraries
#
# There are few sets of libraries:
# Array indexes modes:
# LP - 32 bit indexes of arrays
# ILP - 64 bit indexes of arrays
# Threading:
# SEQUENTIAL - no threading
# INTEL - Intel threading library
# GNU - GNU threading library
# MPI support
# NOMPI - no MPI support
# INTEL - Intel MPI library
# OPEN - Open MPI library
# SGI - SGI MPT Library

# linux
if(UNIX AND NOT APPLE)
    if(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "x86_64")
        set(MKL_ARCH_DIR "intel64")
    else()
        set(MKL_ARCH_DIR "32")
    endif()
endif()

# macos
if(APPLE)
    set(MKL_ARCH_DIR "em64t")
endif()

IF(FORCE_BUILD_32BITS)
    set(MKL_ARCH_DIR "32")
ENDIF()

if (WIN32)
    if(${CMAKE_SIZEOF_VOID_P} EQUAL 8)
        set(MKL_ARCH_DIR "intel64")
    else()
        set(MKL_ARCH_DIR "ia32")
    endif()
endif()

set (MKL_THREAD_VARIANTS SEQUENTIAL GNUTHREAD INTELTHREAD)
set (MKL_MODE_VARIANTS ILP LP)
set (MKL_MPI_VARIANTS NOMPI INTELMPI OPENMPI SGIMPT)

find_path(MKL_ROOT_DIR
    include/mkl_cblas.h
    PATHS
    #$ENV{MKL_ROOT_DIR}
    /opt/intel/mkl/
    /opt/intel/cmkl/
    /Library/Frameworks/Intel_MKL.framework/Versions/Current/lib/universal
    "Program Files (x86)/Intel/ComposerXE-2011/mkl"
)

MESSAGE("MKL_ROOT_DIR : ${MKL_ROOT_DIR}") # for debug

find_path(MKL_INCLUDE_DIR
  mkl_cblas.h
  PATHS
    ${MKL_ROOT_DIR}/include
    ${INCLUDE_INSTALL_DIR}
)

find_path(MKL_FFTW_INCLUDE_DIR
  fftw3.h
  PATH_SUFFIXES fftw
  PATHS
    ${MKL_ROOT_DIR}/include
    ${INCLUDE_INSTALL_DIR}
  NO_DEFAULT_PATH
)

find_library(MKL_CORE_LIBRARY
  mkl_core
  PATHS
    ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}
    ${MKL_ROOT_DIR}/lib/
)

# Threading libraries
find_library(MKL_SEQUENTIAL_LIBRARY
  mkl_sequential
  PATHS
    ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}
    ${MKL_ROOT_DIR}/lib/
)

find_library(MKL_INTELTHREAD_LIBRARY
  mkl_intel_thread
  PATHS
    ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}
    ${MKL_ROOT_DIR}/lib/
)

find_library(MKL_GNUTHREAD_LIBRARY
  mkl_gnu_thread
  PATHS
    ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}
    ${MKL_ROOT_DIR}/lib/
)

# Intel Libraries
IF("${MKL_ARCH_DIR}" STREQUAL "32")
    find_library(MKL_LP_LIBRARY
      mkl_intel
      PATHS
        ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}
        ${MKL_ROOT_DIR}/lib/
    )

    find_library(MKL_ILP_LIBRARY
      mkl_intel
      PATHS
        ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}
        ${MKL_ROOT_DIR}/lib/
    )
else()
    find_library(MKL_LP_LIBRARY
      mkl_intel_lp64
      PATHS
        ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}
        ${MKL_ROOT_DIR}/lib/
    )

    find_library(MKL_ILP_LIBRARY
      mkl_intel_ilp64
      PATHS
        ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}
        ${MKL_ROOT_DIR}/lib/
    )
ENDIF()

# Lapack
find_library(MKL_LAPACK_LIBRARY
  mkl_lapack
  PATHS
    ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}
    ${MKL_ROOT_DIR}/lib/
)

IF(NOT MKL_LAPACK_LIBRARY)
    find_library(MKL_LAPACK_LIBRARY
      mkl_lapack95_lp64
      PATHS
        ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}
        ${MKL_ROOT_DIR}/lib/
    )
ENDIF()

IF(NOT MKL_LAPACK_LIBRARY)
    SET(MKL_LAPACK_LIBRARY ${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}/lib/libmkl_lapack95_lp64.a)
ENDIF()


# iomp5
IF("${MKL_ARCH_DIR}" STREQUAL "32")
    IF(UNIX AND NOT APPLE)
        find_library(MKL_IOMP5_LIBRARY
          iomp5
          PATHS
            ${MKL_ROOT_DIR}/../lib/intel64
        )
    ELSE()
        SET(MKL_IOMP5_LIBRARY "") # no need for mac
    ENDIF()
else()
    IF(UNIX AND NOT APPLE)
        find_library(MKL_IOMP5_LIBRARY
          iomp5
          PATHS
            ${MKL_ROOT_DIR}/../lib/intel64
        )
    ELSE()
        SET(MKL_IOMP5_LIBRARY "") # no need for mac
    ENDIF()
ENDIF()

foreach (MODEVAR ${MKL_MODE_VARIANTS})
    foreach (THREADVAR ${MKL_THREAD_VARIANTS})
        if (MKL_CORE_LIBRARY AND MKL_${MODEVAR}_LIBRARY AND MKL_${THREADVAR}_LIBRARY)
            set(MKL_${MODEVAR}_${THREADVAR}_LIBRARIES
                ${MKL_${MODEVAR}_LIBRARY} ${MKL_${THREADVAR}_LIBRARY} ${MKL_CORE_LIBRARY}
                ${MKL_LAPACK_LIBRARY} ${MKL_IOMP5_LIBRARY})
            message("${MODEVAR} ${THREADVAR} ${MKL_${MODEVAR}_${THREADVAR}_LIBRARIES}") # for debug
        endif()
    endforeach()
endforeach()

set(MKL_LIBRARIES ${MKL_LP_SEQUENTIAL_LIBRARIES})
LINK_DIRECTORIES(${MKL_ROOT_DIR}/lib/${MKL_ARCH_DIR}) # hack

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MKL DEFAULT_MSG MKL_INCLUDE_DIR MKL_LIBRARIES)

mark_as_advanced(MKL_INCLUDE_DIR MKL_LIBRARIES
    MKL_CORE_LIBRARY MKL_LP_LIBRARY MKL_ILP_LIBRARY
    MKL_SEQUENTIAL_LIBRARY MKL_INTELTHREAD_LIBRARY MKL_GNUTHREAD_LIBRARY
)
```