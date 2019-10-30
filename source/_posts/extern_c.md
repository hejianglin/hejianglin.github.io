---
title: extern "C"
date: 2019-06-26 22:24:04
categories:  C/C++
description : extern "C" 的用意
tags : C
---

## 前言
很常见的一个东西,有时候会记反相应的顺序,记录一下

## extern "C"
首先来 C 语言下,这个 main.c 的编译情况:  
``` C
int a = 0;
void fun()
{
	return ;
}

int main(int argc, char *argv[])
{
	int k = a;
	return 0;
}
```
查看符号表
``` shell
gcc -o main_c main.c
nm main_c
```
可以看到是这样的:
``` shell
0000000100000000 T __mh_execute_header
0000000100001000 S _a
0000000100000f80 T _fun
0000000100000f90 T _main
                 U dyld_stub_binder
```

<!--more-->
### 使用 g++ 呢?
复制一份 main.c 的代码为 main.cpp,通过:
``` shell
g++ -o main_cpp main.cpp
nm main_cpp
```
可以看到符号表是这样:
``` shell
0000000100000f80 T __Z3funv
0000000100000000 T __mh_execute_header
0000000100001000 S _a
0000000100000f90 T _main
                 U dyld_stub_binder
```

### extern "C"
为了兼容这样的情况(C 调用 C++ 的接口),修改 main.cpp 为下面的样子:
``` c++
#ifdef __cplusplus
extern "C" {
#endif

int a = 0;
void fun()
{
	return ;
}

int main(int argc, char *argv[])
{
	int k = a;
	return 0;
}

#ifdef __cplusplus
}
#endif
```
重新编译并查看符号表:
``` shell
0000000100000000 T __mh_execute_header
0000000100001000 S _a
0000000100000f80 T _fun
0000000100000f90 T _main
                 U dyld_stub_binder
```

可以看到上面的 fun 符号表和 C 的已经一样了。

✿✿ヽ(°▽°)ノ✿

