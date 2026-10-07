pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-sa
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - sleep
    args:
    - 99d
    volumeMounts:
    - name: registry-credentials
      mountPath: /kaniko/.docker
  - name: kubectl
    image:  alpine/k8s:1.29.0
    command:
    - sleep
    args:
    - 99d
  volumes:
  - name: registry-credentials
    secret:
      secretName: registry-credentials
"""
        }
    }

    environment {
        IMAGE_NAME = "kind-registry:5000/fitness-tracker"
        IMAGE_TAG  = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push with Kaniko') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \
                        --context=`pwd`/app \
                        --dockerfile=`pwd`/app/Dockerfile \
                        --destination=${IMAGE_NAME}:${IMAGE_TAG} \
                        --destination=${IMAGE_NAME}:latest \
                        --insecure \
                        --skip-tls-verify
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh """
                        kubectl set image deployment/fitness-app \
                        fitness-app=${IMAGE_NAME}:${IMAGE_TAG} \
                        -n fitness-tracker

                        kubectl rollout status deployment/fitness-app -n fitness-tracker
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {
                container('kubectl') {
                    sh """
                        sleep 5
                        kubectl run smoke-test --rm -i --restart=Never \
                        --image=curlimages/curl -n fitness-tracker -- \
                        curl -sf http://fitness-app:5000/
                    """
                }
            }
        }
    }
}
