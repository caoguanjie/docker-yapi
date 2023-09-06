# YApi  可视化接口管理平台

源码来源 [yapi官方github](https://github.com/ymfe/yapi)仓库，并基于版本`1.9.2`的基础上二次开发部署


当前集成插件：(在config.json中添加进去即可使用)
- yapi-plugin-add-user
- yapi-plugin-import-swagger-customize
- yapi-plugin-interface-oauth2-token


## doker Hub镜像

为了更方便使用，博主已经构造好了一个镜像，开箱即用 链接：[docker hub](https://hub.docker.com/r/caoguanjie/docker-yapi)

镜像使用的可通过docker-compose的方式构建

```yml
# Use root/example as user/password credentials
version: '3.1'

services:
  mongo:
    image: mongo:latest
    restart: always
    volumes: 
        - ./mongo/data/db:/data/db
    ports: 
        - 27017:27017
    healthcheck:
      test: ["CMD", "netstat -anp | grep 27017"]
      interval: 2m
      timeout: 10s
      retries: 3
  yapi:
    build:
      context: ./
      dockerfile: Dockerfile
    image: yapi
    # 第一次启动会失败，因为MongoDB没有恢复用户数据，导致链接失败
    command: "node /yapi/vendors/server/app.js"
    ports: 
      - 3005:3000
    depends_on: 
      - mongo
```

## 二次开发

### mac环境搭建

硬性要求：以下版本一定要低，否则无法编译成功
-  本地node版本：v8.17.0
-  本地npm版本：v6.13.4
-  本地node-gyp版本：v9.3.1
-  本地python环境：2.7.18


### 部署客户端界面

如果需要调整界面或者改变yapi的代码，调整完代码之后，要执行命令之后，才会显示新的代码
```sh
# 打包yapi的客户端
npm run build-client
```
打包好的文件存放在路径：`static`文件夹里面，我们可以选择把`static`文件夹通过docker的复制命令`docker cp`把改变后的界面代码，复制到容器里面

也可以选择通过Dockerfile的文件，生成新的镜像，然后把镜像上传到docker Hub平台，然后再重启docker-compose命令，更新服务。
```sh
# 通过Dockerfile的文件构建镜像，要进入根目录  
docker build -t caoguanjie/docker-yapi:latest .
# 把镜像提交到docker Hub平台
docker push caoguanjie/docker-yapi:latest
# 去到相应的文件夹，执行docker-compose命令更新服务，记得要修改镜像的版本
docker-compose up
```

## 安装新插件
> 注意本地执行的node环境为：v8.17.0

```sh
# 预装安装yapi-cli: npm install -g yapi-cli --registry https://registry.npmmirror.com
yapi plugin --name yapi-plugin-add-user
# yapi命令会改变config.json文件，并且执行命令：NODE_ENV=production ykit pack -m
```

## 数据备份
1. 先编写shell脚本进行数据库的备份操作
```sh
# 路径： mongodump.sh
# -h 连接的数据库地址， -d 数据库名称，-o 导出路径， -u 用户名， -p 密码
mongodump -h 127.0.0.1:27017 -d yapi -o /data/backup 


# 把数据库文件打包,压缩包的名字类似：yapi_2023-08-23.tar.gz
tar -zcvf  /data/db/backup/yapi_$(date +%F).tar.gz /data/db/backup/yapi
# 对应的解压命令是： tar -xzvf /data/db/backup/yapi_2023-08-23.tar.gz /data/db/backup/yapi

# 删除目录
rm -rf /data/db/backup/yapi
```

2. 设置定时任务。
```sh
# 进到MongoDB容器的终端中，安装crontab
apt-get update
apt-get install -y cron
apt-get install -y vim
apt-get -y install systemctl
# 设置定时任务，执行下面的命令会进去一个配置文件中去
crontab -e 
# 进到配置文件后，键盘输入： i，进行修改
# 加上一条定时任务
# 可以去菜鸟教程查看crontab命令：https://www.runoob.com/w3cnote/linux-crontab-tasks.html

# 定义每周1到六，每天2点进行数据库备份
*   2   *   *   1-6   sh /yapi/mongodump.sh

# 进行上面操作后，键盘输入 esc + :wq(退出并保存)
# ！！！！！注意保存前，一定要删除容器中其他的定时任务，防止占用资源

# cron服务是Linux的内置服务，但它不会开机自动启动。可以用以下命令启动和停止服务
# crond start（启动）、crond stop(停止)、crond restart(重启服务)、crond reload(重新加载)
# 因此我们可以输入下面命令，进行定时器的启动
cron start
```


## 数据还原
直接进入MongoDB的容器的终端
```sh
## 命令结构是：>mongorestore -h <hostname><:port> -d dbname <path>
mongorestore -h 127.0.0.1:27017 -d yapi /data/backup/yapi
## [-h] MongDB所在服务器地址，例如：127.0.0.1或localhost，当然也可以指定端口号：127.0.0.1:27017
## [-D / -d] 需要恢复的数据库实例，例如：test，当然这个名称也可以和备份时候的不一样，比如yapi
## [path] mongorestore 最后的一个参数，设置备份数据所在位置，这个备份数据，就是上面备份生成的备份数据文件夹，例如:D:\MongoDB\Server\4.2\data\yapi
```

如果在容器挂载的数据卷`/data/db/`中找不到文件夹restore-data，可以选择在宿主机中自行创建，创建完成会同步在docker容器中进行同步


我们可以进到yapi正在运行的容器中，打开容器中的终端命令界面，然后输入以下命令即可完成数据的恢复
```sh
sh /yapi/vendors/mongorestore.sh
```


## 踩坑记录

### 管理员账号初始化失败
如果重新安装，出现如下错误，请删除管理员账号信息
```
(node:20024) UnhandledPromiseRejectionWarning: Error: 初始化管理员账号 "admin@admin.com" 失败, E11000 duplicate key error collection: yapi.user index: email_1 dup key: { : "admin@admin.com" }
```
进入数据库删除管理员账户信息
```sh
mongo

> use yapi;

> db.user.remove({"username":"admin"})
```

### 数据库恢复数据失败
```sh
# 错误信息，只有一个数据修复成功，其他都修复失败了
1 document(s) restored successfully. 840 document(s) failed to restore.
```

解决办法

进入容器的终端，进去mongo数据库，删除yapi这个数据，再执行恢复数据

```sh
mongo

> use yapi;

> db.dropDatabase()

> exit

mongorestore -h 127.0.0.1:27017 -d yapi /data/db/restore-data/yapi
```

## mock模拟数据，模拟数组经常失败
问题报错， 问题在[issue](https://github.com/YMFE/yapi/issues/731)：
```sh
2023-08-26 13:02:42 [json-schema-faker] calling JsonSchemaFaker() is deprecated, call either .generate() or .resolve()
```

解决办法：
```sh
# 将版本0.5.0-rc16变成0.5.0-rc13
npm i json-schema-faker@0.5.0-rc13
# 重新编译生成客户端
npm run build-client   
```sh


## MongoDB-启动的时候出现了问题
```
# 通过执行重复命令：mongod --fork --dbpath=/data/db/  --logpath=mongodb.log ，报以下错误
2023-08-31 14:30:54 about to fork child process, waiting until server is ready for connections.
2023-08-31 14:30:54 forked process: 10
2023-08-31 14:30:55 child process started successfully, parent exiting
```
原因：mongod没有后台执行，在终端连接非正常断开后，再次执行mongod报错

解决办法：
1、千万不要直接重启docker的容器，最好是重启docker-compose的服务，避免突然中断数据库带来的问题
2、进入 mongod 上一次启动的时候指定的 data 目录 --dbpath=/data/mongodb，删除掉该文件:
```sh
rm /data/db/mongo.lock
```
3、再执行：
```sh
mongod --repair
```

以上解决方案都不行，就重新部署吧，记得要把`/data/db/backup`文件夹中最近的备份拷贝好，以便恢复数据