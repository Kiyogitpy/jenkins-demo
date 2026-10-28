@Library('demo-lib') _

pipeline {
    // Each stage picks its own agent, so the approval wait below holds no executor.
    agent none

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    parameters {
        booleanParam(name: 'DEPLOY_PRODUCTION', defaultValue: false,
                     description: 'After staging, ask for approval and deploy to production on port 5000.')
    }

    environment {
        IMAGE = "jenkins-demo:${env.BRANCH_NAME.replaceAll('[^A-Za-z0-9_.-]', '-')}-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Test') {
            agent {
                docker {
                    image 'python:3.13-slim'
                    label 'docker'
                }
            }
            steps {
                sh '''
                    python -m venv .venv
                    .venv/bin/pip install --no-cache-dir -q -r requirements-dev.txt
                    .venv/bin/pytest --junitxml=reports/junit.xml
                '''
            }
            post {
                always {
                    junit 'reports/junit.xml'
                    archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
                }
            }
        }

        stage('Build image') {
            agent { label 'docker' }
            steps {
                sh 'docker build -t "$IMAGE" .'
                sh 'docker image inspect "$IMAGE" --format "{{.Id}} {{.Size}}" > image-info.txt'
                archiveArtifacts artifacts: 'image-info.txt'
            }
        }

        stage('Push to Docker Hub') {
            when {
                beforeAgent true
                branch 'main'
            }
            agent { label 'docker' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_TOKEN')]) {
                    // Single quotes: the shell expands the token, so Groovy never puts it in the log.
                    sh '''
                        echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin
                        docker tag "$IMAGE" "$DOCKERHUB_USER/jenkins-demo:$BUILD_NUMBER"
                        docker tag "$IMAGE" "$DOCKERHUB_USER/jenkins-demo:latest"
                        docker push "$DOCKERHUB_USER/jenkins-demo:$BUILD_NUMBER"
                        docker push "$DOCKERHUB_USER/jenkins-demo:latest"
                    '''
                }
            }
            post {
                always { sh 'docker logout' }
            }
        }

        stage('Deploy to staging') {
            when {
                beforeAgent true
                branch 'main'
            }
            agent { label 'docker' }
            steps {
                deployContainer(name: 'jenkins-demo-staging', port: 5001, image: env.IMAGE)
            }
        }

        stage('Deploy to production') {
            when {
                beforeInput true
                branch 'main'
                expression { params.DEPLOY_PRODUCTION }
            }
            input {
                message 'Deploy this build to production on port 5000?'
                ok 'Deploy'
            }
            agent { label 'docker' }
            steps {
                deployContainer(name: 'jenkins-demo-app', port: 5000, image: env.IMAGE)
            }
        }
    }

    post {
        success { echo "Build ${env.BUILD_NUMBER} of ${env.BRANCH_NAME} passed." }
        failure { echo "Build ${env.BUILD_NUMBER} of ${env.BRANCH_NAME} failed: ${env.BUILD_URL}console" }
    }
}
