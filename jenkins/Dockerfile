# Pinned with plugins.txt: plugin versions are resolved against this core version.
FROM jenkins/jenkins:2.541.3-lts-jdk17
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
