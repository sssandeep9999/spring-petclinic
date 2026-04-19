pipeline {
    agent any

    tools {
        maven 'maven3'
    }

    environment {
        SONAR_URL = "http://172.17.0.1:9000"
        SONAR_TOKEN = credentials('sonar-token')
        // Replace with your actual repo URL
        REPO_URL = "https://github.com/sssandeep9999/spring-petclinic"
    }

    stages {
        stage('Prepare') {
            steps {
                script {
                    // Set status to PENDING as soon as the build starts
                    updateGitHubStatus('PENDING', 'Jenkins build is in progress...')
                }
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
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
                    withMaven(mavenSettingsConfig: 'maven-settings') {
                        sh '''
                        mvn deploy -DskipTests -Dcheckstyle.skip=true \
                        -Dusername=$USER \
                        -Dpassword=$PASS
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            step([$class: 'GitHubCommitStatusSetter',
                contextSource: [$class: 'ManuallyEnteredCommitContextSource', context: 'ci/jenkins-build'],
                statusResultSource: [$class: 'ConditionalStatusResultSource', results: [
                
                    [$class: 'BetterThanOrEqualBuildResult', result: 'SUCCESS', state: 'SUCCESS', message: 'Build Passed'],
                 
                    [$class: 'BetterThanOrEqualBuildResult', result: 'FAILURE', state: 'FAILURE', message: 'Build Failed'],
                
                    [$class: 'BetterThanOrEqualBuildResult', result: 'ABORTED', state: 'ERROR', message: 'Build Aborted']
                ]]
            ])
        }
    }
}