FROM jenkins/inbound-agent:latest

USER root

# Debian 13 (trixie) dividio el paquete docker.io: solo trae el daemon y ya no
# el Cliente `docker`. El agente solo necesita el CLI (habla con el socket del
# host), asi que se instala el binario estatico de Docker.
ARG DOCKER_CLI_VERSION=26.1.4

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        python3 \
        python3-pip \
        python3-venv && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz | \
      tar -xz -C /tmp docker/docker && \
    install -m 0755 /tmp/docker/docker /usr/local/bin/docker && \
    rm -rf /tmp/docker

# Deploy con StrictHostKeyChecking=yes: precargar el host key del nodo app. Si
# la VM se reconstruye, la imagen debe reconstruirse (los keys van al build).
RUN mkdir -p /home/jenkins/.ssh && \
    ssh-keyscan -H pushlane-app.lab.local >> /home/jenkins/.ssh/known_hosts 2>/dev/null && \
    chown -R jenkins:jenkins /home/jenkins/.ssh && \
    chmod 700 /home/jenkins/.ssh && chmod 600 /home/jenkins/.ssh/known_hosts

USER jenkins