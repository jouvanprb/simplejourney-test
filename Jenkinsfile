pipeline {
    agent any

    environment {
        APP_NAME              = 'sj-app'
        DOCKER_REGISTRY       = 'docker.io'
        DOCKER_CREDENTIALS_ID = 'docker-registry-creds'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.COMMIT_HASH = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                }
            }
        }

        stage('Test') {
            steps {
                sh 'go test ./...'
            }
        }

        stage('Build Image') {
            steps {
                sh "docker build --build-arg VERSION=${env.COMMIT_HASH} -t ${env.APP_NAME}:${env.COMMIT_HASH} ."
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIALS_ID, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh """
                    echo "Menggunakan kredensial Jenkins ID: ${env.DOCKER_CREDENTIALS_ID} untuk registry: ${env.DOCKER_REGISTRY}"
                    # echo \${DOCKER_PASS} | docker login ${env.DOCKER_REGISTRY} -u \${DOCKER_USER} --password-stdin
                    # docker tag ${env.APP_NAME}:${env.COMMIT_HASH} \${DOCKER_USER}/${env.APP_NAME}:${env.COMMIT_HASH}
                    # docker push \${DOCKER_USER}/${env.APP_NAME}:${env.COMMIT_HASH}
                    """
                }
            }
        }

        stage('Deploy (Hotfix Swap)') {
            steps {
                sh """
                CGO_ENABLED=0 GOOS=linux go build -buildvcs=false -ldflags="-X main.version=${env.COMMIT_HASH}" -o server-pipeline .
                docker cp server-pipeline sj-container:/server
                docker restart sj-container
                curl -s http://localhost:8080
                """
            }
        }
    }

    post {
        failure {
            echo "Pipeline gagal dieksekusi. Tahap pengujian atau deployment bermasalah."
        }
        success {
            echo "Pipeline selesai dengan sukses. Hotfix binary terpasang dan tervalidasi."
        }
    }
}