---
title: makefile(1)入门
date: 2018-05-12 09:12:11
categories:  编译器(compiler)
description : makefile 入门,介绍编写一个简单的makefile
tags : compiler
---



## 前言

最近准备学习一下 Linux 驱动开发,发现自己对 makefile 已经忘的差不多了,索性花点时间重新学习一下,顺便记录一下,个人选择的书籍是:[GNU Make 项目管理](https://book.douban.com/subject/1845284/)


<!--more-->
## make 和 makefile

关于 make 和 makefile 的关系可以直接参考[这里](https://baike.baidu.com/item/make/17067703?fr=aladdin)

简言之: makefile 记录各个源代码之间关系及描述详细的编译过程,make 通过读取 makefile, 按照 makefile 描述编译过程进行自动化编译.



问:那么 makefile 如何编写,make 又是怎么处理makefile的呢？

答:makefile 包含了一组用来编译应用程序的规则,**make 所看到的第一项规则会被视为默认规则**



那么规则长什么样子?

## 规则

一项规则可分为 3 个部分 : 1.target 2.prerequisite(前提条件) 3.command

```
target: prerequisite1  prerequisite2
	commands
```

比如:

### 单个规则

```
//single-target-makefile
hello : hello.c
	gcc hello.c -o hello
```

此时执行 make 则采用 target 默认采用 hello



### 多个规则

```
//multi-target-makefile
count_words: count_words.o lexer.o -lfl //default target
	gcc count_words.o lexer.o -lfl -o count_words

count_words.o: count_words.c //other-tager 1
	gcc -c count_words.c
	
lexer.o: lexer.c //other-target 2
	gcc -c lexer.c

lexer.c: lexer.l //other-target 3 deplay
	flex -t lexer.l > lexer.c

```

关于编译过程的几个步骤可以参考[这里](https://hejianglin.github.io/2018/05/12/compile_process/)

此时执行make可以有 4 种选项:

- make count_words (**默认规则**)
- make count_words.o
- make lexer.o
- make lexer.c

实际上执行 
```
make (count_words)
```
的时候 make 会根据 count_words所需要的依赖关系逐一的编译
```
make lexer.c make lexer.o make count_words.o
```

## 假(PHONY)的工作目标

### clear

.PHONY 用来告诉make,该target不是一个真正的文件.一般用于clear比如:

```
.PHONY: clear
clear:
	rm -rf *.o
```

原因: make 无法区分target 是不是一个真正的文件,比如此处的clear文件和clear命令



### all

同样的应用可以见:

```
.PHONY: all
all: target1 target2
```

如此便可以一次编译多个不相互依赖的target 



### 多次使用

在编写makefile的时候可能需要命令行的可移植性,比如下面

```
.PHONY: check_current_path_space
check_current_path_space:
	df -k . | awk 'NR==2 {print $4}'
```

为了多次使用
```
df -k . | awk 'NR==2 {print $4}
```
可以多添加一个中间层:

```
.PHONY: check_current_path_space
check_current_path_space: df

.PHONY: df
df:
	df -k . | awk 'NR==2 {print $4}'
```



### 说明

**这一步看的不是很懂,设置为TODO吧**



### 空目标(empty target)

**同样没看的明白,TODO**



## 变量

为了提高利用率,makefile 提供变量的使用,最简单的变量形式: 

```
$(var)//等同于 ${var}
```

make 在 makefile 中设定了几个自动变量

### make 设定的自动变量

| 变量   | 含义                        |
| ---- | ------------------------- |
| $@   | 工作目标的文件名                  |
| $%   | Archive member结构中的文件名     |
| $<   | 第一个必要条件的文件名               |
| $?   | 所有必要条件的文件名(时间戳在上次更新之后的文件) |
| $^   | 所有必要条件的文件名(去除重复的文件)       |
| $+   | 所有必要条件的文件名(未去除重复的文件)      |
| $i*   | 工作目标的主文件名(后文介绍)           |

下面是一下相应的测试:

```
#$< 第一个必要条件的文件名
hello: hello.c
	gcc -o $@ $<
#$? 和 $^
sum: sum.c sum_fun.o
	gcc -o $@ $^ # $?

sum_fun.o: sum_fun.c
	gcc -c $< -o $@

.PHONY: clean
clean:
	rm hello

.PHONY: clean_sum
clean_sum:
	rm sum sum_fun.o
```



## 多级目录

平时我们遇到的 make 更多的情况可能是这种目录结构:

```
├── include
│   ├── foo.h
│   └── fun.h
├── makefile
└── src
    ├── foo.c
    ├── fun.c
    └── main.cpp
```

结合前面的学习,我们可能会写出这样的 makefile:

```
test: src/main.c fun.o foo.o
	gcc -o $@ $^

fun.o: src/fun.c include/fun.h
	gcc -c $< -o $@

foo.o: src/foo.c include/foo.h 
	gcc -c $< -o $@
```

不过这样的编译结果是:

```
make: *** No rule to make target `src/main.c', needed by `test'.  Stop.
```

看样子 make 只会把 "src/main.c" 整个当成一个文件,因此此处引出了一个变量:

> VPATH : 告诉 make 到不同的目录去查找源文件

上面的 makefile 利用 VPATH 修改成这样:

```
VPATH = src
test:  fun.o foo.o main.c
	gcc -o $@ $^

fun.o: fun.c include/fun.h
	gcc -c $< -o $@

foo.o: foo.c include/foo.h
	gcc -c $< -o $@
```

然而这回确是找不到 include 的了:

```
gcc -c src/fun.c -o fun.o
src/fun.c:1:10: fatal error: 'fun.h' file not found
#include "fun.h"
         ^~~~~~~
1 error generated.
make: *** [fun.o] Error 1
```

这大概是因为我们在 "fun.c" 中 include 了 "fun.h" ，为了解决这个问题编译器的 "-I" 选项可以帮助我们:

```
VPATH = src
CPPFLAGS = -I include
test:  fun.o foo.o main.c
	gcc $(CPPFLAGS) -o $@ $^

fun.o: fun.c include/fun.h
	gcc $(CPPFLAGS) -c $< -o $@

foo.o: foo.c include/foo.h
	gcc $(CPPFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm fun.o foo.o test
```



### 缺点

上面的 "*.o" 的头文件还是包含 "include/*.h"

虽然 VPATH 变量可以解决搜索问题,不过如果你设置了 VPATH,那么 **make 将会为它所需要的任何文件搜索 VPATH 列表中的每个目录,如果在多个目录中出现同名文件,那么 make 只会获取第一个被找到的文件**



### 解决

使用 vpath ,这个指令的语法:

```
vpath pattern directory-list
```

上面的例子的 makefile 可以修改为:

```
vpath %.c src
vpath %.h include

CPPFLAGS = -I include

test:  fun.o foo.o main.c
	gcc $(CPPFLAGS) -o $@ $^

fun.o: fun.c fun.h
	gcc $(CPPFLAGS) -c $< -o $@

foo.o: foo.c foo.h
	gcc $(CPPFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm fun.o foo.o test
```



## 内置规则

为了简化 makefile 的编写工作, make 内置了许多模式规则而内置规则(built-in rule)是模式规则(pattern rule)的实例。若要查看make 的内置规则可以通过

```
make --print-data-base
```

查看,在我的环境下可以看到

```
# Implicit Rules

%.out:

%.a:

%.ln:

%.o:

%: %.o
#  commands to execute (built-in):
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@

%.c:

%: %.c
#  commands to execute (built-in):
	$(LINK.c) $^ $(LOADLIBES) $(LDLIBS) -o $@

%.ln: %.c
#  commands to execute (built-in):
	$(LINT.c) -C$* $<

%.o: %.c
#  commands to execute (built-in):
	$(COMPILE.c) $(OUTPUT_OPTION) $<

%.cc:

%: %.cc
#  commands to execute (built-in):
	$(LINK.cc) $^ $(LOADLIBES) $(LDLIBS) -o $@

%.o: %.cc
#  commands to execute (built-in):
	$(COMPILE.cc) $(OUTPUT_OPTION) $<

%.C:

%: %.C
#  commands to execute (built-in):
	$(LINK.C) $^ $(LOADLIBES) $(LDLIBS) -o $@

%.o: %.C
#  commands to execute (built-in):
	$(COMPILE.C) $(OUTPUT_OPTION) $<

//...
```

根据上面的描述,再来精简一下原来的makefile:

```
vpath %.c src
vpath %.h include

CPPFLAGS = -I include

test:  fun.o foo.o main.c
	gcc $(CPPFLAGS) -o $@ $^ #因为包含%.o 与 %.c 的结合,因此只能自己编写编译规则
fun.o: fun.c fun.h
foo.o: foo.c foo.h

.PHONY: clean
clean:
	rm fun.o foo.o test
```



### 修改规则变量的建议

> CFLAGS: 编译选项的变量
> CPPFLAGS: 预处理的变量
> TARGET_ARCH:  结构 选项

如果需要更新相应规则的变量值,建议使用**非系统默认**的变量名称,比如:

在原 make 中存在 CPPFLAGS 变量为(可通过 "make -p" 查看):

```
CPPFLAGS = -I includes
```

而此时你需要在添加一个搜索头文件的目录,**建议这么修改:**

```
INCLUDES = -I your_includes
```

然后在相应 makefile 中这么写:

```
gcc $(CPPFLAGS) $(INCLUDES) ...
```



## 静态库

我们可以通过命令 "ar" 生成一个静态库, 关于 ar 可以查看 man,此处重点描述一下静态库在 makefile 中的更新

### 生成

```
vpath %.c src
vpath %.h include

CPPFLAGS = -I include

test:  main.c libmyutil.a
	gcc $(CPPFLAGS) -o $@ $^

libmyutil.a: fun.o foo.o
	ar rv libmyutil.a $^

.INTERMEDIATE: fun.o foo.o

.PHONY: clean
clean:
	rm test libmyutil.a
```

.INTERMEDIATE 和 .PHONY 的类型一样,属于 makefile 中的特殊工作目标,它的作用是设定编译过程的中间文件,如果 make 在更新另一个工作目标期间创建了该文件,则该文件将在 make 运行结束时被自动删除,若在更新之前已存在则不删除.此处删除 fun.o 和 foo.o 文件,因为他们已经被打包到 libmyutil.a 中.

可以看一下 make 的执行流程(使用 "make --just-print" 可 查看过程却不执行):

```
cc  -I include  -c -o fun.o src/fun.c
cc  -I include  -c -o foo.o src/foo.c
ar rv libmyutil.a fun.o foo.o
gcc -I include -o test src/main.c libmyutil.a
rm fun.o foo.o
```



### 更新

按照上面的 makefile,此时如果 foo.c 或者 fun.c **其中一个**发生了改变,那 make 都会尝试重新编译他们,怎样做到只编译更新是此处要解决的问题.



#### library(%.o)

对需要打包的模块进行分别描述可以解决上面那个问题,比如:

```
vpath %.c src
vpath %.h include

CPPFLAGS = -I include

test:  main.c libmyutil.a
	gcc $(CPPFLAGS) -o $@ $^

libmyutil.a: libmyutil.a(fun.o) libmyutil.a(foo.o)
	ar rv libmyutil.a $?

.INTERMEDIATE: fun.o foo.o

.PHONY: clean
clean:
	rm test libmyutil.a
```

如果只是更新了 foo.c 则编译过程可能如下:

```
cc  -I include  -c -o foo.o src/foo.c
ar rv libmyutil.a foo.o
r - foo.o
ar rv libmyutil.a foo.o
r - foo.o
gcc -I include -o test src/main.c libmyutil.a
rm foo.o
```

 

### 链接顺序

> 每项规则的必要条件会依照他们被看到的顺序被一次附加到该工作目标的必要条件列表中

为了解决循环引用的问题(应避免这个问题才是吧),需要引入: "$?" 的使用,关于 "$?" 的使用可以查看上面关于变量的描述
