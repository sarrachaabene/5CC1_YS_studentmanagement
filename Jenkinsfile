pipeline {
    agent any

    tools {
        jdk 'JDK17'
        maven 'M2_HOME'
    }

    environment {
        DOCKERHUB_USER = 'chaabenesarra'
        IMAGE = "${DOCKERHUB_USER}/student-management"
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Git') {
            steps {
                checkout scm
                script {
                    env.BRANCHE = (env.GIT_BRANCH ?: 'main').replaceAll('^origin/', '')
                    env.TAG = "${env.BRANCHE}-${env.BUILD_NUMBER}"
                }
                echo 'Informations sur le dernier commit :'
                sh '''
                    echo "Hash court :"
                    git log -1 --pretty=format:"%h"
                    echo ""
                    echo "Auteur :"
                    git log -1 --pretty=format:"%an"
                    echo ""
                    echo "Message :"
                    git log -1 --pretty=format:"%s"
                    echo ""
                '''
                echo "Branche : ${env.BRANCHE} ; tag de l'image : ${env.TAG}"
            }
        }

        stage('Build') {
            steps {
                sh 'mvn -B clean package -DskipTests'
            }
        }

        stage('Test unitaire') {
            steps {
                sh 'mvn -B test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Docker build') {
            steps {
                sh 'docker build -t ${IMAGE}:${TAG} .'
            }
        }

        stage('Docker push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub',
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_PASS'
                )]) {
                    sh '''
                        set +x
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push "${IMAGE}:${TAG}"

                        if [ "$BRANCHE" = "main" ]; then
                            docker tag "${IMAGE}:${TAG}" "${IMAGE}:latest"
                            docker push "${IMAGE}:latest"
                        fi

                        docker logout
                    '''
                }
            }
        }

        stage('Déploiement') {
            when {
                expression { env.BRANCHE == 'main' }
            }
            steps {
                sh 'docker compose pull app'
                sh 'docker compose up -d'
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            echo "Succès : image ${IMAGE}:${TAG} traitée avec succès."
        }
        failure {
            echo 'Échec : consulter la Console Output du stage en rouge.'
        }
        always {
            sh 'docker logout || true'
            sh 'docker image rm -f "${IMAGE}:${TAG}" || true'
        }
    }
}
