pipeline {
    agent any


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


        stage('Build (Maven)') {
            steps {
                sh 'mvn clean package -DskipTests'
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
                        mvn clean deploy -DskipTests -Dcheckstyle.skip=true \
                        -Dusername=$USER \
                        -Dpassword=$PASS
                        """
                    }
                }
            }
        }
    }
}

