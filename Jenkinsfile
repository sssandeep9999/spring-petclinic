pipeline {

    agent any

    tools {
        maven 'maven3'
        jdk 'jdk17'
    }

    environment {
        SONAR_URL = "http://172.17.0.1:9000"
        SONAR_TOKEN = credentials('sonar-token')

        NEXUS_CREDS = credentials('nexus-creds')

        IMAGE_NAME = "petclinic-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKERHUB_USER = "satyasandeep901"
        POSTGRES_URL = "jdbc:postgresql://postgres:5432/petclinic"
        POSTGRES_USER = "petclinic"
        POSTGRES_PASS = "petclinic"
        SPRING_DOCKER_COMPOSE_ENABLED = "false"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
                echo "BRANCH_NAME: ${env.BRANCH_NAME}"
            }
        }

        /*
        ==================================================
        FEATURE BRANCH CI (FAST VALIDATION)
        ==================================================
        */

        stage('Feature Build') {
            when {
                expression {
                    env.BRANCH_NAME.startsWith("feature/")
                }
            }
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('Feature Unit Test') {
            when {
                expression {
                    env.BRANCH_NAME.startsWith("feature/")
                }
            }
            steps {
                sh 'mvn test'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh """
                    mvn sonar:sonar \
                    -Dsonar.projectKey=petclinic-app \
                    -Dsonar.host.url=$SONAR_URL \
                    -Dsonar.login=$SONAR_TOKEN
                    """
                }
            }
        }

        stage('Quality Gate') {
            when {
                branch 'develop'
            }
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Publish Artifact') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-creds',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    withMaven(globalMavenSettingsConfig: 'maven-settings', maven: 'maven3') {
                        sh 'mvn deploy -DskipTests -Dmaven.install.skip=true'
                    }
                }
            }
        }
    }

    post {

        success {
            echo "CI Pipeline Success - ${env.BRANCH_NAME}"
        }

        failure {
            echo "CI Pipeline Failed - ${env.BRANCH_NAME}"
        }

        always {
            step([$class: 'GitHubCommitStatusSetter',
                contextSource: [$class: 'ManuallyEnteredCommitContextSource', context: 'ci/jenkins-build'],
                statusResultSource: [$class: 'DefaultStatusResultSource']
            ])
        }
    }
}
