---
title: NFS共享设置
date: 2018-04-13 09:42:04
categories:  网络协议
description : Windows 和 Linux 的 NFS 共享设置
tags : NFS
---

## 前言

为了避免每次从windows下载文件之后都要再手动拷贝到虚拟机下面，还是在这 2 个系统之间搭建一个共享机制吧（愁..


<!--more-->
## 环境说明

- 虚拟机：ubuntu-12.04.5-i386
- Windows：Windows 7 旗舰版 32位



## 虚拟机设置

- 安装 nfs-server 和 nfs-comon

  ```
  sudo apt-get install nfs-kernel-server//会自动安装client即nfs-common
  ```

- 设置共享目录权限,比如:

  ```
  chmod 0777 -R /home/hejianglin/nfs
  ```

- 设置 nfs 的共享目录

  ```
  sudo vim /etc/exports
  ```

  在文件的最后添加下面一行

  ```
  /home/hejianglin/nfs *(rw,sync,no_subtree_check)
  ```

  *及括号内的含义可以[参考此处](https://blog.csdn.net/sokril/article/details/78910100)

- 重启 nfs

  ```
  sudo service nfs-kernel-server restart
  ```

- 重启 portmap

  ```
  sudo service portmap restart
  ```

  关于 nfs 和 portmap 的关系可以[参考此处](https://www.centos.org/docs/5/html/Deployment_Guide-en-US/s2-nfs-methodology-portmap.html)

##  Window设置

- 打开nfs功能

  通过**打开或关闭Windows功能**中的nfs服务

## 使用

### Windows为Client,虚拟为Server

打开 Windows 下面的 cmd,执行

```
//mount 虚拟机ip:虚拟机nfs路径 挂载磁盘:
mount 192.168.2.200:/home/hejianglin/nfs K:
```

即可



### Windows为Server,虚拟机为Client



## 总结

✿✿ヽ(°▽°)ノ✿

