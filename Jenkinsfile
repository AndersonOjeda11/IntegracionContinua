// Pipeline de integracion continua de calculadora-ci (Entrega 2).
// Jenkins toma este archivo del repositorio (Pipeline from SCM) y lo ejecuta en cada push a main,
// que detecta con Poll SCM. Construye las imagenes de los dos contenedores de la Entrega 1,
// corre las pruebas unitarias y verifica que los contenedores se comunican por el nombre del servicio.
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '30'))
        timeout(time: 20, unit: 'MINUTES')
    }

    triggers {
        // Revisa GitHub cada minuto; si hay un commit nuevo, lanza el build sin intervencion manual.
        pollSCM('* * * * *')
    }

    environment {
        // Proyecto de Compose propio para no chocar con los contenedores de desarrollo.
        COMPOSE_PROJECT_NAME = 'calculadora-jenkins'
        APP_PORT = '5055'
        TAG = "${env.BUILD_NUMBER}"
        POSTGRES_DB = 'calculadora'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --pretty=format:"Commit %h: %s (%an)%n"'
            }
        }

        stage('Build') {
            steps {
                script {
                    // Plugin Docker Pipeline: construye las imagenes de los dos servicios.
                    docker.build("calculadora-app:${env.TAG}", '-f app/Dockerfile .')
                    docker.build("calculadora-db:${env.TAG}", 'db')
                }
                sh 'docker image ls --filter "reference=calculadora-*:${TAG}"'
            }
        }

        stage('Test') {
            steps {
                // Pruebas unitarias de la calculadora y de la configuracion por ambiente.
                sh 'python3 -m pytest -v -p no:cacheprovider --junitxml=reportes/pruebas-unitarias.xml'
            }
        }

        stage('Test de integracion') {
            steps {
                // La contrasena de PostgreSQL esta guardada en Jenkins (credencial "postgres-ci").
                withCredentials([usernamePassword(credentialsId: 'postgres-ci',
                                                  usernameVariable: 'POSTGRES_USER',
                                                  passwordVariable: 'POSTGRES_PASSWORD')]) {
                    sh '''
                        docker compose up -d --no-build --wait
                        docker compose ps
                        bash scripts/prueba_comunicacion.sh
                    '''
                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: 'reportes/*.xml'
            withCredentials([usernamePassword(credentialsId: 'postgres-ci',
                                              usernameVariable: 'POSTGRES_USER',
                                              passwordVariable: 'POSTGRES_PASSWORD')]) {
                sh 'docker compose down -v --remove-orphans || true'
            }
            sh 'docker image rm calculadora-app:${TAG} calculadora-db:${TAG} || true'
        }
        success {
            echo 'BUILD EXITOSO: imagenes construidas, pruebas unitarias en verde y comunicacion app -> db verificada.'
        }
        failure {
            echo 'BUILD FALLIDO: revise la etapa en rojo y la salida de consola.'
        }
    }
}
