pipeline {
    agent any

    tools {
        maven 'maven3'
    }

    environment {
        SONAR_URL = "http://172.17.0.1:9000"
        SONAR_TOKEN = credentials('sonar-token')
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                echo "GIT_BRANCH: ${env.GIT_BRANCH}"
            }
        }

        stage('Build & Test') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SonarQube') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                    mvn sonar:sonar \
                    -Dsonar.projectKey=petclinic-app \
                    -Dsonar.host.url=$SONAR_URL \
                    -Dsonar.login=$SONAR_TOKEN
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        always {
            step([$class: 'GitHubCommitStatusSetter',
                contextSource: [$class: 'ManuallyEnteredCommitContextSource', context: 'ci/jenkins-build'],
                statusResultSource: [$class: 'DefaultStatusResultSource']
            ])
        }
    }
}
