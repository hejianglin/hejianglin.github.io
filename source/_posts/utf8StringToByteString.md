---
title: UTF8字符编码转换为字节编码
date: 2018-11-12
categories: 编码
description: UTF8字符编码转换为字节编码
tags: 编码
---

在上周碰到一个比较坑爹(有可能也是我后知后觉了 - -' （大雾..)的问题,来看下下面的文件吧:  
```shell
Encryption key:on
ESSID:"\xE8\xA7\x86\xE6\x98\x93\xE7\x82\xB9\xE6\xAD\x8C\xE6\x9C\xBAK72_V2uqa  "
...
Encryption key:on
ESSID:" \xE8\xB7\xAF\xE8\xBE\xB9\xE3\x80\x82 lhwfacl\xE4\xBB\x8E5gu"
```
其中  
```
"\xE8\xA7\x86\xE6\x98\x93\xE7\x82\xB9\xE6\xAD\x8C\xE6\x9C\xBAK72_V2uqa  "
```
已经是UTF8编码了，不过你尝试读取文件然后直接进行转码就会发现死活转不过来，为什么？  

<!--more-->


## 字符和字节
这2个其实区别很明显,但在这里却坑了我很久。使用[xxd](https://en.wikipedia.org/wiki/Hex_dump)看下上面这段字符的编码吧：  
```shell
00000140: 2020 2020 2020 2020 2020 456e 6372 7970            Encryp
00000150: 7469 6f6e 206b 6579 3a6f 6e0a 2020 2020  tion key:on.
00000160: 2020 2020 2020 2020 2020 2020 2020 2020
00000170: 4553 5349 443a 225c 7845 385c 7841 375c  ESSID:"\xE8\xA7\
00000180: 7838 365c 7845 365c 7839 385c 7839 335c  x86\xE6\x98\x93\
00000190: 7845 375c 7838 325c 7842 395c 7845 365c  xE7\x82\xB9\xE6\
000001a0: 7841 445c 7838 435c 7845 365c 7839 435c  xAD\x8C\xE6\x9C\
000001b0: 7842 414b 3732 5f56 3275 7161 2020 220a  xBAK72_V2uqa  ".
```
是了，文件是按字符格式保存的，为什么没有直接转为UTF8格式呢，这个还是不要问我了(- -'因为不支持啊),于是这么一串. 
```
\xE8\xA7\x86\xE6\x98\x93\xE7\x82\xB9\xE6\xAD\x8C\xE6\x9C\xBAK72_V2uqa  
```
你保存到[string](https://en.wikipedia.org/wiki/C%2B%2B_string_handling)下其实就是表面上的东西:  
```c++
char [0] = '\';
char [1] = 'x';
...
```
而不是你想要的:  
```c++
char [0] = E8;
char [1] = A7;
...
```

## 转换一下
既然知道这个,那么转换起来就很快了,流程大概是:  
1. 按字符串分割.  
2. 将字符转为字节格式. 
3. 序列化字节. 
代码如下:

```c++
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

using namespace std;

vector<string> readFile(string const &file)
{
    vector<string> strVector;
    string strLine;
    if(!file.empty()){
        fstream read(file);
        while(getline(read,strLine)){
            strVector.push_back(strLine);
        }
    }

    return strVector;
}

std::vector<std::string> split(const std::string &str,const std::string &pattern)
{
    std::vector<std::string> resVec;

    if ("" == str){
        return resVec;
    }
    //方便截取最后一段数据
    std::string strs = str + pattern;

    size_t pos = strs.find(pattern);
    size_t size = strs.size();

    while (pos != std::string::npos){
        std::string x = strs.substr(0,pos);
        resVec.push_back(x);
        strs = strs.substr(pos+pattern.size(),size);
        pos = strs.find(pattern);
    }

    return resVec;
}


int charToByte(const char s[],char bits[]) {
    int i,n = 0;
    for(i = 0; s[i]; i += 2) {
        if(s[i] >= 'A' && s[i] <= 'F')
            bits[n] = s[i] - 'A' + 10;
        else bits[n] = s[i] - '0';
        if(s[i + 1] >= 'A' && s[i + 1] <= 'F')
            bits[n] = (bits[n] << 4) | (s[i + 1] - 'A' + 10);
        else bits[n] = (bits[n] << 4) | (s[i + 1] - '0');
        ++n;
    }
    return n;
}


int main(int, char **)
{
    //存放最后的结果
    vector<string> result;

    vector<string> fileContent = readFile("./test");
    for(unsigned int i = 0; i< fileContent.size(); i++){

        //存放结果的临时数组
        char *temp = new char[fileContent.at(i).size() + 1];
        memset(temp,0,fileContent.at(i).size() + 1);

        //分割
        vector<string> lineContent = split(fileContent.at(i),"\\x");

        //如果小于 3 说明可能都是纯字符
        if(lineContent.size() < 3){
            result.push_back(fileContent.at(i));
        }

        //转换
        int k = 0;
        for(unsigned int j = 0; j < lineContent.size(); j++){
            if(lineContent.at(j) == ""){
                continue;
            }

            string strLess;
            string strChar = lineContent.at(j);
            if(strChar.size() > 2){
                strLess = strChar.substr(2,strChar.size());
                strChar = strChar.substr(0,2);
            }

            charToByte(strChar.c_str(),temp + k);
            k++;

            if(!strLess.empty()){
                for(unsigned int m = 0; m < strLess.size(); m++){
                    temp[k++] = strLess.at(m);
                }
            }
        }
        result.push_back(string(temp));
        delete []temp;
    }

    for(unsigned int i = 0; i< result.size(); i++){
        cout<<"result:"<<result.at(i)<<endl;
    }


    return 0;
}


```
测试文件内容如下：
```
\xE8\xA7\x86\xE6\x98\x93\xE7\x82\xB9\xE6\xAD\x8C\xE6\x9C\xBAK72_V2uqa  
\xE8\xB7\xAF\xE8\xBE\xB9\xE3\x80\x82 lhwfacl\xE4\xBB\x8E5gu
```

## 参考
- [读取文件](https://blog.csdn.net/CosmopolitanMe/article/details/70879894)
- [截取字符串](https://blog.csdn.net/xjw532881071/article/details/49154911)
- [字符转换](https://blog.csdn.net/u012372584/article/details/78901478)
