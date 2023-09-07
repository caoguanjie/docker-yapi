#!/bin/sh

# -h 连接的数据库地址， -d 数据库名称，-o 导出路径， -u 用户名， -p 密码
mongodump -h 127.0.0.1:27017 -d yapi -o /data/backup 

cd /data/backup 

# 把数据库文件打包，备份压缩文件名带上日期信息，避免重名，并方便识别
tar -zcvf  yapi_$(date +%F).tar.gz yapi

# 删除目录
rm -rf yapi