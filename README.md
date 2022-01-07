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
  注意事项：（[Jenkinfile](https://github.com/passerbyabc/jenkins_doc/blob/main/Jenkinsfile)）
  - 阿里云中应用市场创建的jenkins在配置cloud时，Pod Templates中jnlp用于连接Jenkins Master，在节点configureClouds配置时Pod Templates：jnlp的工作目录应该设置为/home/jenkins（~~/home/jenkins/agent~~）
  - pipeline中的env赋值： BRANCH = "develop" ，请使用双引号，~~如果使用单引号,则会报错~~。
    ```
    environment{
      BRANCH =  "main"
      GIT_URL = "https://github.com/passerbyabc/jenkins_doc.git"

      //将构建任务中的构建参数转换为环境变量
      //IMAGE = sh(returnStdout: true,script: 'echo registry.$image_region.aliyuncs.com/$imag_namespace/$image_reponame').trim()
      IMAGE = "registry.xxxxx.aliyuncs.com/repo/demo"
      APP_NAME = "demo"
      VERSION = "1.0"
      
      GITHUB_CREDS = credentials('github_creds')
    }
		
		
    //克隆源码
    stage('Git'){
      steps{
        git branch: "${BRANCH}", credentialsId: 'github_creds', url: "${GIT_URL}"
      }
    }
    ```
		
  - 获取git版本号赋值给变量
    ```
    // 添加第三个stage, 运行容器镜像构建和推送命令， 用到了environment中定义的groovy环境变量
    stage('Image Build And Publish'){
      steps{
        script{
            commit_id = sh(returnStdout: true,script: "git rev-parse --short HEAD").trim()
            IMAGE = "${IMAGE}:${VERSION}.${BUILD_NUMBER}-${commit_id}"
        }
          
        container("kaniko") {
          // 构建过程中Get私有库时，使用用户名和密码登陆git私有仓库。
          sh "echo \"machine github.com login ${GITHUB_CREDS_USR} password ${GITHUB_CREDS_PSW}\" > ~/.netrc"
          sh "kaniko -f `pwd`/Dockerfile -c `pwd` --destination=${IMAGE} --skip-tls-verify"
        }
      }
    }
    ```
## 参考
- [env](https://stackoverflow.com/questions/53541489/updating-environment-global-variable-in-jenkins-pipeline-from-the-stage-level/53541813)
- [kaniko](https://github.com/GoogleContainerTools/kaniko)
- [阿里云ack](https://help.aliyun.com/document_detail/106712.html)

