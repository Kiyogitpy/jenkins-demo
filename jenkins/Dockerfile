FROM jenkins/jenkins:lts-jdk17
USER root
RUN apt-get update && apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*
# Docker CLI only; builds run on the host daemon through the mounted socket.
COPY --from=docker:27-cli /usr/local/bin/docker /usr/local/bin/docker
# The repo is bind-mounted from Windows, so its owner differs from the container user.
RUN git config --system --add safe.directory '*'
RUN jenkins-plugin-cli --plugins workflow-aggregator git
