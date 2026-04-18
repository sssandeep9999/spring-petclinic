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

        stage('Set Status: Pending') {
            steps {
                script {
                    setGitHubPullRequestStatus(
                        context: 'ci/jenkins',
                        state: 'PENDING',
                        repo: env.GIT_URL,
                        commitId: env.GIT_COMMIT
                    )
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
        success {
            script {
                setGitHubPullRequestStatus(
                    context: 'ci/jenkins',
                    state: 'SUCCESS',
                    repo: env.GIT_URL,
                    commitId: env.GIT_COMMIT
                )
            }
        }
        failure {
            script {
                setGitHubPullRequestStatus(
                    context: 'ci/jenkins',
                    state: 'FAILURE',
                    repo: env.GIT_URL,
                    commitId: env.GIT_COMMIT
                )
            }
        }
    }
}
