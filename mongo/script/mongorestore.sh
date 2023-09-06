#!/bin/sh

## 命令结构是：>mongorestore -h <hostname><:port> -d dbname <path>
mongorestore -h 127.0.0.1:27017 -d yapi /data/db/backup/yapi
## [-h] MongDB所在服务器地址，例如：127.0.0.1或localhost，当然也可以指定端口号：127.0.0.1:27017
## [-D / -d] 需要恢复的数据库实例，例如：test，当然这个名称也可以和备份时候的不一样，比如yapi
## [path] mongorestore 最后的一个参数，设置备份数据所在位置，这个备份数据，就是上面备份生成的备份数据文件夹，例如:D:\MongoDB\Server\4.2\data\yapi