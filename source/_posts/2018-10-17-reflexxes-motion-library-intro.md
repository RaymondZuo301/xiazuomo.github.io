---
title: Reflexxes运动规划库简介
categories:
  - 机器人
tags:
  - Reflexxes
  - 运动规划
  - 机器人
comments: true
mathjax: false
date: 2018-10-17 09:03:41
updated: 2018-10-17 09:03:41
---

## 概述

Reflexxes（全称为Reflexxes Motion Library，简称RML）是一个开源（Type-II开源， Type-IV商业库）的在线运动轨迹生成库，具有众多优点使其可以应用于机器人、数控机床和伺服驱动系统等领域，V-REP中集成了RML-Type-IV,目前Reflexxes公司已经被谷歌收购。

## Reflexxes算法库结构

### 概述
基本结构如下

![framework](algorithm-framework-4.png)

Type-II和Type-IV相差加加速度的边界条件和加速度输出

![type-ii](algorithm-framework-5.png)

![type-iv](algorithm-framework-6.png)

Reflexxes的在线轨迹生成算法主要分为以下三步：

- Step 1: 计算同步时间
- Step 2: 同步所选的轴
- Step 3: 计算输出数值

由于仅有Type-II开源以下仅涉及Type-II相关内容

### 接口层

- `ReflexxesAPI`是唯一的用户接口类非常紧凑，用它的两个方法`ReflexxesAPI::RMLPosition`来执行基于位置的在线轨迹生成算法和`ReflexxesAPI::RMLVelocity`用于基于速度的算法
- `RMLInputParameters`：包含`RMLPositionInputParameters`和`RMLVelocityInputParameters`，用于输入参数
- `RMLOutputParameters`：包含`RMLPositionOutputParameters`和`RMLVelocityOutputParameters`，用于输出参数
- `RMLFlags`包含：`RMLPositionFlags`和`RMLVelocityFlags`，用于在线轨迹规划算法的参数化标记，如同步方式（无同步non-synchronized、时间同步time-synchronized、相位同步phase-synchronized）等
- `RMLVector`：数组类

### 算法层

包含实际的Type-II在线轨迹生成算法，提供给`ReflexxesAPI`使用，其中包含了数学层中提供的决策树`TypeIIRMLDecisionTree`

- `TypeIIRMLPosition`：`ReflexxesAPI::RMLPosition`，实际调用的是`TypeIIRMLPosition::GetNextStateOfMotion`
- `TypeIIRMLVelocity`：`ReflexxesAPI::RMLVelocity`，实际调用的是`TypeIIRMLVelocity::GetNextStateOfMotion`

### 数学层

`TypeIIRMLPosition`和`TypeIIRMLVelocity`类所需的数学函数集合，包含：

- `TypeIIRMLMath::MotionPolynomials`：三个`TypeIIRMLPolynomial`数组（Pos、Vel、Acc）
- `TypeIIRMLMath::TypeIIRMLPolynomial`：三阶多项式

### 示例代码

基本的三轴规划示例代码：

```cpp
#define CYCLE_TIME_IN_SECONDS                   0.001
#define NUMBER_OF_DOFS                          3

int main()
{
// 变量声明
    int                         ResultValue                 =   0       ;
    ReflexxesAPI                *RML                        =   NULL    ;
    RMLPositionInputParameters  *IP                         =   NULL    ;
    RMLPositionOutputParameters *OP                         =   NULL    ;
    RMLPositionFlags            Flags                                   ;
// 初始化
    RML =   new ReflexxesAPI(NUMBER_OF_DOFS, CYCLE_TIME_IN_SECONDS);
    IP  =   new RMLPositionInputParameters(NUMBER_OF_DOFS);
    OP  =   new RMLPositionOutputParameters(NUMBER_OF_DOFS);
// 输入参数
    IP->CurrentPositionVector->VecData      [0] =    100.0      ;
    IP->CurrentPositionVector->VecData      [1] =      0.0      ;
    IP->CurrentPositionVector->VecData      [2] =     50.0      ;

    IP->CurrentVelocityVector->VecData      [0] =    100.0      ;
    IP->CurrentVelocityVector->VecData      [1] =   -220.0      ;
    IP->CurrentVelocityVector->VecData      [2] =    -50.0      ;

    IP->CurrentAccelerationVector->VecData  [0] =   -150.0      ;
    IP->CurrentAccelerationVector->VecData  [1] =    250.0      ;
    IP->CurrentAccelerationVector->VecData  [2] =    -50.0      ;

    IP->MaxVelocityVector->VecData          [0] =    300.0      ;
    IP->MaxVelocityVector->VecData          [1] =    100.0      ;
    IP->MaxVelocityVector->VecData          [2] =    300.0      ;

    IP->MaxAccelerationVector->VecData      [0] =    300.0      ;
    IP->MaxAccelerationVector->VecData      [1] =    200.0      ;
    IP->MaxAccelerationVector->VecData      [2] =    100.0      ;

    IP->MaxJerkVector->VecData              [0] =    400.0      ;
    IP->MaxJerkVector->VecData              [1] =    300.0      ;
    IP->MaxJerkVector->VecData              [2] =    200.0      ;

    IP->TargetPositionVector->VecData       [0] =   -600.0      ;
    IP->TargetPositionVector->VecData       [1] =   -200.0      ;
    IP->TargetPositionVector->VecData       [2] =   -350.0      ;

    IP->TargetVelocityVector->VecData       [0] =    50.0       ;
    IP->TargetVelocityVector->VecData       [1] =   -50.0       ;
    IP->TargetVelocityVector->VecData       [2] =  -200.0       ;

    IP->SelectionVector->VecData            [0] =   true        ;
    IP->SelectionVector->VecData            [1] =   true        ;
    IP->SelectionVector->VecData            [2] =   true        ;

// 迭代运算
    while (ResultValue != ReflexxesAPI::RML_FINAL_STATE_REACHED)
    {
// 获取下一周期状态
        ResultValue =   RML->RMLPosition(*IP, OP, Flags);
// 更新当前状态
        *IP->CurrentPositionVector      =   *OP->NewPositionVector      ;
        *IP->CurrentVelocityVector      =   *OP->NewVelocityVector      ;
        *IP->CurrentAccelerationVector  =   *OP->NewAccelerationVector  ;
    }
    delete  RML         ;
    delete  IP          ;
    delete  OP          ;
    exit(EXIT_SUCCESS)  ;
}
```

## 参考

- [https://www.cnblogs.com/21207-iHome/p/6344467.html](https://www.cnblogs.com/21207-iHome/p/6344467.html)
- [http://www.reflexxes.ws/software/typeiirml/v1.2.6/docs/index.html](http://www.reflexxes.ws/software/typeiirml/v1.2.6/docs/index.html)