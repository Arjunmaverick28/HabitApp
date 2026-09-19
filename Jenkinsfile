
pipeline {
    agent {
        label 'linux-agent'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        JAVA_HOME = '/usr/lib/jvm/java-21-amazon-corretto.x86_64'
        PATH = "${JAVA_HOME}/bin:/usr/local/bin:/usr/bin:/bin"
        DOCKER_IMAGE = 'arjunmaverick/habit-tracker:1.0'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Java and Maven') {
            steps {
                sh '''
                    echo "Running on:"
                    hostname

                    echo "Java version:"
                    java -version

                    echo "Java compiler:"
                    javac -version

                    echo "Maven version:"
                    mvn -version

                    echo "Docker version:"
                    docker --version
                '''
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
                sh 'docker build -t "$DOCKER_IMAGE" .'
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
