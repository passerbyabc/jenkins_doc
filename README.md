# DevOps 部署（阿里云:Jenkins+k8s）
- 在jenkins中执行流水线，调用docker.sock执行build异常：
```
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/auth": dial unix /var/run/docker.sock: connect: permission denied
# 打镜像tag
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/build?buildargs=%7B%7D&cachefrom=%5B%5D&cgroupparent=&cpuperiod=0&cpuquota=0&cpusetcpus=&cpusetmems=&cpushares=0&dockerfile=Dockerfile&version=1": dial unix /var/run/docker.sock: connect: permission denied
```
解决方案：
- 本地Docker中执行jenkins调用宿主docker.sock
  ```
  docker run -it \
    --name jenkins \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -p 8080:8080 \
    jenkins/jenkins:latest
  ```
- Aliyun 容器服务 - Kubernetes ack 解决方案
  + 配置： (参考[阿里云ack](https://help.aliyun.com/document_detail/106712.html))
    在default命名空间下使用生成的config.json文件创建名为jenkins-docker-cfg的Secret
    解决：构建镜像时产生的私有镜像仓库权限验证问题。
  
  1.在本地当前用户根目录～/.docker下生成config.json（包含登陆信息）
  ```
  docker login -u username@youorigin -p password registry.cn-beijin.aliyuncs.com
  ```
  ```
  config.json
  {
    "auths": {
      "registry.cn-beijin.aliyuncs.com": {
        "auth": "fxxxxxxxdBh=="
      }
    }
  }
  ```
  2.创建Secret
  ```
  kubectl create secret generic jenkins-docker-cfg -n default --from-file=.docker/config.json
  ```
  注意事项：
  - 阿里云中应用市场创建的jenkins在配置cloud时，Pod Templates中jnlp用于连接Jenkins Master，在节点configureClouds配置时Pod Templates：jnlp的工作目录应该设置为/home/jenkins（~~/home/jenkins/agent~~）
  - pipeline中的env赋值： BRANCH = "develop" ，请使用双引号，~~如果使用单引号,则会报错~~。
    ```
    //示例
    environment{
        // 将构建任务中的构建参数转换为环境变量
				//IMAGE = sh(returnStdout: true,script: 'echo registry.$image_region.aliyuncs.com/$imag_namespace/$image_reponame').trim()
				IMAGE = "registry.cn-hangzhou.aliyuncs.com/demo/jenkins_doc"
				BRANCH =  "main"
				MYTOOL_VERSION = "1.0"
				APP_NAME = "accounts"
    }
    
    stage('Git'){
      steps{
        git branch: "${BRANCH}", credentialsId: 'gitee_creds', url: 'https://github.com/passerbyabc/jenkins_doc.git'
      }
    }
    ```
  - 获取git版本号赋值给变量
    ```
    stage('Image Build And Publish'){
      environment{
        COMMIT_ID = sh(returnStdout: true,script: "git rev-parse --short HEAD").trim()
        VERSION = "${MYTOOL_VERSION}.${BUILD_NUMBER}-${COMMIT_ID}"
        IMAGE = "${IMAGE}:${VERSION}"
      }

      steps{
        container("kaniko") {
          sh "kaniko -f `pwd`/Dockerfile -c `pwd` --destination=${IMAGE} --skip-tls-verify"
        }
      }
    }
    ```


