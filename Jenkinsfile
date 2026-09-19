
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        DOCKER_IMAGE = 'arjunmaverick/habit-tracker:1.0'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and Test') {
            steps {
                sh '''
                    export MAVEN_OPTS="-Xms64m -Xmx256m"
                    mvn -B clean package
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t "$DOCKER_IMAGE" .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_PASSWORD'
                    )
                ]) {
                    sh '''
                        set +x
                        echo "$DOCKERHUB_PASSWORD" |
                            docker login -u "$DOCKERHUB_USERNAME" --password-stdin

                        docker push "$DOCKER_IMAGE"

                        docker logout
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'HabitApp CI/CD pipeline finished.'
        }
    }
}
