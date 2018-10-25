---
title: KDL运动学动力学库类结构、接口整理
categories:
  - 机器人
tags:
  - KDL
  - 运动学
  - ROS
  - 机器人
comments: true
mathjax: true
date: 2018-10-17 08:54:46
updated: 2018-10-17 08:54:46
---

## 基本数据类型

- Vector：double[3]，3维向量
- Rotation：double[9]，3\*3矩阵
- Frame：Vector+Rotation，变换矩阵
- Twist：Vector(平移速度)+Vector(旋转速度)
- Wrench：Vector(力)+Vector(转矩)

## Kinematic Trees运动学结构数据类型

### Joint关节

Joint = JointType + Scale(输入输出比) + Offset(reference->joint)+非必要（Inertia惯量+Damping阻尼+Stiffness刚度）
JointType = {RotAxis,RotX,RotY,RotZ,TransAxis,TransX,TransY,TransZ,None}

![kdl_joint](kdl-Joint.png)

### RigidBodyInertia刚体惯量

RigidBodyInertia = 质量+重力矩V3+转动惯量M3*3

![kdl-RigidBodyInert](kdl-RigidBodyInert.png)

### Segment杆件

Segment = Joint + RigidBodyInertia + Frame_reference + Frame_tip

![kdl-Segment](kdl-Segment.png)

### Chain无分支运动链

Chain = Vector(Segment)

![kdl-Chain](kdl-Chain.png)

## 算法

![kdl-Solver](kdl-Solver.png)

### 基类

- `SolverI`：solver interface用来存储和描述最近一次错误

### 正运动学

- `ChainFkSolverPos`继承自`SolverI`：Chain的正运动学接口
- `ChainFkSolverPos_recursive`继承自`ChainFkSolverPos`：递归fk
- `ChainFkSolverVel_recursive`继承自`ChainFkSolverPos`：递归fk-vel

例：`ChainFkSolverPos_recursive`接口
- 构造函数`ChainFkSolverPos_recursive(const Chain& chain)`
- 接口`virtual int JntToCart(const JntArray& q_in, Frame& p_out, int segmentNr=-1)`、`virtual int JntToCart(const JntArray& q_in, std::vector<Frame>& p_out, int segmentNr=-1);`

![kdl-ChainFkSolverPos](kdl-ChainFkSolverPos.png)

### 逆运动学

- `ChainIkSolverPos`继承自`SolverI`：Chain的逆运动学接口
- `ChainIkSolverPos_LMA`继承自`ChainIkSolverPos`：逆运动学——莱文贝格-马夸特，Levenberg-Marquardt
- `ChainIkSolverPos_NR`：逆运动学——牛顿-拉夫森，Newton-Raphson
- `ChainIkSolverPos_NR_JL`：逆运动学——牛顿-拉夫森带关节限位，Newton-Raphson with joint limits
- `ChainIkSolverVel_pinv`继承自`ChainIkSolverPos`：ik-vel——广义伪逆，generalize pseudo inverse
- `ChainIkSolverVel_pinv_nso`：ik-vel——广义伪逆（冗余机器人优化）
- `ChainIkSolverVel_pinv_givens`：ik-vel——广义伪逆（Givens）
- `ChainIkSolverVel_wdls`：ik-vel——加权伪逆（阻尼最小二乘）

例：`ChainIkSolverPos_LMA`接口

- 构造函数

```cpp
ChainIkSolverPos_LMA(
    		const KDL::Chain& _chain,
    		const Eigen::Matrix<double,6,1>& _L,
    		double _eps=1E-5,
    		int _maxiter=500,
    		double _eps_joints=1E-15);
    		
ChainIkSolverPos_LMA(
    		const KDL::Chain& _chain,
    		double _eps=1E-5,
    		int _maxiter=500,
    		double _eps_joints=1E-15);
```

- 接口

```cpp
virtual int CartToJnt(const KDL::JntArray& q_init, const KDL::Frame& T_base_goal, KDL::JntArray& q_out);
```

![kdl-ChainIkSolverPos](kdl-ChainIkSolverPos.png)