---
title: makefile(2)变量和宏
date: 2018-05-26 17:52:34
categories:  compiler
description: 介绍在makefile中使用变量和宏的各种方法
tags: compiler
---

## 前言

> make 包含 2 种语言: 第一种用来描述工作目标和必要条件的依赖关系, 第二种是用来进行文字替换的宏语言

我们在上一节已经见过第一种语言(规则)的用法了,其中我们也定义了类似于:

```
VPATH = ...
vpath = ...
CPPFLAG = ..
```

等变量的值,本节主要介绍一下 makefile 中变量的用法.



## 变量

变量的存在是为了最大程度的复用

### 创建变量

变量的来源可以有:

- 文件 

- 命令行

  ```
  make CFLAG=-g ...
  ```

- 环境变量 (优先级低且降低移植性)

- 自动创建

### 一些规则

> 仅记录自己需要注意的规则

- 变量名称区分大小写

- 可以使用 "$(CC)" 或者  "\${CC}" 的方式使用变量

- 一个变量的值由赋值符号右边已删除前导空格的所有字符组成,因此有一种情况需要注意:

  ```
  library = libutils.a #注意libutil.a后面多了一个空格
  ```

  此时如果的变量"library"的值为:

  ```
  libutils.a #同样包含这个空格
  ```

### 类型

make 的变量有2种类型:

- 简单扩展的变量

  ```
  //使用 := 赋值运算符来定义
  MAKE_DEPEND := $(CC) -M
  ```

  扩展的原则：

  > 一旦make从makefile读进该变量的定义语句,赋值运算符的右边部分会立刻被扩展,而扩展后的文本会被存储为该变量的值

  **注意: 如果需要拓展的内容为空,则相应的值被拓展后为<space>(空格)**

  比如,上面的额CC如果未定义,则遇到扩展后将变为:

  ```
  MAKE_DEPEND =  -M
  ```

- 递归扩展的变量

  ```
  //使用 = 赋值运算符来定义
  MAKE_DEPEND = $(CC) -M
  ```

  扩展的原则:

  > 扩展的动作会被延迟到该变量被使用的时候才进行

  比如:

  ```
  MAKE_DEPEND = $(CC) -M
  //第一次使用MAKE_DEPEND但是却没有的定义CC,则:
  MAKE_DEPEND = -M
  //定义 CC
  CC = gcc
  //第二次使用MAKE_DEPEND:
  MAKE_DEPEND = gcc -M
  ```



### 其他的赋值方式

上面说使用了 := 来创建简单变量,使用 = 来创建递归变量,另外make还提供了 ?= 和 +=.



#### 赋值方式 ?=

> ？= 运算符成为附带条件的变量赋值运算符

条件 ?  是什么条件 ? 

?= 用于首次定义,仅在变量的值不存在时对他进行赋值



#### 赋值方式 +=

> += 附加运算符

即附加相应的字符到变量



## 宏

> 变量适合用来存储单行形式的值,可是对于多行形式值,比如脚本命令(函数),却表现得比较尴尬,因此宏就是来做这个事的

**⚠️: 宏只是用来定义变量的另外一种方式**

### 创建宏

在GNU make 中,可以通过define来创建宏(macro),比如,你可以这么使用:

```
define update_dir
	@echo update dir $@... #echo 前置的@不会输出echo命令,只会使用echo输出,更多的意义在后面学习
	# do something
endef #必须独自成一行
```

### 使用宏

宏的使用和变量并没有什么区别,比如:

```
$(target) : $(condition1)  ...
	$(update_dir) #对应上面创建的宏 
```

比如:

```
BIN 	:= /usr/bin
PRINTF 	:= $(BIN)/printf
DF		:= /bin/df -h
AWK 	:= $(BIN)/awk

define _free_space
	$(PRINTF) "disk space statu:\n"
	$(DF) . | $(AWK) 'NR == 2 {print $4}'
endef

.PHONY: free_space
free_space:
	@$(_free_space) #不输出执行的命令行,只输出结果
```



## 目标专属变量

为了为特定目标添加特定的变量,可以使用如下方式:

```
gui.o: CPPFLAG += -DUSE_NEW_MALLOC=1
gui.o: gui.h
	$(COMPILE.c) $(OUTPUT_OPTION) $< 
```

当编译完成 "gui.o" 后 CPPFLAG 将会恢复原来的值



## 条件指令

### 定义

类似于 C  的 "#ifdef" ,在 make 中使用下面的方式定义:

```
ifdef COMSPEC #变量不需要使用$()等方式引用
	PATH_SEP := ;
	EXE_EXT := .exe
else
	PATH_SEP := :
	EXE_EXT :=
endif
```

恩,和 C 的 #ifdef 一模一样,更多条件可以是这样:

```
ifdef var
ifndef var
ifeq test
ifneq test
```

其中 ifeq 和 ifneq 中的 test 可以采用下面的方式:

```
//1
"condition1" "codition2"
//2
(condition1,condition2)
```



### 使用

> 条件处理指令可以用在宏定义和命令脚本中,还可以放在makefile的顶层

``` 
libGui.a: $(condition)
	$(AR) $(ARFLAGS) $@ $<
	ifdef RANLIB
		$(RANLIB) $@
	endif
```



## include 指令

可以包含自身,可能很有用? 下面是一个无限引用自身的写法:

```
.PHONY: dummy
makefile: dummy
	touch $@
```



## 标准的make变量

看图即可：

![标准make变量](http://oqnmphc00.bkt.clouddn.com/18-5-27/22941651.jpg)

