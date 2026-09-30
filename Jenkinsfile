pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        JAVA_HOME = '/usr/lib/jvm/java-21-amazon-corretto.x86_64'
        PATH = "${JAVA_HOME}/bin:/usr/local/bin:/usr/bin:/bin"

        DOCKER_REPOSITORY = 'arjunmaverick/habit-tracker'

        SONAR_ORGANIZATION = 'arjunmaverick28'
        SONAR_PROJECT_KEY = 'Arjunmaverick28_HabitApp'
        SONAR_HOST_URL = 'https://sonarcloud.io'

        GITHUB_REPOSITORY = 'https://github.com/Arjunmaverick28/HabitApp.git'
        GITHUB_BRANCH = 'main'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    echo "======================================"
                    echo "Build Host"
                    echo "======================================"
                    hostname

                    echo ""
                    echo "Java:"
                    java -version

                    echo ""
                    echo "Maven:"
                    mvn -version

                    echo ""
                    echo "Docker:"
                    docker --version

                    echo ""
                    echo "Git:"
                    git --version

                    echo ""
                    echo "Helm:"
                    helm version --short
                '''
            }
        }

        stage('Build and Test') {
            steps {
                sh '''
                    set -e

                    export MAVEN_OPTS="-Xms64m -Xmx256m"

                    mvn -B clean package
                '''
            }
        }

        stage('SonarCloud Analysis + Quality Gate') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'sonarcloud-token',
                        variable: 'SONAR_TOKEN'
                    )
                ]) {
                    sh '''
                        set -e

                        export MAVEN_OPTS="-Xms64m -Xmx256m"

                        mvn -B sonar:sonar \
                            -Dsonar.organization="$SONAR_ORGANIZATION" \
                            -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
                            -Dsonar.host.url="$SONAR_HOST_URL" \
                            -Dsonar.token="$SONAR_TOKEN" \
                            -Dsonar.qualitygate.wait=true \
                            -Dsonar.qualitygate.timeout=300
                    '''
                }
            }
        }

        stage('Set Image Version') {
            steps {
                script {
                    env.IMAGE_TAG = "1.${env.BUILD_NUMBER}"
                    env.DOCKER_IMAGE = "${env.DOCKER_REPOSITORY}:${env.IMAGE_TAG}"

                    echo "Docker image: ${env.DOCKER_IMAGE}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -e

                    docker build \
                        --pull \
                        -t "$DOCKER_IMAGE" \
                        .
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
                            docker login \
                                --username "$DOCKERHUB_USERNAME" \
                                --password-stdin

                        docker push "$DOCKER_IMAGE"

                        docker logout
                    '''
                }
            }
        }

        stage('Update Helm Image Tag') {
            steps {
                sh '''
                    set -e

                    echo "Updating Helm image tag to: $IMAGE_TAG"

                    sed -i -E \
                        's/^  tag: .*/  tag: "'"$IMAGE_TAG"'"/' \
                        helm/values.yaml

                    echo ""
                    echo "Updated Helm values:"
                    cat helm/values.yaml

                    echo ""
                    echo "Helm validation:"
                    helm lint helm
                '''
            }
        }

        stage('Commit and Push Helm Change') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-habitapp',
                        usernameVariable: 'GITHUB_USERNAME',
                        passwordVariable: 'GITHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set -e
                        set +x

                        git config user.name "Jenkins CI"
                        git config user.email "jenkins-ci@users.noreply.github.com"

                        git add helm/values.yaml

                        if git diff --cached --quiet; then
                            echo "No Helm changes to commit."
                            exit 0
                        fi

                        git commit \
                            -m "ci: deploy habit-tracker image ${IMAGE_TAG} [skip ci]"

                        git push \
                            "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/Arjunmaverick28/HabitApp.git" \
                            HEAD:${GITHUB_BRANCH}
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "======================================"
            echo "HabitApp CI/CD pipeline PASSED"
            echo "Docker Image: ${DOCKER_IMAGE}"
            echo "Helm Tag: ${IMAGE_TAG}"
            echo "Argo CD will now reconcile the Git change."
            echo "======================================"
        }

        failure {
            echo "======================================"
            echo "HabitApp CI/CD pipeline FAILED"
            echo "Deployment was NOT promoted."
            echo "======================================"
        }

        always {
            echo "HabitApp CI/CD pipeline finished."
        }
    }
}
