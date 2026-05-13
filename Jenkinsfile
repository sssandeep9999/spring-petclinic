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
        SONAR_URL   = "http://172.17.0.1:9000"
        SONAR_TOKEN = credentials('sonar-token')

        // Optional: used by Maven settings.xml for Nexus deployment
        NEXUS_CREDS = credentials('nexus-creds')

        IMAGE_NAME      = "petclinic-app"
        IMAGE_TAG       = "${BUILD_NUMBER}"
        DOCKERHUB_USER  = "satyasandeep901"

        POSTGRES_URL  = "jdbc:postgresql://postgres:5432/petclinic"
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
        Runs only for: feature/*
        ==================================================
        */

        stage('Feature Build') {
            when {
                expression {
                    env.BRANCH_NAME.startsWith('feature/')
                }
            }
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('Feature Unit Test') {
            when {
                expression {
                    env.BRANCH_NAME.startsWith('feature/')
                }
            }
            steps {
                sh 'mvn test'
            }
        }

        /*
        ==================================================
        FULL CI VALIDATION
        Runs for:
          - Pull Request builds (PR-*)
          - develop branch
        ==================================================
        */

        stage('Develop Build Package') {
            when {
                expression {
                    env.BRANCH_NAME == 'develop' ||
                    env.BRANCH_NAME.startsWith('PR-')
                }
            }
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Develop Test') {
            when {
                expression {
                    env.BRANCH_NAME == 'develop' ||
                    env.BRANCH_NAME.startsWith('PR-')
                }
            }
            steps {
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression {
                    env.BRANCH_NAME == 'develop' ||
                    env.BRANCH_NAME.startsWith('PR-')
                }
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
                expression {
                    env.BRANCH_NAME == 'develop' ||
                    env.BRANCH_NAME.startsWith('PR-')
                }
            }
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        /*
        ==================================================
        ARCHIVE ARTIFACT
        Runs for:
          - Pull Request builds
          - develop branch
        ==================================================
        */

        stage('Archive Artifact') {
            when {
                expression {
                    env.BRANCH_NAME == 'develop' ||
                    env.BRANCH_NAME.startsWith('PR-')
                }
            }
            steps {
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
            }
        }

        /*
        ==================================================
        PUBLISH ARTIFACT TO NEXUS
        Runs only for: develop
        ==================================================
        */

        stage('Publish Artifact to Nexus') {
            when {
                branch 'develop'
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-creds',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {
                    withMaven(
                        maven: 'maven3',
                        globalMavenSettingsConfig: 'maven-settings'
                    ) {
                        sh 'mvn deploy -DskipTests -Dmaven.install.skip=true'
                   }
                }
            }
        }

        /*
        ==================================================
        DOCKER BUILD
        Runs only for: develop
        ==================================================
        */

        stage('Docker Build') {
            when {
                branch 'develop'
            }
            steps {
                sh """
                    docker build \
                      -t $DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG .
                """
            }
        }

        /*
        ==================================================
        DOCKER PUSH
        Runs only for: develop
        ==================================================
        */

        stage('Docker Push') {
            when {
                branch 'develop'
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push $DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG
                    """
                }
            }
        }

        stage('Save Image Tag for Promotion') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    // Save the Docker image tag produced in develop CI
                    writeFile file: 'image-tag.txt', text: "${env.IMAGE_TAG}\n"
                    
                    // Verify saved value
                    def savedTag = readFile('image-tag.txt').trim()
                    echo "Saved promoted image tag: ${savedTag}"
                }

                // Archive the file so qa branch can copy it later
                archiveArtifacts artifacts: 'image-tag.txt', fingerprint: true
            }
        }


        stage('Trigger DEV CD Pipeline') {
            #when {
            #    branch 'develop'
            #}
            steps {
                build job: 'petclinic-dev-cd',
                      parameters: [
                          string(
                              name: 'IMAGE_TAG',
                              value: env.BUILD_NUMBER
                          )
                      ],
                      wait: true
            }
        }

        stage('Trigger QA CD Pipeline') {
            #when {
               # branch 'develop'
            #}
            steps {
                script {
                    build job: 'petclinic-qa-cd',
                          parameters: [
                              string(name: 'IMAGE_TAG', value: env.IMAGE_TAG)
                          ],
                          wait: true,
                          propagate: true
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
    }
}
