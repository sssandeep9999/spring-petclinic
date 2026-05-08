pipeline {

    agent any

    tools {
        maven 'maven3'
        jdk 'jdk17'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    environment {
        SONAR_URL = "http://172.17.0.1:9000"
        SONAR_TOKEN = credentials('sonar-token')

        NEXUS_CREDS = credentials('nexus-creds')

        IMAGE_NAME = "petclinic-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKERHUB_USER = "satyasandeep901"
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

        /*
        ==================================================
        DEVELOP BRANCH FULL CI
        ==================================================
        */

        stage('Develop Build Package') {
            when {
                branch 'develop'
            }
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Develop Test') {
            when {
                branch 'develop'
            }
            steps {
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            when {
                branch 'develop'
            }
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

        /*
        ==================================================
        ARTIFACT PUBLISH
        ==================================================
        */

        stage('Archive Artifact') {
            when {
                branch 'develop'
            }
            steps {
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
            }
        }

        stage('Publish Artifact to Nexus') {
            when {
                branch 'develop'
            }
            steps {
                withMaven(
                    maven: 'maven3',
                    globalMavenSettingsConfig: 'maven-settings'
                ) {
                    sh 'mvn deploy -DskipTests -Dmaven.install.skip=true'
                }
            }
        }

        /*
        ==================================================
        DOCKER BUILD + PUSH
        ==================================================
        */

        stage('Docker Build') {
            when {
                branch 'develop'
            }
            steps {
                sh """
                docker build -t $DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG .
                """
            }
        }

        stage('Docker Push') {
            when {
                branch 'develop'
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh """
                    echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin

                    docker push $DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG
                    """
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
