FROM jenkins/jenkins:lts-jdk21

# Plugins resueltos en build time: reproducibles y sin dependencia de
# conectividad en el primer arranque. jenkins-plugin-cli resuelve las
# dependencias transitivas del update center.
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
