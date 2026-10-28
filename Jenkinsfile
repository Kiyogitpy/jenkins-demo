pipeline {
    agent any

    environment {
        IMAGE = "jenkins-demo:${env.BUILD_NUMBER}"
    }

    stages {
        stage('Test') {
            steps {
                sh 'python3 -m unittest discover -s tests -t . -v'
            }
        }
        stage('Build') {
            steps {
                sh 'docker build -t "$IMAGE" -t jenkins-demo:latest .'
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                    docker rm -f jenkins-demo-app || true
                    docker run -d --name jenkins-demo-app -p 5000:5000 "$IMAGE"
                '''
            }
        }
    }
}
