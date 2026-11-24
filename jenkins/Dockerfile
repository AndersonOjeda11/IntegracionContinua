# Jenkins para la Entrega 2: Jenkins LTS + cliente de Docker + Python para las pruebas unitarias.
# Se construye y levanta con:  docker compose -f jenkins/docker-compose.yml up -d --build

# Imagen oficial de Jenkins LTS con version fija (Java 21).
FROM jenkins/jenkins:2.580.2-lts-jdk21

USER root

# Cliente de Docker con los plugins buildx y compose. El motor es el de Docker Desktop,
# al que Jenkins llega por el socket /var/run/docker.sock montado en docker-compose.yml.
# python3 y pytest se usan en la etapa Test del Jenkinsfile.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg python3 python3-pytest \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin \
 && rm -rf /var/lib/apt/lists/*

USER jenkins

# Plugins (Git/GitHub, Pipeline, Docker Pipeline, credenciales, vistas de etapas, JCasC...).
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Configuracion como codigo: usuario administrador, credencial de PostgreSQL y job del pipeline.
# Los valores secretos NO estan aqui: llegan por variables de entorno desde jenkins/.env.
COPY --chown=jenkins:jenkins casc/ /usr/share/jenkins/casc/
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/casc \
    JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

EXPOSE 8080 50000
