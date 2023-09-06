# FROM node:12-alpine as builder
# WORKDIR /yapi
# RUN apk add --no-cache wget python3 make
# ENV VERSION=1.9.2
# RUN wget https://github.com/YMFE/yapi/archive/v${VERSION}.zip
# RUN unzip v${VERSION}.zip && mv yapi-${VERSION} vendors
# RUN cd /yapi/vendors && cp config_example.json ../config.json && npm install --production --registry https://registry.npm.taobao.org

# FROM node:12-alpine
# ENV TZ="Asia/Shanghai"
# WORKDIR /yapi/vendors
# COPY --from=builder /yapi/vendors /yapi/vendors
# EXPOSE 3000
# ENTRYPOINT ["node"]

FROM node:18.17
COPY repositories /etc/apk/repositories

RUN npm install -g yapi-cli --registry https://registry.npmmirror.com && \
    mkdir -p /yapi

WORKDIR /yapi
COPY ./ /yapi

EXPOSE 3000


