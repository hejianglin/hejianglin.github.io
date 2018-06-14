---
title:makefile(3)函数
date: 2018-05-27 21:22:12
categories:compiler
description :介绍makefile中函数的使用
tags :compiler
---

## 前言 

学习make和makefile的主要目的是分析大型项目的源代码的关系,上一节我们讲述了makefile 中的变量,本节主要学习一下 makefile 中的函数,首先函数肯定可以分为几部分:

- 内置函数
- 用户自动义函数
- 函数的调用
- ..

### 函数的语法

make 下所有函数都有如下形式:

```
$(function-name arg1[,arg2,arg3,..])
```

我们首先来看内置函数:

## 内置函数 

make 的内置函数可分类如下:

### 字符串函数 

#### $(filter pattern …,text)

pattern 中可以使用 % 来做通配符,值得注意的是: **每个 pattern 只支持 1 个 % **,比如:

```
//makefile
words := he the hen other the%
get-word:
	@echo he matches: $(filter he,$(words))
	@echo th% matches: $(filter th%,$(words))
	@echo %th% matches: $(filter %th%,$(words))
```

结果为:

```
//result
he matches: he
th% matches: the the%
%th% matches: #最后一个不匹配,因为words中不存在以th%为结尾的单词
```

#### $(filter-out pattern ..,text)

filter-out同filter相反,比如:

```
//makefile
words := he the hen other the%
get-word:
	@echo %th% matches: $(filter %th%,$(words))
	@echo %th% matches: $(filter-out %th%,$(words))
```

结果为:

```
//result
%th% matches:
%th% matches: he the hen other the%
```

#### $(findstring string…,text)

此函数所返回会的只是**"搜索字符"**而不是包含搜索字符的字符,另外**不支持pattern**

```
words := he the hen other the%
get-word:
	@echo %th% matches: $(findstring %th%,$(words))
	@echo he matches: $(findstring he,$(words))
	@echo he% matches: $(findstring he%,$(words))
```

结果为:

```
%th% matches:
he matches: he
he% matches: he%
```

#### $(subst search-string,replace-string,text)

不具有通配符能力的搜索替换函数,最经常使用于替换文件名列表的扩展名,如:

```
sources := fun.c foo.c
objects := $(subst .c,.o,$(sources))

target:
	@echo $(objects)
```

结果为:

```
fun.o foo.o
```

#### $(patsubst search-pattern,replace-pattern,text)

具有通配符能力的替换功能,有几个注意点:

- 此处的模式只可以包含一个 % 字符
- replace-pattern中的百分比符号会被替换成与符号相符的文字
- search-pattern必须和text的整个值进行匹配

```
source := main.c
object := $(patsubst %.c,%.o,$(source))
target:
	gcc -c $(source) -o $(object)
```

结果为:

```
gcc -c main.c -o main.o
```



### 单词函数 

#### $(words text)

统计text中单词个数 ,按照"space(空格)"进行拆分

```
CURRENT_PATH := $(subst /, ,$(PWD))
words:
	@echo current path $(PWD)
	@echo current path has $(words $(CURRENT_PATH)) directories
```

结果为:

```
current path /Users/hejianglin/study/makefile
current path has 4 directories
```

#### $(word n,text)

"space(空格)"进行拆分,返回 text 中的第 n 个单词,开始编号为 1,如果找不到相应的位置则返回空

```
CURRENT_PATH := $(subst /, ,$(PWD))
words:
	@echo current path $(PWD)
	@echo current path second word: $(word 2,$(CURRENT_PATH))
```

结果为:

```
current path /Users/hejianglin/study/makefile
current path second word: hejianglin
```

#### $(wordlist start,end,text)

"space(空格)"进行拆分,返回 text 中的第 start(含) 到 end(含) 的单词,开始编号为 1,如果找不到相应的位置则返回空



### 文件名函数

#### $(wildcard pattern..)

文件列表

```
source := $(wildcard src/*.c include/*.h)

.PHONY: test
test:
	@echo $(source)
```

结果为:

```
src/foo.c src/fun.c src/main.c include/foo.h include/fun.h
```

#### $(dir list...)

目录列表

```
source := $(wildcard src/*.c include/*.h)

.PHONY: test
test:
	@echo $(dir $(source))
```

结果为:

```
src/ src/ src/ include/ include/
```

#### $(notdir list..)

删除目录的文件列表

```
source := $(wildcard src/*.c include/*.h)

.PHONY: test
test:
	@echo $(notdir $(source))
```

结果为:

```
foo.c fun.c main.c foo.h fun.h
```

#### $(suffix name...)

返回每个单词的后缀

#### $(basename name...)

suffix的反函数

#### $(addsuffix suffix, name...)

添加后缀名称

#### $(addprefix prefix,name...)

addsuffix的反函数,添加前缀

#### $(join prefix-list,suffix-list)

连接字符,dir 和 notdir 的反函数

```
source := $(wildcard src/*.c include/*.h)
prefix_dir := $(dir $(source))
suffix_file := $(notdir $(source))
.PHONY: test
test:
	@echo join $(join $(prefix_dir),$(suffix_file))
```

结果为:

```
join src/foo.c src/fun.c src/main.c include/foo.h include/fun.h
```



### 其他

#### $(sort list)

排序 list 并移除重复项,排序优先级: 数字 > 字母,字母按照升序排序:

```
source := b c 1 2 d 0 c
target:
	@echo sort source: $(sort $(source))
```

结果为:

```
sort source: 0 1 2 b c d
```

#### $(shell command)

执行 shell 命令,输出的换行被替换成单一的空格符号,错误和状态都不会返回

```
.PHONY: test
CURRENT_DATE = $(shell date +%Y%m%d)
test:
	@echo $(CURRENT_DATE)
```

结果为:

```
20180610
```



## 流程控制

### if

#### $(if condition, then-part,else-part)

只要 condition 返回不为空,则为 true 便会执行 then-part, 否则执行 else-part

```
$(if $(filter $(MAKE_VERSION),3.79 3,80),,\
			$(error requires makefile version -.))

.PHONY: test
test:
	@echo join $(join $(prefix_dir),$(suffix_file))
```

结果为:

```
makefile:1: *** requires makefile version -..  Stop.
```

因为本机的 make 版本是 3.81

### for/while

#### $(foreach variable,list,body)





