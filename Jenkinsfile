pipeline{
      // 定义groovy脚本中使用的环境变量
      environment{
        // 将构建任务中的构建参数转换为环境变量
	//IMAGE = sh(returnStdout: true,script: 'echo registry.$image_region.aliyuncs.com/$imag_namespace/$image_reponame').trim()
	IMAGE = "registry.xxxx.aliyuncs.com/demo/demo-test"
	BRANCH =  "develop"
	APP_NAME = "accounts"
	VERSION = "1.0"
      }

      // 定义本次构建使用哪个标签的构建环境，本示例中为 “slave-pipeline”
      agent{
        node{
          label 'slave-pipeline'
        }
      }

      // "stages"定义项目构建的多个模块，可以添加多个 “stage”， 可以多个 “stage” 串行或者并行执行
      stages{
        // 定义第一个stage， 完成克隆源码的任务
        stage('Git'){
          steps{
            git branch: "${BRANCH}", credentialsId: 'github_creds', url: 'https://gitee.com/passerbyabc/jenkins_doc.git'
          }
        }

        // 添加第三个stage, 运行容器镜像构建和推送命令， 用到了environment中定义的groovy环境变量
        stage('Image Build And Publish'){
          steps{
	    //变量的使用
            script{
		commit_id = sh(returnStdout: true,script: "git rev-parse --short HEAD").trim()
		IMAGE = "${IMAGE}:${VERSION}.${BUILD_NUMBER}-${commit_id}"
            }
            container("kaniko") {
              sh "kaniko -f `pwd`/Dockerfile -c `pwd` --destination=${IMAGE} --skip-tls-verify"
            }
          }
        }

        // 添加第四个stage, 部署应用到指定k8s集群
        stage('Deploy to Kubernetes') {
          steps {
            container('kubectl') {
		sh "sed -i 's#IMAGE#${IMAGE}#g' application.yaml"
		sh "sed -i 's#APP_NAME#${APP_NAME}#g' application.yaml"
		sh "kubectl apply -f  application.yaml"
            }
          }
        }
      }
}
