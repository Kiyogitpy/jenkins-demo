FROM jenkins/ssh-agent:jdk17
COPY --from=docker:27-cli /usr/local/bin/docker /usr/local/bin/docker
# Docker Desktop's socket is root:root 660, so the build user needs group 0 to use it.
RUN usermod -aG root jenkins
