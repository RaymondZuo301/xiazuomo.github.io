---
title: pytorch_detectron2_pyinstaller
categories:
  - temp
tags:
  - temp
comments: true
mathjax: false
date: 2019-10-31 11:57:14
updated: 2019-10-31 11:57:14
---

# Pytorch1.3编译

新建conda环境

```bash
conda create -n detectron2_pytorch python=3.6.9
```

安装依赖

numpy 1.15.0 实测可行

```bash
conda install numpy==1.15.0
conda install ninja pyyaml mkl mkl-include setuptools cmake cffi typing
```

根据版本安装magma-cuda

```bash
conda install -c pytorch magma-cuda90
```

拉取pytorch源码

```bash
git clone --recursive https://github.com/pytorch/pytorch
cd pytorch
git checkout v1.3.0
git submodule sync
git submodule update --init --recursive
```

编译

```bash
export MAX_JOBS=4
python setup.py install
```

# detectron2

编译torchvision

```bash
git clone https://github.com/pytorch/vision.git
cd vision
git checkout v0.4.1
python setup.py install
```

安装其他依赖

```bash
pip install opencv-python
pip install 'git+https://github.com/facebookresearch/fvcore'
pip install cython
pip install 'git+https://github.com/cocodataset/cocoapi.git#subdirectory=PythonAPI'
```

编译

```bash
git clone git@github.com:facebookresearch/detectron2.git
cd detectron2
python setup.py build develop
```

# pyinstaller

```bash
pip install pyinstaller
pyinstaller xxx.py
```

修改xxx.spec
```
from PyInstaller.utils.hooks import collect_submodules
from PyInstaller.utils.hooks import collect_data_files
block_cipher = None
a = Analysis(['../test_model_new.py'],
             pathex=['xxxxxxxxxxx'],
             binaries=[],
             datas=collect_data_files('fvcore'),
             hiddenimports=collect_submodules('fvcore'),
             ...
```
