# Version 1.0
#MAINTAINER Aofa
FROM golang:1.16.1-alpine AS builder
COPY . /app
WORKDIR /app
ENV GOPROXY=https://goproxy.cn,direct
ENV GOPRIVATE=github.com
ENV GO111MODULE=on
ENV GOMOD=/app/go.mod

RUN sed -i 's:dl-cdn.alpinelinux.org:mirrors.tuna.tsinghua.edu.cn:g' /etc/apk/repositories && apk add git openssh-client
RUN go mod download && go build -o /main .

FROM alpine:3.12
COPY --from=0 /main /main
CMD ["/main"]
