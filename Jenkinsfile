pipeline {

    agent any

    tools {
        maven 'maven3'
        jdk 'jdk17'
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
            when {
                branch 'develop'
            }
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
            when {
                branch 'qa'
            }
            steps {
                 // Copy image-tag.txt from develop branch build
                 copyArtifacts(
                     projectName: 'Multibranch-Pipleine/develop',
                     selector: lastSuccessful(),
                     filter: 'image-tag.txt'
                 )

                 script {
                     def promotedTag = readFile('image-tag.txt').trim()

                     echo "Promoting Docker image tag ${promotedTag} to QA"

                     build job: 'petclinic-qa-cd',
                           parameters: [
                               string(name: 'IMAGE_TAG', value: promotedTag)
                           ],
                           wait: true,
                           propagate: true
                 }
            }
        }

        stage('Trigger UAT CD Pipeline') {
            when {
                branch 'uat'
            }
            steps {
                 // Copy image-tag.txt from develop branch build
                 copyArtifacts(
                     projectName: 'Multibranch-Pipeline/develop',
                     selector: lastSuccessful(),
                     filter: 'image-tag.txt'
                 )
                 
                 script {
                     def promotedTag = readFile('image-tag.txt').trim()
                     build job: 'petclinic-uat-cd',
                           parameters: [
                               string(name: 'IMAGE_TAG', value: promotedTag)
                           ],
                           wait: true,
                           propagate: true
                 }
            }
        }
        
        stage('Trigger PROD CD Pipeline') {
            when {
                branch 'master'
            }
            steps {
                 // 1. Strict Production Manual Intervention Gate
                 timeout(time: 24, unit: 'HOURS') {
                     input message: "Deploy version to live Production?", ok: "Approve Release"
                 }
                 
                 // 2. Deployment execution via distinct production runner
                 copyArtifacts(
                     projectName: 'Multibranch-Pipeline/develop',
                     selector: lastSuccessful(),
                     filter: 'image-tag.txt'
                 )
                 script {
                     def promotedTag = readFile('image-tag.txt').trim()
                     build job: 'petclinic-prod-cd',
                           parameters: [
                               string(name: 'IMAGE_TAG', value: promotedTag)
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
