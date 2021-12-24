# jenkins_doc
# 问题
- 在jenkins中执行job中，调用docker.sock执行build异常：
```
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/auth": dial unix /var/run/docker.sock: connect: permission denied
# 打镜像tag
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/build?buildargs=%7B%7D&cachefrom=%5B%5D&cgroupparent=&cpuperiod=0&cpuquota=0&cpusetcpus=&cpusetmems=&cpushares=0&dockerfile=Dockerfile&version=1": dial unix /var/run/docker.sock: connect: permission denied
```
解决方案：
- 本地docker中执行jenkins调用宿主docker.sock
  ```
  docker run -it \
    --name jenkins \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -p 8080:8080 \
    jenkins/jenkins:latest
  ```
- alyun 容器服务 - Kubernetes ack 解决方案
  + 配置： (参考[阿里云ack](https://help.aliyun.com/document_detail/106712.html))
  在default命名空间下使用生成的config.json文件创建名为jenkins-docker-cfg的Secret
  解决：构建镜像前的私有镜像仓库权限验证问题。
  ```
  # 该命令会在当前用户根目录.docker下生成config.json登陆信息
  docker login -u username@youorigin -p password registry.cn-hangzhou.aliyuncs.com
  # 创建Secret
  kubectl create secret generic jenkins-docker-cfg -n default --from-file=.docker/config.json
  ```
  注意事项：阿里云中应用市场创建的jenkins在配置cloud时，Pod Templates中jnlp用于连接Jenkins Master，在节点configureClouds配置时Pod Templates：jnlp的工作目录应该设置为/home/jenkins（~~/home/jenkins/agent~~）

