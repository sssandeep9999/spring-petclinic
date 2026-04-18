pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
    }

    tools {
        maven 'maven3'
    }

    environment {
        SONAR_URL = "http://172.17.0.1:9000"
        SONAR_TOKEN = credentials('sonar-token')
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        // 🔥 1. SET PENDING STATUS
        stage('Set Pending Status') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        githubNotify context: 'CI Pipeline', status: 'PENDING'
                    }
                }
            }
        }

        stage('Build Maven') {
            steps {
                sh 'mvn clean package -DskipTests -Dcheckstyle.skip=true'
            }
        }

        stage('SonarQube Analysis') {
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

        stage('Build & Publish Artifact') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {

                    withMaven(
                        mavenSettingsConfig: 'maven-settings'
                    ) {
                        sh """
                        mvn deploy -DskipTests -Dcheckstyle.skip=true \
                        -Dusername=$USER \
                        -Dpassword=$PASS
                        """
                    }
                }
            }
        }

        // 🔥 2. SET SUCCESS STATUS
        stage('Set Success Status') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        githubNotify context: 'CI Pipeline', status: 'SUCCESS'
                }
            }
        }
    }

    // 🔥 3. FAILURE HANDLING
    post {
        failure {
            script {
                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                    githubNotify context: 'CI Pipeline', status: 'FAILURE'
                }
            }
        }
    }
}
